namespace Unii.Sdk;

public class UniiApiException : Exception
{
    public int StatusCode { get; }
    public string ResponseBody { get; }

    public UniiApiException(int statusCode, string message, string responseBody)
        : base($"HTTP {statusCode}: {message}")
    {
        StatusCode = statusCode;
        ResponseBody = responseBody;
    }
}
