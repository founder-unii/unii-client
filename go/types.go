package unii

import "fmt"

// AuthVerifyResponse contains tenant identity and scope returned by /api/v1/auth/verify.
type AuthVerifyResponse struct {
	Status         string `json:"status"`
	KeyID          string `json:"keyId"`
	KeyName        string `json:"keyName"`
	OrganizationID string `json:"organizationId"`
	ProjectID      string `json:"projectId"`
}

// ChatMessage represents a single turn in a conversational exchange.
type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// ChatCompletionRequest defines request options for /api/v1/chat/completions.
type ChatCompletionRequest struct {
	Messages    []ChatMessage `json:"messages,omitempty"`
	Query       string        `json:"query,omitempty"`
	Stream      bool          `json:"stream"`
	Temperature *float64      `json:"temperature,omitempty"`
	MaxTokens   *int          `json:"max_tokens,omitempty"`
	ProjectID   string        `json:"projectId,omitempty"`
}

// ChatCompletionCitation represents grounded source evidence from the knowledge corpus.
type ChatCompletionCitation struct {
	DocumentName string  `json:"documentName"`
	Excerpt      string  `json:"excerpt"`
	Confidence   float64 `json:"confidence"`
}

// ChatCompletionChoice is an assistant response turn option.
type ChatCompletionChoice struct {
	Index        int         `json:"index"`
	Message      ChatMessage `json:"message"`
	FinishReason string      `json:"finish_reason"`
}

// ChatCompletionResponse is the standard JSON completion response.
type ChatCompletionResponse struct {
	ID       string                  `json:"id"`
	Object   string                  `json:"object"`
	Created  int64                   `json:"created"`
	Model    string                  `json:"model"`
	Choices  []ChatCompletionChoice  `json:"choices"`
	Citation *ChatCompletionCitation `json:"citation,omitempty"`
}

// ChatCompletionChunkDelta holds incremental token data in a stream.
type ChatCompletionChunkDelta struct {
	Role    string `json:"role,omitempty"`
	Content string `json:"content,omitempty"`
}

// ChatCompletionChunkChoice represents streaming choices.
type ChatCompletionChunkChoice struct {
	Index        int                      `json:"index"`
	Delta        ChatCompletionChunkDelta `json:"delta"`
	FinishReason *string                  `json:"finish_reason,omitempty"`
}

// ChatCompletionChunk represents an individual SSE chunk frame.
type ChatCompletionChunk struct {
	ID      string                      `json:"id"`
	Object  string                      `json:"object"`
	Choices []ChatCompletionChunkChoice `json:"choices"`
}

// APIError represents an error returned by the Unii API.
type APIError struct {
	StatusCode int    `json:"statusCode"`
	ErrorMsg   string `json:"error"`
	Message    string `json:"message"`
}

func (e *APIError) Error() string {
	if e.Message != "" {
		return fmt.Sprintf("unii api error (status %d): %s", e.StatusCode, e.Message)
	}
	if e.ErrorMsg != "" {
		return fmt.Sprintf("unii api error (status %d): %s", e.StatusCode, e.ErrorMsg)
	}
	return fmt.Sprintf("unii api error (status %d)", e.StatusCode)
}
