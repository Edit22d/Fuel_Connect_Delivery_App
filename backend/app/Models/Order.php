<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    public const PENDING_PAYMENT = 'pending_payment';
    public const CONFIRMED = 'confirmed';      // paid / COD, waiting for a rider
    public const ASSIGNED = 'assigned';        // a rider accepted
    public const PICKED_UP = 'picked_up';      // rider collected the fuel, on the way
    public const ARRIVED = 'arrived';
    public const DELIVERED = 'delivered';
    public const CANCELLED = 'cancelled';

    public const OPEN_STATUSES = [self::PENDING_PAYMENT, self::CONFIRMED, self::ASSIGNED, self::PICKED_UP, self::ARRIVED];

    public const STATUS_LABELS = [
        self::PENDING_PAYMENT => 'Pending payment',
        self::CONFIRMED => 'Confirmed',
        self::ASSIGNED => 'Rider assigned',
        self::PICKED_UP => 'On the way',
        self::ARRIVED => 'Arrived',
        self::DELIVERED => 'Delivered',
        self::CANCELLED => 'Cancelled',
    ];

    protected $fillable = [
        'number', 'customer_id', 'rider_id', 'station_id', 'vehicle_id', 'fuel_type', 'litres', 'price_per_litre',
        'fuel_total', 'delivery_fee', 'service_fee', 'total', 'delivery_address', 'delivery_note', 'delivery_lat',
        'delivery_lng', 'distance_km', 'scheduled_at', 'status', 'payment_method', 'payment_status', 'pickup_code',
        'delivery_code', 'rider_earning', 'cancel_reason', 'cancellation_fee', 'cancelled_by', 'delivery_photo_path',
        'rating', 'rating_comment', 'confirmed_at', 'assigned_at', 'picked_up_at', 'arrived_at', 'delivered_at',
        'cancelled_at',
    ];

    // NOTE: pickup_code / delivery_code are only ever exposed through the API Resource
    // classes (customer sees delivery_code, rider sees neither). Never return an Order directly.

    protected function casts(): array
    {
        return [
            'litres' => 'integer',
            'total' => 'integer',
            'fuel_total' => 'integer',
            'delivery_lat' => 'float',
            'delivery_lng' => 'float',
            'distance_km' => 'float',
            'scheduled_at' => 'datetime',
            'confirmed_at' => 'datetime',
            'assigned_at' => 'datetime',
            'picked_up_at' => 'datetime',
            'arrived_at' => 'datetime',
            'delivered_at' => 'datetime',
            'cancelled_at' => 'datetime',
        ];
    }

    public static function newNumber(): string
    {
        do {
            $number = 'FC-'.random_int(10000, 99999);
        } while (static::where('number', $number)->exists());

        return $number;
    }

    // ----- relations ---------------------------------------------------------
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function rider(): BelongsTo
    {
        return $this->belongsTo(User::class, 'rider_id');
    }

    public function station(): BelongsTo
    {
        return $this->belongsTo(Station::class);
    }

    public function vehicle(): BelongsTo
    {
        return $this->belongsTo(Vehicle::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    // ----- helpers -----------------------------------------------------------
    public function scopeOpen(Builder $q): Builder
    {
        return $q->whereIn('status', self::OPEN_STATUSES);
    }

    public function isOpen(): bool
    {
        return in_array($this->status, self::OPEN_STATUSES, true);
    }

    /** The rider already collected the fuel, so cancelling now costs a fee. */
    public function fuelCollected(): bool
    {
        return in_array($this->status, [self::PICKED_UP, self::ARRIVED], true);
    }

    public function getProductNameAttribute(): string
    {
        return match ($this->fuel_type) {
            'Petrol' => 'Premium petrol',
            'Diesel' => 'Ultra diesel',
            default => 'Power',
        };
    }

    public function getStatusLabelAttribute(): string
    {
        return self::STATUS_LABELS[$this->status] ?? ucfirst($this->status);
    }
}
