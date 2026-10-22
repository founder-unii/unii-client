import assert from "node:assert/strict";
import test from "node:test";

import { UniiClient } from "./client.js";
import { UniiApiError } from "./types.js";

test("UniiClient constructor requires apiKey", () => {
  assert.throws(
    () => new UniiClient({ apiKey: "" }),
    /UniiClient requires an apiKey/,
  );
});

test("verifyAuth sends GET with Authorization header", async () => {
  let capturedUrl = "";
  let capturedHeaders: Record<string, string> = {};

  const mockFetch = (async (
    url: string | URL | Request,
    init?: RequestInit,
  ) => {
    capturedUrl = url.toString();
    capturedHeaders = (init?.headers || {}) as Record<string, string>;

    return new Response(
      JSON.stringify({
        status: "authenticated",
        keyId: "key-123",
        keyName: "Test Key",
        organizationId: "org-123",
        projectId: "proj-123",
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }) as unknown as typeof globalThis.fetch;

  const client = new UniiClient({
    apiKey: "test-secret-key",
    baseUrl: "http://api.test",
    fetch: mockFetch,
  });

  const result = await client.verifyAuth();

  assert.equal(capturedUrl, "http://api.test/api/v1/auth/verify");
  assert.equal(capturedHeaders.Authorization, "Bearer test-secret-key");
  assert.equal(result.status, "authenticated");
  assert.equal(result.keyId, "key-123");
});

test("verifyAuth throws UniiApiError on failure", async () => {
  const mockFetch = (async () => {
    return new Response(
      JSON.stringify({
        error: "Unauthorized",
        message: "Invalid API key",
      }),
      { status: 401, headers: { "Content-Type": "application/json" } },
    );
  }) as unknown as typeof globalThis.fetch;

  const client = new UniiClient({
    apiKey: "bad-key",
    fetch: mockFetch,
  });

  await assert.rejects(
    async () => await client.verifyAuth(),
    (err: unknown) => {
      assert(err instanceof UniiApiError);
      assert.equal(err.status, 401);
      assert.match(err.message, /Invalid API key/);

      return true;
    },
  );
});

test("createChatCompletion sends POST with payload and receives response", async () => {
  let capturedUrl = "";
  let capturedBody = "";

  const mockFetch = (async (
    url: string | URL | Request,
    init?: RequestInit,
  ) => {
    capturedUrl = url.toString();
    capturedBody = init?.body as string;

    return new Response(
      JSON.stringify({
        id: "chatcmpl-1",
        object: "chat.completion",
        created: 1773485000,
        model: "unii-rag",
        choices: [
          {
            index: 0,
            message: {
              role: "assistant",
              content: "Returns allowed in 14 days.",
            },
            finish_reason: "stop",
          },
        ],
        citation: {
          documentName: "policy.pdf",
          excerpt: "14 days return policy",
          confidence: 0.95,
        },
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }) as unknown as typeof globalThis.fetch;

  const client = new UniiClient({
    apiKey: "test-key",
    projectId: "default-proj",
    fetch: mockFetch,
  });

  const response = await client.createChatCompletion({
    messages: [{ role: "user", content: "What is refund policy?" }],
  });

  assert.equal(capturedUrl, "http://localhost:8080/api/v1/chat/completions");
  const parsedBody = JSON.parse(capturedBody);

  assert.equal(parsedBody.stream, false);
  assert.equal(parsedBody.projectId, "default-proj");
  assert.equal(parsedBody.messages[0].content, "What is refund policy?");
  assert.equal(response.id, "chatcmpl-1");
  assert.equal(
    response.choices[0].message.content,
    "Returns allowed in 14 days.",
  );
  assert.equal(response.citation?.documentName, "policy.pdf");
});

test("streamChatCompletion yields tokens over Server-Sent Events", async () => {
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(
        encoder.encode(
          'data: {"id":"c-1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"}}]}\n\n',
        ),
      );
      controller.enqueue(
        encoder.encode(
          'data: {"id":"c-1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":" world"}}]}\n\n',
        ),
      );
      controller.enqueue(encoder.encode("data: [DONE]\n\n"));
      controller.close();
    },
  });

  const mockFetch = (async () => {
    return new Response(stream, {
      status: 200,
      headers: { "Content-Type": "text/event-stream" },
    });
  }) as unknown as typeof globalThis.fetch;

  const client = new UniiClient({
    apiKey: "test-key",
    fetch: mockFetch,
  });

  const chunks = [];

  for await (const chunk of client.streamChatCompletion({
    messages: [{ role: "user", content: "Hi" }],
  })) {
    chunks.push(chunk);
  }

  assert.equal(chunks.length, 2);
  assert.equal(chunks[0].choices[0].delta.content, "Hello");
  assert.equal(chunks[1].choices[0].delta.content, " world");
});

test("createChatCompletion sends frontendTools and receives tool_calls", async () => {
  let capturedBody = "";
  const mockFetch = (async (
    _url: string | URL | Request,
    init?: RequestInit,
  ) => {
    capturedBody = init?.body as string;

    return new Response(
      JSON.stringify({
        id: "chatcmpl-tools",
        object: "chat.completion",
        created: 1773485000,
        model: "unii-rag",
        choices: [
          {
            index: 0,
            message: {
              role: "assistant",
              content: "You can sign up here:",
              tool_calls: [
                {
                  id: "call_signup_123",
                  type: "function",
                  function: {
                    name: "open_signup",
                    arguments: '{"plan":"pro"}',
                  },
                },
              ],
            },
            finish_reason: "tool_calls",
          },
        ],
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }) as unknown as typeof globalThis.fetch;

  const client = new UniiClient({ apiKey: "test-key", fetch: mockFetch });
  const response = await client.createChatCompletion({
    messages: [{ role: "user", content: "I want pro" }],
    frontendTools: [
      {
        name: "open_signup",
        description: "Opens signup dialog",
        parameters: { type: "object" },
      },
    ],
  });

  const parsed = JSON.parse(capturedBody);
  assert.equal(parsed.frontendTools[0].name, "open_signup");
  assert.equal(response.choices[0].finish_reason, "tool_calls");
  assert.equal(
    response.choices[0].message.tool_calls?.[0].function.name,
    "open_signup",
  );
  assert.equal(
    response.choices[0].message.tool_calls?.[0].function.arguments,
    '{"plan":"pro"}',
  );
});

test("streamChatCompletion yields delta with tool_calls", async () => {
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(
        encoder.encode(
          'data: {"id":"c-2","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"role":"assistant","content":"Sure!","tool_calls":[{"id":"call_1","type":"function","function":{"name":"trigger_action","arguments":"{}"}}]}}]}\n\n',
        ),
      );
      controller.enqueue(encoder.encode("data: [DONE]\n\n"));
      controller.close();
    },
  });

  const mockFetch = (async () => {
    return new Response(stream, {
      status: 200,
      headers: { "Content-Type": "text/event-stream" },
    });
  }) as unknown as typeof globalThis.fetch;

  const client = new UniiClient({ apiKey: "test-key", fetch: mockFetch });
  const chunks = [];
  for await (const chunk of client.streamChatCompletion({
    messages: [{ role: "user", content: "Action" }],
  })) {
    chunks.push(chunk);
  }

  assert.equal(chunks.length, 1);
  assert.equal(
    chunks[0].choices[0].delta.tool_calls?.[0].function.name,
    "trigger_action",
  );
});
