import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

/// Frontend-only auth. Everything here is a stand-in for the future backend:
/// replace the bodies of these methods with API calls and keep the signatures.
/// (Passwords are salted+hashed locally only so none are stored in plain text.)

enum OtpPurpose { login, signup, reset }

class AuthResult {
  final bool ok;
  final String? error;
  final OtpPurpose? purpose;
  const AuthResult.ok([this.purpose])
      : ok = true,
        error = null;
  const AuthResult.fail(this.error)
      : ok = false,
        purpose = null;
}

class Account {
  String name, phone, email;
  final String salt;
  String hash;
  Account({required this.name, required this.phone, required this.email, required this.salt, required this.hash});
  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'email': email, 'salt': salt, 'hash': hash};
  factory Account.fromJson(Map<String, dynamic> j) => Account(
        name: j['name'] as String,
        phone: j['phone'] as String,
        email: j['email'] as String,
        salt: j['salt'] as String,
        hash: j['hash'] as String,
      );
}

class Profile {
  String name, phone, email;
  Profile(this.name, this.phone, this.email);
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class Validators {
  static String? normalizePhone(String raw) {
    var d = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (d.startsWith('+')) d = d.substring(1);
    if (d.length == 12 && d.startsWith('256')) {
      d = d.substring(3);
    } else if (d.length == 10 && d.startsWith('0')) {
      d = d.substring(1);
    }
    if (!RegExp(r'^[1-9]\d{8}$').hasMatch(d)) return null;
    return '+256$d';
  }

  static String? phone(String v) {
    if (v.trim().isEmpty) return 'Enter your phone number';
    if (normalizePhone(v) == null) return 'Enter a valid Uganda number, e.g. +256 700 123 456';
    return null;
  }

  static String? name(String v) => v.trim().length < 2 ? 'Enter your full name' : null;

  static String? email(String v) {
    if (v.trim().isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static bool hasLen(String p) => p.length >= 8;
  static bool hasLetterAndNumber(String p) => RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p);
  static bool passwordOk(String p) => hasLen(p) && hasLetterAndNumber(p);
  static String? password(String v) {
    if (v.isEmpty) return 'Create a password';
    if (!passwordOk(v)) return 'Use at least 8 characters with a letter and a number';
    return null;
  }

  /// 0..4 segments for the strength meter.
  static int strength(String p) {
    if (p.isEmpty) return 0;
    var s = 0;
    if (hasLen(p)) s++;
    if (hasLetterAndNumber(p)) s++;
    if (RegExp(r'[a-z]').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p) || p.length >= 12) s++;
    return s;
  }
}

String formatPhone(String e164) {
  // +256700123456 -> +256 700 123 456
  if (e164.length != 13) return e164;
  return '${e164.substring(0, 4)} ${e164.substring(4, 7)} ${e164.substring(7, 10)} ${e164.substring(10)}';
}

String maskPhone(String e164) {
  if (e164.length != 13) return e164;
  return '${e164.substring(0, 4)} ${e164.substring(4, 7)} ••• ${e164.substring(10)}';
}

class AuthService {
  static const demoPhone = '+256700123456';
  static const demoPassword = 'Fuel@2025';
  static const _prefsKey = 'fc_accounts_v1';
  static const resendAfter = 30; // seconds
  static const validFor = 120; // seconds
  static const maxAttempts = 5;

  final List<Account> _accounts = [];
  Account? current;
  final Profile profile = Profile('Joel Kato', demoPhone, 'joel.kato@email.com');

  // pending verification
  OtpPurpose? purpose;
  String? pendingPhone;
  String? code; // exposed only for demo mode
  DateTime? _sentAt;
  DateTime? _expiresAt;
  int _attempts = 0;

