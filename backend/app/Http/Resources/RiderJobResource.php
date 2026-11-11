<?php

namespace App\Http\Resources;

use App\Support\Geo;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** Rider view of an order (job card / request / active trip). @mixin \App\Models\Order */
class RiderJobResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $o = $this->resource;
        $pickupKm = $o->pickup_km ?? null;        // set by DeliveryService::availableFor
        $tripKm = (float) $o->distance_km;

        return [
            'id' => $o->id,
            'number' => $o->number,
            'status' => $o->status,
            'station' => ['id' => $o->station->id, 'name' => $o->station->name, 'address' => $o->station->address, 'lat' => $o->station->lat, 'lng' => $o->station->lng],
            'drop_off' => ['address' => $o->delivery_address, 'lat' => $o->delivery_lat, 'lng' => $o->delivery_lng, 'note' => $o->delivery_note],
            'customer' => ['name' => $o->customer->name, 'initials' => $o->customer->initials, 'rating' => 4.9],
            'product_name' => $o->product_name,
            'fuel_type' => $o->fuel_type,
            'litres' => $o->litres,
            'vehicle' => $o->vehicle ? ['name' => $o->vehicle->name, 'color' => $o->vehicle->color, 'plate' => $o->vehicle->plate] : null,
            'pickup_km' => $pickupKm,
            'trip_km' => $tripKm,
            'total_km' => round(($pickupKm ?? 0) + $tripKm, 1),
            'minutes' => Geo::minutes(($pickupKm ?? 0) + $tripKm),
            'earning' => $o->rider_earning > 0 ? $o->rider_earning : ($o->estimated_earning ?? 0),
            'payment_method' => $o->payment_method,
            'collect_cash' => $o->payment_status === 'cod' ? $o->total : 0,
            'created_at' => $o->created_at?->toIso8601String(),
        ];
    }
}
