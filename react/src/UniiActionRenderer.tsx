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

  if (action) {
    return <>{action.render(renderProps)}</>;
  }

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
    </div>
  );
}
