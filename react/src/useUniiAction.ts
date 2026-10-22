import { useEffect, useRef } from "react";

import { useUniiContext } from "./context.js";
import type { UniiActionConfig } from "./types.js";

/**
 * Hook to register an action on the active screen / component.
 * Executes onBeforeMount / onAfterMount when component mounts,
 * and onBeforeUnmount / onAfterUnmount when component leaves the screen.
 */
export function useUniiAction<TArgs = any, TResult = any>(
  config: UniiActionConfig<TArgs, TResult>,
): void {
  const { registerAction, unregisterAction } = useUniiContext();
  const configRef = useRef(config);

  configRef.current = config;

  useEffect(() => {
    // 1. onBeforeMount lifecycle
    configRef.current.onBeforeMount?.();

    // 2. Register proxy config that delegates to latest ref
    const actionProxy: UniiActionConfig<TArgs, TResult> = {
      name: config.name,
      description: config.description,
      parameters: config.parameters,
      icon: configRef.current.icon,
      handler: (args: TArgs) => configRef.current.handler?.(args) as any,
      component: configRef.current.component,
      render: configRef.current.render,
      onBeforeExecute: (args: TArgs) =>
        configRef.current.onBeforeExecute?.(args),
      onAfterExecute: (result: TResult, args: TArgs) =>
        configRef.current.onAfterExecute?.(result, args),
      onError: (err: Error, args: TArgs) =>
        configRef.current.onError?.(err, args),
    };

    registerAction(actionProxy);

    // 3. onAfterMount lifecycle
    configRef.current.onAfterMount?.();

    return () => {
      // 4. onBeforeUnmount lifecycle
      configRef.current.onBeforeUnmount?.();

      unregisterAction(config.name);

      // 5. onAfterUnmount lifecycle
      configRef.current.onAfterUnmount?.();
    };
  }, [config.name, registerAction, unregisterAction]);
}
