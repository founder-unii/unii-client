# Unii Swift SDK

Official Swift client package for the Unii conversational AI and knowledge grounding platform.

Compatible with iOS 15+, macOS 12+, tvOS 15+, and watchOS 8+. Built on modern Swift Concurrency (`async`/`await`, `AsyncThrowingStream`, and `Sendable`).

## Installation

Add Unii to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/malviys/unii-swift.git", from: "0.1.0")
]
```

Or add via Xcode: **File > Add Package Dependencies...** and enter repository URL.

## Quick Start

```swift
import Foundation
import Unii

// 1. Initialize client
let client = UniiClient(
    apiKey: ProcessInfo.processInfo.environment["UNII_API_KEY"] ?? "your-api-key",
    baseURL: "http://localhost:8080"
)

// 2. Verify credentials
let auth = try await client.verifyAuth()
print("Authenticated for project: \(auth.projectId)")

// 3. Conversational completion with grounded citations
let response = try await client.createChatCompletion(
    ChatCompletionRequest(
        messages: [
            ChatMessage.user("What is the return window?")
        ]
    )
)

if let choice = response.choices.first {
    print("Answer: \(choice.message.content)")
}
if let citation = response.citation {
    print("Source: \(citation.documentName) (\(citation.confidence))")
}

// 4. Stream tokens in real time
let stream = client.streamChatCompletion(
    ChatCompletionRequest(
        messages: [
            ChatMessage.user("Explain the return steps in detail.")
        ]
    )
)

for try await chunk in stream {
    if let delta = chunk.choices.first?.delta.content {
        print(delta, terminator: "")
        fflush(stdout)
    }
}
```

## Features

- Native Swift Concurrency (`async`/`await` and `AsyncThrowingStream`).
- Full type safety using `Codable` and `Sendable` types.
- Zero external third-party dependencies (built with Foundation and `URLSession`).
- Real-time Server-Sent Events (SSE) streaming support.
