<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Transaction;
use App\Services\OrderService;
use App\Services\PaymentService;
use App\Services\Payments\GatewayResult;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Payment providers call this when the customer approves (or declines) a mobile-money /
 * card prompt. Authenticated with a shared secret in the `X-Webhook-Secret` header;
 * adapt the payload mapping to the provider you integrate (MTN MoMo, Airtel, Flutterwave...).
 *
 * Expected body: { "reference": "TX-ABC123", "status": "successful|failed", "provider_reference": "..." }
 */
class PaymentWebhookController extends Controller
{
    public function handle(Request $request, string $provider, PaymentService $payments, OrderService $orders): JsonResponse
    {
        $secret = config('fuelconnect.payments.webhook_secret');
        abort_unless($secret && hash_equals($secret, (string) $request->header('X-Webhook-Secret')), 401, 'Invalid webhook signature.');

        $data = $request->validate([
            'reference' => ['required', 'string'],
            'status' => ['required', 'in:successful,failed'],
            'provider_reference' => ['nullable', 'string'],
        ]);

        $tx = Transaction::where('reference', $data['reference'])->firstOrFail();

        $payments->applyResult($tx, new GatewayResult($data['status'], $data['provider_reference'] ?? null));

        if ($data['status'] === 'successful' && $tx->type === Transaction::ORDER_PAYMENT && $tx->order_id) {
            $order = Order::find($tx->order_id);
            if ($order) {
                $orders->confirm($order);
            }
        }

        return response()->json(['received' => true]);
    }
}
