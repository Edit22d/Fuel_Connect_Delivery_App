<?php

namespace App\Http\Resources;

use App\Support\Geo;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Station */
class StationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $lat = $request->query('lat') !== null ? (float) $request->query('lat') : null;
        $lng = $request->query('lng') !== null ? (float) $request->query('lng') : null;
        $km = Geo::km($lat, $lng, $this->lat, $this->lng);

        return [
            'id' => $this->id,
            'name' => $this->name,
            'brand' => $this->brand,
            'address' => $this->address,
            'lat' => $this->lat,
            'lng' => $this->lng,
            'rating' => $this->rating,
            'image_url' => $this->image_path ? asset('storage/'.$this->image_path) : null,
            'prices' => ['Petrol' => $this->price_petrol, 'Diesel' => $this->price_diesel, 'Power' => $this->price_power],
            'distance_km' => $km,
            'eta_minutes' => $km !== null ? Geo::minutes($km) + 10 : null,
        ];
    }
}
