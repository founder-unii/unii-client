<?php

declare(strict_types=1);

namespace Unii\Models;

class StreamDelta
{
    public function __construct(
        public readonly ?string $role = null,
        public readonly ?string $content = null
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            role: isset($data['role']) ? (string) $data['role'] : null,
            content: isset($data['content']) ? (string) $data['content'] : null
        );
    }
}
