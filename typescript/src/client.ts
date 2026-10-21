import {
  AuthVerifyResponse,
  ChatCompletionChunk,
  ChatCompletionRequest,
  ChatCompletionResponse,
  UniiApiError,
  UniiClientOptions,
} from "./types.js";

export class UniiClient {
  private readonly apiKey: string;
  private readonly baseUrl: string;
  private readonly projectId?: string;
  private readonly fetchFn: typeof globalThis.fetch;

  constructor(options: UniiClientOptions) {
    if (!options?.apiKey) {
      throw new Error("UniiClient requires an apiKey");
    }
    this.apiKey = options.apiKey;
    this.baseUrl = (options.baseUrl || "http://localhost:8080").replace(
      /\/+$/,
      "",
    );
    this.projectId = options.projectId;
    this.fetchFn = options.fetch || globalThis.fetch.bind(globalThis);
  }

  private getHeaders(
    extraHeaders: Record<string, string> = {},
  ): Record<string, string> {
    return {
      Authorization: `Bearer ${this.apiKey}`,
      ...extraHeaders,
    };
  }

  private async handleError(response: Response): Promise<never> {
    let message = response.statusText || "Request failed";
    let details: unknown;

    try {
      const json = await response.json();

      details = json;
      if (typeof json === "object" && json !== null) {
        if ("message" in json && typeof json.message === "string") {
          message = json.message;
        } else if ("error" in json && typeof json.error === "string") {
          message = json.error;
        }
      }
    } catch {
      // Body not JSON
    }
    throw new UniiApiError(response.status, message, details);
  }

  async verifyAuth(): Promise<AuthVerifyResponse> {
    const url = `${this.baseUrl}/api/v1/auth/verify`;
    const response = await this.fetchFn(url, {
      method: "GET",
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      await this.handleError(response);
    }

    return (await response.json()) as AuthVerifyResponse;
  }

  async createChatCompletion(
    request: ChatCompletionRequest,
  ): Promise<ChatCompletionResponse> {
    const url = `${this.baseUrl}/api/v1/chat/completions`;
    const payload = {
      ...request,
      stream: false,
      projectId: request.projectId || this.projectId,
    };

    const response = await this.fetchFn(url, {
      method: "POST",
      headers: this.getHeaders({
        "Content-Type": "application/json",
      }),
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      await this.handleError(response);
    }

    return (await response.json()) as ChatCompletionResponse;
  }

  async *streamChatCompletion(
    request: ChatCompletionRequest,
  ): AsyncIterable<ChatCompletionChunk> {
    const url = `${this.baseUrl}/api/v1/chat/completions`;
    const payload = {
      ...request,
      stream: true,
      projectId: request.projectId || this.projectId,
    };

    const response = await this.fetchFn(url, {
      method: "POST",
      headers: this.getHeaders({
        "Content-Type": "application/json",
        Accept: "text/event-stream",
      }),
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      await this.handleError(response);
    }

    if (!response.body) {
      throw new UniiApiError(
        500,
        "Response body is null, cannot stream tokens",
      );
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";

    try {
      while (true) {
        const { done, value } = await reader.read();

        if (done) {
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n");

        buffer = lines.pop() || "";

        for (const line of lines) {
          const trimmed = line.trim();

          if (!trimmed || trimmed.startsWith(":")) {
            continue; // Skip keep-alives or comments
          }
          if (trimmed.startsWith("data:")) {
            const data = trimmed.slice(5).trim();

            if (data === "[DONE]") {
              return;
            }
            try {
              const chunk = JSON.parse(data) as ChatCompletionChunk;

              yield chunk;
            } catch {
              // Ignore malformed chunk
            }
          }
        }
      }

      if (buffer.trim().startsWith("data:")) {
        const data = buffer.trim().slice(5).trim();

        if (data !== "[DONE]") {
          try {
            yield JSON.parse(data) as ChatCompletionChunk;
          } catch {
            // Ignore
          }
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
}
