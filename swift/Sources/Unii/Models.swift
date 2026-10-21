import Foundation

public struct ChatMessage: Codable, Sendable, Equatable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }

    public static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: "user", content: content)
    }

    public static func assistant(_ content: String) -> ChatMessage {
        ChatMessage(role: "assistant", content: content)
    }

    public static func system(_ content: String) -> ChatMessage {
        ChatMessage(role: "system", content: content)
    }
}

public struct ChatCompletionRequest: Codable, Sendable {
    public var messages: [ChatMessage]?
    public var query: String?
    public var stream: Bool
    public var temperature: Double?
    public var maxTokens: Int?
    public var projectId: String?

    public init(
        messages: [ChatMessage]? = nil,
        query: String? = nil,
        stream: Bool = false,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        projectId: String? = nil
    ) {
        self.messages = messages
        self.query = query
        self.stream = stream
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.projectId = projectId
    }

    enum CodingKeys: String, CodingKey {
        case messages
        case query
        case stream
        case temperature
        case maxTokens = "max_tokens"
        case projectId
    }
}

public struct Citation: Codable, Sendable, Equatable {
    public let documentName: String
    public let excerpt: String
    public let confidence: Double

    public init(documentName: String, excerpt: String, confidence: Double) {
        self.documentName = documentName
        self.excerpt = excerpt
        self.confidence = confidence
    }
}

public struct ChatChoice: Codable, Sendable, Equatable {
    public let index: Int
    public let message: ChatMessage
    public let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

public struct ChatCompletionResponse: Codable, Sendable {
    public let id: String
    public let object: String
    public let created: Int64
    public let model: String
    public let choices: [ChatChoice]
    public let citation: Citation?

    public init(
        id: String,
        object: String,
        created: Int64,
        model: String,
        choices: [ChatChoice],
        citation: Citation? = nil
    ) {
        self.id = id
        self.object = object
        self.created = created
        self.model = model
        self.choices = choices
        self.citation = citation
    }
}

public struct StreamDelta: Codable, Sendable, Equatable {
    public let role: String?
    public let content: String?

    public init(role: String? = nil, content: String? = nil) {
        self.role = role
        self.content = content
    }
}

public struct StreamChoice: Codable, Sendable, Equatable {
    public let index: Int
    public let delta: StreamDelta
    public let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index
        case delta
        case finishReason = "finish_reason"
    }

    public init(index: Int, delta: StreamDelta, finishReason: String? = nil) {
        self.index = index
        self.delta = delta
        self.finishReason = finishReason
    }
}

public struct ChatCompletionChunk: Codable, Sendable {
    public let id: String
    public let object: String
    public let choices: [StreamChoice]

    public init(id: String, object: String, choices: [StreamChoice]) {
        self.id = id
        self.object = object
        self.choices = choices
    }
}

public struct AuthVerificationResponse: Codable, Sendable, Equatable {
    public let status: String
    public let keyId: String
    public let keyName: String
    public let organizationId: String
    public let projectId: String

    public init(status: String, keyId: String, keyName: String, organizationId: String, projectId: String) {
        self.status = status
        self.keyId = keyId
        self.keyName = keyName
        self.organizationId = organizationId
        self.projectId = projectId
    }
}
