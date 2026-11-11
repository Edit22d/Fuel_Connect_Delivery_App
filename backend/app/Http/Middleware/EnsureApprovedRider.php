<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Riders can sign in while pending, but can only work once an admin approved them. */
class EnsureApprovedRider
{
    public function handle(Request $request, Closure $next): Response
    {
        $profile = $request->user()?->rider;

        if (! $profile || ! $profile->isApproved()) {
            return response()->json(['message' => 'Your rider application is still being reviewed.', 'approval_status' => $profile?->approval_status], 403);
        }

        return $next($request);
    }
}
