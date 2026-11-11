<?php

namespace App\Services;

use App\Models\Station;
use App\Support\Geo;

class PricingService
{
    /** Price breakdown for a prospective order (mirrors the Flutter checkout summary). */
    public function quote(Station $station, string $fuelType, int $litres, ?float $lat = null, ?float $lng = null): array
    {
        $perLitre = $station->priceFor($fuelType);
        abort_if($perLitre <= 0, 422, "{$fuelType} isn’t available at {$station->name} right now.");

        $fuelTotal = $perLitre * $litres;
        $delivery = (int) config('fuelconnect.delivery_fee');
        $service = (int) config('fuelconnect.service_fee');
        $distance = Geo::km($station->lat, $station->lng, $lat, $lng) ?? 4.0;

        return [
            'fuel_type' => $fuelType,
            'litres' => $litres,
            'price_per_litre' => $perLitre,
            'fuel_total' => $fuelTotal,
            'delivery_fee' => $delivery,
            'service_fee' => $service,
            'total' => $fuelTotal + $delivery + $service,
            'distance_km' => $distance,
            'eta_minutes' => Geo::minutes($distance) + 10,   // +10 min station handling
            'currency' => 'UGX',
        ];
    }

    /** Rider pay for a trip: base + per-km for pickup leg and trip leg, rounded to the nearest UGX 500. */
    public function riderEarning(float $pickupKm, float $tripKm): int
    {
        $raw = config('fuelconnect.rider_base_pay') + config('fuelconnect.rider_per_km') * ($pickupKm + $tripKm);

        return (int) (round($raw / 500) * 500);
    }
}
