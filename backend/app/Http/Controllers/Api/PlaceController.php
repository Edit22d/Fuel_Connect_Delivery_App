<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SavedPlace;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlaceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->savedPlaces()->orderBy('id')->get()]);
    }

    public function store(Request $request): JsonResponse
    {
        $place = $request->user()->savedPlaces()->create($this->validated($request));

        return response()->json(['data' => $place], 201);
    }

    public function update(Request $request, SavedPlace $place): JsonResponse
    {
        abort_unless($place->user_id === $request->user()->id, 404);
        $place->update($this->validated($request));

        return response()->json(['data' => $place->fresh()]);
    }

    public function destroy(Request $request, SavedPlace $place): JsonResponse
    {
        abort_unless($place->user_id === $request->user()->id, 404);
        $place->delete();

        return response()->json(['message' => 'Place removed.']);
    }

    private function validated(Request $request): array
    {
        return $request->validate([
            'label' => ['required', 'string', 'max:40'],
            'address' => ['required', 'string', 'max:255'],
            'lat' => ['nullable', 'numeric', 'between:-90,90'],
            'lng' => ['nullable', 'numeric', 'between:-180,180'],
        ]);
    }
}
