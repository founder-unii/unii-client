<?php

declare(strict_types=1);

namespace Unii\Models;

class ChatCompletionResponse
{
    /**
     * @param array<ChatChoice> $choices
     */
    public function __construct(
        public readonly string $id,
        public readonly string $object,
        public readonly int $created,
        public readonly string $model,
        public readonly array $choices,
        public readonly ?Citation $citation = null
    ) {}

    public static function fromArray(array $data): self
    {
        $choices = array_map(
            fn(array $c) => ChatChoice::fromArray($c),
            (array) ($data['choices'] ?? [])
        );

        $citation = isset($data['citation']) && is_array($data['citation'])
            ? Citation::fromArray($data['citation'])
            : null;

        return new self(
            id: (string) ($data['id'] ?? ''),
            object: (string) ($data['object'] ?? 'chat.completion'),
            created: (int) ($data['created'] ?? time()),
            model: (string) ($data['model'] ?? 'unii-rag'),
            choices: $choices,
            citation: $citation
        );
    }
}
