<?php

namespace App\Services\Payments;

use App\Models\Transaction;
use Illuminate\Support\Str;

/** Approves everything instantly. For development and demos only. */
class SandboxGateway implements PaymentGateway
{
    public function charge(Transaction $transaction, array $context = []): GatewayResult
    {
        return new GatewayResult(GatewayResult::SUCCESSFUL, 'SBX-'.strtoupper(Str::random(8)));
    }
}
