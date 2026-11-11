<?php

namespace App\Support;

/**
 * Ugandan phone numbers, same rules as the Flutter app's `Validators.normalizePhone`.
 * Accepts +256 700 123 456, 0700123456 or 700123456 and returns +256700123456.
 */
class Phone
{
    public static function normalize(?string $raw): ?string
    {
        if ($raw === null) {
            return null;
        }

        $d = preg_replace('/[\s\-\(\)]/', '', $raw) ?? '';
        if (str_starts_with($d, '+')) {
            $d = substr($d, 1);
        }

        if (strlen($d) === 12 && str_starts_with($d, '256')) {
            $d = substr($d, 3);
        } elseif (strlen($d) === 10 && str_starts_with($d, '0')) {
            $d = substr($d, 1);
        }

        return preg_match('/^[1-9]\d{8}$/', $d) ? '+256'.$d : null;
    }

    public static function mask(string $e164): string
    {
        return strlen($e164) < 7 ? $e164 : substr($e164, 0, 8).' ••• '.substr($e164, -3);
    }
}
