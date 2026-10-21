using System.Net.Http.Headers;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.Json;

namespace Unii.Sdk;

public class UniiClient
{
    private readonly string _apiKey;
    private readonly string _baseUrl;
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public UniiClient(string apiKey, string baseUrl = "http://localhost:8080", HttpClient? httpClient = null)
    {
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new ArgumentException("apiKey is required and cannot be empty", nameof(apiKey));
        }

        _apiKey = apiKey.Trim();
        _baseUrl = baseUrl.TrimEnd('/');
        _httpClient = httpClient ?? new HttpClient();
    }

    private HttpRequestMessage CreateRequest(HttpMethod method, string path)
    {
        var request = new HttpRequestMessage(method, $"{_baseUrl}{path}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);
        request.Headers.Add("User-Agent", "unii-csharp-sdk/0.1.0");
        return request;
    }

    public async Task<AuthVerificationResponse> VerifyAuthAsync(CancellationToken cancellationToken = default)
    {
        using var request = CreateRequest(HttpMethod.Get, "/api/v1/auth/verify");
        using var response = await _httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);

        var content = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            throw new UniiApiException((int)response.StatusCode, "Auth verification failed", content);
        }

        return JsonSerializer.Deserialize<AuthVerificationResponse>(content, JsonOptions)
            ?? throw new UniiApiException((int)response.StatusCode, "Null response returned", content);
    }

    public async Task<ChatCompletionResponse> CreateChatCompletionAsync(ChatCompletionRequest request, CancellationToken cancellationToken = default)
    {
        request.Stream = false;
        var path = "/api/v1/chat/completions";
        if (!string.IsNullOrEmpty(request.ProjectId))
        {
            path += $"?projectId={Uri.EscapeDataString(request.ProjectId)}";
        }

        using var httpRequest = CreateRequest(HttpMethod.Post, path);
        var json = JsonSerializer.Serialize(request, JsonOptions);
        httpRequest.Content = new StringContent(json, Encoding.UTF8, "application/json");

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken).ConfigureAwait(false);
        var content = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);

        if (!response.IsSuccessStatusCode)
        {
            throw new UniiApiException((int)response.StatusCode, "Chat completion failed", content);
        }

        return JsonSerializer.Deserialize<ChatCompletionResponse>(content, JsonOptions)
            ?? throw new UniiApiException((int)response.StatusCode, "Null response returned", content);
    }

    public async IAsyncEnumerable<StreamChatCompletionChunk> StreamChatCompletionAsync(
        ChatCompletionRequest request,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        request.Stream = true;
        var path = "/api/v1/chat/completions?stream=true";
        if (!string.IsNullOrEmpty(request.ProjectId))
        {
            path += $"&projectId={Uri.EscapeDataString(request.ProjectId)}";
        }

        using var httpRequest = CreateRequest(HttpMethod.Post, path);
        httpRequest.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("text/event-stream"));
        var json = JsonSerializer.Serialize(request, JsonOptions);
        httpRequest.Content = new StringContent(json, Encoding.UTF8, "application/json");

        using var response = await _httpClient.SendAsync(httpRequest, HttpCompletionOption.ResponseHeadersRead, cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            var err = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            throw new UniiApiException((int)response.StatusCode, "Chat streaming failed", err);
        }

        using var stream = await response.Content.ReadAsStreamAsync(cancellationToken).ConfigureAwait(false);
        using var reader = new StreamReader(stream, Encoding.UTF8);

        while (!reader.EndOfStream)
        {
            var line = await reader.ReadLineAsync(cancellationToken).ConfigureAwait(false);
            if (string.IsNullOrWhiteSpace(line) || !line.StartsWith("data:"))
            {
                continue;
            }

            var data = line[5..].Trim();
            if (data == "[DONE]")
            {
                yield break;
            }

            StreamChatCompletionChunk? chunk = null;
            try
            {
                chunk = JsonSerializer.Deserialize<StreamChatCompletionChunk>(data, JsonOptions);
            }
            catch (JsonException)
            {
                continue;
            }

            if (chunk != null)
            {
                yield return chunk;
            }
        }
    }
}
