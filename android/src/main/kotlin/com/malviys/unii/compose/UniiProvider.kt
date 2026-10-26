package com.malviys.unii.compose

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import com.malviys.unii.ChatMessage
import com.malviys.unii.UniiClient

val LocalUniiState = compositionLocalOf<UniiState> {
    error("LocalUniiState not found. Wrap your composable hierarchy with UniiProvider.")
}

@Composable
fun rememberUniiState(
    client: UniiClient,
    initialMessages: List<ChatMessage> = emptyList(),
    onActionExecute: ((name: String, args: Map<String, Any?>, result: Any?) -> Unit)? = null,
    stream: Boolean = true
): UniiState {
    val scope = rememberCoroutineScope()
    return remember(client) {
        UniiState(
            client = client,
            coroutineScope = scope,
            initialMessages = initialMessages,
            onActionExecuteCallback = onActionExecute,
            stream = stream
        )
    }
}

@Composable
fun UniiProvider(
    client: UniiClient,
    initialMessages: List<ChatMessage> = emptyList(),
    onActionExecute: ((name: String, args: Map<String, Any?>, result: Any?) -> Unit)? = null,
    stream: Boolean = true,
    content: @Composable () -> Unit
) {
    val state = rememberUniiState(
        client = client,
        initialMessages = initialMessages,
        onActionExecute = onActionExecute,
        stream = stream
    )

    CompositionLocalProvider(LocalUniiState provides state) {
        content()
    }
}
