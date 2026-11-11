<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\NoticeController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PaymentWebhookController;
use App\Http\Controllers\Api\PlaceController;
use App\Http\Controllers\Api\Rider\DeliveryController;
use App\Http\Controllers\Api\Rider\EarningController;
use App\Http\Controllers\Api\Rider\ProfileController as RiderProfileController;
use App\Http\Controllers\Api\RiderAuthController;
use App\Http\Controllers\Api\StationController;
use App\Http\Controllers\Api\VehicleController;
use App\Http\Controllers\Api\WalletController;
use Illuminate\Support\Facades\Route;

/*
| All routes live under /api/v1. Auth is a Sanctum bearer token:
|   Authorization: Bearer <token>
*/
Route::prefix('v1')->middleware('throttle:api')->group(function () {

    Route::get('health', fn () => response()->json(['status' => 'ok', 'time' => now()->toIso8601String()]));

    // ---- Public: customer auth --------------------------------------------------
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register'])->middleware('throttle:otp');
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:login');
        Route::post('otp/send', [AuthController::class, 'sendOtp'])->middleware('throttle:otp');
        Route::post('otp/verify', [AuthController::class, 'verifyOtp'])->middleware('throttle:login');
        Route::post('forgot', [AuthController::class, 'forgot'])->middleware('throttle:otp');
        Route::post('reset', [AuthController::class, 'reset'])->middleware('throttle:login');
    });

    // ---- Public: rider auth ------------------------------------------------------
    Route::post('rider/register', [RiderAuthController::class, 'register'])->middleware('throttle:otp');
    Route::post('rider/login', [RiderAuthController::class, 'login'])->middleware('throttle:login');

    // ---- Public: payment provider callbacks (secret header) ------------------------
    Route::post('payments/webhook/{provider}', [PaymentWebhookController::class, 'handle']);

    // ---- Signed in (any role) ----------------------------------------------------
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);
        Route::put('me', [AuthController::class, 'updateMe']);

        Route::get('notifications', [NoticeController::class, 'index']);
        Route::post('notifications/read-all', [NoticeController::class, 'readAll']);
        Route::post('notifications/{notice}/read', [NoticeController::class, 'markRead']);

        // ---- Customer app ----------------------------------------------------------
        Route::middleware('role:customer')->group(function () {
            Route::get('stations', [StationController::class, 'index']);
            Route::get('stations/{station}', [StationController::class, 'show']);

            Route::apiResource('vehicles', VehicleController::class)->except('show');
            Route::apiResource('places', PlaceController::class)->except('show');

            Route::post('orders/quote', [OrderController::class, 'quote']);
            Route::get('orders', [OrderController::class, 'index']);
            Route::post('orders', [OrderController::class, 'store']);
            Route::get('orders/{order}', [OrderController::class, 'show']);
            Route::get('orders/{order}/tracking', [OrderController::class, 'tracking']);
            Route::get('orders/{order}/cancel-preview', [OrderController::class, 'cancelPreview']);
            Route::post('orders/{order}/cancel', [OrderController::class, 'cancel']);
            Route::post('orders/{order}/rate', [OrderController::class, 'rate']);

            Route::get('wallet', [WalletController::class, 'show']);
            Route::get('wallet/transactions', [WalletController::class, 'history']);
            Route::post('wallet/topup', [WalletController::class, 'topUp']);
        });

        // ---- Rider app ---------------------------------------------------------------
        Route::prefix('rider')->middleware(['role:rider', 'rider.approved'])->group(function () {
            Route::post('status', [RiderProfileController::class, 'status']);
            Route::post('location', [RiderProfileController::class, 'location']);

            Route::get('dashboard', [DeliveryController::class, 'dashboard']);
            Route::get('deliveries', [DeliveryController::class, 'available']);
            Route::get('deliveries/active', [DeliveryController::class, 'active']);
            Route::get('deliveries/{order}', [DeliveryController::class, 'show']);
            Route::post('deliveries/{order}/accept', [DeliveryController::class, 'accept']);
            Route::post('deliveries/{order}/reject', [DeliveryController::class, 'reject']);
            Route::post('deliveries/{order}/pickup', [DeliveryController::class, 'pickup']);
            Route::post('deliveries/{order}/arrived', [DeliveryController::class, 'arrived']);
            Route::post('deliveries/{order}/deliver', [DeliveryController::class, 'deliver']);

            Route::get('earnings', [EarningController::class, 'summary']);
            Route::post('withdraw', [EarningController::class, 'withdraw']);
        });
    });
});
