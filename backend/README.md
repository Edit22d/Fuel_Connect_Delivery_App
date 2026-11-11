# FuelConnect backend — Laravel 11 API + Filament admin

```
Flutter app (customer + rider)  ──►  Laravel REST API (/api/v1, Sanctum tokens)  ──►  MySQL / PostgreSQL
                                          ▲
                              Filament admin panel (/admin)
```

## Run it

Requires PHP 8.2+, Composer, and MySQL or PostgreSQL.

```bash
cd backend
composer install
cp .env.example .env          # then set DB_* (MySQL is the default, PostgreSQL block is in the file)
php artisan key:generate
php artisan migrate --seed    # schema + demo data
php artisan storage:link      # station photos
php artisan serve             # http://localhost:8000
```

| | URL | Login |
|---|---|---|
| Admin panel | http://localhost:8000/admin | `admin@fuelconnect.test` / `Admin@2025` |
| API | http://localhost:8000/api/v1 | see below |

Demo accounts (same as the Flutter app): customer `+256 700 123 456` / `Fuel@2025`,
rider `+256 701 234 567` / `Rider@2025`. A second rider (`+256 702 345 678`) is
**pending**, so you can try approving them in Filament.

For an Android emulator the API base URL is `http://10.0.2.2:8000/api/v1`.

> **Development switches** (`.env`): `FC_OTP_SHOW_CODE=true` returns the verification code in
> the API response (the app shows it in a toast in demo mode). `FC_PAYMENT_DRIVER=sandbox`
> approves every mobile-money/card payment instantly. **Turn both off / replace them in production.**

## What's in the box

**Database** (`database/migrations`): `users` (customers, riders, admins by `role`), `riders`,
`stations`, `vehicles`, `saved_places`, `orders`, `order_rejections`, `transactions` (one money
ledger: payments, top-ups, refunds, rider earnings, payouts), `otp_codes`, `app_notices`.
All money is whole UGX integers.

**API** (`routes/api.php`, full list in [`docs/API.md`](docs/API.md)): auth + OTP, stations, vehicles,
saved places, quote → order → pay → track → cancel → rate, wallet, notifications, and the complete
rider flow (register, login, online toggle, available deliveries, accept/reject, pickup, arrived,
deliver, earnings, withdraw).

**Delivery logic** (`app/Services`):
- `PricingService` — fuel + delivery fee + service fee; rider pay = base + per-km, rounded to UGX 500.
- `OrderService` — create/pay/confirm/cancel/rate. Cancelling after the rider collected the fuel costs
  the cancellation fee (UGX 8,000, as in the app); paid orders are refunded automatically.
- `DeliveryService` — what a rider can see (radius, not-rejected, due), race-safe **accept** (row lock,
  one active job per rider), pickup with the station's 6-digit code, delivery with the customer's 4-digit
  code + photo, earnings credit, customer reward points, rider payouts.
- `PaymentService` + `PaymentGateway` interface — wallet and cash handled internally; mobile money/card
  go through a gateway. Only a **sandbox** gateway is included; add MTN MoMo / Airtel / Flutterwave by
  implementing `App\Services\Payments\PaymentGateway` and binding it in `AppServiceProvider`.
  Provider callbacks hit `POST /api/v1/payments/webhook/{provider}` (secret header).

**Filament admin** (`app/Filament`):
| Module | Does |
|---|---|
| Dashboard | Total revenue, total orders, active riders, pending deliveries, orders & revenue charts, latest orders |
| Customers | View/edit, suspend/reactivate, see each customer's orders |
| Riders | Register riders, approve/reject applications (with documents), suspend, monitor activity |
| Orders | View all, assign a rider, update status, cancel (auto-refund) |
| Fuel stations | Manage stations and per-litre prices |
| Payments | All transactions; filter by MoMo / Airtel / card / cash / wallet; refund records; mark refunds & payouts paid |

Rider documents and delivery photos are stored on the **private** disk and only streamed to signed-in admins.

## Security notes
- Sanctum bearer tokens; suspended users are blocked and their tokens revoked.
- OTP codes are hashed, expire in 2 minutes, max 5 attempts; rate limits on auth routes.
- Pickup/delivery codes are never exposed to the wrong party (riders never see them; customers only see the delivery code).
- Orders are only ever read by their owner (customer), their rider, or an admin.

## Not done / next steps
- Real SMS provider (`App\Services\Sms\SmsSender`), real payment gateway, FCM push notifications.
- Flutter app is still mocked; point `AuthService` / `RiderState` at this API.
- Automated tests.
