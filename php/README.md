# unii-php (Unii PHP SDK)

Official PHP client library for the Unii conversational AI and knowledge grounding platform.

Compatible with PHP 8.1+ and modern PHP frameworks (Laravel, Symfony, etc.). Uses standard cURL with streaming SSE support.

## Installation

Install using Composer:

```bash
composer require unii/sdk
```

## Quick Start

```php
<?php

use Unii\Client;
use Unii\Models\ChatMessage;
use Unii\Models\ChatCompletionRequest;

require 'vendor/autoload.php';

$client = new Client(
    apiKey: getenv('UNII_API_KEY') ?: 'your-api-key',
    baseUrl: 'http://localhost:8080'
);

// 1. Verify API Key
$auth = $client->verifyAuth();
echo "Authenticated for Project ID: " . $auth->projectId . "\n";

// 2. Chat Completion
$response = $client->createChatCompletion(new ChatCompletionRequest(
    messages: [
        ChatMessage::user('What are the refund policy terms?')
    ]
));

echo $response->choices[0]->message->content . "\n";
if ($response->citation !== null) {
    echo "Source: " . $response->citation->documentName . " (Confidence: " . $response->citation->confidence . ")\n";
}

// 3. Stream Tokens via Server-Sent Events (SSE)
$stream = $client->streamChatCompletion(new ChatCompletionRequest(
    messages: [
        ChatMessage::user('Summarize the return window.')
    ]
));

foreach ($stream as $chunk) {
    echo $chunk->choices[0]->delta->content ?? '';
}
```

## Features

- Complete type safety with PHP 8.1+ constructor promotion and readonly properties.
- Full support for grounded citation attribution.
- Server-Sent Events generator iterator for real-time token streaming.
- Standard cURL HTTP client with configurable base URLs and request timeouts.
