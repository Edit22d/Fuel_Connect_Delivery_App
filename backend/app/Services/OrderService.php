<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Station;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class OrderService
{
    public function __construct(
        private PricingService $pricing,
        private PaymentService $payments,
        private Notifier $notifier,
    ) {
    }

    /**
     * Creates an order and collects payment.
     *
     * @param array{station_id:int, fuel_type:string, litres:int, payment_method:string, delivery_address:string,
     *              vehicle_id?:int|null, delivery_note?:string|null, delivery_lat?:float|null, delivery_lng?:float|null,
     *              scheduled_at?:string|null, phone?:string|null} $data
     */
    public function create(User $customer, array $data): Order
    {
        $station = Station::where('is_active', true)->findOrFail($data['station_id']);
        $quote = $this->pricing->quote($station, $data['fuel_type'], (int) $data['litres'], $data['delivery_lat'] ?? null, $data['delivery_lng'] ?? null);

        $order = DB::transaction(function () use ($customer, $station, $quote, $data) {
            return Order::create([
                'number' => Order::newNumber(),
                'customer_id' => $customer->id,
                'station_id' => $station->id,
                'vehicle_id' => $data['vehicle_id'] ?? null,
                'fuel_type' => $quote['fuel_type'],
                'litres' => $quote['litres'],
                'price_per_litre' => $quote['price_per_litre'],
                'fuel_total' => $quote['fuel_total'],
                'delivery_fee' => $quote['delivery_fee'],
                'service_fee' => $quote['service_fee'],
                'total' => $quote['total'],
                'delivery_address' => $data['delivery_address'],
                'delivery_note' => $data['delivery_note'] ?? null,
                'delivery_lat' => $data['delivery_lat'] ?? null,
                'delivery_lng' => $data['delivery_lng'] ?? null,
                'distance_km' => $quote['distance_km'],
                'scheduled_at' => $data['scheduled_at'] ?? null,
                'status' => Order::PENDING_PAYMENT,
                'payment_method' => $data['payment_method'],
                'payment_status' => 'unpaid',
                'pickup_code' => str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT),
                'delivery_code' => str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT),
            ]);
        });

        // Payment happens outside the DB transaction: a failed payment must leave the order for the customer to retry.
        $payment = $this->payments->collect($order, $data['phone'] ?? null);
        if (in_array($payment, ['paid', 'cod'], true)) {
            $this->confirm($order);
        }

        return $order->fresh(['station', 'vehicle']);
    }

    /** Payment received (or cash on delivery): the order now waits for a rider. */
    public function confirm(Order $order): Order
    {
        if ($order->status !== Order::PENDING_PAYMENT) {
            return $order;
        }

        $order->update(['status' => Order::CONFIRMED, 'confirmed_at' => now()]);

        $this->notifier->send($order->customer, 'check', 'Payment confirmed', "Your payment of UGX ".number_format($order->total)." for order {$order->number} was successful.");

        return $order;
    }

    /** Fee that would apply if the customer cancelled right now. */
    public function cancellationFee(Order $order): int
    {
        if (! $order->fuelCollected() || $order->payment_status !== 'paid') {
            return 0;
        }

        return min((int) config('fuelconnect.cancellation_fee'), $order->total);
    }

    public function cancel(Order $order, ?string $reason, string $by = 'customer'): Order
    {
        return DB::transaction(function () use ($order, $reason, $by) {
            $order = Order::whereKey($order->id)->lockForUpdate()->firstOrFail();

            abort_unless($order->isOpen(), 422, 'This order can no longer be cancelled.');
            abort_if($by === 'customer' && $order->status === Order::ARRIVED, 422, 'Your driver has arrived. Please speak to them or contact support.');

            $fee = $by === 'customer' ? $this->cancellationFee($order) : 0;
            $refund = $order->payment_status === 'paid' ? $order->total - $fee : 0;
            $riderId = $order->rider_id;

            $order->update([
                'status' => Order::CANCELLED,
                'cancel_reason' => $reason,
                'cancellation_fee' => $fee,
                'cancelled_by' => $by,
                'cancelled_at' => now(),
            ]);

            if ($refund > 0) {
                $this->payments->refund($order, $refund);
                $order->update(['payment_status' => 'refunded']);
            }

            $this->notifier->send($order->customer, 'shield', 'Order cancelled', $refund > 0
                ? "Order {$order->number} was cancelled. UGX ".number_format($refund).' will be refunded within 24 hours.'
                : "Order {$order->number} was cancelled.");
            if ($riderId) {
                $this->notifier->send(User::find($riderId), 'shield', 'Delivery cancelled', "Order {$order->number} was cancelled by the ".($by === 'admin' ? 'FuelConnect team' : 'customer').'.');
            }

            return $order->fresh(['station', 'vehicle']);
        });
    }

    public function rate(Order $order, int $rating, ?string $comment = null): Order
    {
        abort_unless($order->status === Order::DELIVERED, 422, 'You can rate an order once it has been delivered.');
        abort_if($order->rating !== null, 422, 'You have already rated this delivery.');

        $order->update(['rating' => $rating, 'rating_comment' => $comment]);

        return $order;
    }
}
