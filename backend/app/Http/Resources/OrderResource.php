<?php

namespace App\Http\Resources;

use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** Customer view of an order. @mixin \App\Models\Order */
class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $o = $this->resource;
        $showCode = $o->isOpen() && in_array($o->payment_status, ['paid', 'cod'], true);

        return [
            'id' => $o->id,
            'number' => $o->number,
            'status' => $o->status,
            'status_label' => $o->status_label,
            'fuel_type' => $o->fuel_type,
            'product_name' => $o->product_name,
            'litres' => $o->litres,
            'price_per_litre' => $o->price_per_litre,
            'fuel_total' => $o->fuel_total,
            'delivery_fee' => $o->delivery_fee,
            'service_fee' => $o->service_fee,
            'total' => $o->total,
            'payment_method' => $o->payment_method,
            'payment_status' => $o->payment_status,
            'delivery_address' => $o->delivery_address,
            'delivery_note' => $o->delivery_note,
            'scheduled_at' => $o->scheduled_at?->toIso8601String(),
            'station' => $this->whenLoaded('station', fn () => ['id' => $o->station->id, 'name' => $o->station->name, 'brand' => $o->station->brand]),
            'vehicle' => $this->whenLoaded('vehicle', fn () => $o->vehicle ? ['id' => $o->vehicle->id, 'name' => $o->vehicle->name, 'plate' => $o->vehicle->plate] : null),
            // The customer tells this 4-digit code to the rider on arrival.
            'delivery_code' => $showCode ? $o->delivery_code : null,
            'cancellation_fee' => $o->cancellation_fee,
            'cancel_reason' => $o->cancel_reason,
            'refund_amount' => $o->status === Order::CANCELLED && $o->payment_status === 'refunded' ? $o->total - $o->cancellation_fee : 0,
            'rating' => $o->rating,
            'created_at' => $o->created_at?->toIso8601String(),
            'delivered_at' => $o->delivered_at?->toIso8601String(),
            'cancelled_at' => $o->cancelled_at?->toIso8601String(),
        ];
    }
}
