# unii-kotlin (Kotlin SDK)

Official Kotlin client library for the Unii conversational AI platform.

Designed specifically for Kotlin with native coroutines and `Flow<ChatCompletionChunk>` for reactive streaming.

## Installation

Add to your `build.gradle.kts`:

```kotlin
dependencies {
    implementation("io.github.dev-unii:unii-kotlin:0.1.0")
}
```

## Quick Start

```kotlin
import com.malviys.unii.UniiClient
import com.malviys.unii.ChatMessage
import com.malviys.unii.ChatCompletionRequest
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val client = UniiClient(
        apiKey = System.getenv("UNII_API_KEY") ?: "YOUR_API_KEY",
        baseUrl = "http://localhost:8080"
    )

    // 1. Verify credentials
    val auth = client.verifyAuth()
    println("Connected for project: ${auth.projectId}")

    // 2. Chat completion
    val response = client.createChatCompletion(
        ChatCompletionRequest(
            messages = listOf(ChatMessage.user("Explain the return policy."))
        )
    )
    println(response.choices.first().message.content)

    // 3. Reactive streaming with Coroutine Flow
    client.streamChatCompletion(
        ChatCompletionRequest(
            messages = listOf(ChatMessage.user("List the warranty conditions."))
        )
    ).collect { chunk ->
        chunk.choices.firstOrNull()?.delta?.content?.let { print(it) }
    }
}
```

## Features

- Built with Kotlin Coroutines (`suspend` functions and `Flow`).
- Full JSON serialization support via `kotlinx.serialization`.
- Server-Sent Events (SSE) streaming backed by OkHttp SSE.
- Multiplatform and Android ready.
