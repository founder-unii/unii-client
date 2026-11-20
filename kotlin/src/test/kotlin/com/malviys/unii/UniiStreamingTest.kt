package com.malviys.unii

import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class UniiStreamingTest {
    @Test
    fun `default client waits for inference longer than ten seconds`(): Unit = runBlocking {
        val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
        server.createContext("/api/v1/chat/completions") { exchange ->
            // The live backend can take 18 seconds before it sends response headers.
            Thread.sleep(11_000)
            val body = "data: {\"id\":\"chat-slow\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Ready\"}}]}\n\ndata: [DONE]\n\n".toByteArray()
            exchange.responseHeaders.set("Content-Type", "text/event-stream")
            exchange.sendResponseHeaders(200, body.size.toLong())
            exchange.responseBody.use { it.write(body) }
        }
        server.start()
        try {
            val client = UniiClient("test-key", "http://127.0.0.1:${server.address.port}")
            val chunks = client.streamChatCompletion(ChatCompletionRequest(query = "Hello")).toList()
            assertEquals("Ready", chunks.single().choices.single().delta.content)
        } finally {
            server.stop(0)
        }
    }

    @Test
    fun `stream accepts JSON errors without masking status and details`(): Unit = runBlocking {
        val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
        server.createContext("/api/v1/chat/completions") { exchange ->
            val acceptsJson = exchange.requestHeaders.getFirst("Accept").contains("application/json")
            val body = """{"error":"Unauthorized","message":"Invalid API key"}""".toByteArray()
            exchange.responseHeaders.set("Content-Type", "application/json")
            exchange.sendResponseHeaders(if (acceptsJson) 401 else 406, body.size.toLong())
            exchange.responseBody.use { it.write(body) }
        }
        server.start()
        try {
            val client = UniiClient("test-key", "http://127.0.0.1:${server.address.port}")
            try {
                client.streamChatCompletion(ChatCompletionRequest(query = "Hello")).toList()
                fail<Unit>("Expected API failure")
            } catch (error: UniiApiException) {
                assertEquals(401, error.statusCode)
                assertTrue(error.details.orEmpty().contains("Invalid API key"))
            }
        } finally {
            server.stop(0)
        }
    }

    @Test
    fun `stream still receives content and tool calls`(): Unit = runBlocking {
        val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
        server.createContext("/api/v1/chat/completions") { exchange ->
            val body = """data: {"id":"chat-1","choices":[{"index":0,"delta":{"content":"Hello","tool_calls":[{"id":"call-1","function":{"name":"query_diagnostics","arguments":"{}"}}]}}]}

 data: [DONE]

""".replace(" data:", "data:").toByteArray()
            exchange.responseHeaders.set("Content-Type", "text/event-stream")
            exchange.sendResponseHeaders(200, body.size.toLong())
            exchange.responseBody.use { it.write(body) }
        }
        server.start()
        try {
            val client = UniiClient("test-key", "http://127.0.0.1:${server.address.port}")
            val chunks = client.streamChatCompletion(ChatCompletionRequest(query = "Hello")).toList()
            assertEquals(1, chunks.size)
            assertEquals("Hello", chunks.single().choices.single().delta.content)
            assertEquals("query_diagnostics", chunks.single().choices.single().delta.toolCalls?.single()?.function?.name)
        } finally {
            server.stop(0)
        }
    }
    @Test
    fun `text messages omit absent tool history fields`(): Unit = runBlocking {
        val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
        server.createContext("/api/v1/chat/completions") { exchange ->
            val requestBody = exchange.requestBody.bufferedReader().use { it.readText() }
            val hasToolHistory = requestBody.contains("\"tool_calls\"")
            val body = if (hasToolHistory) {
                """{"message":"Tool history is unsupported."}"""
            } else {
                "data: {\"id\":\"chat-1\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Accepted\"}}]}\n\ndata: [DONE]\n\n"
            }
            val bytes = body.toByteArray()
            exchange.responseHeaders.set("Content-Type", if (hasToolHistory) "application/json" else "text/event-stream")
            exchange.sendResponseHeaders(if (hasToolHistory) 400 else 200, bytes.size.toLong())
            exchange.responseBody.use { it.write(bytes) }
        }
        server.start()
        try {
            val client = UniiClient("test-key", "http://127.0.0.1:${server.address.port}")
            val chunks = client.streamChatCompletion(
                ChatCompletionRequest(messages = listOf(ChatMessage.user("Hello")))
            ).toList()
            assertEquals("Accepted", chunks.single().choices.single().delta.content)
        } finally {
            server.stop(0)
        }
    }

}
