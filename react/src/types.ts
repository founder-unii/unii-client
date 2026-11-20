import type { ComponentType, ReactNode } from "react";

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

export interface UniiActionLifecycle<TArgs = any, TResult = any> {
  // Mounting & screen lifecycles
  onBeforeMount?: () => void;
  onAfterMount?: () => void;
  onBeforeUnmount?: () => void;
  onAfterUnmount?: () => void;

  // Execution lifecycles
  onBeforeExecute?: (args: TArgs) => boolean | void | Promise<boolean | void>;
  onAfterExecute?: (result: TResult, args: TArgs) => void;
  onError?: (error: Error, args: TArgs) => void;
}

export interface UniiActionRenderProps<TArgs = any, TResult = any> {
  args: TArgs;
  result?: TResult;
  status: ActionStatus;
  error?: Error;
  execute: (overrideArgs?: Partial<TArgs>) => Promise<TResult>;
  reject?: () => void;
}

export interface UniiActionConfig<
  TArgs = any,
  TResult = any,
> extends UniiActionLifecycle<TArgs, TResult> {
  name: string;
  description: string;
  parameters?: Record<string, any>;

  // Human-in-the-loop approval gate
  requiresApproval?: boolean | ((args: TArgs) => boolean | Promise<boolean>);

  // Icon component passed directly (no string keys, receives data-icon)
  icon?: ComponentType<{ "data-icon"?: string }>;

  // Execution callback
  handler?: (args: TArgs) => Promise<TResult> | TResult;

  // Custom UI Component or render function
  component?: ComponentType<UniiActionRenderProps<TArgs, TResult>>;
  render?: (props: UniiActionRenderProps<TArgs, TResult>) => ReactNode;
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
