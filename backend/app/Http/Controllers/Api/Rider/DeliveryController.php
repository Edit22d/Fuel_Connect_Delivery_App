<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Http\Resources\RiderJobResource;
use App\Models\Order;
use App\Models\Transaction;
use App\Services\DeliveryService;
use App\Support\Geo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/** Everything on the rider dashboard → request → accept → pickup → navigate → delivery path. */
class DeliveryController extends Controller
{
    public function __construct(private DeliveryService $deliveries)
    {
    }

    /** GET /rider/dashboard */
    public function dashboard(Request $request): JsonResponse
    {
        $user = $request->user();
        $profile = $user->rider;

        $todayStart = now()->startOfDay();
        $earnedToday = (int) Transaction::where('user_id', $user->id)->where('type', Transaction::RIDER_EARNING)
            ->where('status', Transaction::SUCCESSFUL)->where('created_at', '>=', $todayStart)->sum('amount');
        $deliveredToday = Order::where('rider_id', $user->id)->where('status', Order::DELIVERED)->where('delivered_at', '>=', $todayStart)->count();
        $rating = Order::where('rider_id', $user->id)->whereNotNull('rating')->avg('rating');

        $available = $profile->is_online ? $this->deliveries->availableFor($user) : collect();
        $active = $this->deliveries->activeFor($user);

        return response()->json(['data' => [
            'rider' => ['name' => $user->name, 'initials' => $user->initials, 'is_online' => $profile->is_online],
            'today' => ['earnings' => $earnedToday, 'deliveries' => $deliveredToday, 'rating' => round((float) ($rating ?? 5), 1)],
            'available_count' => $available->count(),
            'available_preview' => $available->take(1)->map(fn ($o) => (new RiderJobResource($o))->resolve())->values(),
            'active_trip' => $active ? (new RiderJobResource($active))->resolve() : null,
        ]]);
    }

    /** GET /rider/deliveries?sort=nearest|pay|shortest */
    public function available(Request $request): JsonResponse
    {
        $request->validate(['sort' => ['nullable', 'in:nearest,pay,shortest']]);
        $user = $request->user();

        $jobs = $user->rider->is_online ? $this->deliveries->availableFor($user, $request->query('sort', 'nearest')) : collect();

        return response()->json([
            'data' => RiderJobResource::collection($jobs)->resolve(),
            'online' => $user->rider->is_online,
        ]);
    }

    public function active(Request $request): JsonResponse
    {
        $active = $this->deliveries->activeFor($request->user());

        return response()->json(['data' => $active ? (new RiderJobResource($active))->resolve() : null]);
    }

    public function show(Request $request, Order $order): RiderJobResource
    {
        $user = $request->user();
        $open = $order->status === Order::CONFIRMED && $order->rider_id === null;
        abort_unless($open || $order->rider_id === $user->id, 404);

        $order->load(['station', 'customer', 'vehicle']);
        $profile = $user->rider;
        $order->pickup_km = Geo::km($profile->current_lat, $profile->current_lng, $order->station->lat, $order->station->lng);

        return new RiderJobResource($order);
    }

    public function accept(Request $request, Order $order): JsonResponse
    {
        $order = $this->deliveries->accept($order, $request->user());

        return response()->json(['data' => (new RiderJobResource($order))->resolve(), 'message' => 'Delivery accepted. Head to the station to collect the fuel.']);
    }

    public function reject(Request $request, Order $order): JsonResponse
    {
        $data = $request->validate(['reason' => ['nullable', 'string', 'max:255']]);
        $this->deliveries->reject($order, $request->user(), $data['reason'] ?? null);

        return response()->json(['message' => 'Request rejected.']);
    }

    public function pickup(Request $request, Order $order): JsonResponse
    {
        $data = $request->validate(['code' => ['required', 'string', 'size:6']]);
        $order = $this->deliveries->pickup($order, $request->user(), $data['code']);

        return response()->json(['data' => ['status' => $order->status], 'message' => 'Pickup confirmed. Navigate to the customer.']);
    }

    public function arrived(Request $request, Order $order): JsonResponse
    {
        $order = $this->deliveries->arrived($order, $request->user());

        return response()->json(['data' => ['status' => $order->status]]);
    }

    /** POST /rider/deliveries/{order}/deliver (multipart: code + photo) */
    public function deliver(Request $request, Order $order): JsonResponse
    {
        $data = $request->validate([
            'code' => ['required', 'string', 'size:4'],
            'photo' => ['required', 'image', 'max:5120'],
        ]);

        $path = $request->file('photo')->store("delivery-proof/{$order->id}", 'local');
        try {
            $order = $this->deliveries->deliver($order, $request->user(), $data['code'], $path);
        } catch (\Throwable $e) {
            Storage::disk('local')->delete($path);   // wrong code etc.: don't keep the orphaned photo
            throw $e;
        }

        return response()->json([
            'data' => ['status' => $order->status, 'earning' => $order->rider_earning, 'order' => $order->number],
            'message' => 'Delivery completed.',
        ]);
    }
}
