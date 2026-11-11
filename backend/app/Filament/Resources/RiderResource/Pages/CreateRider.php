<?php

namespace App\Filament\Resources\RiderResource\Pages;

use App\Filament\Resources\RiderResource;
use App\Models\Rider;
use App\Models\User;
use App\Support\Phone;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class CreateRider extends CreateRecord
{
    protected static string $resource = RiderResource::class;

    /** A rider is a User (role=rider) plus a Rider profile. */
    protected function handleRecordCreation(array $data): Model
    {
        $phone = Phone::normalize($data['phone']);
        if (! $phone || User::where('phone', $phone)->exists()) {
            throw ValidationException::withMessages(['data.phone' => $phone ? 'That phone number is already registered.' : 'Enter a valid Ugandan phone number.']);
        }

        return DB::transaction(function () use ($data, $phone) {
            $user = User::create([
                'name' => $data['name'], 'phone' => $phone, 'password' => $data['password'],
                'role' => User::ROLE_RIDER, 'status' => $data['user_status'] ?? 'active',
            ]);

            $profile = Arr::only($data, ['national_id', 'permit_number', 'vehicle_type', 'vehicle_registration', 'approval_status', 'rejection_reason', 'is_online']);
            if (($profile['approval_status'] ?? null) === Rider::APPROVED) {
                $profile['approved_at'] = now();
            }

            return $user->rider()->create($profile);
        });
    }
}
