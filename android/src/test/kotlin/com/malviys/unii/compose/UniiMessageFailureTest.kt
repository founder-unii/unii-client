package com.malviys.unii.compose

import com.malviys.unii.UniiApiException
import com.malviys.unii.UniiClient
import java.io.IOException
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.*
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class UniiMessageFailureTest {
    private fun response(code: Int, body: String, contentType: String) = OkHttpClient.Builder()
        .addInterceptor { chain ->
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1)
                .code(code).message("Test response").header("Content-Type", contentType)
                .body(body.toResponseBody(contentType.toMediaType())).build()
        }.build()

    @Test
    fun `HTTP error is recoverable and retry does not duplicate user message`() = runTest {
        val attempts = AtomicInteger()
        val http = OkHttpClient.Builder().addInterceptor { chain ->
            val failed = attempts.getAndIncrement() == 0
            val body = if (failed) """{"message":"Invalid API key"}""" else
                "data: {\"id\":\"chat-1\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"Recovered\"}}]}\n\ndata: [DONE]\n\n"
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1)
                .code(if (failed) 401 else 200).message("Test response")
                .header("Content-Type", if (failed) "application/json" else "text/event-stream")
                .body(body.toResponseBody((if (failed) "application/json" else "text/event-stream").toMediaType())).build()
        }.build()
        val state = UniiState(UniiClient("test-key", okHttpClient = http), this)
        state.sendMessage("Hello")
        state.sendMessage("Duplicate")
        assertTrue(state.isLoading.value)
        state.isLoading.first { !it }
        assertEquals(401, (state.error.value as UniiApiException).statusCode)
        assertEquals(listOf("Hello"), state.messages.value.map { it.content })
        state.retryLastMessage()
        state.isLoading.first { !it }
        assertNull(state.error.value)
        assertEquals(listOf("Hello", "Recovered"), state.messages.value.map { it.content })
        assertEquals(2, attempts.get())
    }

    @Test
    fun `HTTP 406 stays in state instead of crashing the UI scope`() = runTest {
        val http = response(406, """{"message":"Not Acceptable"}""", "application/json")
        val state = UniiState(UniiClient("test-key", okHttpClient = http), this)
        state.sendMessage("What can you do?")
        state.isLoading.first { !it }
        val failure = state.error.value as UniiApiException
        assertEquals(406, failure.statusCode)
        assertTrue(failure.details.orEmpty().contains("Not Acceptable"))
        assertEquals(listOf("What can you do?"), state.messages.value.map { it.content })
    }

    @Test
    fun `network failure resets loading without escaping scope`() = runTest {
        val http = OkHttpClient.Builder().addInterceptor { throw IOException("Connection refused") }.build()
        val state = UniiState(UniiClient("test-key", okHttpClient = http), this)
        state.sendMessage("Hello")
        state.isLoading.first { !it }
        assertTrue(state.error.value is IOException)
        assertEquals(1, state.messages.value.size)
    }

    @Test
    fun `non streaming HTTP failure also stays in state`() = runTest {
        val http = response(503, """{"message":"Unavailable"}""", "application/json")
        val state = UniiState(UniiClient("test-key", okHttpClient = http), this, stream = false)
        state.sendMessage("Hello")
        state.isLoading.first { !it }
        assertEquals(503, (state.error.value as UniiApiException).statusCode)
    }

    @Test
    fun `action cancellation is not reported as a request failure`() = runTest {
        val http = response(200, """{"id":"chat-1","created":0,"choices":[{"index":0,"message":{"role":"assistant","content":"","tool_calls":[{"id":"call-1","function":{"name":"cancel","arguments":"{}"}}]}}]}""", "application/json")
        val state = UniiState(UniiClient("test-key", okHttpClient = http), this, stream = false)
        state.registerAction(UniiActionConfig(name = "cancel", description = "Cancel", handler = {
            throw CancellationException("Screen left")
        }))
        state.sendMessage("Hello")
        state.isLoading.first { !it }
        assertNull(state.error.value)
    }
}
