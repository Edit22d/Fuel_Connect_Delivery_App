<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('riders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('national_id', 20);
            $table->string('vehicle_type');
            $table->string('vehicle_registration', 15);
            $table->string('permit_number', 40);
            $table->json('documents')->nullable();                     // {national_id: path, permit: path, logbook: path, photo: path}
            $table->string('approval_status', 20)->default('pending')->index();  // pending | approved | rejected
            $table->text('rejection_reason')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->boolean('is_online')->default(false)->index();
            $table->decimal('current_lat', 10, 7)->nullable();
            $table->decimal('current_lng', 10, 7)->nullable();
            $table->timestamp('location_updated_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('riders');
    }
};
