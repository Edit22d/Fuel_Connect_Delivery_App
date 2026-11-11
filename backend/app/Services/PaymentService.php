<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Transaction;
use App\Models\User;
use App\Services\Payments\GatewayResult;
use App\Services\Payments\PaymentGateway;
use Illuminate\Support\Facades\DB;

class PaymentService
{
    public const METHODS = ['momo', 'airtel', 'card', 'wallet', 'cash'];

    public function __construct(private PaymentGateway $gateway)
    {
    }

    /**
     * Collects payment for an order.
     * Returns the resulting payment status: 'paid' | 'cod' | 'pending'.
     * Wallet and cash are settled here; mobile money / card go through the gateway.
     */
    public function collect(Order $order, ?string $phone = null): string
    {
        if ($order->payment_method === 'cash') {
            $order->update(['payment_status' => 'cod']);

            return 'cod';
        }

        if ($order->payment_method === 'wallet') {
            DB::transaction(function () use ($order) {
                $user = User::whereKey($order->customer_id)->lockForUpdate()->firstOrFail();
                abort_if($user->wallet_balance < $order->total, 422, 'Your wallet balance is too low. Top up or pick another method.');

                $user->decrement('wallet_balance', $order->total);
                $this->record($order->customer_id, Transaction::ORDER_PAYMENT, 'wallet', $order->total, Transaction::SUCCESSFUL, $order);
                $order->update(['payment_status' => 'paid']);
            });

            return 'paid';
        }

        // momo | airtel | card
        $tx = $this->record($order->customer_id, Transaction::ORDER_PAYMENT, $order->payment_method, $order->total, Transaction::PENDING, $order, ['phone' => $phone]);
        $result = $this->gateway->charge($tx, ['phone' => $phone]);

        return $this->applyResult($tx, $result);
    }

    /** Wallet top-up through the gateway. Returns the transaction (may still be pending). */
    public function topUp(User $user, int $amount, string $method, ?string $phone = null): Transaction
    {
        abort_unless(in_array($method, ['momo', 'airtel', 'card'], true), 422, 'Choose mobile money or card to top up.');

        $tx = $this->record($user->id, Transaction::WALLET_TOPUP, $method, $amount, Transaction::PENDING, null, ['phone' => $phone], 'Wallet top up');
        $this->applyResult($tx, $this->gateway->charge($tx, ['phone' => $phone]));

        return $tx->fresh();
    }

    /**
     * Called for a gateway result and for provider webhooks. Idempotent.
     * Returns 'paid' | 'pending' | 'failed'.
     */
    public function applyResult(Transaction $tx, GatewayResult $result): string
    {
        if ($tx->status === Transaction::SUCCESSFUL) {
            return 'paid';
        }

        if ($result->status === GatewayResult::PENDING) {
            $tx->update(['provider_reference' => $result->providerReference ?? $tx->provider_reference]);

            return 'pending';
        }

        if ($result->status === GatewayResult::FAILED) {
            $tx->update(['status' => Transaction::FAILED, 'provider_reference' => $result->providerReference, 'description' => $result->message]);

            return 'failed';
        }

        DB::transaction(function () use ($tx, $result) {
            $tx->update(['status' => Transaction::SUCCESSFUL, 'provider_reference' => $result->providerReference]);

            if ($tx->type === Transaction::WALLET_TOPUP) {
                User::whereKey($tx->user_id)->increment('wallet_balance', $tx->amount);
            } elseif ($tx->order_id) {
                Order::whereKey($tx->order_id)->update(['payment_status' => 'paid']);
            }
        });

        return 'paid';
    }

    /**
     * Refund a paid order. Wallet refunds are instant; the rest are recorded as
     * `pending` and an admin marks them successful in Filament once the provider
     * has paid them back (within 24h, as promised in the app).
     */
    public function refund(Order $order, int $amount): ?Transaction
    {
        if ($amount <= 0) {
            return null;
        }

        $method = $order->payment_method;

        return DB::transaction(function () use ($order, $amount, $method) {
            $instant = $method === 'wallet';
            if ($instant) {
                User::whereKey($order->customer_id)->increment('wallet_balance', $amount);
            }

            return $this->record(
                $order->customer_id, Transaction::REFUND, $method, $amount,
                $instant ? Transaction::SUCCESSFUL : Transaction::PENDING, $order, null, "Refund for order {$order->number}"
            );
        });
    }

    private function record(int $userId, string $type, ?string $method, int $amount, string $status, ?Order $order = null, ?array $meta = null, ?string $description = null): Transaction
    {
        return Transaction::create([
            'reference' => Transaction::newReference(),
            'user_id' => $userId,
            'order_id' => $order?->id,
            'type' => $type,
            'method' => $method,
            'amount' => $amount,
            'status' => $status,
            'description' => $description ?? ($order ? "Order {$order->number}" : null),
            'meta' => $meta,
        ]);
    }

    /** Used by DeliveryService for rider earnings / payouts and cash on delivery. */
    public function ledger(int $userId, string $type, ?string $method, int $amount, string $status, ?Order $order = null, ?array $meta = null, ?string $description = null): Transaction
    {
        return $this->record($userId, $type, $method, $amount, $status, $order, $meta, $description);
    }
}
