# Unii.Sdk (C# / .NET)

Official .NET client library for Unii platform. Compatible with .NET 8.0, 9.0, and 10.0.

## Installation

```bash
dotnet add package Unii.Sdk
```

## Quick Start

```csharp
using Unii.Sdk;

var client = new UniiClient(Environment.GetEnvironmentVariable("UNII_API_KEY")!);

// 1. Verify key
var auth = await client.VerifyAuthAsync();
Console.WriteLine($"Key: {auth.KeyName}");

// 2. Chat completion
var response = await client.CreateChatCompletionAsync(new ChatCompletionRequest
{
    Messages = new List<ChatMessage>
    {
        ChatMessage.User("What is the refund policy?")
    }
});
Console.WriteLine(response.Choices[0].Message.Content);

// 3. Real-time token streaming
await foreach (var chunk in client.StreamChatCompletionAsync(new ChatCompletionRequest
{
    Messages = new List<ChatMessage> { ChatMessage.User("Explain warranty terms.") }
}))
{
    Console.Write(chunk.Choices[0].Delta.Content);
}
```
