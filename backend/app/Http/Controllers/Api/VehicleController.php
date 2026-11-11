<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vehicle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class VehicleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->vehicles()->orderBy('id')->get()]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validated($request);
        $vehicle = $request->user()->vehicles()->create($data);

        return response()->json(['data' => $vehicle], 201);
    }

    public function update(Request $request, Vehicle $vehicle): JsonResponse
    {
        abort_unless($vehicle->user_id === $request->user()->id, 404);
        $vehicle->update($this->validated($request, $vehicle));

        return response()->json(['data' => $vehicle->fresh()]);
    }

    public function destroy(Request $request, Vehicle $vehicle): JsonResponse
    {
        abort_unless($vehicle->user_id === $request->user()->id, 404);
        $vehicle->delete();

        return response()->json(['message' => 'Vehicle removed.']);
    }

    private function validated(Request $request, ?Vehicle $vehicle = null): array
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:80'],
            'plate' => ['required', 'string', 'max:15', Rule::unique('vehicles')->where('user_id', $request->user()->id)->ignore($vehicle?->id)],
            'fuel_type' => ['required', 'in:Petrol,Diesel'],
            'color' => ['nullable', 'string', 'max:30'],
            'tank_litres' => ['nullable', 'integer', 'min:10', 'max:500'],
        ]);
        $data['plate'] = strtoupper(trim($data['plate']));

        return $data;
    }
}
