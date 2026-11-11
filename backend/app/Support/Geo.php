<?php

namespace App\Support;

class Geo
{
    /** Great-circle distance in kilometres. */
    public static function km(?float $lat1, ?float $lng1, ?float $lat2, ?float $lng2): ?float
    {
        if ($lat1 === null || $lng1 === null || $lat2 === null || $lng2 === null) {
            return null;
        }

        $r = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return round($r * 2 * atan2(sqrt($a), sqrt(1 - $a)), 2);
    }

    /** Minutes to cover $km at the configured average city speed (minimum 1). */
    public static function minutes(float $km): int
    {
        return max(1, (int) round($km / config('fuelconnect.average_speed_kmh', 28) * 60));
    }
}
