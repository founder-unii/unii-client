import React, {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useRef,
  useState,
} from "react";

import type {
  ChatMessage,
  FrontendToolDefinition,
  ToolCall,
  UniiClient,
} from "@unii/sdk";

import type { UniiActionConfig, UniiContextValue } from "./types.js";

export const UniiContext = createContext<UniiContextValue | null>(null);

export interface UniiProviderProps {
  client: UniiClient;
  children: ReactNode;
  initialMessages?: ChatMessage[];
  onActionExecute?: (actionName: string, args: any, result: any) => void;
  stream?: boolean;
}

export function UniiProvider({
  client,
  children,
  initialMessages = [],
  onActionExecute,
  stream = true,
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
        throw new Error(
          `Action "${name}" is not registered on current screen.`,
        );
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
      if (!content.trim() || isLoading) {
        return;
      }

      const userMsg: ChatMessage = { role: "user", content: content.trim() };
      const nextMessages = [...messages, userMsg];

      setMessages(nextMessages);
      setIsLoading(true);

      try {
        const activeTools = getActiveTools();
        const requestPayload = {
          messages: nextMessages,
          frontendTools: activeTools.length > 0 ? activeTools : undefined,
        };

        if (stream) {
          let accumulatedContent = "";
          const accumulatedToolCalls: ToolCall[] = [];

          // Initialize streaming message placeholder
          setMessages([...nextMessages, { role: "assistant", content: "" }]);

          for await (const chunk of client.streamChatCompletion(
            requestPayload,
          )) {
            const choice = chunk.choices?.[0];

            if (!choice) {
              continue;
            }

            const delta = choice.delta;

            if (delta?.content) {
              accumulatedContent += delta.content;
            }

            if (delta?.tool_calls && delta.tool_calls.length > 0) {
              for (const tc of delta.tool_calls) {
                const existingIdx = accumulatedToolCalls.findIndex(
                  (t) =>
                    (tc.id && t.id === tc.id) ||
                    (tc.function?.name &&
                      t.function?.name === tc.function?.name),
                );

                if (existingIdx >= 0) {
                  const existing = accumulatedToolCalls[existingIdx];

                  if (tc.function?.arguments) {
                    existing.function.arguments =
                      (existing.function.arguments || "") +
                      tc.function.arguments;
                  }
                } else {
                  accumulatedToolCalls.push({
                    id:
                      tc.id ||
                      `call_${Date.now()}_${accumulatedToolCalls.length}`,
                    type: tc.type || "function",
                    function: {
                      name: tc.function?.name || "",
                      arguments: tc.function?.arguments || "",
                    },
                  });
                }
              }
            }

            setMessages([
              ...nextMessages,
              {
                role: "assistant",
                content: accumulatedContent,
                tool_calls:
                  accumulatedToolCalls.length > 0
                    ? [...accumulatedToolCalls]
                    : undefined,
              },
            ]);
          }

          // Trigger handlers for received tool calls
          if (accumulatedToolCalls.length > 0) {
            for (const toolCall of accumulatedToolCalls) {
              const toolName = toolCall.function?.name;
              let parsedArgs = {};

              try {
                parsedArgs = JSON.parse(toolCall.function?.arguments || "{}");
              } catch {
                // Ignore JSON parse error, pass raw
              }

              if (toolName && actionsRef.current.has(toolName)) {
                await executeAction(toolName, parsedArgs);
              }
            }
          }
        } else {
          const response = await client.createChatCompletion(requestPayload);
          const choice = response.choices?.[0];

          if (choice?.message) {
            const assistantMsg = choice.message;

            setMessages([...nextMessages, assistantMsg]);

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
        }
      } finally {
        setIsLoading(false);
      }
    },
    [client, messages, isLoading, stream, getActiveTools, executeAction],
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

export function useUniiChat(): Pick<
  UniiContextValue,
  "messages" | "sendMessage" | "isLoading"
> {
  const { messages, sendMessage, isLoading } = useUniiContext();

  return { messages, sendMessage, isLoading };
}
