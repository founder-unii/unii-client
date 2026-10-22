import React, {
  createContext,
  useContext,
  useRef,
  useState,
  useCallback,
  type ReactNode,
} from "react";
import type { UniiClient, ChatMessage, FrontendToolDefinition } from "@unii/sdk";
import type { UniiActionConfig, UniiContextValue } from "./types.js";

export const UniiContext = createContext<UniiContextValue | null>(null);

export interface UniiProviderProps {
  client: UniiClient;
  children: ReactNode;
  initialMessages?: ChatMessage[];
  onActionExecute?: (actionName: string, args: any, result: any) => void;
}

export function UniiProvider({
  client,
  children,
  initialMessages = [],
  onActionExecute,
}: UniiProviderProps) {
  const actionsRef = useRef<Map<string, UniiActionConfig>>(new Map());
  const [messages, setMessages] = useState<ChatMessage[]>(initialMessages);
  const [isLoading, setIsLoading] = useState(false);

  const registerAction = useCallback((config: UniiActionConfig) => {
    actionsRef.current.set(config.name, config);
  }, []);

  const unregisterAction = useCallback((name: string) => {
    actionsRef.current.delete(name);
  }, []);

  const getAction = useCallback((name: string) => {
    return actionsRef.current.get(name);
  }, []);

  const getActiveTools = useCallback((): FrontendToolDefinition[] => {
    const tools: FrontendToolDefinition[] = [];
    for (const action of actionsRef.current.values()) {
      tools.push({
        name: action.name,
        description: action.description,
        parameters: action.parameters || { type: "object" },
      });
    }
    return tools;
  }, []);

  const executeAction = useCallback(
    async (name: string, args: any): Promise<any> => {
      const action = actionsRef.current.get(name);
      if (!action) {
        throw new Error(`Action "${name}" is not registered on current screen.`);
      }

      // 1. onBeforeExecute lifecycle
      if (action.onBeforeExecute) {
        const canProceed = await action.onBeforeExecute(args);
        if (canProceed === false) {
          return null; // Execution cancelled by user hook
        }
      }

      try {
        // 2. Main handler callback
        let result: any = null;
        if (action.handler) {
          result = await action.handler(args);
        }

        // 3. onAfterExecute lifecycle
        if (action.onAfterExecute) {
          action.onAfterExecute(result, args);
        }

        if (onActionExecute) {
          onActionExecute(name, args, result);
        }

        return result;
      } catch (err: any) {
        // 4. onError lifecycle
        if (action.onError) {
          action.onError(err, args);
        }
        throw err;
      }
    },
    [onActionExecute],
  );

  const sendMessage = useCallback(
    async (content: string) => {
      if (!content.trim() || isLoading) return;

      const userMsg: ChatMessage = { role: "user", content: content.trim() };
      const nextMessages = [...messages, userMsg];
      setMessages(nextMessages);
      setIsLoading(true);

      try {
        const activeTools = getActiveTools();
        const response = await client.createChatCompletion({
          messages: nextMessages,
          frontendTools: activeTools.length > 0 ? activeTools : undefined,
        });

        const choice = response.choices?.[0];
        if (choice?.message) {
          const assistantMsg = choice.message;
          setMessages([...nextMessages, assistantMsg]);

          // Automatically trigger registered handlers for received tool calls
          if (assistantMsg.tool_calls && assistantMsg.tool_calls.length > 0) {
            for (const toolCall of assistantMsg.tool_calls) {
              const toolName = toolCall.function.name;
              let parsedArgs = {};
              try {
                parsedArgs = JSON.parse(toolCall.function.arguments || "{}");
              } catch {
                // Ignore JSON parse error, pass raw
              }

              if (actionsRef.current.has(toolName)) {
                await executeAction(toolName, parsedArgs);
              }
            }
          }
        }
      } finally {
        setIsLoading(false);
      }
    },
    [client, messages, isLoading, getActiveTools, executeAction],
  );

  const value: UniiContextValue = {
    registerAction,
    unregisterAction,
    executeAction,
    getAction,
    getActiveTools,
    messages,
    sendMessage,
    isLoading,
  };

  return <UniiContext.Provider value={value}>{children}</UniiContext.Provider>;
}

export function useUniiContext(): UniiContextValue {
  const ctx = useContext(UniiContext);
  if (!ctx) {
    throw new Error("useUniiContext must be used within a UniiProvider");
  }
  return ctx;
}
