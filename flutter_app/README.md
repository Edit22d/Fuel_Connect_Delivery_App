# FuelConnect — Flutter frontend

A Flutter rebuild of the FuelConnect Figma Make prototype (`Friendly_Greeting.zip`):
same gold-on-black theme, Plus Jakarta Sans, the same three AI images, the same
copy and the same 26 screens, plus one new screen (**New password**).
Backend is not wired yet — see "What is mocked".

## Run it

```bash
flutter create . --platforms=android,ios,web   # generates the platform folders only
flutter pub get
flutter run -d chrome        # or any emulator / device
flutter build web            # static site you can host anywhere
```

Requires Flutter 3.24+ (Dart 3.4+). `flutter create .` will not overwrite `lib/`, `pubspec.yaml` or `test/`.

Android: to let the Safety screen dial 999, add this inside `<manifest>` of
`android/app/src/main/AndroidManifest.xml`:
`<queries><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent></queries>`

## Demo account

| Phone | Password |
|---|---|
| `+256 700 123 456` | `Fuel@2025` |

Or create your own on **Create account**. Accounts persist on the device.
With `kDemoMode = true` (lib/core/theme.dart) the 6-character verification code is
shown in a toast, because no SMS is sent yet.

## Flows that work

- **Sign in / Create account** — validation, duplicate checks, hashed local storage.
- **Verification** — 6-character code (digits; `kOtpAlphanumeric` switches to letters+digits), paste / SMS autofill, 2-minute expiry, 30 s resend cooldown, 5 attempts.
- **Forgot password** — phone → verification → **New password** screen (show/hide, strength meter, rules checklist, *confirm password* match) → success → sign in with the new password.
- **Ordering** — fuel type, litres, vehicle compatibility check, delivery address & time, payment method (wallet balance is charged), live tracking, delivery complete + rating.
- **Menu (top-right icon)** — opens the list of all 27 screens; works on every screen.
- Search & filters, saved places, vehicles, wallet top-up, rewards redemption, notifications, settings toggles, profile editing, support chat.

## Responsive

Mobile layouts below 760 px, two-column layouts above (same breakpoint as the design),
`clamp()`-style fluid type and padding, safe-area aware, system font scale capped at 120 %.

## Two source quirks kept on purpose

The original CSS has two accidents; they are reproduced exactly. Set
`kReproduceSourceQuirks = false` in `lib/core/theme.dart` to fix both:
1. Forward buttons ("Continue", "Order fuel now"...) use the left-pointing arrow icon.
2. The *Total* row in price summaries receives the TotalEnergies red→blue gradient.

## What is mocked (replace when the backend exists)

`lib/services/auth_service.dart` — every method (`signIn`, `signUp`, `requestPasswordReset`,
`startOtp`/`verifyOtp`, `resetPassword`) is the seam for the API. Order, wallet, rewards and
tracking state lives in `lib/core/app_state.dart`. "Continue with Google", driver call and
statements show a placeholder message.

## Fonts offline

Plus Jakarta Sans is fetched by `google_fonts` on first run. To bundle it, drop the TTFs in
`assets/google_fonts/` and list that folder under `flutter: assets:`.
