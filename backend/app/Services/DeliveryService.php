<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderRejection;
use App\Models\Rider;
use App\Models\Transaction;
use App\Models\User;
use App\Support\Geo;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/** Delivery logic: what a rider can see, accept, collect and hand over. */
class DeliveryService
{
    private const ACTIVE = [Order::ASSIGNED, Order::PICKED_UP, Order::ARRIVED];

    public function __construct(
        private PricingService $pricing,
        private PaymentService $payments,
        private Notifier $notifier,
    ) {
    }

    public function activeFor(User $rider): ?Order
    {
        return Order::with(['station', 'customer', 'vehicle'])
            ->where('rider_id', $rider->id)->whereIn('status', self::ACTIVE)->latest('assigned_at')->first();
    }

    /**
     * Requests this rider can take. Hidden: ones they rejected, scheduled orders that
     * are not due within the hour, and (when the rider shares a location) anything
     * beyond the dispatch radius. Each order gets `pickup_km` and `estimated_earning`.
     *
     * @return Collection<int, Order>
     */
    public function availableFor(User $rider, string $sort = 'nearest'): Collection
    {
        $profile = $rider->rider;
        $radius = (float) config('fuelconnect.dispatch_radius_km');

        $orders = Order::with(['station', 'customer', 'vehicle'])
            ->where('status', Order::CONFIRMED)->whereNull('rider_id')
            ->whereNotIn('id', OrderRejection::where('rider_id', $rider->id)->select('order_id'))
            ->where(fn ($q) => $q->whereNull('scheduled_at')->orWhere('scheduled_at', '<=', now()->addHour()))
            ->get();

        $orders = $orders->map(function (Order $o) use ($profile) {
            $o->pickup_km = Geo::km($profile?->current_lat, $profile?->current_lng, $o->station->lat, $o->station->lng);
            $o->estimated_earning = $this->pricing->riderEarning($o->pickup_km ?? 0.0, (float) $o->distance_km);

            return $o;
        })->filter(fn (Order $o) => $o->pickup_km === null || $o->pickup_km <= $radius);

        $sorted = match ($sort) {
            'pay' => $orders->sortByDesc('estimated_earning'),
            'shortest' => $orders->sortBy('distance_km'),
            default => $orders->sortBy(fn (Order $o) => $o->pickup_km ?? 9999),
        };

        return $sorted->values();
    }

    public function accept(Order $order, User $rider): Order
    {
        return DB::transaction(function () use ($order, $rider) {
            // Lock so two riders tapping "Accept" at the same time can't both win.
            $order = Order::whereKey($order->id)->lockForUpdate()->firstOrFail();

            abort_unless($order->status === Order::CONFIRMED && $order->rider_id === null, 409, 'Another rider already took this delivery.');
            abort_if($this->activeFor($rider) !== null, 422, 'Finish your current delivery before taking a new one.');

            $this->assignTo($order, $rider);

            return $order->fresh(['station', 'customer', 'vehicle']);
        });
    }

    /** Rider declines a request, or hands back one they accepted but haven't collected yet. */
    public function reject(Order $order, User $rider, ?string $reason): void
    {
        DB::transaction(function () use ($order, $rider, $reason) {
            $order = Order::whereKey($order->id)->lockForUpdate()->firstOrFail();

            $open = $order->status === Order::CONFIRMED && $order->rider_id === null;
            $mine = $order->status === Order::ASSIGNED && $order->rider_id === $rider->id;
            abort_unless($open || $mine, 422, 'This request is no longer available.');

            OrderRejection::firstOrCreate(['order_id' => $order->id, 'rider_id' => $rider->id], ['reason' => $reason]);

            if ($mine) {
                $order->update(['rider_id' => null, 'status' => Order::CONFIRMED, 'assigned_at' => null, 'rider_earning' => 0]);
                $this->notifier->send($order->customer, 'truck', 'Finding another driver', "Your driver couldn’t take order {$order->number}. We’re matching you with another one.");
            }
        });
    }

    /** Admin (Filament) or dispatcher assigns a rider directly. */
    public function assign(Order $order, User $rider): Order
    {
        return DB::transaction(function () use ($order, $rider) {
            $order = Order::whereKey($order->id)->lockForUpdate()->firstOrFail();

            abort_unless(in_array($order->status, [Order::CONFIRMED, Order::ASSIGNED], true), 422, 'Only confirmed orders waiting for pickup can be assigned.');
            abort_unless($rider->role === User::ROLE_RIDER && $rider->rider?->isApproved() && $rider->isActive(), 422, 'That rider is not approved.');

            $this->assignTo($order, $rider);

            return $order->fresh(['station', 'customer', 'rider']);
        });
    }

