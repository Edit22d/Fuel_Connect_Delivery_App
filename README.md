# FuelConnect — full stack

```
flutter_app/   Flutter frontend: customer app + rider app (all 52-screen prototype screens except the admin ones)
backend/       Laravel 11 REST API + Filament admin dashboard (the 8 admin screens live here)
```

1. **Backend** → `backend/README.md` (composer install, migrate --seed, serve; admin at `/admin`).
2. **Flutter** → `flutter_app/README.md` for how to run, and `flutter_app/NEW_SCREENS.md` for what was added.

Your original Flutter code is untouched except two additive edits (new screen registrations);
see `flutter_app/NEW_SCREENS.md`. The Flutter app still uses mocked data; the backend is ready for you to connect it to.
