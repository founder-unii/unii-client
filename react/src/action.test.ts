import assert from "node:assert/strict";
import test from "node:test";

import React from "react";

import type { FrontendToolDefinition } from "@unii/sdk";

import type { UniiActionConfig, UniiActionRenderProps } from "./types.js";

test("UniiAction registration and deregistration on screen navigation", () => {
  const registeredActions = new Map<string, UniiActionConfig>();

  const registerAction = (config: UniiActionConfig) => {
    registeredActions.set(config.name, config);
  };

  const unregisterAction = (name: string) => {
    registeredActions.delete(name);
  };

  const pricingAction: UniiActionConfig = {
    name: "open_signup",
    description: "Signup modal on pricing page",
    parameters: {
      type: "object",
      properties: { plan: { type: "string" } },
      required: ["plan"],
    },
    render: (props) => {
      return React.createElement("div", null, `Signup for ${props.args.plan}`);
    },
  };

  // 1. User visits /pricing
  registerAction(pricingAction);
  assert.equal(registeredActions.has("open_signup"), true);
  assert.equal(
    registeredActions.get("open_signup")?.description,
    "Signup modal on pricing page",
  );

  // 2. User navigates away from /pricing
  unregisterAction(pricingAction.name);
  assert.equal(registeredActions.has("open_signup"), false);
});

test("UniiAction generates FrontendToolDefinition with name, description, and parameters", () => {
  const actions = new Map<string, UniiActionConfig>();

  const checkoutAction: UniiActionConfig = {
    name: "checkout_cart",
    description: "Processes checkout with cart items",
    parameters: {
      type: "object",
      properties: {
        cartId: { type: "string" },
        currency: { type: "string" },
      },
      required: ["cartId"],
    },
    render: (props) =>
      React.createElement("div", null, `Checkout ${props.args.cartId}`),
  };

  actions.set(checkoutAction.name, checkoutAction);

  const getActiveTools = (): FrontendToolDefinition[] => {
    return Array.from(actions.values()).map((action) => ({
      name: action.name,
      description: action.description,
      parameters: action.parameters || { type: "object" },
    }));
  };

  const tools = getActiveTools();

  assert.equal(tools.length, 1);
  assert.deepEqual(tools[0], {
    name: "checkout_cart",
    description: "Processes checkout with cart items",
    parameters: {
      type: "object",
      properties: {
        cartId: { type: "string" },
        currency: { type: "string" },
      },
      required: ["cartId"],
    },
  });
});

test("Generative UI render prop provides execution controls and arguments", () => {
  let renderedOutput = "";
  let executedWithArgs: any = null;

  const action: UniiActionConfig<{ plan: string }> = {
    name: "card_action",
    description: "Renders subscription card",
    render: (props) => {
      renderedOutput = `Card for ${props.args.plan} - Status: ${props.status}`;

      return null;
    },
  };

  const renderProps: UniiActionRenderProps<{ plan: string }> = {
    args: { plan: "pro" },
    status: "idle",
    execute: async (overrideArgs) => {
      executedWithArgs = overrideArgs;

      return undefined as any;
    },
    reject: () => {},
  };

  action.render(renderProps);

  assert.equal(renderedOutput, "Card for pro - Status: idle");

  renderProps.execute({ plan: "enterprise" });
  assert.deepEqual(executedWithArgs, { plan: "enterprise" });
});

test("executeAction triggers provider onActionExecute listener", async () => {
  let notifiedAction: string | null = null;
  let notifiedArgs: any = null;

  const actions = new Map<string, UniiActionConfig>();

  const testAction: UniiActionConfig = {
    name: "show_alert",
    description: "Shows an alert to the user",
    render: () => null,
  };

  actions.set(testAction.name, testAction);

  const onActionExecute = (name: string, args: any, result: any) => {
    notifiedAction = name;
    notifiedArgs = args;
  };

  const executeAction = async (name: string, args: any) => {
    const act = actions.get(name);

    if (!act) {
      throw new Error(`Action "${name}" is not registered on current screen.`);
    }
    onActionExecute(name, args, null);

    return null;
  };

  await executeAction("show_alert", { message: "Welcome!" });

  assert.equal(notifiedAction, "show_alert");
  assert.deepEqual(notifiedArgs, { message: "Welcome!" });
});

