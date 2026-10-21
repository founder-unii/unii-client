# unii (Dart & Flutter SDK)

Official Dart and Flutter client SDK for the Unii conversational AI and RAG grounding platform.

Supports Dart 3.0+ and all Flutter targets (iOS, Android, Web, macOS, Windows, Linux).

## Installation

Add `unii` to your `pubspec.yaml`:

```yaml
dependencies:
  unii: ^0.1.0
```

Or run:

```bash
dart pub add unii
# or for Flutter:
flutter pub add unii
```

## Quick Start

```dart
import 'package:unii/unii.dart';

void main() async {
  final client = UniiClient(
    apiKey: 'YOUR_API_KEY',
    baseUrl: 'http://localhost:8080',
  );

  // 1. Verify credentials
  final auth = await client.verifyAuth();
  print('Authenticated for Project ID: ${auth.projectId}');

  // 2. Chat Completion
  final response = await client.createChatCompletion(
    ChatCompletionRequest(
      messages: [
        ChatMessage.user('What are the refund terms?'),
      ],
    ),
  );

  print('Assistant: ${response.choices.first.message.content}');
  if (response.citation != null) {
    print('Source: ${response.citation!.documentName}');
  }

  // 3. Stream Tokens via Server-Sent Events (SSE)
  final stream = client.streamChatCompletion(
    ChatCompletionRequest(
      messages: [
        ChatMessage.user('Summarize the return window.'),
      ],
    ),
  );

  await for (final chunk in stream) {
    final delta = chunk.choices.first.delta.content;
    if (delta != null) {
      print(delta);
    }
  }

  client.close();
}
```

## Features

- Full support for grounded RAG citations (`documentName`, `excerpt`, `confidence`).
- Asynchronous reactive streaming using native Dart `Stream<ChatCompletionChunk>`.
- Cross-platform compatibility for Flutter mobile, web, and desktop applications.
