<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('number', 20)->unique();                    // FC-29841
            $table->foreignId('customer_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('rider_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('station_id')->constrained()->restrictOnDelete();
            $table->foreignId('vehicle_id')->nullable()->constrained()->nullOnDelete();

            $table->string('fuel_type', 10);                           // Petrol | Diesel | Power
            $table->unsignedSmallInteger('litres');
            $table->unsignedInteger('price_per_litre');
            $table->unsignedBigInteger('fuel_total');
            $table->unsignedInteger('delivery_fee');
            $table->unsignedInteger('service_fee');
            $table->unsignedBigInteger('total');

            $table->string('delivery_address');
            $table->text('delivery_note')->nullable();
            $table->decimal('delivery_lat', 10, 7)->nullable();
            $table->decimal('delivery_lng', 10, 7)->nullable();
            $table->decimal('distance_km', 6, 2)->default(0);          // station -> customer
            $table->timestamp('scheduled_at')->nullable();

            // pending_payment | confirmed | assigned | picked_up | arrived | delivered | cancelled
            $table->string('status', 20)->default('pending_payment')->index();
            $table->string('payment_method', 20);                      // momo | airtel | card | wallet | cash
            $table->string('payment_status', 20)->default('unpaid')->index();   // unpaid | paid | refunded | cod

            $table->string('pickup_code', 6);                          // shown by the station, typed by the rider
            $table->string('delivery_code', 4);                        // shown to the customer, typed by the rider
            $table->unsignedInteger('rider_earning')->default(0);

            $table->string('cancel_reason')->nullable();
            $table->unsignedInteger('cancellation_fee')->default(0);
            $table->string('cancelled_by', 20)->nullable();            // customer | admin | system
            $table->string('delivery_photo_path')->nullable();
            $table->unsignedTinyInteger('rating')->nullable();
            $table->text('rating_comment')->nullable();

            $table->timestamp('confirmed_at')->nullable();
            $table->timestamp('assigned_at')->nullable();
            $table->timestamp('picked_up_at')->nullable();
            $table->timestamp('arrived_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'rider_id']);
        });

        // Riders who declined a request never see it again.
        Schema::create('order_rejections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('rider_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason')->nullable();
            $table->timestamps();
            $table->unique(['order_id', 'rider_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_rejections');
        Schema::dropIfExists('orders');
    }
};
