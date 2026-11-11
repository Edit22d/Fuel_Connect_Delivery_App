<?php

namespace App\Services\Payments;

use App\Models\Transaction;

/**
 * Implement this for MTN MoMo, Airtel Money, Flutterwave, Pesapal... then
 * select it in AppServiceProvider (FC_PAYMENT_DRIVER).
 *
 * `charge()` must NOT throw for a declined payment; return GatewayResult::FAILED.
 * For prompts the customer approves on their handset return PENDING and finish the
 * payment from the provider's webhook (POST /api/v1/payments/webhook/{provider}).
 */
interface PaymentGateway
{
    /** @param array{phone?: string} $context */
    public function charge(Transaction $transaction, array $context = []): GatewayResult;
}
