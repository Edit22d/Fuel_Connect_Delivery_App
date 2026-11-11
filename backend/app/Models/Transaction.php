<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class Transaction extends Model
{
    // types
    public const ORDER_PAYMENT = 'order_payment';
    public const WALLET_TOPUP = 'wallet_topup';
    public const REFUND = 'refund';
    public const RIDER_EARNING = 'rider_earning';
    public const RIDER_PAYOUT = 'rider_payout';

    // statuses
    public const PENDING = 'pending';
    public const SUCCESSFUL = 'successful';
    public const FAILED = 'failed';

    protected $fillable = [
        'reference', 'user_id', 'order_id', 'type', 'method', 'amount', 'status',
        'provider_reference', 'description', 'meta',
    ];

    protected function casts(): array
    {
        return ['amount' => 'integer', 'meta' => 'array'];
    }

    public static function newReference(): string
    {
        return 'TX-'.strtoupper(Str::random(10));
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /** +1 = money in for the user's wallet/earnings, -1 = money out. */
    public function direction(): int
    {
        return in_array($this->type, [self::WALLET_TOPUP, self::REFUND, self::RIDER_EARNING], true) ? 1 : -1;
    }
}
