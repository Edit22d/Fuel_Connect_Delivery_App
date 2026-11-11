<?php

namespace App\Services\Payments;

final class GatewayResult
{
    public const SUCCESSFUL = 'successful';
    public const PENDING = 'pending';   // customer still has to approve on their phone; a webhook finishes it
    public const FAILED = 'failed';

    public function __construct(
        public readonly string $status,
        public readonly ?string $providerReference = null,
        public readonly ?string $message = null,
    ) {
    }
}
