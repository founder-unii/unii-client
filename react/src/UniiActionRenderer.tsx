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

  const isApprovalRequired =
    !initialResult &&
    (typeof action?.requiresApproval === "function"
      ? Boolean(action.requiresApproval(parsedArgs))
      : Boolean(action?.requiresApproval));

  const [status, setStatus] = useState<ActionStatus>(
    initialResult
      ? "complete"
      : isApprovalRequired
        ? "pending_approval"
        : "idle",
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

  const reject = () => {
    setStatus("idle");
  };

  const renderProps: UniiActionRenderProps = {
    args: parsedArgs,
    result,
    status,
    error,
    execute,
    reject,
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
      data-slot="unii-action"
      data-status={status}
      style={{
        marginTop: "8px",
        padding: "12px",
        borderRadius: "8px",
        border: "1px solid rgba(99, 102, 241, 0.2)",
        backgroundColor: "rgba(99, 102, 241, 0.05)",
      }}
    >
      <div
        data-slot="action-header"
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: "8px",
          fontSize: "12px",
          fontWeight: 600,
          color: "#6366f1",
        }}
      >
        <span
          style={{ display: "inline-flex", alignItems: "center", gap: "6px" }}
        >
          {ActionIcon && <ActionIcon data-icon="inline-start" />}
          Action: {actionName}
        </span>
        {status === "pending_approval" && (
          <span
            style={{
              padding: "2px 6px",
              borderRadius: "4px",
              fontSize: "10px",
              fontWeight: 500,
              backgroundColor: "rgba(244, 63, 94, 0.1)",
              color: "#e11d48",
            }}
          >
            Approval Required
          </span>
        )}
      </div>

      <div data-slot="action-body" style={{ marginTop: "8px" }}>
        {status === "pending_approval" ? (
          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <button
              type="button"
              onClick={() => execute()}
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "6px",
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
              Approve & Run
            </button>
            <button
              type="button"
              onClick={reject}
              style={{
                display: "inline-flex",
                alignItems: "center",
                padding: "6px 14px",
                borderRadius: "6px",
                backgroundColor: "transparent",
                color: "#64748b",
                border: "1px solid #cbd5e1",
                cursor: "pointer",
                fontSize: "12px",
                fontWeight: 500,
              }}
            >
              Reject
            </button>
          </div>
        ) : (
          <button
            type="button"
            disabled={status === "executing"}
            onClick={() => execute()}
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "6px",
              padding: "6px 14px",
              borderRadius: "6px",
              backgroundColor: "#4f46e5",
              color: "#ffffff",
              border: "none",
              cursor: status === "executing" ? "default" : "pointer",
              fontSize: "12px",
              fontWeight: 500,
              opacity: status === "executing" ? 0.7 : 1,
            }}
          >
            {ActionIcon && <ActionIcon data-icon="inline-start" />}
            {status === "executing"
              ? "Processing..."
              : status === "complete"
                ? "Completed"
                : `Run ${actionName}`}
          </button>
        )}
      </div>
    </div>
  );
}
