package com.malviys.unii.compose

import com.malviys.unii.ChatMessage
import com.malviys.unii.ChatCompletionRequest
import com.malviys.unii.FrontendToolDefinition
import com.malviys.unii.ToolCall
import com.malviys.unii.ToolCallFunction
import com.malviys.unii.UniiClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

class UniiState(
    val client: UniiClient,
    private val coroutineScope: CoroutineScope,
    initialMessages: List<ChatMessage> = emptyList(),
    private val onActionExecuteCallback: ((name: String, args: Map<String, Any?>, result: Any?) -> Unit)? = null,
    val stream: Boolean = true
) {
    private val actions = mutableMapOf<String, UniiActionConfig>()
    private val json = Json { ignoreUnknownKeys = true }

    private val _messages = MutableStateFlow(initialMessages)
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun registerAction(config: UniiActionConfig) {
        actions[config.name] = config
    }

    fun unregisterAction(name: String) {
        actions.remove(name)
    }

    fun getAction(name: String): UniiActionConfig? = actions[name]

    fun getActiveTools(): List<FrontendToolDefinition> =
        actions.values.map { it.toFrontendToolDefinition() }

    suspend fun executeAction(name: String, args: Map<String, Any?>): Any? {
        val action = actions[name]
            ?: throw IllegalStateException("Action \"$name\" is not registered on current screen.")

        if (action.onBeforeExecute?.invoke(args) == false) {
            return null
        }

        return try {
            val result = action.handler?.invoke(args)
            action.onAfterExecute?.invoke(result, args)
            onActionExecuteCallback?.invoke(name, args, result)
            result
        } catch (t: Throwable) {
            action.onError?.invoke(t, args)
            throw t
        }
    }

    fun sendMessage(content: String) {
        if (content.isBlank() || _isLoading.value) return
        val userMsg = ChatMessage.user(content.trim())
        val currentList = _messages.value + userMsg
        _messages.value = currentList

        coroutineScope.launch {
            _isLoading.value = true
            try {
                val tools = getActiveTools()
                val req = ChatCompletionRequest(
                    messages = currentList,
                    frontendTools = if (tools.isNotEmpty()) tools else null,
                    stream = stream
                )

                if (stream) {
                    var accumulatedContent = ""
                    val accumulatedToolCalls = mutableListOf<ToolCall>()
                    _messages.value = currentList + ChatMessage.assistant("")

                    client.streamChatCompletion(req).collect { chunk ->
                        val choice = chunk.choices.firstOrNull() ?: return@collect
                        val delta = choice.delta
                        delta.content?.let { accumulatedContent += it }
                        delta.toolCalls?.forEach { tc ->
                            val existingIdx = accumulatedToolCalls.indexOfFirst {
                                (tc.id.isNotBlank() && it.id == tc.id) ||
                                (tc.function.name.isNotBlank() && it.function.name == tc.function.name)
                            }
                            if (existingIdx >= 0) {
                                val existing = accumulatedToolCalls[existingIdx]
                                accumulatedToolCalls[existingIdx] = existing.copy(
                                    function = existing.function.copy(
                                        arguments = existing.function.arguments + tc.function.arguments
                                    )
                                )
                            } else {
                                accumulatedToolCalls.add(tc)
                            }
                        }

                        _messages.value = currentList + ChatMessage(
                            role = "assistant",
                            content = accumulatedContent,
                            toolCalls = if (accumulatedToolCalls.isNotEmpty()) accumulatedToolCalls.toList() else null
                        )
                    }

                    // Execute accumulated tool calls
                    for (tc in accumulatedToolCalls) {
                        val toolName = tc.function.name
                        val args = parseJsonArgs(tc.function.arguments)
                        if (actions.containsKey(toolName)) {
                            executeAction(toolName, args)
                        }
                    }
                } else {
                    val response = client.createChatCompletion(req)
                    val choice = response.choices.firstOrNull()
                    if (choice != null) {
                        val assistantMsg = choice.message
                        _messages.value = currentList + assistantMsg
                        assistantMsg.toolCalls?.forEach { tc ->
                            val args = parseJsonArgs(tc.function.arguments)
                            if (actions.containsKey(tc.function.name)) {
                                executeAction(tc.function.name, args)
                            }
                        }
                    }
                }
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun parseJsonArgs(rawJson: String): Map<String, Any?> {
        if (rawJson.isBlank()) return emptyMap()
        return try {
            val element = json.parseToJsonElement(rawJson)
            if (element is JsonObject) {
                element.toMapValue()
            } else {
                emptyMap()
            }
        } catch (_: Exception) {
            emptyMap()
        }
    }

    private fun JsonObject.toMapValue(): Map<String, Any?> {
        return this.mapValues { (_, value) -> value.toAnyValue() }
    }

    private fun JsonElement.toAnyValue(): Any? {
        return when (this) {
            is JsonPrimitive -> {
                if (this.isString) {
                    this.content
                } else {
                    this.booleanOrNull ?: this.longOrNull ?: this.doubleOrNull ?: this.content
                }
            }
            is JsonObject -> this.toMapValue()
            is JsonArray -> this.map { it.toAnyValue() }
        }
    }
}
