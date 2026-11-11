<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Models\Station;
use App\Services\OrderService;
use App\Services\PaymentService;
use App\Services\PricingService;
use App\Support\Geo;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class OrderController extends Controller
{
    private const STEPS = ['Order confirmed', 'Fuel collected', 'Arriving at your location', 'Delivery complete'];

    public function __construct(private OrderService $orders, private PricingService $pricing)
    {
    }

    /** POST /orders/quote: price breakdown for the checkout screen. */
    public function quote(Request $request): JsonResponse
    {
        $data = $request->validate([
            'station_id' => ['required', 'integer', 'exists:stations,id'],
            'fuel_type' => ['required', 'in:Petrol,Diesel,Power'],
            'litres' => ['required', 'integer', 'min:'.config('fuelconnect.min_litres'), 'max:'.config('fuelconnect.max_litres')],
            'delivery_lat' => ['nullable', 'numeric'],
            'delivery_lng' => ['nullable', 'numeric'],
        ]);

        $quote = $this->pricing->quote(Station::findOrFail($data['station_id']), $data['fuel_type'], $data['litres'], $data['delivery_lat'] ?? null, $data['delivery_lng'] ?? null);

        return response()->json(['data' => $quote]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            'station_id' => ['required', 'integer', 'exists:stations,id'],
            'fuel_type' => ['required', 'in:Petrol,Diesel,Power'],
            'litres' => ['required', 'integer', 'min:'.config('fuelconnect.min_litres'), 'max:'.config('fuelconnect.max_litres')],
            'vehicle_id' => ['nullable', 'integer', Rule::exists('vehicles', 'id')->where('user_id', $user->id)],
            'payment_method' => ['required', Rule::in(PaymentService::METHODS)],
            'phone' => ['required_if:payment_method,momo,airtel', 'nullable', 'string'],
            'delivery_address' => ['required', 'string', 'max:255'],
            'delivery_note' => ['nullable', 'string', 'max:500'],
            'delivery_lat' => ['nullable', 'numeric', 'between:-90,90'],
            'delivery_lng' => ['nullable', 'numeric', 'between:-180,180'],
            'scheduled_at' => ['nullable', 'date', 'after:now'],
        ]);

        // Vehicle compatibility: diesel can't go into a petrol car (Power is a petrol grade).
        if (! empty($data['vehicle_id'])) {
            $vehicle = $user->vehicles()->findOrFail($data['vehicle_id']);
            $needs = $data['fuel_type'] === 'Diesel' ? 'Diesel' : 'Petrol';
            abort_if($vehicle->fuel_type !== $needs, 422, "{$vehicle->name} runs on {$vehicle->fuel_type}. Please choose a matching fuel.");
        }

        abort_if(
            $user->orders()->where('status', Order::PENDING_PAYMENT)->where('created_at', '>', now()->subMinutes(10))->count() >= 3,
            429, 'You have several unpaid orders. Finish or wait before placing another.'
        );

        $order = $this->orders->create($user, $data);

        return response()->json(['data' => new OrderResource($order), 'message' => $order->status === Order::PENDING_PAYMENT
            ? 'Approve the payment on your phone to confirm your order.'
            : 'Your order is confirmed.'], 201);
    }

    /** GET /orders?scope=active|history */
    public function index(Request $request): AnonymousResourceCollection
    {
        $orders = $request->user()->orders()->with(['station', 'vehicle'])
            ->when($request->query('scope') === 'active', fn ($q) => $q->open())
            ->when($request->query('scope') === 'history', fn ($q) => $q->whereIn('status', [Order::DELIVERED, Order::CANCELLED]))
            ->latest('id')->paginate(20);

        return OrderResource::collection($orders);
    }

    public function show(Request $request, Order $order): OrderResource
    {
        return new OrderResource($this->mine($request, $order)->load(['station', 'vehicle']));
    }

    /** GET /orders/{id}/cancel-preview: what the cancel screen shows before confirming. */
    public function cancelPreview(Request $request, Order $order): JsonResponse
    {
        $order = $this->mine($request, $order);
        $fee = $this->orders->cancellationFee($order);

        return response()->json(['data' => [
            'amount_paid' => $order->payment_status === 'paid' ? $order->total : 0,
            'cancellation_fee' => $fee,
            'refund_amount' => $order->payment_status === 'paid' ? $order->total - $fee : 0,
            'refund_method' => $order->payment_method,
            'fuel_collected' => $order->fuelCollected(),
        ]]);
    }

    public function cancel(Request $request, Order $order): JsonResponse
    {
        $data = $request->validate(['reason' => ['required', 'string', 'max:255']]);
        $cancelled = $this->orders->cancel($this->mine($request, $order), $data['reason'], 'customer');

        return response()->json(['data' => new OrderResource($cancelled)]);
    }

    public function rate(Request $request, Order $order): JsonResponse
    {
        $data = $request->validate(['rating' => ['required', 'integer', 'between:1,5'], 'comment' => ['nullable', 'string', 'max:500']]);
        $rated = $this->orders->rate($this->mine($request, $order), $data['rating'], $data['comment'] ?? null);

        return response()->json(['data' => new OrderResource($rated->load(['station', 'vehicle']))]);
    }

    /** GET /orders/{id}/tracking: poll every few seconds from the live tracking screen. */
    public function tracking(Request $request, Order $order): JsonResponse
    {
        $order = $this->mine($request, $order)->load(['station', 'rider.rider']);

        $step = match ($order->status) {
            Order::PENDING_PAYMENT, Order::CONFIRMED => 0,
            Order::ASSIGNED => 0,
            Order::PICKED_UP => 1,
            Order::ARRIVED => 2,
            default => 3,
        };

        $rider = $order->rider;
        $loc = $rider?->rider;
        $km = $loc ? Geo::km($loc->current_lat, $loc->current_lng, $order->delivery_lat, $order->delivery_lng) : null;
        $rating = $rider ? Order::where('rider_id', $rider->id)->whereNotNull('rating')->avg('rating') : null;

        return response()->json(['data' => [
            'status' => $order->status,
            'status_label' => $order->status_label,
            'step' => $step,
            'steps' => self::STEPS,
            'eta_minutes' => $order->status === Order::ARRIVED ? 0 : ($km !== null ? Geo::minutes($km) : null),
            'rider' => $rider ? [
                'name' => $rider->name,
                'initials' => $rider->initials,
                'rating' => round((float) ($rating ?? 5), 1),
                'phone' => in_array($order->status, [Order::ASSIGNED, Order::PICKED_UP, Order::ARRIVED], true) ? $rider->phone : null,
                'lat' => $loc?->current_lat,
                'lng' => $loc?->current_lng,
                'location_updated_at' => $loc?->location_updated_at?->toIso8601String(),
            ] : null,
            'delivery' => ['address' => $order->delivery_address, 'lat' => $order->delivery_lat, 'lng' => $order->delivery_lng],
        ]]);
    }

    private function mine(Request $request, Order $order): Order
    {
        abort_unless($order->customer_id === $request->user()->id, 404);

        return $order;
    }
}
