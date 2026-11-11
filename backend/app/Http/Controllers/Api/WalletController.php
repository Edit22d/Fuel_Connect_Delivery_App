<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Services\PaymentService;
use App\Support\Phone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function __construct(private PaymentService $payments)
    {
    }

    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json(['data' => [
            'balance' => $user->wallet_balance,
            'points' => $user->points,
            'recent' => $this->present($user->transactions()->whereIn('type', [Transaction::ORDER_PAYMENT, Transaction::WALLET_TOPUP, Transaction::REFUND])->latest('id')->limit(5)->get()),
        ]]);
    }

    /** GET /wallet/transactions: paginated history. */
    public function history(Request $request): JsonResponse
    {
        $page = $request->user()->transactions()->whereIn('type', [Transaction::ORDER_PAYMENT, Transaction::WALLET_TOPUP, Transaction::REFUND])
            ->latest('id')->paginate(30);

        return response()->json(['data' => $this->present($page->items()), 'meta' => ['current_page' => $page->currentPage(), 'last_page' => $page->lastPage()]]);
    }

    public function topUp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'amount' => ['required', 'integer', 'min:5000', 'max:5000000'],
            'method' => ['required', 'in:momo,airtel,card'],
            'phone' => ['required_if:method,momo,airtel', 'nullable', 'string'],
        ]);

        $phone = isset($data['phone']) ? Phone::normalize($data['phone']) : null;
        abort_if(in_array($data['method'], ['momo', 'airtel'], true) && ! $phone, 422, 'Enter a valid mobile money number.');

        $tx = $this->payments->topUp($request->user(), $data['amount'], $data['method'], $phone);

        return response()->json([
            'data' => ['transaction' => $this->present([$tx])[0], 'balance' => $request->user()->fresh()->wallet_balance],
            'message' => $tx->status === Transaction::SUCCESSFUL ? 'Wallet topped up.' : 'Approve the payment on your phone to finish topping up.',
        ], 201);
    }

    private function present(iterable $txs): array
    {
        $out = [];
        foreach ($txs as $t) {
            $out[] = [
                'id' => $t->id,
                'reference' => $t->reference,
                'type' => $t->type,
                'title' => match ($t->type) {
                    Transaction::WALLET_TOPUP => 'Wallet top up',
                    Transaction::REFUND => 'Refund',
                    default => 'Fuel order',
                },
                'subtitle' => $t->description,
                'amount' => $t->direction() * $t->amount,      // signed, as in the app's wallet list
                'method' => $t->method,
                'status' => $t->status,
                'created_at' => $t->created_at?->toIso8601String(),
            ];
        }

        return $out;
    }
}
