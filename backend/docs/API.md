# FuelConnect API v1

Base URL `/api/v1` · JSON · `Authorization: Bearer <token>` for protected routes.
Errors are `{ "message": "..." }` with 401 / 403 / 404 / 409 / 422 / 429. Validation errors add `errors: {field: [..]}`.

## Customer auth
| Method | Path | Body | Notes |
|---|---|---|---|
| POST | `/auth/register` | `name, phone, email?, password` | Sends OTP (`purpose=signup`) |
| POST | `/auth/login` | `phone, password` | `{otp_required:true}`, or a token if `FC_OTP_ON_LOGIN=false` |
| POST | `/auth/otp/send` | `phone, purpose` | resend (30 s cooldown) |
| POST | `/auth/otp/verify` | `phone, purpose, code` | signup/login → `{token, user}`; reset → `{reset_token}` |
| POST | `/auth/forgot` | `phone` | Sends OTP (`reset`) |
| POST | `/auth/reset` | `phone, reset_token, password, password_confirmation` | revokes all tokens |
| POST | `/auth/logout` · GET `/me` · PUT `/me` | `name?, email?, emergency_contact?` | Edit profile screen |

## Customer app (role: customer)
| Screen | Endpoint |
|---|---|
| Partner stations / Station | `GET /stations?lat&lng&q&brand&sort` · `GET /stations/{id}` |
| My vehicles | `GET/POST /vehicles` · `PUT/DELETE /vehicles/{id}` |
| Saved places | `GET/POST /places` · `PUT/DELETE /places/{id}` |
| Delivery summary | `POST /orders/quote` `{station_id, fuel_type, litres, delivery_lat?, delivery_lng?}` |
| Payment → Order confirmed | `POST /orders` `{station_id, fuel_type, litres, vehicle_id?, payment_method: momo\|airtel\|card\|wallet\|cash, phone?, delivery_address, delivery_note?, delivery_lat?, delivery_lng?, scheduled_at?}` |
| Orders / Order details | `GET /orders?scope=active\|history` · `GET /orders/{id}` |
| Live tracking | `GET /orders/{id}/tracking` (poll every 3–5 s) |
| Cancel order | `GET /orders/{id}/cancel-preview` then `POST /orders/{id}/cancel` `{reason}` |
| Delivery complete | `POST /orders/{id}/rate` `{rating 1-5, comment?}` |
| Wallet | `GET /wallet` · `GET /wallet/transactions` · `POST /wallet/topup` `{amount, method, phone?}` |
| Notifications | `GET /notifications` · `POST /notifications/{id}/read` · `POST /notifications/read-all` |

`status` values: `pending_payment → confirmed → assigned → picked_up → arrived → delivered` (or `cancelled`).
`pending_payment` means a mobile-money prompt is waiting; poll `GET /orders/{id}` until it becomes `confirmed`.

## Rider
| Screen | Endpoint |
|---|---|
| Rider registration | `POST /rider/register` (multipart) `name, phone, password, national_id, vehicle_type, vehicle_registration, permit_number, documents[national_id\|permit\|logbook\|photo]` (files) |
| Rider login | `POST /rider/login` `{phone, password}` → 403 with a clear message while pending/rejected |

Below needs a rider token **and** an approved application:
| Screen | Endpoint |
|---|---|
| ONLINE chip | `POST /rider/status` `{online}` · `POST /rider/location` `{lat,lng}` (every ~10 s) |
| Rider dashboard | `GET /rider/dashboard` |
| Available deliveries | `GET /rider/deliveries?sort=nearest\|pay\|shortest` |
| Delivery request | `GET /rider/deliveries/{id}` |
| Accept / Reject | `POST /rider/deliveries/{id}/accept` · `POST /rider/deliveries/{id}/reject` `{reason?}` (409 if another rider got it first) |
| Active trip | `GET /rider/deliveries/active` |
| Confirm pickup | `POST /rider/deliveries/{id}/pickup` `{code: 6 digits}` |
| Navigate → "I've arrived" | `POST /rider/deliveries/{id}/arrived` |
| Confirm delivery | `POST /rider/deliveries/{id}/deliver` (multipart) `{code: 4 digits, photo}` |
| Earnings | `GET /rider/earnings` · `POST /rider/withdraw` `{amount, method: momo\|airtel, phone}` |

## Webhook
`POST /payments/webhook/{provider}` · header `X-Webhook-Secret` · `{reference, status: successful|failed, provider_reference?}`
