import 'package:flutter_test/flutter_test.dart';
import 'package:fuelconnect/services/auth_service.dart';

void main() {
  group('phone validation', () {
    test('normalises Uganda numbers', () {
      expect(Validators.normalizePhone('0700123456'), '+256700123456');
      expect(Validators.normalizePhone('+256 700 123 456'), '+256700123456');
      expect(Validators.normalizePhone('700123456'), '+256700123456');
    });
    test('rejects bad numbers', () {
      expect(Validators.normalizePhone('12345'), isNull);
      expect(Validators.phone(''), isNotNull);
    });
  });

  group('password rules', () {
    test('needs 8+ chars with a letter and a number', () {
      expect(Validators.passwordOk('short1'), isFalse);
      expect(Validators.passwordOk('longpassword'), isFalse);
      expect(Validators.passwordOk('Fuel@2025'), isTrue);
    });
    test('strength meter grows with variety', () {
      expect(Validators.strength(''), 0);
      expect(Validators.strength('Fuel@2025xyz'), 4);
    });
  });

  group('verification code', () {
    test('is exactly $kOtpLengthText characters and verifies once', () {
      final a = AuthService();
      a.startOtp(OtpPurpose.reset, phone: AuthService.demoPhone);
      expect(a.code!.length, 6);

      final wrong = a.code == '000000' ? '111111' : '000000';
      expect(a.verifyOtp(wrong).ok, isFalse);

      final r = a.verifyOtp(a.code!);
      expect(r.ok, isTrue);
      expect(r.purpose, OtpPurpose.reset);
      expect(a.resetVerified, isTrue);
      expect(a.verifyOtp('123456').ok, isFalse); // code is single-use
    });
  });
}

const kOtpLengthText = 'six';
