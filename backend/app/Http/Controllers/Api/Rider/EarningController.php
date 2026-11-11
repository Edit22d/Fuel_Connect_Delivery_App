<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Services\DeliveryService;
use App\Support\Phone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EarningController extends Controller
{
    public function __construct(private DeliveryService $deliveries)
    {
    }

    /** GET /rider/earnings: hero balance, week stats, 7-day chart and recent list. */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $weekStart = now()->startOfWeek();           // Monday

        $earnings = Transaction::where('user_id', $user->id)->where('type', Transaction::RIDER_EARNING)
            ->where('status', Transaction::SUCCESSFUL)->where('created_at', '>=', $weekStart)->get();

        $perDay = array_fill(0, 7, 0);
        foreach ($earnings as $t) {
            $perDay[$t->created_at->dayOfWeekIso - 1] += $t->amount;
        }
        $max = max($perDay) ?: 1;
        $weekTotal = array_sum($perDay);
        $trips = $earnings->count();

        $recent = Transaction::with('order.station')->where('user_id', $user->id)->where('type', Transaction::RIDER_EARNING)
            ->latest('id')->limit(10)->get()->map(fn ($t) => [
                'station' => $t->order?->station?->name ?? 'Delivery',
                'order' => $t->order?->number,
                'amount' => $t->amount,
                'created_at' => $t->created_at->toIso8601String(),
            ]);

        return response()->json(['data' => [
            'available' => $user->rider->availableBalance(),
            'week_total' => $weekTotal,
            'week_trips' => $trips,
            'avg_per_trip' => $trips ? (int) round($weekTotal / $trips) : 0,
            'week_bars' => array_map(fn ($v) => (int) round($v / $max * 100), $perDay),   // Mon..Sun, percent of best day
            'recent' => $recent,
        ]]);
    }

    /** POST /rider/withdraw { amount, method: momo|airtel, phone } */
    public function withdraw(Request $request): JsonResponse
    {
        $data = $request->validate([
            'amount' => ['required', 'integer', 'min:1'],
            'method' => ['required', 'in:momo,airtel'],
            'phone' => ['required', 'string'],
        ]);
        $phone = Phone::normalize($data['phone']);
        abort_unless($phone, 422, 'Enter a valid mobile money number.');

        $tx = $this->deliveries->requestPayout($request->user(), $data['amount'], $data['method'], $phone);

        return response()->json([
            'data' => ['reference' => $tx->reference, 'amount' => $tx->amount, 'status' => $tx->status, 'available' => $request->user()->rider->availableBalance()],
            'message' => 'Withdrawal requested. It will reach your mobile money shortly.',
        ], 201);
    }
}
