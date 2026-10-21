<?php

declare(strict_types=1);

namespace Unii\Models;

class Citation
{
    public function __construct(
        public readonly string $documentName,
        public readonly string $excerpt,
        public readonly float $confidence
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            documentName: (string) ($data['documentName'] ?? ''),
            excerpt: (string) ($data['excerpt'] ?? ''),
            confidence: (float) ($data['confidence'] ?? 0.0)
        );
    }
}
