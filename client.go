package unii

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// Option is a functional option for configuring Client.
type Option func(*Client)

// WithBaseURL configures a custom API base URL.
func WithBaseURL(baseURL string) Option {
	return func(c *Client) {
		c.baseURL = strings.TrimRight(baseURL, "/")
	}
}

// WithHTTPClient configures a custom net/http Client.
func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		c.httpClient = httpClient
	}
}

// WithProjectID configures a default project ID for requests.
func WithProjectID(projectID string) Option {
	return func(c *Client) {
		c.projectID = projectID
	}
}

// Client is the primary interface for communicating with the Unii API.
type Client struct {
	apiKey     string
	baseURL    string
	projectID  string
	httpClient *http.Client
}

// NewClient creates a new Unii API client with the given API key.
func NewClient(apiKey string, opts ...Option) *Client {
	c := &Client{
		apiKey:  apiKey,
		baseURL: "http://localhost:8080",
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
	for _, opt := range opts {
		opt(c)
	}
	return c
}

func (c *Client) newRequest(ctx context.Context, method, path string, body any) (*http.Request, error) {
	var reader io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("marshal request body: %w", err)
		}
		reader = bytes.NewReader(data)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, reader)
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	return req, nil
}

func (c *Client) parseError(resp *http.Response) error {
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)

	var apiErr APIError
	apiErr.StatusCode = resp.StatusCode
	if err := json.Unmarshal(body, &apiErr); err != nil {
		apiErr.Message = strings.TrimSpace(string(body))
		if apiErr.Message == "" {
			apiErr.Message = resp.Status
		}
	}
	return &apiErr
}

// VerifyAuth validates active API key status and tenant identity.
func (c *Client) VerifyAuth(ctx context.Context) (*AuthVerifyResponse, error) {
	req, err := c.newRequest(ctx, http.MethodGet, "/api/v1/auth/verify", nil)
	if err != nil {
		return nil, err
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("execute request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, c.parseError(resp)
	}

	var result AuthVerifyResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("decode response: %w", err)
	}

	return &result, nil
}

// CreateChatCompletion executes a synchronous conversational turn and returns a grounded completion.
func (c *Client) CreateChatCompletion(ctx context.Context, req *ChatCompletionRequest) (*ChatCompletionResponse, error) {
	payload := *req
	payload.Stream = false
	if payload.ProjectID == "" && c.projectID != "" {
		payload.ProjectID = c.projectID
	}

	httpReq, err := c.newRequest(ctx, http.MethodPost, "/api/v1/chat/completions", payload)
	if err != nil {
		return nil, err
	}

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("execute request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, c.parseError(resp)
	}

	var result ChatCompletionResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("decode response: %w", err)
	}

	return &result, nil
}

// ChatCompletionStream represents a server-sent events stream of chat completion tokens.
type ChatCompletionStream struct {
	reader io.ReadCloser
	scan   *bufio.Scanner
}

// Recv returns the next streaming completion chunk, or io.EOF when stream is complete.
func (s *ChatCompletionStream) Recv() (*ChatCompletionChunk, error) {
	for s.scan.Scan() {
		line := strings.TrimSpace(s.scan.Text())
		if line == "" || strings.HasPrefix(line, ":") {
			continue // skip empty lines and sse keepalives
		}
		if strings.HasPrefix(line, "data:") {
			data := strings.TrimSpace(strings.TrimPrefix(line, "data:"))
			if data == "[DONE]" {
				return nil, io.EOF
			}
			var chunk ChatCompletionChunk
			if err := json.Unmarshal([]byte(data), &chunk); err != nil {
				continue
			}
			return &chunk, nil
		}
	}
	if err := s.scan.Err(); err != nil {
		return nil, err
	}
	return nil, io.EOF
}

// Close closes the underlying stream reader.
func (s *ChatCompletionStream) Close() error {
	return s.reader.Close()
}

// StreamChatCompletion opens a Server-Sent Events stream for real-time tokens.
func (c *Client) StreamChatCompletion(ctx context.Context, req *ChatCompletionRequest) (*ChatCompletionStream, error) {
	payload := *req
	payload.Stream = true
	if payload.ProjectID == "" && c.projectID != "" {
		payload.ProjectID = c.projectID
	}

	httpReq, err := c.newRequest(ctx, http.MethodPost, "/api/v1/chat/completions", payload)
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Accept", "text/event-stream")

	// Avoid client timeout on streaming requests
	client := c.httpClient
	if client.Timeout > 0 {
		clientCopy := *client
		clientCopy.Timeout = 0
		client = &clientCopy
	}

	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("execute request: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, c.parseError(resp)
	}

	return &ChatCompletionStream{
		reader: resp.Body,
		scan:   bufio.NewScanner(resp.Body),
	}, nil
}
