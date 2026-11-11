<?php

namespace App\Filament\Resources\RiderResource\Pages;

use App\Filament\Resources\RiderResource;
use App\Models\Rider;
use App\Support\Phone;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class EditRider extends EditRecord
{
    protected static string $resource = RiderResource::class;

    protected function getHeaderActions(): array
    {
        return [Actions\DeleteAction::make()];
    }

    protected function mutateFormDataBeforeFill(array $data): array
    {
        $user = $this->record->user;
        $data['name'] = $user->name;
        $data['phone'] = $user->phone;
        $data['user_status'] = $user->status;

        return $data;
    }

    protected function handleRecordUpdate(Model $record, array $data): Model
    {
        /** @var Rider $record */
        $phone = Phone::normalize($data['phone']);
        if (! $phone) {
            throw ValidationException::withMessages(['data.phone' => 'Enter a valid Ugandan phone number.']);
        }

        return DB::transaction(function () use ($record, $data, $phone) {
            $user = array_filter(['name' => $data['name'], 'phone' => $phone, 'status' => $data['user_status'], 'password' => $data['password'] ?? null], fn ($v) => $v !== null);
            $record->user->update($user);
            if (($user['status'] ?? 'active') === 'suspended') {
                $record->user->tokens()->delete();
            }

            $profile = Arr::only($data, ['national_id', 'permit_number', 'vehicle_type', 'vehicle_registration', 'approval_status', 'rejection_reason', 'is_online']);
            if (($profile['approval_status'] ?? null) === Rider::APPROVED && ! $record->approved_at) {
                $profile['approved_at'] = now();
            }
            $record->update($profile);

            return $record;
        });
    }
}
