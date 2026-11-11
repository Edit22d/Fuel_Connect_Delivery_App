<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Station extends Model
{
    protected $fillable = [
        'name', 'brand', 'address', 'lat', 'lng', 'image_path', 'rating',
        'price_petrol', 'price_diesel', 'price_power', 'is_active',
    ];

    protected function casts(): array
    {
        return [
            'lat' => 'float',
            'lng' => 'float',
            'rating' => 'float',
            'is_active' => 'boolean',
        ];
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function priceFor(string $fuelType): int
    {
        return (int) match (strtolower($fuelType)) {
            'petrol' => $this->price_petrol,
            'diesel' => $this->price_diesel,
            'power' => $this->price_power,
            default => 0,
        };
    }
}
