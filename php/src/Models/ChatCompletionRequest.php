<?php

declare(strict_types=1);

namespace Unii\Models;

class ChatCompletionRequest
{
    /**
     * @param array<ChatMessage|array{role: string, content: string}> $messages
     */
    public function __construct(
        public readonly array $messages = [],
        public readonly ?string $query = null,
        public readonly bool $stream = false,
        public readonly ?float $temperature = null,
        public readonly ?int $maxTokens = null,
        public readonly ?string $projectId = null
    ) {}

    public function toArray(): array
    {
        $payload = [
            'stream' => $this->stream,
        ];

        if (!empty($this->messages)) {
            $payload['messages'] = array_map(
                fn($m) => $m instanceof ChatMessage ? $m->toArray() : $m,
                $this->messages
            );
        }

        if ($this->query !== null) {
            $payload['query'] = $this->query;
        }

        if ($this->temperature !== null) {
            $payload['temperature'] = $this->temperature;
        }

        if ($this->maxTokens !== null) {
            $payload['max_tokens'] = $this->maxTokens;
        }

        if ($this->projectId !== null) {
            $payload['projectId'] = $this->projectId;
        }

        return $payload;
    }
}
