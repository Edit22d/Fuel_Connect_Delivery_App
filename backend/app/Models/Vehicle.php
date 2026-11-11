<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Vehicle extends Model
{
    protected $fillable = ['user_id', 'name', 'plate', 'fuel_type', 'color', 'tank_litres'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
