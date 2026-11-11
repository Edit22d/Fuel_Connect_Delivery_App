<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // One table for customers, riders and admins, told apart by `role`.
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone', 20)->unique();          // E.164, e.g. +256700123456
            $table->string('email')->nullable()->unique();
            $table->string('password');
            $table->string('role', 20)->default('customer')->index();   // customer | rider | admin
            $table->string('status', 20)->default('active')->index();   // active | suspended
            $table->string('emergency_contact', 20)->nullable();
            $table->string('avatar_path')->nullable();
            $table->unsignedBigInteger('wallet_balance')->default(0);   // UGX
            $table->unsignedInteger('points')->default(0);
            $table->timestamp('phone_verified_at')->nullable();
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
    }
};
