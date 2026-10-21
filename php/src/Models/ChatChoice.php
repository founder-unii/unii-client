<?php

declare(strict_types=1);

namespace Unii\Models;

class ChatChoice
{
    public function __construct(
        public readonly int $index,
        public readonly ChatMessage $message,
        public readonly string $finishReason
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            index: (int) ($data['index'] ?? 0),
            message: ChatMessage::fromArray((array) ($data['message'] ?? [])),
            finishReason: (string) ($data['finish_reason'] ?? 'stop')
        );
    }
}
