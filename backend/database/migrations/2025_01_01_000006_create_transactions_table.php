<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // The single money ledger: order payments, wallet top-ups, refunds, rider earnings and payouts.
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 40)->unique();                 // TX-XXXXXXXXXX
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->foreignId('order_id')->nullable()->constrained()->nullOnDelete();
            // order_payment | wallet_topup | refund | rider_earning | rider_payout
            $table->string('type', 20)->index();
            // momo | airtel | card | wallet | cash | bank
            $table->string('method', 20)->nullable()->index();
            $table->bigInteger('amount');                              // UGX, positive; direction comes from `type`
            // pending | successful | failed
            $table->string('status', 20)->default('pending')->index();
            $table->string('provider_reference')->nullable();
            $table->string('description')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
