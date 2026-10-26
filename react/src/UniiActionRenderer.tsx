import React, { useState } from "react";

import type { ToolCall } from "@unii/sdk";

import { useUniiContext } from "./context.js";
import type { ActionStatus, UniiActionRenderProps } from "./types.js";

export interface UniiActionRendererProps {
  toolCall: ToolCall;
  initialResult?: any;
}

export function UniiActionRenderer({
  toolCall,
  initialResult,
}: UniiActionRendererProps) {
  const { getAction, executeAction } = useUniiContext();
  const actionName = toolCall.function.name;
  const action = getAction(actionName);

  let parsedArgs: any = {};

  try {
    parsedArgs = JSON.parse(toolCall.function.arguments || "{}");
  } catch {
    parsedArgs = {};
  }

  const [status, setStatus] = useState<ActionStatus>(
    initialResult ? "complete" : "idle",
  );
  const [result, setResult] = useState<any>(initialResult);
  const [error, setError] = useState<Error | undefined>();

  const execute = async (overrideArgs?: Partial<any>): Promise<any> => {
    setStatus("executing");
    try {
      const mergedArgs = { ...parsedArgs, ...overrideArgs };
      const res = await executeAction(actionName, mergedArgs);

      setResult(res);
      setStatus("complete");

      return res;
    } catch (err: any) {
      setError(err);
      setStatus("error");
      throw err;
    }
  };

  const renderProps: UniiActionRenderProps = {
    args: parsedArgs,
    result,
    status,
    error,
    execute,
  };

  // 1. Custom React Component
  if (action?.component) {
    const Component = action.component;

    return <Component {...renderProps} />;
  }

  // 2. Custom render function
  if (action?.render) {
    return <>{action.render(renderProps)}</>;
  }

  // 3. Fallback default button card
  const ActionIcon = action?.icon;

  return (
    <div
      style={{
        marginTop: "8px",
        padding: "12px",
        borderRadius: "8px",
        border: "1px solid rgba(99, 102, 241, 0.2)",
        backgroundColor: "rgba(99, 102, 241, 0.05)",
      }}
    >
      <div style={{ fontSize: "12px", fontWeight: 600, color: "#6366f1" }}>
        Action: {actionName}
      </div>
      <button
        type="button"
        disabled={status === "executing"}
        onClick={() => execute()}
        style={{
          display: "inline-flex",
          alignItems: "center",
          gap: "6px",
          marginTop: "8px",
          padding: "6px 14px",
          borderRadius: "6px",
          backgroundColor: "#4f46e5",
          color: "#ffffff",
          border: "none",
          cursor: "pointer",
          fontSize: "12px",
          fontWeight: 500,
        }}
      >
        {ActionIcon && <ActionIcon data-icon="inline-start" />}
        {status === "executing"
          ? "Processing..."
          : status === "complete"
            ? "Completed"
            : `Run ${actionName}`}
      </button>
    </div>
  );
}
