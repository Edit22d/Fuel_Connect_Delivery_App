<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Rider extends Model
{
    public const PENDING = 'pending';
    public const APPROVED = 'approved';
    public const REJECTED = 'rejected';

    protected $fillable = [
        'user_id', 'national_id', 'vehicle_type', 'vehicle_registration', 'permit_number', 'documents',
        'approval_status', 'rejection_reason', 'approved_at', 'is_online', 'current_lat', 'current_lng',
        'location_updated_at',
    ];

    protected function casts(): array
    {
        return [
            'documents' => 'array',
            'is_online' => 'boolean',
            'approved_at' => 'datetime',
            'location_updated_at' => 'datetime',
            'current_lat' => 'float',
            'current_lng' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isApproved(): bool
    {
        return $this->approval_status === self::APPROVED;
    }

    public function scopeApproved(Builder $q): Builder
    {
        return $q->where('approval_status', self::APPROVED);
    }

    public function scopeOnline(Builder $q): Builder
    {
        return $q->where('is_online', true);
    }

    /** Earnings minus payouts that are pending or already paid. */
    public function availableBalance(): int
    {
        $earned = Transaction::where('user_id', $this->user_id)
            ->where('type', Transaction::RIDER_EARNING)->where('status', Transaction::SUCCESSFUL)->sum('amount');
        $paidOut = Transaction::where('user_id', $this->user_id)
            ->where('type', Transaction::RIDER_PAYOUT)->whereIn('status', [Transaction::PENDING, Transaction::SUCCESSFUL])->sum('amount');

        return max(0, (int) ($earned - $paidOut));
    }
}
