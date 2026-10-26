# unii_flutter (Flutter SDK)

Official Flutter client library for Unii conversational AI with CopilotKit-style tool execution and generative UI in Flutter apps.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  unii_flutter:
    git:
      url: https://github.com/malviys/unii-client.git
      path: flutter
  # Or from pub:
  # unii_flutter: ^0.1.0
```

## Quick Start

### 1. Initialize UniiProvider

Wrap your widget tree with `UniiProvider`:

```dart
import 'package:flutter/material.dart';
import 'package:unii_flutter/unii_flutter.dart';

void main() {
  final client = UniiClient(apiKey: 'YOUR_UNII_API_KEY');
  final controller = UniiController(client: client);

  runApp(
    UniiProvider(
      controller: controller,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
}
```

### 2. Register Screen Actions with `UniiAction`

Register tool capabilities and custom generative UI widgets on any screen:

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UniiAction(
      config: UniiActionConfig(
        name: 'book_flight',
        description: 'Books a flight to target destination',
        handler: (args) async {
          final destination = args['destination'] ?? 'Tokyo';
          return {'status': 'confirmed', 'flightNumber': 'UN-404'};
        },
        render: (context, props) {
          return Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Book flight to ${props.args['destination']}'),
                  ElevatedButton(
                    onPressed: props.status == ActionStatus.executing
                        ? null
                        : () => props.execute(),
                    child: Text(
                      props.status == ActionStatus.complete
                          ? 'Confirmed!'
                          : 'Confirm Booking',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Unii AI Chat')),
        body: const ChatView(),
      ),
    );
  }
}
```

### 3. Render Assistant Tool Calls with `UniiActionRenderer`

In your message list widget, render assistant tool calls with `UniiActionRenderer`:

```dart
ListView.builder(
  itemCount: controller.messages.length,
  itemBuilder: (context, index) {
    final message = controller.messages[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message.content),
        if (message.toolCalls != null)
          ...message.toolCalls!.map(
            (tc) => UniiActionRenderer(toolCall: tc),
          ),
      ],
    );
  },
)
```

## Features

- **Flutter Native**: Uses `ChangeNotifier` and `InheritedNotifier` for seamless state updates and reactivity.
- **CopilotKit-style Frontend Tools**: Register widget-scoped actions that automatically bind to Unii backend tool definitions.
- **Generative UI**: Render custom interactive Flutter widgets when the assistant executes actions.
- **Full Lifecycle Support**: `onBeforeMount`, `onAfterMount`, `onBeforeExecute`, `onAfterExecute`, and `onError`.
