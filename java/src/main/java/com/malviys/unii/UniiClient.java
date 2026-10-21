package com.malviys.unii;

import com.malviys.unii.exception.UniiApiException;
import com.malviys.unii.model.*;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;

public class UniiClient {
    private final String apiKey;
    private final String baseUrl;
    private final HttpClient httpClient;

    private UniiClient(Builder builder) {
        this.apiKey = Objects.requireNonNull(builder.apiKey, "apiKey is required");
        if (apiKey.isBlank()) {
            throw new IllegalArgumentException("apiKey cannot be empty");
        }
        this.baseUrl = builder.baseUrl.replaceAll("/+$", "");
        this.httpClient = builder.httpClient != null ? builder.httpClient : HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();
    }

    public static Builder builder() {
        return new Builder();
    }

    public static UniiClient create(String apiKey) {
        return builder().apiKey(apiKey).build();
    }

    public AuthVerificationResponse verifyAuth() {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/v1/auth/verify"))
                .header("Authorization", "Bearer " + apiKey)
                .header("User-Agent", "unii-java-sdk/0.1.0")
                .GET()
                .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() >= 400) {
                throw new UniiApiException(response.statusCode(), "Authentication failed", response.body());
            }

            String body = response.body();
            return new AuthVerificationResponse(
                extractJsonString(body, "status", "authenticated"),
                extractJsonString(body, "keyId", ""),
                extractJsonString(body, "keyName", ""),
                extractJsonString(body, "organizationId", ""),
                extractJsonString(body, "projectId", "")
            );
        } catch (UniiApiException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Failed to verify authentication: " + e.getMessage(), e);
        }
    }

    public ChatCompletionResponse createChatCompletion(ChatCompletionRequest req) {
        try {
            String url = baseUrl + "/api/v1/chat/completions";
            if (req.projectId() != null && !req.projectId().isBlank()) {
                url += "?projectId=" + req.projectId();
            }

            String jsonPayload = buildChatPayload(req, false);

            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .header("User-Agent", "unii-java-sdk/0.1.0")
                .POST(HttpRequest.BodyPublishers.ofString(jsonPayload, StandardCharsets.UTF_8))
                .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() >= 400) {
                throw new UniiApiException(response.statusCode(), "Chat completion failed", response.body());
            }

            String body = response.body();
            String id = extractJsonString(body, "id", "chatcmpl-" + System.currentTimeMillis());
            String model = extractJsonString(body, "model", "unii-rag");
            String content = extractJsonString(body, "content", "");

            Citation citation = null;
            if (body.contains("\"citation\"")) {
                String docName = extractJsonString(body, "documentName", "");
                String excerpt = extractJsonString(body, "excerpt", "");
                citation = new Citation(docName, excerpt, 0.95);
            }

            List<ChatChoice> choices = List.of(
                new ChatChoice(0, new ChatMessage("assistant", content), "stop")
            );

            return new ChatCompletionResponse(id, "chat.completion", System.currentTimeMillis() / 1000, model, choices, citation);
        } catch (UniiApiException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Failed to create chat completion: " + e.getMessage(), e);
        }
    }

    public Stream<StreamChatCompletionChunk> streamChatCompletion(ChatCompletionRequest req) {
        try {
            String url = baseUrl + "/api/v1/chat/completions?stream=true";
            if (req.projectId() != null && !req.projectId().isBlank()) {
                url += "&projectId=" + req.projectId();
            }

            String jsonPayload = buildChatPayload(req, true);

            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .header("Accept", "text/event-stream")
                .header("User-Agent", "unii-java-sdk/0.1.0")
                .POST(HttpRequest.BodyPublishers.ofString(jsonPayload, StandardCharsets.UTF_8))
                .build();

            HttpResponse<InputStream> response = httpClient.send(request, HttpResponse.BodyHandlers.ofInputStream());
            if (response.statusCode() >= 400) {
                String err = new String(response.body().readAllBytes(), StandardCharsets.UTF_8);
                throw new UniiApiException(response.statusCode(), "Stream failed", err);
            }

            BufferedReader reader = new BufferedReader(new InputStreamReader(response.body(), StandardCharsets.UTF_8));
            Iterator<StreamChatCompletionChunk> iterator = new Iterator<>() {
                private StreamChatCompletionChunk nextChunk = null;
                private boolean done = false;

                @Override
                public boolean hasNext() {
                    if (done) return false;
                    if (nextChunk != null) return true;

                    try {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            line = line.trim();
                            if (line.isEmpty() || !line.startsWith("data:")) continue;
                            String data = line.substring(5).trim();
                            if ("[DONE]".equals(data)) {
                                done = true;
                                reader.close();
                                return false;
                            }
                            String content = extractJsonString(data, "content", "");
                            nextChunk = new StreamChatCompletionChunk(
                                "chatcmpl-" + System.currentTimeMillis(),
                                "chat.completion.chunk",
                                System.currentTimeMillis() / 1000,
                                "unii-rag",
                                List.of(new StreamChoice(0, new StreamDelta("assistant", content), null))
                            );
                            return true;
                        }
                        done = true;
                        reader.close();
                        return false;
                    } catch (Exception e) {
                        done = true;
                        return false;
                    }
                }

                @Override
                public StreamChatCompletionChunk next() {
                    if (!hasNext()) throw new NoSuchElementException();
                    StreamChatCompletionChunk c = nextChunk;
                    nextChunk = null;
                    return c;
                }
            };

            return StreamSupport.stream(((Iterable<StreamChatCompletionChunk>) () -> iterator).spliterator(), false);
        } catch (UniiApiException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Failed to stream chat completion: " + e.getMessage(), e);
        }
    }

    private String buildChatPayload(ChatCompletionRequest req, boolean forceStream) {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"messages\":[");
        for (int i = 0; i < req.messages().size(); i++) {
            ChatMessage msg = req.messages().get(i);
            if (i > 0) sb.append(",");
            sb.append("{\"role\":\"").append(escapeJson(msg.role())).append("\",\"content\":\"")
              .append(escapeJson(msg.content())).append("\"}");
        }
        sb.append("],\"stream\":").append(forceStream || Boolean.TRUE.equals(req.stream()));
        if (req.temperature() != null) {
            sb.append(",\"temperature\":").append(req.temperature());
        }
        if (req.maxTokens() != null) {
            sb.append(",\"max_tokens\":").append(req.maxTokens());
        }
        sb.append("}");
        return sb.toString();
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }

    private static String extractJsonString(String json, String key, String defaultVal) {
        Pattern pattern = Pattern.compile("\"" + Pattern.quote(key) + "\"\\s*:\\s*\"([^\"]*)\"");
        Matcher matcher = pattern.matcher(json);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return defaultVal;
    }

    public static class Builder {
        private String apiKey;
        private String baseUrl = "http://localhost:8080";
        private HttpClient httpClient;

        public Builder apiKey(String apiKey) {
            this.apiKey = apiKey;
            return this;
        }

        public Builder baseUrl(String baseUrl) {
            if (baseUrl != null && !baseUrl.isBlank()) {
                this.baseUrl = baseUrl;
            }
            return this;
        }

        public Builder httpClient(HttpClient httpClient) {
            this.httpClient = httpClient;
            return this;
        }

        public UniiClient build() {
            return new UniiClient(this);
        }
    }
}
