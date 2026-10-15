package unii

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"testing"
)

type roundTripFunc func(req *http.Request) *http.Response

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req), nil
}

func newMockClient(apiKey string, fn roundTripFunc, opts ...Option) *Client {
	httpClient := &http.Client{
		Transport: fn,
	}
	allOpts := append([]Option{
		WithBaseURL("http://api.test"),
		WithHTTPClient(httpClient),
	}, opts...)
	return NewClient(apiKey, allOpts...)
}

func TestVerifyAuth(t *testing.T) {
	var capturedPath string
	var capturedAuth string

	client := newMockClient("test-api-key", func(req *http.Request) *http.Response {
		capturedPath = req.URL.Path
		capturedAuth = req.Header.Get("Authorization")

		body, _ := json.Marshal(AuthVerifyResponse{
			Status:         "authenticated",
			KeyID:          "key-1",
			KeyName:        "Production Key",
			OrganizationID: "org-1",
			ProjectID:      "proj-1",
		})

		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(bytes.NewReader(body)),
		}
	})

	resp, err := client.VerifyAuth(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if capturedPath != "/api/v1/auth/verify" {
		t.Fatalf("unexpected path: %s", capturedPath)
	}
	if capturedAuth != "Bearer test-api-key" {
		t.Fatalf("unexpected auth: %s", capturedAuth)
	}
	if resp.Status != "authenticated" {
		t.Fatalf("expected status authenticated, got %s", resp.Status)
	}
	if resp.KeyID != "key-1" {
		t.Fatalf("expected keyId key-1, got %s", resp.KeyID)
	}
}

func TestVerifyAuthError(t *testing.T) {
	client := newMockClient("bad-key", func(req *http.Request) *http.Response {
		body, _ := json.Marshal(map[string]string{
			"error":   "Unauthorized",
			"message": "Invalid API key",
		})
		return &http.Response{
			StatusCode: http.StatusUnauthorized,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(bytes.NewReader(body)),
		}
	})

	_, err := client.VerifyAuth(context.Background())
	if err == nil {
		t.Fatal("expected error, got nil")
	}

	var apiErr *APIError
	if !errors.As(err, &apiErr) {
		t.Fatalf("expected APIError, got %T: %v", err, err)
	}
	if apiErr.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", apiErr.StatusCode)
	}
	if apiErr.Message != "Invalid API key" {
		t.Fatalf("unexpected message: %s", apiErr.Message)
	}
}

func TestCreateChatCompletion(t *testing.T) {
	var capturedReq ChatCompletionRequest

	client := newMockClient("test-key", func(req *http.Request) *http.Response {
		if req.Method != http.MethodPost {
			t.Errorf("expected POST, got %s", req.Method)
		}
		if req.URL.Path != "/api/v1/chat/completions" {
			t.Errorf("unexpected path: %s", req.URL.Path)
		}

		_ = json.NewDecoder(req.Body).Decode(&capturedReq)

		body, _ := json.Marshal(ChatCompletionResponse{
			ID:      "chatcmpl-test",
			Object:  "chat.completion",
			Created: 1773485000,
			Model:   "unii-rag",
			Choices: []ChatCompletionChoice{
				{
					Index:        0,
					Message:      ChatMessage{Role: "assistant", Content: "Hello world!"},
					FinishReason: "stop",
				},
			},
			Citation: &ChatCompletionCitation{
				DocumentName: "doc.txt",
				Excerpt:      "Hello snippet",
				Confidence:   0.98,
			},
		})

		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body:       io.NopCloser(bytes.NewReader(body)),
		}
	})

	resp, err := client.CreateChatCompletion(context.Background(), &ChatCompletionRequest{
		Messages: []ChatMessage{{Role: "user", Content: "hello"}},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if capturedReq.Stream {
		t.Fatalf("expected stream=false, got true")
	}
	if len(capturedReq.Messages) != 1 || capturedReq.Messages[0].Content != "hello" {
		t.Fatalf("unexpected messages: %+v", capturedReq.Messages)
	}
	if resp.ID != "chatcmpl-test" {
		t.Fatalf("expected chatcmpl-test, got %s", resp.ID)
	}
	if len(resp.Choices) != 1 || resp.Choices[0].Message.Content != "Hello world!" {
		t.Fatalf("unexpected choices: %+v", resp.Choices)
	}
	if resp.Citation == nil || resp.Citation.DocumentName != "doc.txt" {
		t.Fatalf("unexpected citation: %+v", resp.Citation)
	}
}

func TestStreamChatCompletion(t *testing.T) {
	sseData := "data: {\"id\":\"c-1\",\"object\":\"chat.completion.chunk\",\"choices\":[{\"index\":0,\"delta\":{\"role\":\"assistant\",\"content\":\"Hello\"}}]}\n\n" +
		"data: {\"id\":\"c-1\",\"object\":\"chat.completion.chunk\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\" world\"}}]}\n\n" +
		"data: [DONE]\n\n"

	client := newMockClient("test-key", func(req *http.Request) *http.Response {
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"text/event-stream"}},
			Body:       io.NopCloser(bytes.NewBufferString(sseData)),
		}
	})

	stream, err := client.StreamChatCompletion(context.Background(), &ChatCompletionRequest{
		Messages: []ChatMessage{{Role: "user", Content: "hi"}},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	defer stream.Close()

	var chunks []*ChatCompletionChunk
	for {
		chunk, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			t.Fatalf("unexpected stream error: %v", err)
		}
		chunks = append(chunks, chunk)
	}

	if len(chunks) != 2 {
		t.Fatalf("expected 2 chunks, got %d", len(chunks))
	}
	if chunks[0].Choices[0].Delta.Content != "Hello" {
		t.Fatalf("expected Hello, got %s", chunks[0].Choices[0].Delta.Content)
	}
	if chunks[1].Choices[0].Delta.Content != " world" {
		t.Fatalf("expected world, got %s", chunks[1].Choices[0].Delta.Content)
	}
}
