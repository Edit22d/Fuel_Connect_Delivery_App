<?php

namespace App\Services;

use App\Models\AppNotice;
use App\Models\User;

/** Writes to the in-app notification centre (the bell screen in the Flutter app). */
class Notifier
{
    public function send(?User $user, string $icon, string $title, string $body): void
    {
        if ($user === null) {
            return;
        }

        AppNotice::create(['user_id' => $user->id, 'icon' => $icon, 'title' => $title, 'body' => $body]);
        // Push notifications (FCM) can be dispatched from here later.
    }
}
