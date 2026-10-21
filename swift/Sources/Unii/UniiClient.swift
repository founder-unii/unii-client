import Foundation

public final class UniiClient: @unchecked Sendable {
    public let apiKey: String
    public let baseURL: URL
    public let projectId: String?
    private let urlSession: URLSession

    public init(
        apiKey: String,
        baseURL: String = "http://localhost:8080",
        projectId: String? = nil,
        urlSession: URLSession = .shared
    ) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!trimmedKey.isEmpty, "apiKey cannot be empty")
        self.apiKey = trimmedKey
        let trimmedURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.baseURL = URL(string: trimmedURL) ?? URL(string: "http://localhost:8080")!
        self.projectId = projectId
        self.urlSession = urlSession
    }

    private func createRequest(path: String, method: String) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("unii-swift-sdk/0.1.0", forHTTPHeaderField: "User-Agent")
        return request
    }

    public func verifyAuth() async throws -> AuthVerificationResponse {
        var request = createRequest(path: "api/v1/auth/verify", method: "GET")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UniiApiError(statusCode: 0, message: "Invalid response from server")
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            let errorText = String(data: data, encoding: .utf8) ?? "Authentication verification failed"
            throw UniiApiError(statusCode: httpResponse.statusCode, message: errorText)
        }

        return try JSONDecoder().decode(AuthVerificationResponse.self, from: data)
    }

    public func createChatCompletion(_ completionRequest: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        var req = completionRequest
        req.stream = false
        if req.projectId == nil {
            req.projectId = self.projectId
        }

        var request = createRequest(path: "api/v1/chat/completions", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(req)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UniiApiError(statusCode: 0, message: "Invalid response from server")
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            let errorText = String(data: data, encoding: .utf8) ?? "Chat completion failed"
            throw UniiApiError(statusCode: httpResponse.statusCode, message: errorText)
        }

        return try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
    }

    public func streamChatCompletion(_ completionRequest: ChatCompletionRequest) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var req = completionRequest
                    req.stream = true
                    if req.projectId == nil {
                        req.projectId = self.projectId
                    }

                    var request = self.createRequest(path: "api/v1/chat/completions", method: "POST")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.httpBody = try JSONEncoder().encode(req)

                    let (bytes, response) = try await self.urlSession.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw UniiApiError(statusCode: 0, message: "Invalid stream response")
                    }

                    guard (200..<300).contains(httpResponse.statusCode) else {
                        throw UniiApiError(statusCode: httpResponse.statusCode, message: "Stream request failed")
                    }

                    let decoder = JSONDecoder()
                    for try await line in bytes.lines {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty || trimmed.hasPrefix(":") {
                            continue
                        }

                        if trimmed.hasPrefix("data:") {
                            let dataContent = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
                            if dataContent == "[DONE]" {
                                continuation.finish()
                                return
                            }

                            if let data = dataContent.data(using: .utf8) {
                                if let chunk = try? decoder.decode(ChatCompletionChunk.self, from: data) {
                                    continuation.yield(chunk)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
