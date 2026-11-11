<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Pricing (all amounts in whole Ugandan shillings)
    |--------------------------------------------------------------------------
    */
    'delivery_fee' => (int) env('FC_DELIVERY_FEE', 8000),
    'service_fee' => (int) env('FC_SERVICE_FEE', 2500),
    'cancellation_fee' => (int) env('FC_CANCELLATION_FEE', 8000),
    'min_litres' => 5,
    'max_litres' => 200,

    /*
    |--------------------------------------------------------------------------
    | Rider pay: base + per km (pickup leg + trip leg), rounded to nearest 500
    |--------------------------------------------------------------------------
    */
    'rider_base_pay' => (int) env('FC_RIDER_BASE_PAY', 8000),
    'rider_per_km' => (int) env('FC_RIDER_PER_KM', 1650),
    'rider_min_withdrawal' => (int) env('FC_RIDER_MIN_WITHDRAWAL', 10000),

    /*
    |--------------------------------------------------------------------------
    | Dispatch
    |--------------------------------------------------------------------------
    | Riders only see requests within this radius of their last known location.
    */
    'dispatch_radius_km' => (float) env('FC_DISPATCH_RADIUS_KM', 15),
    'average_speed_kmh' => 28,

    /*
    |--------------------------------------------------------------------------
    | Verification codes (OTP)
    |--------------------------------------------------------------------------
    | `show_code` returns the code in the API response while developing, the
    | same way the Flutter app shows it in a toast in demo mode. NEVER enable
    | it in production. `driver` = log | (add your SMS provider in App\Services\Sms).
    */
    'otp' => [
        'length' => 6,
        'ttl_minutes' => 2,
        'max_attempts' => 5,
        'resend_after_seconds' => 30,
        'on_login' => (bool) env('FC_OTP_ON_LOGIN', true),
        'show_code' => (bool) env('FC_OTP_SHOW_CODE', false),
        'driver' => env('FC_SMS_DRIVER', 'log'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Payments
    |--------------------------------------------------------------------------
    | `sandbox` approves every mobile-money / card payment instantly so the app
    | can be developed end to end. Add real gateways (MTN MoMo, Airtel Money,
    | Flutterwave, Pesapal...) by implementing App\Services\Payments\PaymentGateway.
    */
    'payments' => [
        'driver' => env('FC_PAYMENT_DRIVER', 'sandbox'),
        'webhook_secret' => env('FC_PAYMENT_WEBHOOK_SECRET'),
    ],

    'rewards_points_per_ugx' => 1 / 1000,
];
