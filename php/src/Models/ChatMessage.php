<?php

declare(strict_types=1);

namespace Unii\Models;

class ChatMessage
{
    public function __construct(
        public readonly string $role,
        public readonly string $content
    ) {}

    public static function user(string $content): self
    {
        return new self('user', $content);
    }

    public static function assistant(string $content): self
    {
        return new self('assistant', $content);
    }

    public static function system(string $content): self
    {
        return new self('system', $content);
    }

    public function toArray(): array
    {
        return [
            'role' => $this->role,
            'content' => $this->content,
        ];
    }

    public static function fromArray(array $data): self
    {
        return new self(
            role: (string) ($data['role'] ?? 'user'),
            content: (string) ($data['content'] ?? '')
        );
    }
}
