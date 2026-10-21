<?php

declare(strict_types=1);

namespace Unii\Models;

class AuthVerificationResponse
{
    public function __construct(
        public readonly string $status,
        public readonly string $keyId,
        public readonly string $keyName,
        public readonly string $organizationId,
        public readonly string $projectId
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            status: (string) ($data['status'] ?? ''),
            keyId: (string) ($data['keyId'] ?? ''),
            keyName: (string) ($data['keyName'] ?? ''),
            organizationId: (string) ($data['organizationId'] ?? ''),
            projectId: (string) ($data['projectId'] ?? '')
        );
    }
}
