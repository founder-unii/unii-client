# unii-go

Official Go client library for the Unii API.

## Installation

```bash
go get github.com/malviys/unii-go
```

## Quickstart

```go
package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log"
	"os"

	"github.com/malviys/unii-go"
)

func main() {
	ctx := context.Background()
	client := unii.NewClient(os.Getenv("UNII_API_KEY"), unii.WithBaseURL("http://localhost:8080"))

	// 1. Verify tenant authentication
	auth, err := client.VerifyAuth(ctx)
	if err != nil {
		log.Fatalf("Verify auth failed: %v", err)
	}
	fmt.Printf("Authenticated project: %s\n", auth.ProjectID)

	// 2. Synchronous chat completion
	resp, err := client.CreateChatCompletion(ctx, &unii.ChatCompletionRequest{
		Messages: []unii.ChatMessage{
			{Role: "user", Content: "What is the return policy?"},
		},
	})
	if err != nil {
		log.Fatalf("Chat completion failed: %v", err)
	}
	fmt.Printf("Answer: %s\n", resp.Choices[0].Message.Content)
	if resp.Citation != nil {
		fmt.Printf("Source: %s\n", resp.Citation.DocumentName)
	}

	// 3. Real-time streaming over Server-Sent Events
	stream, err := client.StreamChatCompletion(ctx, &unii.ChatCompletionRequest{
		Messages: []unii.ChatMessage{
			{Role: "user", Content: "Explain returns"},
		},
	})
	if err != nil {
		log.Fatalf("Stream failed: %v", err)
	}
	defer stream.Close()

	for {
		chunk, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			log.Fatalf("Error reading chunk: %v", err)
		}
		if len(chunk.Choices) > 0 {
			fmt.Print(chunk.Choices[0].Delta.Content)
		}
	}
}
```
