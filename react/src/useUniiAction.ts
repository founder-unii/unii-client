import { useEffect, useRef } from "react";

import { useUniiContext } from "./context.js";
import type { UniiActionConfig, UniiActionRenderProps } from "./types.js";

/**
 * Hook to register an action on the active screen / component.
 * Automatically registers the action upon mounting and unregisters upon unmounting.
 */
export function useUniiAction<TArgs = any, TResult = any>(
  config: UniiActionConfig<TArgs, TResult>,
): void {
  const { registerAction, unregisterAction } = useUniiContext();
  const configRef = useRef(config);

  configRef.current = config;

  useEffect(() => {
    const actionProxy: UniiActionConfig<TArgs, TResult> = {
      name: config.name,
      description: config.description,
      parameters: config.parameters,
      requiresApproval: config.requiresApproval,
      execute: async (args: TArgs) => {
        const fn = configRef.current.execute || configRef.current.handler;
        if (fn) {
          return await fn(args);
        }
        return undefined as any;
      },
      render: config.render
        ? (props: UniiActionRenderProps<TArgs, TResult>) => {
            return configRef.current.render
              ? configRef.current.render(props)
              : null;
          }
        : undefined,
    };

    registerAction(actionProxy);

    return () => {
      unregisterAction(config.name);
    };
  }, [
    config.name,
    config.description,
    config.parameters,
    config.requiresApproval,
    config.execute,
    config.handler,
    config.render,
    registerAction,
    unregisterAction,
  ]);
}
