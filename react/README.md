# @unii/react

Official React SDK for the Unii conversational AI platform with CopilotKit-style tool execution and Generative UI.

## Installation

```bash
npm install @unii/react @unii/sdk
```

## Quick Start

### 1. Wrap your application with `UniiProvider`

```tsx
import React from "react";
import { UniiClient } from "@unii/sdk";
import { UniiProvider } from "@unii/react";

const client = new UniiClient({
  apiKey: process.env.NEXT_PUBLIC_UNII_API_KEY || "your-api-key",
});

export function App({ children }: { children: React.ReactNode }) {
  return (
    <UniiProvider client={client}>
      {children}
    </UniiProvider>
  );
}
```

### 2. Register Screen Actions with `useUniiAction`

```tsx
import { useUniiAction } from "@unii/react";
import { useTheme } from "next-themes";

export function ThemeComponent() {
  const { setTheme } = useTheme();

  useUniiAction({
    name: "toggle_theme",
    description: "Switches visual theme between light and dark",
    parameters: {
      type: "object",
      properties: {
        mode: { type: "string", enum: ["light", "dark", "system"] },
      },
      required: ["mode"],
    },
    // Direct execution callback
    execute: async (args: { mode: string }) => {
      setTheme(args.mode);
      return { success: true, theme: args.mode };
    },
  });

  return <div>Screen Content</div>;
}

export function OrderComponent() {
  useUniiAction({
    name: "confirm_order",
    description: "Confirms order details for the user",
    parameters: {
      type: "object",
      properties: {
        orderId: { type: "string" },
      },
      required: ["orderId"],
    },
    // Optional Human-in-the-Loop (HITL) approval before executing
    requiresApproval: true,
    execute: async ({ orderId }) => {
      await api.confirmOrder(orderId);
    },
    render: ({ args, status, execute, reject }) => (
      <div className="p-4 border rounded">
        <h4>Confirm Order #{args.orderId}</h4>
        {status === "pending_approval" ? (
          <div className="flex gap-2">
            <button onClick={() => execute()}>Approve Order</button>
            <button onClick={reject}>Reject</button>
          </div>
        ) : (
          <button onClick={() => execute()} disabled={status === "executing"}>
            {status === "complete" ? "Confirmed!" : "Confirm"}
          </button>
        )}
      </div>
    ),
  });

  return <div>Order Details</div>;
}
```

### 3. Render Generative UI with `UniiActionRenderer`

```tsx
import { useUniiChat, UniiActionRenderer } from "@unii/react";

export function Chat() {
  const { messages, sendMessage, isLoading } = useUniiChat();

  return (
    <div>
      {messages.map((m, i) => (
        <div key={i}>
          {/* Structured streaming parts: text, reasoning, tool_call, citation */}
          {m.parts ? (
            m.parts.map((part, pIdx) => {
              if (part.type === "reasoning") {
                return <blockquote key={pIdx} className="text-muted text-xs italic">{part.reasoning}</blockquote>;
              }
              if (part.type === "text") {
                return <p key={pIdx}>{part.text}</p>;
              }
              if (part.type === "tool_call") {
                return <UniiActionRenderer key={part.toolCall.id} toolCall={part.toolCall} />;
              }
              return null;
            })
          ) : (
            <p>{m.content}</p>
          )}

          {/* Fallback for standard tool calls */}
          {!m.parts && m.tool_calls?.map((tc) => (
            <UniiActionRenderer key={tc.id} toolCall={tc} />
          ))}
        </div>
      ))}
    </div>
  );
}
```

### 4. Integration with shadcn AI Elements

`@unii/react` works seamlessly with [shadcn AI Elements](https://ui.shadcn.com/docs/ai-elements):

- **`MessageScroller`**: Wrap message history with `<MessageScroller>` and `<MessageScrollerViewport>` for auto-scroll locking and scroll-to-bottom actions.
- **`Message` & `Bubble`**: Style user and assistant message turns using `<Message align="start" | "end">` and `<Bubble variant="default" | "secondary">`.
- **`Trace`**: Render execution steps and reasoning logs using `<Trace>` and `<TraceCollapsible>`.
- **`Confirmation`**: Use interactive approval cards for actions with `requiresApproval: true`.

## License

MIT
