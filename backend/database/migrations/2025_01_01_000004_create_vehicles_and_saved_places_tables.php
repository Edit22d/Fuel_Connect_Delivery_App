<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');                                    // Toyota RAV4
            $table->string('plate', 15);
            $table->string('fuel_type', 10);                           // Petrol | Diesel
            $table->string('color', 30)->nullable();
            $table->unsignedSmallInteger('tank_litres')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'plate']);
        });

        Schema::create('saved_places', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('label', 40);                               // Home, Office, Gym
            $table->string('address');
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('saved_places');
        Schema::dropIfExists('vehicles');
    }
};
