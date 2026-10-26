# @unii/compose (Android & Jetpack Compose SDK)

Official Android client library for Unii conversational AI with CopilotKit-style tool execution and generative UI in Jetpack Compose.

## Installation

Add to your `build.gradle.kts` (app module):

```kotlin
dependencies {
    implementation("io.github.dev-unii:unii-compose:0.1.0")
    implementation("io.github.dev-unii:unii-kotlin:0.1.0")
}
```

## Quick Start

### 1. Initialize UniiProvider

Wrap your screen or application hierarchy in `UniiProvider`:

```kotlin
@Composable
fun App() {
    val client = remember {
        UniiClient(apiKey = "YOUR_UNII_API_KEY")
    }

    UniiProvider(client = client) {
        OrderScreen()
    }
}
```

### 2. Register Screen Actions with `UniiAction`

Register tool capabilities and generative UI components directly on your active screen:

```kotlin
@Composable
fun OrderScreen() {
    var orderStatus by remember { mutableStateOf("Pending") }

    UniiAction(
        config = UniiActionConfig(
            name = "confirm_order",
            description = "Confirms and places the user order",
            handler = { args ->
                val orderId = args["orderId"] as? String ?: "ORD-1"
                orderStatus = "Confirmed ($orderId)"
                mapOf("status" to "success", "orderId" to orderId)
            },
            render = { props ->
                Card(
                    modifier = Modifier.fillMaxWidth().padding(8.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Confirm Order #${props.args["orderId"]}")
                        Button(
                            onClick = {
                                CoroutineScope(Dispatchers.Main).launch {
                                    props.execute(null)
                                }
                            },
                            enabled = props.status != ActionStatus.EXECUTING
                        ) {
                            Text(if (props.status == ActionStatus.COMPLETE) "Confirmed!" else "Confirm Now")
                        }
                    }
                }
            }
        )
    )

    ChatView()
}
```

### 3. Render Generative UI with `UniiActionRenderer`

In your message list composable, use `UniiActionRenderer` to render assistant tool calls:

```kotlin
@Composable
fun MessageItem(message: ChatMessage) {
    Column {
        Text(text = message.content)

        message.toolCalls?.forEach { toolCall ->
            UniiActionRenderer(toolCall = toolCall)
        }
    }
}
```

## Features

- **Jetpack Compose Native**: Built for modern declarative Android UI using Compose State and Coroutines.
- **CopilotKit-style Tool Execution**: Register screen-local actions that automatically bind to Unii backend tool definitions.
- **Generative UI**: Render custom Composable cards when the assistant invokes specific actions.
- **Full Lifecycle Support**: `onBeforeMount`, `onAfterMount`, `onBeforeExecute`, `onAfterExecute`, and `onError`.
