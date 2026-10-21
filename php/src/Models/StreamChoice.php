<?php

declare(strict_types=1);

namespace Unii\Models;

class StreamChoice
{
    public function __construct(
        public readonly int $index,
        public readonly StreamDelta $delta,
        public readonly ?string $finishReason = null
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            index: (int) ($data['index'] ?? 0),
            delta: StreamDelta::fromArray((array) ($data['delta'] ?? [])),
            finishReason: isset($data['finish_reason']) ? (string) $data['finish_reason'] : null
        );
    }
}
