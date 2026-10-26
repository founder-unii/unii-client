package com.malviys.unii.compose

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect

@Composable
fun UniiAction(config: UniiActionConfig) {
    val state = LocalUniiState.current

    DisposableEffect(config.name) {
        config.onBeforeMount?.invoke()
        state.registerAction(config)
        config.onAfterMount?.invoke()

        onDispose {
            config.onBeforeUnmount?.invoke()
            state.unregisterAction(config.name)
            config.onAfterUnmount?.invoke()
        }
    }
}
