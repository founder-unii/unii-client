<?php

declare(strict_types=1);

namespace Unii\Exceptions;

use Exception;

class UniiApiException extends Exception
{
    public function __construct(
        int $statusCode,
        string $message,
        private readonly mixed $details = null
    ) {
        parent::__construct($message, $statusCode);
    }

    public function getStatusCode(): int
    {
        return $this->code;
    }

    public function getDetails(): mixed
    {
        return $this->details;
    }
}
