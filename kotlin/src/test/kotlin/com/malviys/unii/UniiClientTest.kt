package com.malviys.unii

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class UniiClientTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun testChatMessageSerialization() {
        val userMsg = ChatMessage.user("Hello Kotlin")
        assertEquals("user", userMsg.role)
        assertEquals("Hello Kotlin", userMsg.content)

        val serialized = json.encodeToString(userMsg)
        val decoded = json.decodeFromString<ChatMessage>(serialized)
        assertEquals("user", decoded.role)
        assertEquals("Hello Kotlin", decoded.content)
    }

    @Test
    fun testChatCompletionResponseDeserialization() {
        val raw = """
            {
                "id": "chatcmpl-kt-123",
                "object": "chat.completion",
                "created": 1700000000,
                "model": "unii-rag",
                "choices": [
                    {
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": "Kotlin response"
                        },
                        "finish_reason": "stop"
                    }
                ],
                "citation": {
                    "documentName": "kotlin_guide.md",
                    "excerpt": "Coroutines and Flows",
                    "confidence": 0.97
                }
            }
        """.trimIndent()

        val res = json.decodeFromString<ChatCompletionResponse>(raw)
        assertEquals("chatcmpl-kt-123", res.id)
        assertEquals(1, res.choices.size)
        assertEquals("Kotlin response", res.choices[0].message.content)
        assertNotNull(res.citation)
        assertEquals("kotlin_guide.md", res.citation?.documentName)
        assertEquals(0.97, res.citation?.confidence)
    }

    @Test
    fun testAuthVerificationResponseDeserialization() {
        val raw = """
            {
                "status": "authenticated",
                "keyId": "k-kt",
                "keyName": "test-key",
                "organizationId": "org-kt",
                "projectId": "proj-kt"
            }
        """.trimIndent()

        val auth = json.decodeFromString<AuthVerificationResponse>(raw)
        assertEquals("authenticated", auth.status)
        assertEquals("k-kt", auth.keyId)
        assertEquals("proj-kt", auth.projectId)
    }

    @Test
    fun testClientRequiresApiKey() {
        assertThrows(IllegalArgumentException::class.java) {
            UniiClient(apiKey = "")
        }
    }

    @Test
    fun testToolCallSerialization() {
        val toolCall = ToolCall(
            id = "call_123",
            type = "function",
            function = ToolCallFunction(
                name = "get_weather",
                arguments = "{\"location\":\"San Francisco\"}"
            )
        )
        val assistantMsg = ChatMessage.assistant(
            content = "Checking weather...",
            toolCalls = listOf(toolCall)
        )

        val serialized = json.encodeToString(assistantMsg)
        val decoded = json.decodeFromString<ChatMessage>(serialized)
        assertEquals("assistant", decoded.role)
        assertEquals(1, decoded.toolCalls?.size)
        assertEquals("call_123", decoded.toolCalls?.first()?.id)
        assertEquals("get_weather", decoded.toolCalls?.first()?.function?.name)
    }
}
