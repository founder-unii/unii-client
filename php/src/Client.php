<?php

declare(strict_types=1);

namespace Unii;

use Generator;
use InvalidArgumentException;
use Unii\Exceptions\UniiApiException;
use Unii\Models\AuthVerificationResponse;
use Unii\Models\ChatCompletionRequest;
use Unii\Models\ChatCompletionResponse;
use Unii\Models\StreamChatCompletionChunk;

class Client
{
    private string $baseUrl;

    public function __construct(
        private readonly string $apiKey,
        string $baseUrl = 'http://localhost:8080',
        private readonly ?string $projectId = null
    ) {
        if (trim($this->apiKey) === '') {
            throw new InvalidArgumentException('Unii apiKey is required');
        }
        $this->baseUrl = rtrim($baseUrl, '/');
    }

    public function getBaseUrl(): string
    {
        return $this->baseUrl;
    }

    public function getProjectId(): ?string
    {
        return $this->projectId;
    }

    public function verifyAuth(): AuthVerificationResponse
    {
        $url = $this->baseUrl . '/api/v1/auth/verify';
        $ch = curl_init($url);
        if ($ch === false) {
            throw new UniiApiException(0, 'Failed to initialize curl');
        }

        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                'Authorization: Bearer ' . $this->apiKey,
                'User-Agent: unii-php-sdk/0.1.0',
                'Accept: application/json',
            ],
            CURLOPT_TIMEOUT => 30,
        ]);

        $response = curl_exec($ch);
        $statusCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($response === false) {
            throw new UniiApiException(0, 'cURL request failed: ' . $error);
        }

        $json = json_decode((string) $response, true);
        if ($statusCode < 200 || $statusCode >= 300) {
            $msg = is_array($json) && isset($json['message']) ? (string) $json['message'] : 'Auth verification failed';
            throw new UniiApiException($statusCode, $msg, $json);
        }

        return AuthVerificationResponse::fromArray((array) $json);
    }

    public function createChatCompletion(ChatCompletionRequest $request): ChatCompletionResponse
    {
        $url = $this->baseUrl . '/api/v1/chat/completions';
        $payload = $request->toArray();
        $payload['stream'] = false;
        if (!isset($payload['projectId']) && $this->projectId !== null) {
            $payload['projectId'] = $this->projectId;
        }

        $ch = curl_init($url);
        if ($ch === false) {
            throw new UniiApiException(0, 'Failed to initialize curl');
        }

        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => (string) json_encode($payload),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                'Authorization: Bearer ' . $this->apiKey,
                'Content-Type: application/json',
                'Accept: application/json',
                'User-Agent: unii-php-sdk/0.1.0',
            ],
            CURLOPT_TIMEOUT => 60,
        ]);

        $response = curl_exec($ch);
        $statusCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($response === false) {
            throw new UniiApiException(0, 'cURL request failed: ' . $error);
        }

        $json = json_decode((string) $response, true);
        if ($statusCode < 200 || $statusCode >= 300) {
            $msg = is_array($json) && isset($json['message']) ? (string) $json['message'] : 'Chat completion failed';
            throw new UniiApiException($statusCode, $msg, $json);
        }

        return ChatCompletionResponse::fromArray((array) $json);
    }

    /**
     * @return Generator<StreamChatCompletionChunk>
     */
    public function streamChatCompletion(ChatCompletionRequest $request): Generator
    {
        $url = $this->baseUrl . '/api/v1/chat/completions';
        $payload = $request->toArray();
        $payload['stream'] = true;
        if (!isset($payload['projectId']) && $this->projectId !== null) {
            $payload['projectId'] = $this->projectId;
        }

        $ch = curl_init($url);
        if ($ch === false) {
            throw new UniiApiException(0, 'Failed to initialize curl');
        }

        $buffer = '';
        $queue = [];

        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => (string) json_encode($payload),
            CURLOPT_HTTPHEADER => [
                'Authorization: Bearer ' . $this->apiKey,
                'Content-Type: application/json',
                'Accept: text/event-stream',
                'User-Agent: unii-php-sdk/0.1.0',
            ],
            CURLOPT_TIMEOUT => 60,
            CURLOPT_WRITEFUNCTION => function ($handle, $data) use (&$buffer, &$queue) {
                $buffer .= $data;
                $lines = explode("\n", $buffer);
                $buffer = array_pop($lines) ?? '';

                foreach ($lines as $line) {
                    $trimmed = trim($line);
                    if ($trimmed === '' || str_starts_with($trimmed, ':')) {
                        continue;
                    }
                    if (str_starts_with($trimmed, 'data:')) {
                        $content = trim(substr($trimmed, 5));
                        if ($content === '[DONE]') {
                            $queue[] = '[DONE]';
                            return strlen($data);
                        }
                        $json = json_decode($content, true);
                        if (is_array($json)) {
                            $queue[] = StreamChatCompletionChunk::fromArray($json);
                        }
                    }
                }
                return strlen($data);
            },
        ]);

        curl_exec($ch);
        $statusCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($statusCode < 200 || $statusCode >= 300) {
            throw new UniiApiException($statusCode, 'Streaming request failed');
        }

        foreach ($queue as $item) {
            if ($item === '[DONE]') {
                return;
            }
            yield $item;
        }
    }
}
