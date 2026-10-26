package com.malviys.unii.compose

import androidx.compose.runtime.Composable
import com.malviys.unii.FrontendToolDefinition
import kotlinx.serialization.json.JsonObject

interface UniiActionLifecycle {
    val onBeforeMount: (() -> Unit)? get() = null
    val onAfterMount: (() -> Unit)? get() = null
    val onBeforeUnmount: (() -> Unit)? get() = null
    val onAfterUnmount: (() -> Unit)? get() = null
    val onBeforeExecute: (suspend (args: Map<String, Any?>) -> Boolean)? get() = null
    val onAfterExecute: ((result: Any?, args: Map<String, Any?>) -> Unit)? get() = null
    val onError: ((error: Throwable, args: Map<String, Any?>) -> Unit)? get() = null
}

data class UniiActionRenderProps(
    val args: Map<String, Any?>,
    val result: Any?,
    val status: ActionStatus,
    val error: Throwable?,
    val execute: suspend (overrideArgs: Map<String, Any?>?) -> Any?
)

data class UniiActionConfig(
    val name: String,
    val description: String,
    val parameters: JsonObject? = null,
    val handler: (suspend (args: Map<String, Any?>) -> Any?)? = null,
    val render: (@Composable (props: UniiActionRenderProps) -> Unit)? = null,
    override val onBeforeMount: (() -> Unit)? = null,
    override val onAfterMount: (() -> Unit)? = null,
    override val onBeforeUnmount: (() -> Unit)? = null,
    override val onAfterUnmount: (() -> Unit)? = null,
    override val onBeforeExecute: (suspend (args: Map<String, Any?>) -> Boolean)? = null,
    override val onAfterExecute: ((result: Any?, args: Map<String, Any?>) -> Unit)? = null,
    override val onError: ((error: Throwable, args: Map<String, Any?>) -> Unit)? = null
) : UniiActionLifecycle {
    fun toFrontendToolDefinition(): FrontendToolDefinition =
        FrontendToolDefinition(
            name = name,
            description = description,
            parameters = parameters
        )
}
