<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    /** POST /rider/status { online: true|false } (the ONLINE chip in the app header) */
    public function status(Request $request): JsonResponse
    {
        $data = $request->validate(['online' => ['required', 'boolean']]);
        $request->user()->rider->update(['is_online' => $data['online']]);

        return response()->json(['online' => (bool) $data['online']]);
    }

    /** POST /rider/location { lat, lng }: send every ~10 s while online or on a trip. */
    public function location(Request $request): JsonResponse
    {
        $data = $request->validate(['lat' => ['required', 'numeric', 'between:-90,90'], 'lng' => ['required', 'numeric', 'between:-180,180']]);
        $request->user()->rider->update(['current_lat' => $data['lat'], 'current_lng' => $data['lng'], 'location_updated_at' => now()]);

        return response()->json(['ok' => true]);
    }
}