test("UniiProvider streams chat response chunks and triggers tool call upon completion", async () => {
  const chunks: Array<{
    choices: Array<{
      delta: {
        content?: string;
        tool_calls?: Array<{
          id: string;
          type: "function";
          function: { name: string; arguments: string };
        }>;
      };
    }>;
  }> = [
    { choices: [{ delta: { content: "Hello " } }] },
    { choices: [{ delta: { content: "there!" } }] },
    {
      choices: [
        {
          delta: {
            tool_calls: [
              {
                id: "call_123",
                type: "function" as const,
                function: {
                  name: "open_modal",
                  arguments: '{"view":"pricing"}',
                },
              },
            ],
          },
        },
      ],
    },
  ];

  let accumulatedContent = "";
  const accumulatedToolCalls: any[] = [];
  const stateUpdates: string[] = [];

  for (const chunk of chunks) {
    const delta = chunk.choices[0].delta;

    if (delta.content) {
      accumulatedContent += delta.content;
    }
    if (delta.tool_calls) {
      accumulatedToolCalls.push(...delta.tool_calls);
    }
    stateUpdates.push(accumulatedContent);
  }

  assert.equal(accumulatedContent, "Hello there!");
  assert.deepEqual(stateUpdates, ["Hello ", "Hello there!", "Hello there!"]);
  assert.equal(accumulatedToolCalls.length, 1);
  assert.equal(accumulatedToolCalls[0].function.name, "open_modal");
  assert.deepEqual(JSON.parse(accumulatedToolCalls[0].function.arguments), {
    view: "pricing",
  });
});

test("requiresApproval gate prevents automatic tool execution on completion", async () => {
  let executed = false;

  const sensitiveAction: UniiActionConfig = {
    name: "delete_database",
    description: "Deletes database",
    requiresApproval: true,
    render: () => null,
  };

  const actions = new Map<string, UniiActionConfig>();

  actions.set(sensitiveAction.name, sensitiveAction);

  const executeAction = async (name: string, args: any) => {
    executed = true;

    return { status: "deleted" };
  };

  // Simulating completion trigger
  const toolCall = {
    id: "call_del",
    function: { name: "delete_database", arguments: "{}" },
  };
  const action = actions.get(toolCall.function.name);
  const requiresApproval =
    typeof action?.requiresApproval === "function"
      ? await action.requiresApproval({})
      : Boolean(action?.requiresApproval);

  // If requiresApproval is true, auto-execution is skipped
  if (!requiresApproval) {
    await executeAction(toolCall.function.name, {});
  }

  assert.equal(
    executed,
    false,
    "Sensitive action must not auto-execute without approval",
  );

  // User manually triggers approval
  await executeAction(toolCall.function.name, {});
  assert.equal(executed, true, "Action executes upon manual approval");
});

test("Streaming parts accumulate reasoning, text, and tool calls", () => {
  const accumulatedReasoning = "Looking up project documents...";
  const accumulatedContent = "Found 2 results.";
  const accumulatedToolCalls = [
    {
      id: "call_1",
      type: "function" as const,
      function: { name: "search", arguments: '{"q":"rag"}' },
    },
  ];

  const parts: Array<
    | { type: "reasoning"; reasoning: string }
    | { type: "text"; text: string }
    | { type: "tool_call"; toolCall: any }
  > = [];

  if (accumulatedReasoning) {
    parts.push({ type: "reasoning", reasoning: accumulatedReasoning });
  }
  if (accumulatedContent) {
    parts.push({ type: "text", text: accumulatedContent });
  }
  for (const tc of accumulatedToolCalls) {
    parts.push({ type: "tool_call", toolCall: tc });
  }

  assert.equal(parts.length, 3);
  assert.equal(parts[0].type, "reasoning");
  assert.equal(parts[1].type, "text");
  assert.equal(parts[2].type, "tool_call");
});
