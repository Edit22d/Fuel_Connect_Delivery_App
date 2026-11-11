<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Rider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/** Streams private uploads (rider documents, delivery photos) to signed-in admins only. */
class AdminFileController extends Controller
{
    public function riderDocument(Request $request, Rider $rider, string $doc): StreamedResponse
    {
        $this->authorizeAdmin($request);
        $path = $rider->documents[$doc] ?? null;
        abort_unless($path && Storage::disk('local')->exists($path), 404);

        return Storage::disk('local')->response($path);
    }

    public function deliveryProof(Request $request, Order $order): StreamedResponse
    {
        $this->authorizeAdmin($request);
        abort_unless($order->delivery_photo_path && Storage::disk('local')->exists($order->delivery_photo_path), 404);

        return Storage::disk('local')->response($order->delivery_photo_path);
    }

    private function authorizeAdmin(Request $request): void
    {
        $user = $request->user();
        abort_unless($user && $user->role === 'admin' && $user->isActive(), 403);
    }
}
