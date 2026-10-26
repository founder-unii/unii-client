package com.malviys.unii

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

@Serializable
data class ToolCallFunction(
    val name: String,
    val arguments: String = "{}"
)

@Serializable
data class ToolCall(
    val id: String = "",
    val type: String = "function",
    val function: ToolCallFunction
)

@Serializable
data class FrontendToolDefinition(
    val name: String,
    val description: String,
    val parameters: JsonObject? = null
)

@Serializable
data class ChatMessage(
    val role: String,
    val content: String,
    @SerialName("tool_calls")
    val toolCalls: List<ToolCall>? = null
) {
    companion object {
        fun user(content: String) = ChatMessage("user", content)
        fun assistant(content: String, toolCalls: List<ToolCall>? = null) = ChatMessage("assistant", content, toolCalls)
        fun system(content: String) = ChatMessage("system", content)
    }
}

@Serializable
data class ChatCompletionRequest(
    val messages: List<ChatMessage>? = null,
    val query: String? = null,
    val stream: Boolean = false,
    val temperature: Double? = null,
    @SerialName("max_tokens")
    val maxTokens: Int? = null,
    val projectId: String? = null,
    val frontendTools: List<FrontendToolDefinition>? = null,
    val tools: List<FrontendToolDefinition>? = null
)

@Serializable
data class Citation(
    val documentName: String,
    val excerpt: String,
    val confidence: Double
)

@Serializable
data class ChatChoice(
    val index: Int,
    val message: ChatMessage,
    @SerialName("finish_reason")
    val finishReason: String? = "stop"
)

@Serializable
data class ChatCompletionResponse(
    val id: String,
    val `object`: String = "chat.completion",
    val created: Long,
    val model: String = "unii-rag",
    val choices: List<ChatChoice>,
    val citation: Citation? = null
)

@Serializable
data class StreamDelta(
    val role: String? = null,
    val content: String? = null,
    @SerialName("tool_calls")
    val toolCalls: List<ToolCall>? = null
)

@Serializable
data class StreamChoice(
    val index: Int,
    val delta: StreamDelta,
    @SerialName("finish_reason")
    val finishReason: String? = null
)

@Serializable
data class ChatCompletionChunk(
    val id: String,
    val `object`: String = "chat.completion.chunk",
    val choices: List<StreamChoice>
)

@Serializable
data class AuthVerificationResponse(
    val status: String,
    val keyId: String,
    val keyName: String,
    val organizationId: String,
    val projectId: String
)
