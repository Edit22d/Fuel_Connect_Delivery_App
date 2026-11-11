<?php

namespace Database\Seeders;

use App\Models\Order;
use App\Models\Rider;
use App\Models\Station;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Demo data that mirrors the Flutter prototype (Joel Kato, Marcus K., Stabex Kira Road…).
 * Coordinates are approximate. Run:  php artisan migrate:fresh --seed
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ---- People ---------------------------------------------------------------
        User::create([
            'name' => 'FuelConnect Admin', 'phone' => '+256700000000', 'email' => 'admin@fuelconnect.test',
            'password' => 'Admin@2025', 'role' => User::ROLE_ADMIN, 'phone_verified_at' => now(),
        ]);

        $joel = User::create([
            'name' => 'Joel Kato', 'phone' => '+256700123456', 'email' => 'joel.kato@email.com',
            'password' => 'Fuel@2025', 'wallet_balance' => 480000, 'points' => 2450, 'phone_verified_at' => now(),
        ]);
        $joel->vehicles()->createMany([
            ['name' => 'Toyota RAV4', 'plate' => 'UBP 482M', 'fuel_type' => 'Petrol', 'color' => 'Black', 'tank_litres' => 60],
            ['name' => 'Toyota Hilux', 'plate' => 'UBN 117Q', 'fuel_type' => 'Diesel', 'color' => 'Silver', 'tank_litres' => 80],
        ]);
        $joel->savedPlaces()->createMany([
            ['label' => 'Home', 'address' => 'Plot 18, Kira Road, Bukoto', 'lat' => 0.3500, 'lng' => 32.6020],
            ['label' => 'Office', 'address' => 'Rwenzori Towers, Nakasero', 'lat' => 0.3170, 'lng' => 32.5790],
            ['label' => 'Gym', 'address' => 'Acacia Mall, Kisementi', 'lat' => 0.3365, 'lng' => 32.5870],
        ]);

        $aisha = User::create(['name' => 'Aisha Nabirye', 'phone' => '+256703456789', 'email' => 'aisha@email.com', 'password' => 'Fuel@2025', 'phone_verified_at' => now()]);
        $david = User::create(['name' => 'David Ssemwogerere', 'phone' => '+256704567890', 'password' => 'Fuel@2025', 'phone_verified_at' => now()]);

        $marcus = User::create(['name' => 'Marcus Kiggundu', 'phone' => '+256701234567', 'password' => 'Rider@2025', 'role' => User::ROLE_RIDER, 'phone_verified_at' => now()]);
        $marcus->rider()->create([
            'national_id' => 'CM90012345678A', 'vehicle_type' => 'Fuel delivery truck', 'vehicle_registration' => 'UBX 123A',
            'permit_number' => 'DP-4482910', 'approval_status' => Rider::APPROVED, 'approved_at' => now()->subMonths(2),
            'is_online' => true, 'current_lat' => 0.3476, 'current_lng' => 32.5825, 'location_updated_at' => now(),
        ]);

        $peter = User::create(['name' => 'Peter Okello', 'phone' => '+256702345678', 'password' => 'Rider@2025', 'role' => User::ROLE_RIDER]);
        $peter->rider()->create([
            'national_id' => 'CM88077654321B', 'vehicle_type' => 'Motorbike tanker', 'vehicle_registration' => 'UEA 551K',
            'permit_number' => 'DP-7731208', 'approval_status' => Rider::PENDING,
        ]);

        // ---- Stations ----------------------------------------------------------------
        $stabex = Station::create(['name' => 'Stabex Kira Road', 'brand' => 'STABEX', 'address' => 'Kira Road, Kamwokya', 'lat' => 0.3445, 'lng' => 32.5990, 'rating' => 4.9, 'price_petrol' => 5180, 'price_diesel' => 4960, 'price_power' => 6450, 'image_path' => null]);
        $shell = Station::create(['name' => 'Shell Lugogo', 'brand' => 'SHELL', 'address' => 'Lugogo Bypass, Kampala', 'lat' => 0.3270, 'lng' => 32.6010, 'rating' => 4.8, 'price_petrol' => 5240, 'price_diesel' => 5480, 'price_power' => 6520]);
        $rubis = Station::create(['name' => 'Rubis Bukoto', 'brand' => 'RUBIS', 'address' => 'Bukoto Street, Kampala', 'lat' => 0.3500, 'lng' => 32.6050, 'rating' => 4.8, 'price_petrol' => 5160, 'price_diesel' => 4940, 'price_power' => 6400]);
        Station::create(['name' => 'TotalEnergies Ntinda', 'brand' => 'TOTALENERGIES', 'address' => 'Ntinda Road, Kampala', 'lat' => 0.3720, 'lng' => 32.6160, 'rating' => 4.7, 'price_petrol' => 5200, 'price_diesel' => 4990, 'price_power' => 6480]);
        Station::create(['name' => 'City Oil Kisementi', 'brand' => 'CITY OIL', 'address' => 'Kisementi, Kololo', 'lat' => 0.3380, 'lng' => 32.5890, 'rating' => 4.6, 'price_petrol' => 5190, 'price_diesel' => 4970, 'price_power' => 0]);

        // ---- History: delivered orders over the last 14 days (feeds the dashboard charts) ----
        $customers = [$joel, $aisha, $david];
        $stations = [$stabex, $shell, $rubis];
        $methods = ['momo', 'airtel', 'card', 'wallet', 'cash'];
        mt_srand(42);
        for ($i = 0; $i < 22; $i++) {
            $when = now()->subDays(mt_rand(0, 13))->setTime(mt_rand(7, 19), mt_rand(0, 59));
            $customer = $customers[$i % 3];
            $station = $stations[$i % 3];
            $fuel = $i % 4 === 0 ? 'Diesel' : 'Petrol';
            $order = $this->makeOrder($customer, $station, $fuel, mt_rand(15, 50), $methods[$i % 5], 'delivered', $when, $marcus, mt_rand(0, 4) ? 5 : 4);
            $this->ledger($order, $marcus);
        }

        // ---- Live work: requests the rider can take right now ----------------------------
        $this->makeOrder($joel, $stabex, 'Petrol', 35, 'momo', 'confirmed', now()->subMinutes(4), null, null, 'Acacia Mall, Kisementi', 0.3365, 32.5870);
        $this->makeOrder($aisha, $shell, 'Diesel', 28, 'wallet', 'confirmed', now()->subMinutes(9), null, null, 'Naguru Hill Road, Naguru', 0.3405, 32.6100);
        $this->makeOrder($david, $rubis, 'Petrol', 22, 'cash', 'confirmed', now()->subMinutes(14), null, null, 'Ntinda Shopping Centre, Ntinda', 0.3640, 32.6150);

        // ---- A cancelled order with a pending refund (shows in Payments → Refund records) ----
        $cancelled = $this->makeOrder($aisha, $stabex, 'Petrol', 20, 'momo', 'cancelled', now()->subDay(), null, null);
        $cancelled->update(['payment_status' => 'refunded', 'cancel_reason' => 'I changed my mind', 'cancelled_by' => 'customer', 'cancelled_at' => now()->subDay()]);
        Transaction::create(['reference' => Transaction::newReference(), 'user_id' => $aisha->id, 'order_id' => $cancelled->id, 'type' => Transaction::REFUND, 'method' => 'momo', 'amount' => $cancelled->total, 'status' => Transaction::PENDING, 'description' => "Refund for order {$cancelled->number}"]);

        // ---- Notifications for the demo customer ---------------------------------------------
        $joel->notices()->createMany([
            ['icon' => 'fuel', 'title' => 'Prices dropped near you', 'body' => 'Petrol is now UGX 5,180/L at Stabex Kira Road.'],
            ['icon' => 'shield', 'title' => 'Safety check complete', 'body' => 'Your delivery partner has passed the pre-trip safety check.', 'read_at' => now()],
        ]);
    }

    private function makeOrder(User $customer, Station $station, string $fuel, int $litres, string $method, string $status, $when, ?User $rider, ?int $rating, string $address = 'Acacia Mall, Kisementi', float $lat = 0.3365, float $lng = 32.5870): Order
    {
        $price = $station->priceFor($fuel);
        $fuelTotal = $price * $litres;
        $fee = (int) config('fuelconnect.delivery_fee');
        $service = (int) config('fuelconnect.service_fee');
        $delivered = $status === 'delivered';

        // unguarded: lets us back-date created_at/updated_at for the demo history
        return Order::unguarded(fn () => Order::create([
            'number' => Order::newNumber(),
            'customer_id' => $customer->id,
            'rider_id' => $rider?->id,
            'station_id' => $station->id,
            'vehicle_id' => $customer->vehicles()->where('fuel_type', $fuel === 'Diesel' ? 'Diesel' : 'Petrol')->value('id'),
            'fuel_type' => $fuel,
            'litres' => $litres,
            'price_per_litre' => $price,
            'fuel_total' => $fuelTotal,
            'delivery_fee' => $fee,
            'service_fee' => $service,
            'total' => $fuelTotal + $fee + $service,
            'delivery_address' => $address,
            'delivery_lat' => $lat,
            'delivery_lng' => $lng,
            'distance_km' => 4.6,
            'status' => $status,
            'payment_method' => $method,
            'payment_status' => $method === 'cash' && ! $delivered ? 'cod' : 'paid',
            'pickup_code' => str_pad((string) mt_rand(0, 999999), 6, '0', STR_PAD_LEFT),
            'delivery_code' => str_pad((string) mt_rand(0, 9999), 4, '0', STR_PAD_LEFT),
            'rider_earning' => $rider ? 18500 : 0,
            'rating' => $rating,
            'confirmed_at' => $when,
            'assigned_at' => $rider ? $when : null,
            'picked_up_at' => $delivered ? $when->copy()->addMinutes(12) : null,
            'delivered_at' => $delivered ? $when->copy()->addMinutes(35) : null,
            'created_at' => $when,
            'updated_at' => $when,
        ]));
    }

    private function ledger(Order $order, User $rider): void
    {
        $at = $order->delivered_at;
        Transaction::insert([
            ['reference' => Transaction::newReference(), 'user_id' => $order->customer_id, 'order_id' => $order->id, 'type' => Transaction::ORDER_PAYMENT, 'method' => $order->payment_method, 'amount' => $order->total, 'status' => Transaction::SUCCESSFUL, 'description' => "Order {$order->number}", 'created_at' => $order->created_at, 'updated_at' => $order->created_at],
            ['reference' => Transaction::newReference(), 'user_id' => $rider->id, 'order_id' => $order->id, 'type' => Transaction::RIDER_EARNING, 'method' => null, 'amount' => $order->rider_earning, 'status' => Transaction::SUCCESSFUL, 'description' => "Delivery {$order->number}", 'created_at' => $at, 'updated_at' => $at],
        ]);
    }
}
