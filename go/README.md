# unii-go

Official Go client library for the Unii API. Verify project API keys, request answers grounded in your project's knowledge, and read chat completions over Server-Sent Events (SSE).

## Requirements

- Go 1.21 or later.
- A running Unii API.
- An active project API key. In the Unii workbench, select your project, open **Developers → API Keys**, and select **Create API Key**.
- Project knowledge available to the server for grounded answers.

## Installation

From your application's Go module:

```bash
go get github.com/malviys/unii-go/go
```

The import path is `github.com/malviys/unii-go/go`; the Go package name is `unii`. The SDK uses only the Go standard library.

## Quickstart

Set your project API key and `UNII_BASE_URL`. Replace the example URL with your Unii server's address:

```bash
export UNII_API_KEY='your-project-api-key'
export UNII_BASE_URL='https://your-unii-server.example'
```

These variables are read by the examples. The client itself receives its configuration through `NewClient` and options.

Save the following as `main.go`, then run `go run .`:

```go
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/malviys/unii-go/go"
)

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	apiKey := os.Getenv("UNII_API_KEY")
	if apiKey == "" {
		return fmt.Errorf("set UNII_API_KEY before running this example")
	}
	baseURL := os.Getenv("UNII_BASE_URL")
	if baseURL == "" {
		return fmt.Errorf("set UNII_BASE_URL before running this example")
	}
	client := unii.NewClient(apiKey, unii.WithBaseURL(baseURL))

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	resp, err := client.CreateChatCompletion(ctx, &unii.ChatCompletionRequest{
		Messages: []unii.ChatMessage{
			{Role: "user", Content: "What is the return policy?"},
		},
	})
	if err != nil {
		return fmt.Errorf("create chat completion: %w", err)
	}
	if len(resp.Choices) == 0 {
		return fmt.Errorf("chat completion returned no choices")
	}

	fmt.Println(resp.Choices[0].Message.Content)
	if resp.Citation != nil {
		fmt.Printf("Source: %s\n", resp.Citation.DocumentName)
		fmt.Printf("Excerpt: %s\n", resp.Citation.Excerpt)
	}
	return nil
}
```

The answer and optional citation depend on your project's knowledge. Authentication verification is optional; chat requests also authenticate the API key.

## Configuration

Pass options to `unii.NewClient(apiKey, opts...)`:

| Option                   | Configuration                                      | Purpose                                                                 |
| ------------------------ | -------------------------------------------------- | ----------------------------------------------------------------------- |
| `WithBaseURL(url)`       | `UNII_BASE_URL`, passed explicitly in the examples | Set the server origin, without `/api/v1`. Trailing slashes are removed. |
| `WithHTTPClient(client)` | A 60-second timeout by default                     | Set a custom HTTP client, transport, or timeout.                        |
| `WithProjectID(id)`      | Unset by default                                   | Set a default project ID for chat requests.                             |

A request's nonempty `ProjectID` overrides the client default. When neither is set, the server uses the project associated with the API key. An explicit project ID must match that project's key; it does not grant access to another project.

For example, with imports `net/http`, `os`, `time`, and `github.com/malviys/unii-go/go`:

```go
client := unii.NewClient(
	os.Getenv("UNII_API_KEY"),
	unii.WithBaseURL(os.Getenv("UNII_BASE_URL")),
	unii.WithProjectID("your-project-id"),
	unii.WithHTTPClient(&http.Client{Timeout: 45 * time.Second}),
)
```

Use a request context to cancel work or set a deadline. For streaming requests, the SDK disables `http.Client.Timeout`, including a custom client's overall timeout. Use a context deadline to bound the stream's lifetime. Custom transport settings still apply.

## Authentication

The SDK sends the key as `Authorization: Bearer <api-key>` on every request. To inspect the key's identity before making a chat request, use `VerifyAuth`.

With the `client` and `ctx` from the quickstart:

```go
auth, err := client.VerifyAuth(ctx)
if err != nil {
	return fmt.Errorf("verify authentication: %w", err)
}
fmt.Printf("Key: %s\nProject: %s\nOrganization: %s\n",
	auth.KeyName, auth.ProjectID, auth.OrganizationID)
```

The response also includes `Status` and `KeyID`.

## Streaming

