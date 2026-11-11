<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Usage: ->middleware('role:customer') or 'role:rider'. Also blocks suspended accounts. */
class EnsureRole
{
    public function handle(Request $request, Closure $next, string $role): Response
    {
        $user = $request->user();

        if (! $user || $user->role !== $role) {
            return response()->json(['message' => 'This area is for '.$role.' accounts.'], 403);
        }
        if (! $user->isActive()) {
            return response()->json(['message' => 'Your account has been suspended. Please contact FuelConnect support.'], 403);
        }

        return $next($request);
    }
}
