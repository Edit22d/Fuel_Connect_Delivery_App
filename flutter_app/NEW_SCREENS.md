# New screens added from the Figma prototype (`Friendly_Greeting`)

Your existing screens, widgets, state and services are unchanged. Only two
existing files were touched, **additions only**:

| File | What was added |
|---|---|
| `lib/core/app_state.dart` | 14 new `Screen` enum values + 14 prototype-menu entries (appended after "Safety centre") |
| `lib/shell.dart` | 2 imports + 14 `case` lines in the screen switch |

## New files

| File | Contents |
|---|---|
| `lib/screens/extra_customer_screens.dart` | Order confirmed · Edit profile · App settings |
| `lib/screens/rider_screens.dart` | Rider registration (3 steps) · Rider login · Rider dashboard · Available deliveries · Delivery request · Accept/Reject · Navigate to customer · Confirm pickup · Confirm delivery · Rider earnings |
| `lib/core/rider_state.dart` | Mock rider state (jobs, earnings, trip). Same shapes the Laravel `/rider/*` API returns |
| `lib/core/extras_state.dart` | Emergency contact + app-settings toggles |
| `test/rider_state_test.dart` | Unit tests for the rider flow logic |

`CancelOrderScreen` already existed in `order_screens.dart` but wasn't registered
anywhere, so it is now wired in (not rewritten).

All 14 screens open from the top-right prototype menu (now 41 entries).

## Demo rider account

| Phone | Password |
|---|---|
| `+256 701 234 567` | `Rider@2025` |

Registering a new rider shows "application under review" on sign-in, exactly as
the backend does until an admin approves them in Filament.

## Not rewired on purpose (so nothing in your screens changes)

These are the one-line hooks if you want the new screens reachable from the
existing buttons. None are applied:

- Payment success → `go(Screen.orderConfirmation)` (instead of going straight to tracking)
- Tracking screen "Cancel" → `go(Screen.cancelOrder)`
- Settings "Personal details" row → `go(Screen.editProfile)`; add a row for `Screen.appSettings`
- A "Become a delivery partner" link on Sign in → `go(Screen.riderRegistration)`

## Backend

The Flutter app is still mocked. The Laravel API in `../backend` exposes the
matching endpoints; swap the bodies of `AuthService` and `RiderState` for HTTP calls.
