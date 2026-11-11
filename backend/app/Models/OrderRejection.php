<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderRejection extends Model
{
    protected $fillable = ['order_id', 'rider_id', 'reason'];
}
