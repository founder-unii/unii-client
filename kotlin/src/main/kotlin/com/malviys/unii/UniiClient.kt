package com.malviys.unii

import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.sse.EventSource
import okhttp3.sse.EventSourceListener
import okhttp3.sse.EventSources
import java.io.IOException
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class UniiClient(
    private val apiKey: String,
    baseUrl: String = "http://localhost:8080",
    private val defaultProjectId: String? = null,
    private val okHttpClient: OkHttpClient = OkHttpClient()
) {
    init {
        require(apiKey.isNotBlank()) { "apiKey cannot be blank" }
    }

    val baseUrl: String = baseUrl.trimEnd('/')

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    private fun requestBuilder(path: String): Request.Builder {
        return Request.Builder()
            .url("$baseUrl$path")
            .header("Authorization", "Bearer $apiKey")
            .header("User-Agent", "unii-kotlin-sdk/0.1.0")
    }

    suspend fun verifyAuth(): AuthVerificationResponse = suspendCancellableCoroutine { continuation ->
        val request = requestBuilder("/api/v1/auth/verify")
            .header("Accept", "application/json")
            .get()
            .build()

        val call = okHttpClient.newCall(request)
        continuation.invokeOnCancellation { call.cancel() }

        call.enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                continuation.resumeWithException(e)
            }

            override fun onResponse(call: Call, response: Response) {
                response.use { res ->
                    val bodyString = res.body?.string().orEmpty()
                    if (!res.isSuccessful) {
                        continuation.resumeWithException(
                            UniiApiException(res.code, "Auth verification failed", bodyString)
                        )
                        return
                    }
                    try {
                        val auth = json.decodeFromString<AuthVerificationResponse>(bodyString)
                        continuation.resume(auth)
                    } catch (e: Exception) {
                        continuation.resumeWithException(e)
                    }
                }
            }
        })
    }

    suspend fun createChatCompletion(request: ChatCompletionRequest): ChatCompletionResponse =
        suspendCancellableCoroutine { continuation ->
            val payload = request.copy(
                stream = false,
                projectId = request.projectId ?: defaultProjectId
            )
            val jsonBody = json.encodeToString(payload)
            val req = requestBuilder("/api/v1/chat/completions")
                .header("Accept", "application/json")
                .post(jsonBody.toRequestBody("application/json".toMediaType()))
                .build()

            val call = okHttpClient.newCall(req)
            continuation.invokeOnCancellation { call.cancel() }

            call.enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    continuation.resumeWithException(e)
                }

                override fun onResponse(call: Call, response: Response) {
                    response.use { res ->
                        val bodyString = res.body?.string().orEmpty()
                        if (!res.isSuccessful) {
                            continuation.resumeWithException(
                                UniiApiException(res.code, "Chat completion failed", bodyString)
                            )
                            return
                        }
                        try {
                            val chatRes = json.decodeFromString<ChatCompletionResponse>(bodyString)
                            continuation.resume(chatRes)
                        } catch (e: Exception) {
                            continuation.resumeWithException(e)
                        }
                    }
                }
            })
        }

    fun streamChatCompletion(request: ChatCompletionRequest): Flow<ChatCompletionChunk> = callbackFlow {
        val payload = request.copy(
            stream = true,
            projectId = request.projectId ?: defaultProjectId
        )
        val jsonBody = json.encodeToString(payload)
        val req = requestBuilder("/api/v1/chat/completions")
            .header("Accept", "text/event-stream")
            .post(jsonBody.toRequestBody("application/json".toMediaType()))
            .build()

        val factory = EventSources.createFactory(okHttpClient)
        val eventSource = factory.newEventSource(req, object : EventSourceListener() {
            override fun onEvent(eventSource: EventSource, id: String?, type: String?, data: String) {
                if (data.trim() == "[DONE]") {
                    channel.close()
                    return
                }
                try {
                    val chunk = json.decodeFromString<ChatCompletionChunk>(data)
                    trySend(chunk)
                } catch (_: Exception) {
                    // skip malformed frame
                }
            }

            override fun onFailure(eventSource: EventSource, t: Throwable?, response: Response?) {
                val err = if (response != null && !response.isSuccessful) {
                    UniiApiException(response.code, "Stream failed: ${response.message}")
                } else {
                    t ?: RuntimeException("SSE stream failed")
                }
                channel.close(err)
            }

            override fun onClosed(eventSource: EventSource) {
                channel.close()
            }
        })

        awaitClose {
            eventSource.cancel()
        }
    }
}