    private function assignTo(Order $order, User $rider): void
    {
        $profile = $rider->rider;
        $pickupKm = Geo::km($profile?->current_lat, $profile?->current_lng, $order->station->lat, $order->station->lng) ?? 0.0;

        $order->update([
            'rider_id' => $rider->id,
            'status' => Order::ASSIGNED,
            'assigned_at' => now(),
            'rider_earning' => $this->pricing->riderEarning($pickupKm, (float) $order->distance_km),
        ]);

        $this->notifier->send($order->customer, 'truck', 'Driver assigned', "{$rider->name} will collect your fuel from {$order->station->name}.");
        $this->notifier->send($rider, 'truck', 'New delivery assigned', "Order {$order->number} from {$order->station->name}.");
    }

    public function pickup(Order $order, User $rider, string $code): Order
    {
        $this->assertMine($order, $rider);
        abort_unless($order->status === Order::ASSIGNED, 422, 'This order isn’t waiting for pickup.');
        abort_unless(hash_equals((string) $order->pickup_code, $code), 422, 'That pickup code isn’t correct. Check it with the station attendant.');

        $order->update(['status' => Order::PICKED_UP, 'picked_up_at' => now()]);
        $this->notifier->send($order->customer, 'truck', 'Your fuel is on the way', "{$rider->name} has collected your order and is heading to you.");

        return $order;
    }

    public function arrived(Order $order, User $rider): Order
    {
        $this->assertMine($order, $rider);
        abort_unless($order->status === Order::PICKED_UP, 422, 'Confirm fuel pickup first.');

        $order->update(['status' => Order::ARRIVED, 'arrived_at' => now()]);
        $this->notifier->send($order->customer, 'truck', 'Driver has arrived', "Meet {$rider->name} at your delivery point. Your delivery code is {$order->delivery_code}.");

        return $order;
    }

    public function deliver(Order $order, User $rider, string $code, ?string $photoPath = null): Order
    {
        return DB::transaction(function () use ($order, $rider, $code, $photoPath) {
            $order = Order::whereKey($order->id)->lockForUpdate()->firstOrFail();
            $this->assertMine($order, $rider);

            abort_unless(in_array($order->status, [Order::PICKED_UP, Order::ARRIVED], true), 422, 'This order isn’t out for delivery.');
            abort_unless(hash_equals((string) $order->delivery_code, $code), 422, 'That delivery code isn’t correct. Ask the customer for their 4-digit code.');

            $order->update([
                'status' => Order::DELIVERED,
                'delivered_at' => now(),
                'arrived_at' => $order->arrived_at ?? now(),
                'delivery_photo_path' => $photoPath,
            ]);

            // Cash on delivery: the rider collected it, so record the payment now.
            if ($order->payment_status === 'cod') {
                $this->payments->ledger($order->customer_id, Transaction::ORDER_PAYMENT, 'cash', $order->total, Transaction::SUCCESSFUL, $order);
                $order->update(['payment_status' => 'paid']);
            }

            // Rider earnings and customer rewards.
            if ($order->rider_earning > 0) {
                $this->payments->ledger($rider->id, Transaction::RIDER_EARNING, null, $order->rider_earning, Transaction::SUCCESSFUL, $order, null, "Delivery {$order->number}");
            }
            $points = (int) floor($order->total * config('fuelconnect.rewards_points_per_ugx'));
            if ($points > 0) {
                User::whereKey($order->customer_id)->increment('points', $points);
            }

            $this->notifier->send($order->customer, 'check', 'Delivery complete', "{$order->litres} litres of {$order->product_name} were delivered safely. You earned {$points} points.");
            $this->notifier->send($rider, 'check', 'Delivery completed', 'UGX '.number_format($order->rider_earning)." was added to your earnings for order {$order->number}.");

            return $order->fresh(['station', 'customer']);
        });
    }

    // ----- earnings ----------------------------------------------------------
    public function requestPayout(User $rider, int $amount, string $method, string $phone): Transaction
    {
        $min = (int) config('fuelconnect.rider_min_withdrawal');
        abort_if($amount < $min, 422, 'The minimum withdrawal is UGX '.number_format($min).'.');

        return DB::transaction(function () use ($rider, $amount, $method, $phone) {
            // Serialise payouts per rider so the balance can't be spent twice.
            User::whereKey($rider->id)->lockForUpdate()->first();
            $available = Rider::where('user_id', $rider->id)->firstOrFail()->availableBalance();
            abort_if($amount > $available, 422, 'You only have UGX '.number_format($available).' available to withdraw.');

            // Stays `pending` until an admin confirms the mobile-money transfer in Filament.
            return $this->payments->ledger($rider->id, Transaction::RIDER_PAYOUT, $method, $amount, Transaction::PENDING, null, ['phone' => $phone], 'Rider withdrawal');
        });
    }

    private function assertMine(Order $order, User $rider): void
    {
        abort_unless($order->rider_id === $rider->id, 403, 'This delivery belongs to another rider.');
    }
}
