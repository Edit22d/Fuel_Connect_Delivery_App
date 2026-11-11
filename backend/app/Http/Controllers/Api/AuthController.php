<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\OtpService;
use App\Support\Phone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Customer authentication. Same flow as the Flutter app:
 * register → OTP → token · login → OTP → token · forgot → OTP → new password.
 */
class AuthController extends Controller
{
    public function __construct(private OtpService $otp)
    {
    }

    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:100'],
            'phone' => ['required', 'string'],
            'email' => ['nullable', 'email', 'max:150', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'regex:/[A-Za-z]/', 'regex:/\d/'],
        ], ['password.regex' => 'Use at least one letter and one number.']);

        $phone = $this->phoneOrFail($data['phone']);
        abort_if(User::where('phone', $phone)->exists(), 422, 'An account with this phone number already exists.');

        User::create([
            'name' => trim($data['name']),
            'phone' => $phone,
            'email' => $data['email'] ?? null,
            'password' => $data['password'],
            'role' => User::ROLE_CUSTOMER,
        ]);

        return response()->json(['message' => 'Account created. Enter the code we sent you.', 'phone' => $phone, 'otp' => $this->otp->send($phone, 'signup')], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate(['phone' => ['required', 'string'], 'password' => ['required', 'string']]);
        $phone = $this->phoneOrFail($data['phone']);

        $user = User::where('phone', $phone)->first();
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            abort(422, 'Incorrect phone number or password.');
        }
        abort_unless($user->role === User::ROLE_CUSTOMER, 403, 'Please use the rider portal to sign in.');
        abort_unless($user->isActive(), 403, 'Your account has been suspended. Please contact FuelConnect support.');

        if (! config('fuelconnect.otp.on_login')) {
            return $this->tokenResponse($user);
        }

        return response()->json(['otp_required' => true, 'phone' => $phone, 'otp' => $this->otp->send($phone, 'login')]);
    }

    public function sendOtp(Request $request): JsonResponse
    {
        $data = $request->validate(['phone' => ['required', 'string'], 'purpose' => ['required', 'in:signup,login,reset']]);
        $phone = $this->phoneOrFail($data['phone']);
        abort_unless(User::where('phone', $phone)->exists(), 404, 'We couldn’t find an account with that phone number.');

        return response()->json(['phone' => $phone, 'otp' => $this->otp->send($phone, $data['purpose'])]);
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'phone' => ['required', 'string'],
            'purpose' => ['required', 'in:signup,login,reset'],
            'code' => ['required', 'string', 'size:'.config('fuelconnect.otp.length')],
        ]);
        $phone = $this->phoneOrFail($data['phone']);
        $user = User::where('phone', $phone)->first();
        abort_unless($user, 404, 'We couldn’t find an account with that phone number.');

        $this->otp->verify($phone, $data['purpose'], $data['code']);

        if ($data['purpose'] === 'reset') {
            $token = Str::random(48);
            Cache::put("pwreset:{$phone}", hash('sha256', $token), now()->addMinutes(10));

            return response()->json(['reset_token' => $token, 'expires_in' => 600]);
        }

        abort_unless($user->isActive(), 403, 'Your account has been suspended. Please contact FuelConnect support.');
        if (! $user->phone_verified_at) {
            $user->update(['phone_verified_at' => now()]);
        }

        return $this->tokenResponse($user);
    }

    public function forgot(Request $request): JsonResponse
    {
        $data = $request->validate(['phone' => ['required', 'string']]);
        $phone = $this->phoneOrFail($data['phone']);
        abort_unless(User::where('phone', $phone)->exists(), 404, 'We couldn’t find an account with that phone number.');

        return response()->json(['phone' => $phone, 'otp' => $this->otp->send($phone, 'reset')]);
    }

    public function reset(Request $request): JsonResponse
    {
        $data = $request->validate([
            'phone' => ['required', 'string'],
            'reset_token' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'regex:/[A-Za-z]/', 'regex:/\d/', 'confirmed'],
        ], ['password.regex' => 'Use at least one letter and one number.']);
        $phone = $this->phoneOrFail($data['phone']);

        $expected = Cache::get("pwreset:{$phone}");
        abort_unless($expected && hash_equals($expected, hash('sha256', $data['reset_token'])), 422, 'Please verify your phone number first.');

        $user = User::where('phone', $phone)->firstOrFail();
        abort_if(Hash::check($data['password'], $user->password), 422, 'Choose a password you haven’t used before.');

        $user->update(['password' => $data['password']]);
        $user->tokens()->delete();          // sign out every device
        Cache::forget("pwreset:{$phone}");

        return response()->json(['message' => 'Password updated. Sign in with your new password.']);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Signed out.']);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user()->load('rider'));
    }

    public function updateMe(Request $request): UserResource
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'min:2', 'max:100'],
            'email' => ['sometimes', 'nullable', 'email', 'max:150', 'unique:users,email,'.$user->id],
            'emergency_contact' => ['sometimes', 'nullable', 'string'],
        ]);

        if (array_key_exists('emergency_contact', $data) && $data['emergency_contact'] !== null && $data['emergency_contact'] !== '') {
            $data['emergency_contact'] = $this->phoneOrFail($data['emergency_contact']);
        }

        $user->update($data);

        return new UserResource($user->fresh());
    }

    private function tokenResponse(User $user): JsonResponse
    {
        return response()->json([
            'token' => $user->createToken('mobile')->plainTextToken,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
        ]);
    }

    private function phoneOrFail(string $raw): string
    {
        $phone = Phone::normalize($raw);
        abort_unless($phone, 422, 'Enter a valid Ugandan phone number, e.g. +256 700 123 456.');

        return $phone;
    }
}
