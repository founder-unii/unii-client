package com.malviys.unii.compose

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.malviys.unii.ToolCall
import kotlinx.coroutines.launch

@Composable
fun UniiActionRenderer(
    toolCall: ToolCall,
    initialResult: Any? = null,
    modifier: Modifier = Modifier
) {
    val state = LocalUniiState.current
    val coroutineScope = rememberCoroutineScope()
    val actionName = toolCall.function.name
    val action = state.getAction(actionName)
    val parsedArgs = remember(toolCall.function.arguments) {
        state.parseJsonArgs(toolCall.function.arguments)
    }

    var status by remember {
        mutableStateOf(if (initialResult != null) ActionStatus.COMPLETE else ActionStatus.IDLE)
    }
    var result by remember { mutableStateOf(initialResult) }
    var error by remember { mutableStateOf<Throwable?>(null) }

    val execute: suspend (Map<String, Any?>?) -> Any? = { overrideArgs ->
        status = ActionStatus.EXECUTING
        try {
            val mergedArgs = parsedArgs + (overrideArgs ?: emptyMap())
            val res = state.executeAction(actionName, mergedArgs)
            result = res
            status = ActionStatus.COMPLETE
            res
        } catch (t: Throwable) {
            error = t
            status = ActionStatus.ERROR
            throw t
        }
    }

    val renderProps = UniiActionRenderProps(
        args = parsedArgs,
        result = result,
        status = status,
        error = error,
        execute = execute
    )

    // 1. Custom Generative UI render composable
    if (action?.render != null) {
        action.render.invoke(renderProps)
        return
    }

    // 2. Default Material 3 Action Card
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        ) {
            Text(
                text = "Action: $actionName",
                style = MaterialTheme.typography.labelMedium.copy(
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            )

            if (parsedArgs.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Args: $parsedArgs",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            when (status) {
                ActionStatus.IDLE -> {
                    Button(
                        onClick = {
                            coroutineScope.launch {
                                try {
                                    execute(null)
                                } catch (_: Throwable) { }
                            }
                        },
                        modifier = Modifier.align(Alignment.End),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text("Execute", fontSize = 12.sp)
                    }
                }
                ActionStatus.EXECUTING -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 4.dp)
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            strokeWidth = 2.dp
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Executing...",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
                ActionStatus.COMPLETE -> {
                    Text(
                        text = "✓ Completed ${result?.let { "($it)" } ?: ""}",
                        style = MaterialTheme.typography.bodySmall.copy(
                            color = Color(0xFF16A34A),
                            fontWeight = FontWeight.Medium
                        )
                    )
                }
                ActionStatus.ERROR -> {
                    Text(
                        text = "✗ Error: ${error?.message ?: "Unknown error"}",
                        style = MaterialTheme.typography.bodySmall.copy(
                            color = MaterialTheme.colorScheme.error,
                            fontWeight = FontWeight.Medium
                        )
                    )
                }
            }
        }
    }
}
