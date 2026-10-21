<?php

declare(strict_types=1);

namespace Unii\Models;

class StreamChatCompletionChunk
{
    /**
     * @param array<StreamChoice> $choices
     */
    public function __construct(
        public readonly string $id,
        public readonly string $object,
        public readonly array $choices
    ) {}

    public static function fromArray(array $data): self
    {
        $choices = array_map(
            fn(array $c) => StreamChoice::fromArray($c),
            (array) ($data['choices'] ?? [])
        );

        return new self(
            id: (string) ($data['id'] ?? ''),
            object: (string) ($data['object'] ?? 'chat.completion.chunk'),
            choices: $choices
        );
    }
}
