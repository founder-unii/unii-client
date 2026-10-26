import assert from "node:assert/strict";
import test from "node:test";

import React from "react";

import type { UniiActionConfig, UniiContextValue } from "./types.js";

test("UniiAction execution flow: onBeforeExecute -> handler -> onAfterExecute", async () => {
  const lifecycleEvents: string[] = [];

  const action: UniiActionConfig = {
    name: "test_action",
    description: "Test description",
    onBeforeExecute: (args) => {
      lifecycleEvents.push(`beforeExecute:${args.step}`);

      return true;
    },
    handler: async (args) => {
      lifecycleEvents.push(`handler:${args.step}`);

      return { status: "ok", step: args.step };
    },
    onAfterExecute: (result, args) => {
      lifecycleEvents.push(`afterExecute:${result.status}:${args.step}`);
    },
  };

  const actions = new Map<string, UniiActionConfig>();

  actions.set(action.name, action);

  const executeAction = async (name: string, args: any) => {
    const act = actions.get(name);

    if (!act) {
      throw new Error("Not found");
    }
    if (act.onBeforeExecute) {
      const ok = await act.onBeforeExecute(args);

      if (ok === false) {
        return null;
      }
    }
    const res = await act.handler!(args);

    if (act.onAfterExecute) {
      act.onAfterExecute(res, args);
    }

    return res;
  };

  const result = await executeAction("test_action", { step: 1 });

  assert.deepEqual(result, { status: "ok", step: 1 });
  assert.deepEqual(lifecycleEvents, [
    "beforeExecute:1",
    "handler:1",
    "afterExecute:ok:1",
  ]);
});

test("onBeforeExecute returning false cancels handler execution", async () => {
  let handlerCalled = false;

  const action: UniiActionConfig = {
    name: "guarded_action",
    description: "Guard test",
    onBeforeExecute: () => {
      return false; // Cancel execution
    },
    handler: () => {
      handlerCalled = true;

      return "done";
    },
  };

  const actions = new Map<string, UniiActionConfig>();

  actions.set(action.name, action);

  const executeAction = async (name: string, args: any) => {
    const act = actions.get(name);

    if (!act) {
      throw new Error("Not found");
    }
    if (act.onBeforeExecute) {
      const ok = await act.onBeforeExecute(args);

      if (ok === false) {
        return null;
      }
    }

    return await act.handler!(args);
  };

  const result = await executeAction("guarded_action", {});

  assert.equal(result, null);
  assert.equal(handlerCalled, false);
});

test("onError lifecycle catches handler failures", async () => {
  let errorCaught: string | null = null;

  const action: UniiActionConfig = {
    name: "failing_action",
    description: "Fail test",
    handler: () => {
      throw new Error("Simulated API failure");
    },
    onError: (err) => {
      errorCaught = err.message;
    },
  };

  const actions = new Map<string, UniiActionConfig>();

  actions.set(action.name, action);

  const executeAction = async (name: string, args: any) => {
    const act = actions.get(name);

    if (!act) {
      throw new Error("Not found");
    }
    try {
      return await act.handler!(args);
    } catch (err: any) {
      act.onError?.(err, args);
      throw err;
    }
  };

  await assert.rejects(
    async () => await executeAction("failing_action", {}),
    /Simulated API failure/,
  );
  assert.equal(errorCaught, "Simulated API failure");
});

test("Screen mount and unmount lifecycles properly register and deregister tools", () => {
  const mountEvents: string[] = [];
  const registeredTools = new Map<string, UniiActionConfig>();

  const simulateComponentMount = (config: UniiActionConfig) => {
    // onBeforeMount
    config.onBeforeMount?.();
    // register
    registeredTools.set(config.name, config);
    // onAfterMount
    config.onAfterMount?.();

    // return unmount function
    return () => {
      // onBeforeUnmount
      config.onBeforeUnmount?.();
      // unregister
      registeredTools.delete(config.name);
      // onAfterUnmount
      config.onAfterUnmount?.();
    };
  };

  const pricingAction: UniiActionConfig = {
    name: "open_signup",
    description: "Signup modal on pricing page",
    onBeforeMount: () => mountEvents.push("beforeMount:pricing"),
    onAfterMount: () => mountEvents.push("afterMount:pricing"),
    onBeforeUnmount: () => mountEvents.push("beforeUnmount:pricing"),
    onAfterUnmount: () => mountEvents.push("afterUnmount:pricing"),
  };

  // 1. User visits /pricing
  const unmount = simulateComponentMount(pricingAction);

  assert.equal(registeredTools.has("open_signup"), true);
  assert.deepEqual(mountEvents, ["beforeMount:pricing", "afterMount:pricing"]);

  // 2. User leaves /pricing for /dashboard
  unmount();
  assert.equal(registeredTools.has("open_signup"), false);
  assert.deepEqual(mountEvents, [
    "beforeMount:pricing",
    "afterMount:pricing",
    "beforeUnmount:pricing",
    "afterUnmount:pricing",
  ]);
});

test("Generative UI render prop provides execution controls and arguments", () => {
  let renderedOutput = "";

  const action: UniiActionConfig = {
    name: "card_action",
    description: "Renders card",
    render: (props) => {
      renderedOutput = `Card for ${props.args.plan} - Status: ${props.status}`;

      return null;
    },
  };

  action.render!({
    args: { plan: "pro" },
    status: "idle",
    execute: async () => {},
  });

  assert.equal(renderedOutput, "Card for pro - Status: idle");
});

test("Action icon is passed as component object and receives data-icon (shadcn rules)", () => {
  let capturedDataIcon: string | undefined;

  const MockCheckIcon: React.ComponentType<{ "data-icon"?: string }> = (
    props,
  ) => {
    capturedDataIcon = props["data-icon"];

    return React.createElement("svg", props);
  };

  const action: UniiActionConfig = {
    name: "icon_action",
    description: "Icon test",
    icon: MockCheckIcon, // Passed as component object, NOT string key
  };

  assert.equal(action.icon, MockCheckIcon);

  // When rendered inside button, receives data-icon="inline-start" without sizing classes
  const element = React.createElement(action.icon!, {
    "data-icon": "inline-start",
  });

  assert.equal(element.props["data-icon"], "inline-start");
  assert.equal((element.props as any).className, undefined); // No sizing classes
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

  let actionExecutedWith: any = null;
  const mockAction: UniiActionConfig = {
    name: "open_modal",
    description: "Opens view modal",
    handler: (args) => {
      actionExecutedWith = args;

      return { success: true };
    },
  };

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

  if (accumulatedToolCalls.length > 0 && mockAction.handler) {
    const args = JSON.parse(accumulatedToolCalls[0].function.arguments);

    await mockAction.handler(args);
  }

  assert.equal(accumulatedContent, "Hello there!");
  assert.deepEqual(stateUpdates, ["Hello ", "Hello there!", "Hello there!"]);
  assert.deepEqual(actionExecutedWith, { view: "pricing" });
});
