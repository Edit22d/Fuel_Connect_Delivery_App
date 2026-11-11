<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\StationResource;
use App\Models\Station;
use App\Support\Geo;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class StationController extends Controller
{
    /** GET /stations?lat=&lng=&q=&brand=&sort=distance|price|rating */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['lat' => ['nullable', 'numeric'], 'lng' => ['nullable', 'numeric']]);

        $stations = Station::where('is_active', true)
            ->when($request->query('q'), fn ($q, $term) => $q->where(fn ($w) => $w->where('name', 'like', "%{$term}%")->orWhere('brand', 'like', "%{$term}%")))
            ->when($request->query('brand'), fn ($q, $brand) => $q->where('brand', strtoupper($brand)))
            ->get();

        $lat = $request->query('lat') !== null ? (float) $request->query('lat') : null;
        $lng = $request->query('lng') !== null ? (float) $request->query('lng') : null;

        $sorted = match ($request->query('sort')) {
            'price' => $stations->sortBy('price_petrol'),
            'rating' => $stations->sortByDesc('rating'),
            default => $stations->sortBy(fn (Station $s) => Geo::km($lat, $lng, $s->lat, $s->lng) ?? 9999),
        };

        return StationResource::collection($sorted->values());
    }

    public function show(Station $station): StationResource
    {
        abort_unless($station->is_active, 404);

        return new StationResource($station);
    }
}
