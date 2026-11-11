<?php

namespace App\Providers;

use App\Services\Payments\PaymentGateway;
use App\Services\Payments\SandboxGateway;
use App\Services\Sms\LogSmsSender;
use App\Services\Sms\SmsSender;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Swap these for real providers (see config/fuelconnect.php).
        $this->app->bind(SmsSender::class, fn () => match (config('fuelconnect.otp.driver')) {
            default => new LogSmsSender(),
        });

        $this->app->bind(PaymentGateway::class, fn () => match (config('fuelconnect.payments.driver')) {
            default => new SandboxGateway(),
        });
    }

    public function boot(): void
    {
        RateLimiter::for('api', fn (Request $r) => Limit::perMinute(120)->by($r->user()?->id ?: $r->ip()));
        RateLimiter::for('otp', fn (Request $r) => Limit::perMinute(6)->by($r->ip()));
        RateLimiter::for('login', fn (Request $r) => Limit::perMinute(10)->by($r->ip().'|'.$r->input('phone')));
    }
}
