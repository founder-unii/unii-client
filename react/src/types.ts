import type { ReactNode } from "react";

import type {
  ChatMessage,
  FrontendToolDefinition,
  ToolCall,
  UniiMessagePart,
} from "@unii/sdk";

export type { UniiMessagePart };

export type ActionStatus =
  | "idle"
  | "pending_approval"
  | "executing"
  | "complete"
  | "error";

export interface UniiActionRenderProps<TArgs = any, TResult = any> {
  args: TArgs;
  result?: TResult;
  status: ActionStatus;
  error?: Error;
  execute: (overrideArgs?: Partial<TArgs>) => Promise<TResult>;
  reject?: () => void;
}

export interface UniiActionConfig<TArgs = any, TResult = any> {
  name: string;
  description: string;
  parameters?: Record<string, any>;

  // Human-in-the-loop approval gate
  requiresApproval?: boolean | ((args: TArgs) => boolean | Promise<boolean>);

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
