import 'package:flutter/material.dart';

/// One delivery request offered to a rider.
class RiderJob {
  final String id, station, pickupArea, dropArea, dropAddress;
  final String customer, customerRating, product, vehicle, plate;
  final int litres, pay, minutes;
  final double pickupKm, tripKm;
  const RiderJob({
    required this.id,
    required this.station,
    required this.pickupArea,
    required this.dropArea,
    required this.dropAddress,
    required this.customer,
    required this.customerRating,
    required this.product,
    required this.vehicle,
    required this.plate,
    required this.litres,
    required this.pay,
    required this.minutes,
    required this.pickupKm,
    required this.tripKm,
  });

  double get totalKm => pickupKm + tripKm;
  String get totalKmLabel => '${totalKm.toStringAsFixed(1)} km';
  String get productLine => '$product · ${litres}L';
  String get customerInitials {
    final p = customer.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (p.isEmpty) return '?';
    if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
    return (p.first.substring(0, 1) + p.last.substring(0, 1)).toUpperCase();
  }
}

class RiderEarning {
  final String station, when;
  final int amount;
  const RiderEarning(this.station, this.when, this.amount);
}

/// Frontend-only rider state (mirrors what the Laravel `/rider/*` endpoints
/// return). Replace the bodies with API calls when the backend is connected.
class RiderState extends ChangeNotifier {
  static const demoPhone = '+256701234567';
  static const demoPassword = 'Rider@2025';

  String name = 'Marcus K.';
  bool signedIn = false;
  bool online = true;
  bool applicationPending = false;

  String get initials {
    final p = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (p.isEmpty) return '?';
    if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
    return (p.first.substring(0, 1) + p.last.substring(0, 1)).toUpperCase();
  }

  static const List<RiderJob> _sample = [
    RiderJob(
      id: 'FC-29841', station: 'Stabex Kira Road', pickupArea: 'Kira Road', dropArea: 'Kisementi',
      dropAddress: 'Acacia Mall, Kisementi', customer: 'Joel Kato', customerRating: '4.9',
      product: 'Premium petrol', vehicle: 'Black Toyota RAV4', plate: 'UBP 482M',
      litres: 35, pay: 18500, minutes: 22, pickupKm: 1.8, tripKm: 4.6,
    ),
    RiderJob(
      id: 'FC-29850', station: 'Shell Lugogo', pickupArea: 'Lugogo', dropArea: 'Naguru',
      dropAddress: 'Naguru Hill Road, Naguru', customer: 'Aisha Nabirye', customerRating: '4.8',
      product: 'Ultra diesel', vehicle: 'Silver Toyota Hilux', plate: 'UBN 117Q',
      litres: 28, pay: 16000, minutes: 18, pickupKm: 3.2, tripKm: 3.1,
    ),
    RiderJob(
      id: 'FC-29853', station: 'Rubis Bukoto', pickupArea: 'Bukoto', dropArea: 'Ntinda',
      dropAddress: 'Ntinda Shopping Centre, Ntinda', customer: 'David Ssemwogerere', customerRating: '4.7',
      product: 'Premium petrol', vehicle: 'White Honda CR-V', plate: 'UBR 905T',
      litres: 22, pay: 21500, minutes: 26, pickupKm: 4.1, tripKm: 5.8,
    ),
  ];

  final List<RiderJob> jobs = List.of(_sample);

  /// The request the rider is looking at (request / accept / pickup screens).
  RiderJob? selected;

  /// The delivery the rider accepted and is currently performing.
  RiderJob? activeTrip;

  /// Job shown on the detail screens. Falls back to the first sample job so
  /// every screen can be opened directly from the prototype menu.
  RiderJob get job => selected ?? activeTrip ?? (jobs.isNotEmpty ? jobs.first : _sample.first);

  // ----- earnings -----------------------------------------------------------
  int todayEarnings = 74500;
  int todayDeliveries = 4;
  double rating = 4.9;
  int available = 486500;
  int weekTotal = 312000;
  int weekTrips = 18;
  final List<int> weekBars = [45, 70, 52, 85, 62, 95, 74];
  final List<RiderEarning> recent = [
    const RiderEarning('Stabex Kira Road', 'Today · #FC-29841', 18500),
    const RiderEarning('Shell Lugogo', 'Today · #FC-29795', 16000),
    const RiderEarning('Rubis Bukoto', 'Yesterday · #FC-29682', 21500),
  ];

  int get avgPerTrip => weekTrips == 0 ? 0 : (weekTotal / weekTrips).round();

  // ----- session ------------------------------------------------------------
  void signIn() {
    signedIn = true;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    selected = null;
    activeTrip = null;
    notifyListeners();
  }

  void toggleOnline() {
    online = !online;
    notifyListeners();
  }

  // ----- deliveries ---------------------------------------------------------
  void select(RiderJob j) {
    selected = j;
    notifyListeners();
  }

  void accept() {
    final j = job;
    activeTrip = j;
    selected = j;
    jobs.removeWhere((x) => x.id == j.id);
    notifyListeners();
  }

  void reject() {
    final j = job;
    jobs.removeWhere((x) => x.id == j.id);
    selected = null;
    notifyListeners();
  }

  void refreshJobs() {
    jobs
      ..clear()
      ..addAll(_sample.where((s) => s.id != activeTrip?.id));
    notifyListeners();
  }

  void completeDelivery() {
    final j = activeTrip ?? job;
    todayEarnings += j.pay;
    todayDeliveries += 1;
    available += j.pay;
    weekTotal += j.pay;
    weekTrips += 1;
    recent.insert(0, RiderEarning(j.station, 'Today · #${j.id}', j.pay));
    activeTrip = null;
    selected = null;
    notifyListeners();
  }

  /// Moves the whole available balance out and returns the amount withdrawn.
  int withdraw() {
    final amount = available;
    available = 0;
    notifyListeners();
    return amount;
  }
}

final rider = RiderState();
