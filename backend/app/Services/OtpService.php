<?php

namespace App\Services;

use App\Models\OtpCode;
use App\Services\Sms\SmsSender;
use Illuminate\Support\Facades\Hash;

class OtpService
{
    public function __construct(private SmsSender $sms)
    {
    }

    /**
     * Sends a fresh code. Returns ['expires_in' => seconds, 'resend_in' => seconds, 'code' => ?string].
     * `code` is only present when FC_OTP_SHOW_CODE=true (development).
     */
    public function send(string $phone, string $purpose): array
    {
        $cfg = config('fuelconnect.otp');

        $last = OtpCode::where('phone', $phone)->where('purpose', $purpose)->latest('id')->first();
        if ($last && $last->created_at->diffInSeconds(now()) < $cfg['resend_after_seconds']) {
            $wait = (int) ceil($cfg['resend_after_seconds'] - $last->created_at->diffInSeconds(now()));
            abort(429, "Please wait {$wait} seconds before requesting another code.");
        }

        OtpCode::where('phone', $phone)->where('purpose', $purpose)->whereNull('consumed_at')
            ->update(['consumed_at' => now()]);

        $code = '';
        for ($i = 0; $i < $cfg['length']; $i++) {
            $code .= random_int(0, 9);
        }

        OtpCode::create([
            'phone' => $phone,
            'purpose' => $purpose,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes($cfg['ttl_minutes']),
        ]);

        $this->sms->send($phone, "Your FuelConnect verification code is {$code}. It expires in {$cfg['ttl_minutes']} minutes. Never share it.");

        return array_filter([
            'expires_in' => $cfg['ttl_minutes'] * 60,
            'resend_in' => $cfg['resend_after_seconds'],
            'code' => $cfg['show_code'] ? $code : null,
        ], fn ($v) => $v !== null);
    }

    /** Aborts with a friendly 422 unless the code is right; the code is single use. */
    public function verify(string $phone, string $purpose, string $code): void
    {
        $max = config('fuelconnect.otp.max_attempts');
        $otp = OtpCode::where('phone', $phone)->where('purpose', $purpose)->whereNull('consumed_at')->latest('id')->first();

        if (! $otp) {
            abort(422, 'Request a new code to continue.');
        }
        if ($otp->expires_at->isPast()) {
            abort(422, 'This code has expired. Send a new one.');
        }
        if ($otp->attempts >= $max) {
            abort(422, 'Too many attempts. Send a new code.');
        }

        if (! Hash::check($code, $otp->code_hash)) {
            $otp->increment('attempts');
            $left = $max - $otp->attempts;
            abort(422, $left > 0
                ? "That code isn’t correct. {$left} ".($left === 1 ? 'attempt' : 'attempts').' left.'
                : 'Too many attempts. Send a new code.');
        }

        $otp->update(['consumed_at' => now()]);
    }
}
