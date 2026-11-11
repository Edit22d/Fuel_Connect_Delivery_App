<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Rider;
use App\Models\User;
use App\Support\Phone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

/** Rider registration (3 steps in the app, one request here) and sign in. */
class RiderAuthController extends Controller
{
    private const DOCS = ['national_id', 'permit', 'logbook', 'photo'];

    public function register(Request $request): JsonResponse
    {
        $rules = [
            'name' => ['required', 'string', 'min:2', 'max:100'],
            'phone' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'regex:/[A-Za-z]/', 'regex:/\d/'],
            'national_id' => ['required', 'string', 'regex:/^[A-Za-z0-9]{14}$/'],
            'vehicle_type' => ['required', 'string', 'min:3', 'max:60'],
            'vehicle_registration' => ['required', 'string', 'regex:/^[A-Za-z]{3}\s?\d{3}[A-Za-z]$/'],
            'permit_number' => ['required', 'string', 'min:5', 'max:40'],
        ];
        foreach (self::DOCS as $doc) {
            $rules["documents.$doc"] = ['required', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'];
        }
        $data = $request->validate($rules, [
            'national_id.regex' => 'Enter your 14-character National ID number.',
            'vehicle_registration.regex' => 'Enter a valid plate, e.g. UBX 123A.',
        ]);

        $phone = Phone::normalize($data['phone']);
        abort_unless($phone, 422, 'Enter a valid Ugandan phone number, e.g. +256 700 123 456.');
        abort_if(User::where('phone', $phone)->exists(), 422, 'An account with this phone number already exists.');

        DB::transaction(function () use ($data, $phone, $request) {
            $user = User::create(['name' => trim($data['name']), 'phone' => $phone, 'password' => $data['password'], 'role' => User::ROLE_RIDER]);

            $paths = [];
            foreach (self::DOCS as $doc) {
                // Private disk: documents are never publicly reachable, admins view them via Filament.
                $paths[$doc] = $request->file("documents.$doc")->store("rider-documents/{$user->id}", 'local');
            }

            Rider::create([
                'user_id' => $user->id,
                'national_id' => strtoupper($data['national_id']),
                'vehicle_type' => $data['vehicle_type'],
                'vehicle_registration' => strtoupper(preg_replace('/\s+/', ' ', trim($data['vehicle_registration']))),
                'permit_number' => $data['permit_number'],
                'documents' => $paths,
            ]);
        });

        return response()->json(['message' => 'Application submitted. We’ll notify you once your documents are approved.'], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate(['phone' => ['required', 'string'], 'password' => ['required', 'string']]);
        $phone = Phone::normalize($data['phone']);
        $user = $phone ? User::with('rider')->where('phone', $phone)->first() : null;

        if (! $user || $user->role !== User::ROLE_RIDER || ! Hash::check($data['password'], $user->password)) {
            abort(422, 'Incorrect phone number or password.');
        }
        abort_unless($user->isActive(), 403, 'Your account has been suspended. Please contact FuelConnect support.');

        $status = $user->rider?->approval_status;
        if ($status === Rider::PENDING) {
            abort(403, 'Your application is still being reviewed. We’ll notify you as soon as it’s approved.');
        }
        if ($status === Rider::REJECTED) {
            abort(403, 'Your application wasn’t approved'.($user->rider->rejection_reason ? ': '.$user->rider->rejection_reason : '.').' Contact support for help.');
        }

        return response()->json([
            'token' => $user->createToken('rider')->plainTextToken,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
        ]);
    }
}
