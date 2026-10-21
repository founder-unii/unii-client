package com.malviys.unii.exception;

public class UniiApiException extends RuntimeException {
    private final int statusCode;
    private final String responseBody;

    public UniiApiException(int statusCode, String message, String responseBody) {
        super("HTTP " + statusCode + ": " + message);
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    public int getStatusCode() {
        return statusCode;
    }

    public String getResponseBody() {
        return responseBody;
    }
}
