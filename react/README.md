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

export function OrderComponent() {
  useUniiAction({
    name: "confirm_order",
    description: "Confirms order details for the user",
    handler: async (args) => {
      return { success: true, orderId: args.orderId };
    },
    render: ({ args, status, execute }) => (
      <div className="p-4 border rounded">
        <h4>Confirm Order #{args.orderId}</h4>
        <button onClick={() => execute()} disabled={status === "executing"}>
          {status === "complete" ? "Confirmed!" : "Confirm"}
        </button>
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
          <p>{m.content}</p>
          {m.tool_calls?.map((tc) => (
            <UniiActionRenderer key={tc.id} toolCall={tc} />
          ))}
        </div>
      ))}
    </div>
  );
}
```

## License

MIT