  // password reset
  bool resetVerified = false;
  String? resetPhone;

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
      if (raw != null) {
        for (final j in jsonDecode(raw) as List) {
          _accounts.add(Account.fromJson(Map<String, dynamic>.from(j as Map)));
        }
      }
    } catch (_) {}
    if (!_accounts.any((a) => a.phone == demoPhone)) {
      _accounts.add(_make('Joel Kato', demoPhone, 'joel.kato@email.com', demoPassword));
      await _save();
    }
  }

  Account _make(String name, String phone, String email, String password) {
    final salt = _randomString(12);
    return Account(name: name, phone: phone, email: email, salt: salt, hash: _hash(salt, password));
  }

  String _hash(String salt, String password) => sha256.convert(utf8.encode('$salt:$password')).toString();

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefsKey, jsonEncode(_accounts.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }

  Account? _byPhone(String e164) {
    for (final a in _accounts) {
      if (a.phone == e164) return a;
    }
    return null;
  }

  static final _rnd = Random.secure();
  static String _randomString(int n) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(n, (_) => chars[_rnd.nextInt(chars.length)]).join();
  }

  Future<void> _latency() => Future.delayed(const Duration(milliseconds: 700));

  // ----- sign in / up ------------------------------------------------------
  Future<AuthResult> signIn(String phone, String password) async {
    await _latency();
    final n = Validators.normalizePhone(phone);
    final a = n == null ? null : _byPhone(n);
    if (a == null || a.hash != _hash(a.salt, password)) {
      return const AuthResult.fail('Incorrect phone number or password.');
    }
    return const AuthResult.ok();
  }

  Future<AuthResult> signUp({required String name, required String phone, required String email, required String password}) async {
    await _latency();
    final n = Validators.normalizePhone(phone)!;
    if (_byPhone(n) != null) return const AuthResult.fail('An account with this phone number already exists. Try signing in.');
    if (_accounts.any((a) => a.email.toLowerCase() == email.trim().toLowerCase())) {
      return const AuthResult.fail('An account with this email already exists.');
    }
    _accounts.add(_make(name.trim(), n, email.trim(), password));
    await _save();
    return const AuthResult.ok();
  }

  Future<AuthResult> requestPasswordReset(String phone) async {
    await _latency();
    final n = Validators.normalizePhone(phone);
    if (n == null || _byPhone(n) == null) {
      return const AuthResult.fail('We couldn’t find an account with that phone number.');
    }
    return const AuthResult.ok();
  }

  // ----- verification code -------------------------------------------------
  bool get hasPending => pendingPhone != null;

  void startOtp(OtpPurpose p, {required String phone}) {
    purpose = p;
    pendingPhone = Validators.normalizePhone(phone) ?? phone;
    const digits = '0123456789';
    const alnum = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const pool = kOtpAlphanumeric ? alnum : digits;
    code = List.generate(kOtpLength, (_) => pool[_rnd.nextInt(pool.length)]).join();
    _sentAt = DateTime.now();
    _expiresAt = _sentAt!.add(const Duration(seconds: validFor));
    _attempts = 0;
    if (p != OtpPurpose.reset) resetVerified = false;
  }

  int get secondsLeft {
    if (_expiresAt == null) return 0;
    return max(0, _expiresAt!.difference(DateTime.now()).inSeconds);
  }

  int get resendIn {
    if (_sentAt == null) return 0;
    return max(0, resendAfter - DateTime.now().difference(_sentAt!).inSeconds);
  }

  AuthResult verifyOtp(String entered) {
    if (pendingPhone == null || code == null) return const AuthResult.fail('Request a new code to continue.');
    if (secondsLeft == 0) return const AuthResult.fail('This code has expired. Send a new one.');
    if (_attempts >= maxAttempts) return const AuthResult.fail('Too many attempts. Send a new code.');
    if (entered.toUpperCase() != code) {
      _attempts++;
      final left = maxAttempts - _attempts;
      return AuthResult.fail(left > 0
          ? 'That code isn’t correct. $left ${left == 1 ? 'attempt' : 'attempts'} left.'
          : 'Too many attempts. Send a new code.');
    }
    final p = purpose!;
    final phone = pendingPhone!;
    pendingPhone = null;
    code = null;
    if (p == OtpPurpose.reset) {
      resetVerified = true;
      resetPhone = phone;
    } else {
      current = _byPhone(phone);
      if (current != null) {
        profile
          ..name = current!.name
          ..phone = current!.phone
          ..email = current!.email;
      }
    }
    return AuthResult.ok(p);
  }

  // ----- password reset ----------------------------------------------------
  Future<AuthResult> resetPassword(String newPassword) async {
    await _latency();
    final a = resetPhone == null ? null : _byPhone(resetPhone!);
    if (!resetVerified || a == null) return const AuthResult.fail('Please verify your phone number first.');
    if (a.hash == _hash(a.salt, newPassword)) {
      return const AuthResult.fail('Choose a password you haven’t used before.');
    }
    a.hash = _hash(a.salt, newPassword);
    await _save();
    resetVerified = false;
    resetPhone = null;
    return const AuthResult.ok();
  }

  // ----- profile / session -------------------------------------------------
  Future<void> updateProfile(String name, String email) async {
    profile
      ..name = name
      ..email = email;
    if (current != null) {
      current!
        ..name = name
        ..email = email;
      await _save();
    }
  }

  void signOut() {
    current = null;
    profile
      ..name = 'Joel Kato'
      ..phone = demoPhone
      ..email = 'joel.kato@email.com';
  }
}

final auth = AuthService();
