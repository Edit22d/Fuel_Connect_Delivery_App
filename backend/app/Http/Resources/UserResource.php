<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\User */
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'initials' => $this->initials,
            'phone' => $this->phone,
            'email' => $this->email,
            'role' => $this->role,
            'status' => $this->status,
            'emergency_contact' => $this->emergency_contact,
            'wallet_balance' => $this->wallet_balance,
            'points' => $this->points,
            'phone_verified' => $this->phone_verified_at !== null,
            'rider' => $this->when($this->role === 'rider' && $this->relationLoaded('rider') && $this->rider, fn () => [
                'approval_status' => $this->rider->approval_status,
                'rejection_reason' => $this->rider->rejection_reason,
                'is_online' => $this->rider->is_online,
                'vehicle_type' => $this->rider->vehicle_type,
                'vehicle_registration' => $this->rider->vehicle_registration,
            ]),
        ];
    }
}
