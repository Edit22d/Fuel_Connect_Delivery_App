<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stations', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('brand', 40)->index();                      // STABEX, SHELL, RUBIS...
            $table->string('address');
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->string('image_path')->nullable();
            $table->decimal('rating', 2, 1)->default(4.5);
            $table->unsignedInteger('price_petrol')->default(0);       // UGX per litre
            $table->unsignedInteger('price_diesel')->default(0);
            $table->unsignedInteger('price_power')->default(0);
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stations');
    }
};
