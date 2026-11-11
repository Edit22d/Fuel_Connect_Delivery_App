<?php

namespace App\Models;

use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements FilamentUser
{
    use HasApiTokens;

    public const ROLE_CUSTOMER = 'customer';
    public const ROLE_RIDER = 'rider';
    public const ROLE_ADMIN = 'admin';

    protected $fillable = [
        'name', 'phone', 'email', 'password', 'role', 'status', 'emergency_contact',
        'avatar_path', 'wallet_balance', 'points', 'phone_verified_at',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'phone_verified_at' => 'datetime',
            'wallet_balance' => 'integer',
            'points' => 'integer',
        ];
    }

    /** Only active admins may open the Filament panel. */
    public function canAccessPanel(Panel $panel): bool
    {
        return $this->role === self::ROLE_ADMIN && $this->status === 'active';
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function getInitialsAttribute(): string
    {
        $parts = preg_split('/\s+/', trim($this->name), -1, PREG_SPLIT_NO_EMPTY) ?: [];
        if (count($parts) === 0) {
            return '?';
        }
        if (count($parts) === 1) {
            return mb_strtoupper(mb_substr($parts[0], 0, 1));
        }

        return mb_strtoupper(mb_substr($parts[0], 0, 1).mb_substr(end($parts), 0, 1));
    }

    // ----- scopes ------------------------------------------------------------
    public function scopeCustomers(Builder $q): Builder
    {
        return $q->where('role', self::ROLE_CUSTOMER);
    }

    public function scopeRiders(Builder $q): Builder
    {
        return $q->where('role', self::ROLE_RIDER);
    }

    // ----- relations ---------------------------------------------------------
    public function rider(): HasOne
    {
        return $this->hasOne(Rider::class);
    }

    /** Orders this user placed as a customer. */
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'customer_id');
    }

    /** Orders this user delivers as a rider. */
    public function deliveries(): HasMany
    {
        return $this->hasMany(Order::class, 'rider_id');
    }

    public function vehicles(): HasMany
    {
        return $this->hasMany(Vehicle::class);
    }

    public function savedPlaces(): HasMany
    {
        return $this->hasMany(SavedPlace::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    public function notices(): HasMany
    {
        return $this->hasMany(AppNotice::class);
    }
}