`StreamChatCompletion` opens an SSE response. Call `Recv` until it returns `io.EOF`, and close the stream when finished. Content arrives in `Choices[i].Delta.Content`; chunks can have no choices or contain only metadata.

This helper requires imports `context`, `errors`, `fmt`, `io`, `time`, and `github.com/malviys/unii-go/go`. Call it with your configured client, for example `printStream(context.Background(), client)`:

```go
func printStream(ctx context.Context, client *unii.Client) error {
	ctx, cancel := context.WithTimeout(ctx, 2*time.Minute)
	defer cancel()

	stream, err := client.StreamChatCompletion(ctx, &unii.ChatCompletionRequest{
		Messages: []unii.ChatMessage{
			{Role: "user", Content: "Explain the return policy"},
		},
	})
	if err != nil {
		return fmt.Errorf("open chat stream: %w", err)
	}
	defer stream.Close()

	for {
		chunk, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			fmt.Println()
			return nil
		}
		if err != nil {
			return fmt.Errorf("read chat stream: %w", err)
		}
		for _, choice := range chunk.Choices {
			fmt.Print(choice.Delta.Content)
		}
	}
}
```

The current Unii server sends the completed answer in a single SSE content event. The SDK can read multiple chunks when the server supplies them. The streaming response type does not expose citations; use a synchronous completion when you need source evidence.

## Error handling

Non-2xx HTTP responses return `*unii.APIError`. Use `errors.As` to inspect the status and server message. Network, context, and response-decoding errors are returned as other error types.

This example requires imports `errors` and `log`, in addition to the quickstart's imports:

```go
resp, err := client.CreateChatCompletion(ctx, &unii.ChatCompletionRequest{
	Query: "What is the return policy?",
})
if err != nil {
	var apiErr *unii.APIError
	if errors.As(err, &apiErr) {
		log.Printf("Unii API status=%d message=%q error=%q",
			apiErr.StatusCode, apiErr.Message, apiErr.ErrorMsg)
	}
	return err
}
fmt.Printf("Received %d choices\n", len(resp.Choices))
```

| Status | What to check                                                 |
| ------ | ------------------------------------------------------------- |
| `400`  | Supply nonempty `Messages` or `Query`.                        |
| `401`  | Check for a missing, invalid, or revoked project API key.     |
| `403`  | Check that an explicit `ProjectID` matches the key's project. |
| `503`  | Check that the server's inference service is available.       |

The SDK does not automatically retry failed requests.

## API reference

| Method                 | Endpoint                                 | Result                    |
| ---------------------- | ---------------------------------------- | ------------------------- |
| `VerifyAuth`           | `GET /api/v1/auth/verify`                | `*AuthVerifyResponse`     |
| `CreateChatCompletion` | `POST /api/v1/chat/completions`          | `*ChatCompletionResponse` |
| `StreamChatCompletion` | `POST /api/v1/chat/completions` with SSE | `*ChatCompletionStream`   |

Pass a non-nil `*ChatCompletionRequest` to either chat method.

| Request field | Behavior                                                                                                                           |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `Messages`    | A slice of `ChatMessage` values with `Role` and `Content`. The current server uses the last nonempty message content as the query. |
| `Query`       | A direct query string. The current server gives a nonempty `Query` precedence over `Messages`.                                     |
| `ProjectID`   | An optional project ID, subject to the API key's project scope.                                                                    |
| `Temperature` | Optional `*float64`, omitted when nil. Serialized by the SDK; the current server does not apply it.                                |
| `MaxTokens`   | Optional `*int`, omitted when nil. Serialized as `max_tokens`; the current server does not apply it.                               |
| `Stream`      | Set automatically by the chosen method: `false` for synchronous completion, `true` for streaming.                                  |

Synchronous responses include `ID`, `Object`, `Created`, `Model`, and `Choices`. Each choice contains `Index`, `Message`, and `FinishReason`. `Citation` can be nil; when present, it provides `DocumentName`, `Excerpt`, and `Confidence`.

Streaming chunks expose `ID`, `Object`, and `Choices`. Each streaming choice contains `Index`, `Delta`, and an optional `FinishReason`.

See [client.go](client.go) for methods and configuration options, and [types.go](types.go) for all exported request and response fields. This SDK currently covers authentication verification and chat completions.

## Development

From the `go/` directory:

```bash
go test ./...
go vet ./...
```

The existing tests use mock HTTP transports and do not require a running Unii server or an API key.
