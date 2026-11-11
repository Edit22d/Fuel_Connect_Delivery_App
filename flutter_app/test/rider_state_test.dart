import 'package:flutter_test/flutter_test.dart';
import 'package:fuelconnect/core/rider_state.dart';

void main() {
  group('rider flow', () {
    test('accepting a request removes it from the list and starts a trip', () {
      final r = RiderState();
      final first = r.jobs.first;
      r.select(first);
      r.accept();
      expect(r.activeTrip?.id, first.id);
      expect(r.jobs.any((j) => j.id == first.id), isFalse);
    });

    test('completing a delivery credits earnings (matches the design: 74,500 + 18,500)', () {
      final r = RiderState();
      r.select(r.jobs.first);
      r.accept();
      r.completeDelivery();
      expect(r.todayEarnings, 93000);
      expect(r.todayDeliveries, 5);
      expect(r.activeTrip, isNull);
      expect(r.recent.first.amount, 18500);
    });

    test('withdraw empties the available balance and returns the amount', () {
      final r = RiderState();
      final before = r.available;
      expect(r.withdraw(), before);
      expect(r.available, 0);
    });

    test('rejecting drops the request', () {
      final r = RiderState();
      final id = r.jobs.first.id;
      r.select(r.jobs.first);
      r.reject();
      expect(r.jobs.any((j) => j.id == id), isFalse);
    });
  });
}
