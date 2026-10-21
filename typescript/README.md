# @unii/sdk

Official TypeScript/JavaScript SDK for interacting with the Unii API.

## Installation

```bash
npm install @unii/sdk
# or
pnpm add @unii/sdk
# or
bun add @unii/sdk
```

## Quickstart

```typescript
import { UniiClient } from "@unii/sdk";

const client = new UniiClient({
  apiKey: process.env.UNII_API_KEY!,
  baseUrl: "http://localhost:8080", // Optional, defaults to http://localhost:8080
});

// 1. Verify tenant authentication
const auth = await client.verifyAuth();
console.log("Authenticated with project:", auth.projectId);

// 2. Execute grounded conversational completions (JSON)
const completion = await client.createChatCompletion({
  messages: [{ role: "user", content: "What is the return window?" }],
});
console.log("Answer:", completion.choices[0].message.content);
if (completion.citation) {
  console.log("Source:", completion.citation.documentName);
}

// 3. Stream grounded tokens (Server-Sent Events)
for await (const chunk of client.streamChatCompletion({
  messages: [{ role: "user", content: "Explain warranty terms" }],
})) {
  process.stdout.write(chunk.choices[0]?.delta.content || "");
}
```
