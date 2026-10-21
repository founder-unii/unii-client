export interface AuthVerifyResponse {
  status: string;
  keyId: string;
  keyName: string;
  organizationId: string;
  projectId: string;
}

export type ChatRole = "system" | "user" | "assistant";

export interface ChatMessage {
  role: ChatRole | string;
  content: string;
}

export interface ChatCompletionRequest {
  messages: ChatMessage[];
  query?: string;
  stream?: boolean;
  temperature?: number;
  maxTokens?: number;
  projectId?: string;
}

export interface ChatCompletionChoice {
  index: number;
  message: ChatMessage;
  finish_reason: string;
}

export interface ChatCompletionCitation {
  documentName: string;
  excerpt: string;
  confidence: number;
}

export interface ChatCompletionResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: ChatCompletionChoice[];
  citation?: ChatCompletionCitation;
}

export interface ChatCompletionChunkDelta {
  role?: string;
  content?: string;
}

export interface ChatCompletionChunkChoice {
  index: number;
  delta: ChatCompletionChunkDelta;
  finish_reason?: string | null;
}

export interface ChatCompletionChunk {
  id: string;
  object: string;
  choices: ChatCompletionChunkChoice[];
}

export interface UniiClientOptions {
  apiKey: string;
  baseUrl?: string;
  projectId?: string;
  fetch?: typeof globalThis.fetch;
}

export class UniiApiError extends Error {
  readonly status: number;
  readonly errorDetails?: unknown;

  constructor(status: number, message: string, errorDetails?: unknown) {
    super(`Unii API Error (${status}): ${message}`);
    this.name = "UniiApiError";
    this.status = status;
    this.errorDetails = errorDetails;
  }
}
