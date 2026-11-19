import type { ReactNode } from "react";

import type { ChatMessage, FrontendToolDefinition, ToolCall } from "@unii/sdk";

export type ActionStatus = "idle" | "executing" | "complete" | "error";

export interface UniiActionRenderProps<TArgs = any, TResult = any> {
  args: TArgs;
  result?: TResult;
  status: ActionStatus;
  error?: Error;
  execute: (overrideArgs?: Partial<TArgs>) => Promise<TResult>;
}

export interface UniiActionConfig<TArgs = any, TResult = any> {
  name: string;
  description: string;
  parameters?: Record<string, any>;
  render: (props: UniiActionRenderProps<TArgs, TResult>) => ReactNode;
}

export interface UniiContextValue {
  registerAction: (config: UniiActionConfig) => void;
  unregisterAction: (name: string) => void;
  executeAction: (name: string, args: any) => Promise<any>;
  getAction: (name: string) => UniiActionConfig | undefined;
  getActiveTools: () => FrontendToolDefinition[];
  messages: ChatMessage[];
  sendMessage: (content: string) => Promise<void>;
  isLoading: boolean;
}
