import 'package:flutter/material.dart';
import 'data.dart';
import 'icons.dart';

enum Screen {
  splash, onboarding, login, signup, forgot, otp, newPassword, locationAccess,
  home, partners, station, fuel, vehicle, checkout, payment, tracking, success,
  orders, orderDetail, wallet, rewards, notifications, profile, addresses,
  vehicles, support, safety,
  // Added from the Figma prototype (customer extras + rider app).
  orderConfirmation, cancelOrder, editProfile, appSettings,
  riderRegistration, riderLogin, riderDashboard, riderDeliveries, riderRequest,
  riderDecision, riderNavigation, riderPickup, riderDelivery, riderEarnings,
}

class MenuEntry {
  final Screen screen;
  final String label;
  const MenuEntry(this.screen, this.label);
}

/// Items of the top-right menu (same list as the original prototype navigator,
/// plus the new password screen).
const kMenuEntries = [
  MenuEntry(Screen.splash, 'Splash'),
  MenuEntry(Screen.onboarding, 'Onboarding'),
  MenuEntry(Screen.login, 'Sign in'),
  MenuEntry(Screen.signup, 'Create account'),
  MenuEntry(Screen.forgot, 'Reset password'),
  MenuEntry(Screen.otp, 'Verification'),
  MenuEntry(Screen.newPassword, 'New password'),
  MenuEntry(Screen.locationAccess, 'Location access'),
  MenuEntry(Screen.home, 'Home'),
  MenuEntry(Screen.partners, 'Partner stations'),
  MenuEntry(Screen.station, 'Station'),
  MenuEntry(Screen.fuel, 'Select fuel'),
  MenuEntry(Screen.vehicle, 'Select vehicle'),
  MenuEntry(Screen.checkout, 'Delivery'),
  MenuEntry(Screen.payment, 'Payment'),
  MenuEntry(Screen.tracking, 'Live tracking'),
  MenuEntry(Screen.success, 'Completed'),
  MenuEntry(Screen.orders, 'Orders'),
  MenuEntry(Screen.orderDetail, 'Order details'),
  MenuEntry(Screen.wallet, 'Wallet'),
  MenuEntry(Screen.rewards, 'Rewards'),
  MenuEntry(Screen.notifications, 'Notifications'),
  MenuEntry(Screen.profile, 'Settings'),
  MenuEntry(Screen.addresses, 'Saved places'),
  MenuEntry(Screen.vehicles, 'My vehicles'),
  MenuEntry(Screen.support, 'Help centre'),
  MenuEntry(Screen.safety, 'Safety centre'),
  MenuEntry(Screen.orderConfirmation, 'Order confirmed'),
  MenuEntry(Screen.cancelOrder, 'Cancel order'),
  MenuEntry(Screen.editProfile, 'Edit profile'),
  MenuEntry(Screen.appSettings, 'App settings'),
  MenuEntry(Screen.riderRegistration, 'Rider registration'),
  MenuEntry(Screen.riderLogin, 'Rider login'),
  MenuEntry(Screen.riderDashboard, 'Rider dashboard'),
  MenuEntry(Screen.riderDeliveries, 'Available deliveries'),
  MenuEntry(Screen.riderRequest, 'Delivery request'),
  MenuEntry(Screen.riderDecision, 'Accept or reject'),
  MenuEntry(Screen.riderNavigation, 'Navigate to customer'),
  MenuEntry(Screen.riderPickup, 'Confirm pickup'),
  MenuEntry(Screen.riderDelivery, 'Confirm delivery'),
  MenuEntry(Screen.riderEarnings, 'Rider earnings'),
];

class AppState extends ChangeNotifier {
  // ----- navigation --------------------------------------------------------
  Screen current = Screen.splash;
  final List<Screen> _stack = [Screen.splash];
  bool get canGoBack => _stack.length > 1;

  void go(Screen s, {bool root = false, bool replace = false}) {
    if (root) {
      _stack
        ..clear()
        ..add(s);
    } else if (replace) {
      _stack[_stack.length - 1] = s;
    } else {
      _stack.add(s);
    }
    current = s;
    notifyListeners();
  }

  bool back() {
    if (_stack.length > 1) {
      _stack.removeLast();
      current = _stack.last;
      notifyListeners();
      return true;
    }
    return false;
  }

  void backOr(Screen fallback) {
    if (!back()) go(fallback, root: true);
  }

  // ----- location ----------------------------------------------------------
  String location = 'Kololo, Kampala';
  bool pushOn = true;
  bool locationOn = true;

  // ----- order builder -----------------------------------------------------
  static const prices = {'Petrol': 5180, 'Diesel': 4960, 'Power': 6450};
  static const deliveryFee = 8000;
  static const serviceFee = 2500;

  String fuelType = 'Petrol';
  int litres = 35;
  String vehicleId = 'rav4';
  bool scheduled = false;
  TimeOfDay? scheduledAt;
  String deliveryAddress = 'Acacia Mall, Kisementi';
  String deliveryNote = '';
  String payId = 'visa';
  bool stationSaved = false;

  int get fuelTotal => litres * prices[fuelType]!;
  int get orderTotal => fuelTotal + deliveryFee + serviceFee;
  String get productName =>
      fuelType == 'Petrol' ? 'Premium petrol' : (fuelType == 'Diesel' ? 'Ultra diesel' : 'Power');
  String fuelClass(String t) => t == 'Diesel' ? 'Diesel' : 'Petrol';

  final List<Vehicle> vehicles = [
    const Vehicle(id: 'rav4', name: 'Toyota RAV4', plate: 'UBP 482M', fuel: 'Petrol', color: 'Black', tank: '60L', visual: 'RAV4'),
    const Vehicle(id: 'hilux', name: 'Toyota Hilux', plate: 'UBN 117Q', fuel: 'Diesel', color: 'Silver', tank: '80L', visual: 'HILUX'),
  ];
  Vehicle get selectedVehicle =>
      vehicles.firstWhere((v) => v.id == vehicleId, orElse: () => vehicles.first);

  final List<Place> places = [
    const Place('Home', 'Plot 18, Kira Road, Bukoto'),
    const Place('Office', 'Rwenzori Towers, Nakasero'),
    const Place('Gym', 'Acacia Mall, Kisementi'),
  ];

  final List<PayMethod> payMethods = [
    const PayMethod(id: 'momo', title: 'MTN Mobile Money', caption: '+256 700 ••• 456', badge: 'MTN', badgeBg: Color(0xFFFFCB05), badgeFg: Color(0xFF171717)),
    const PayMethod(id: 'airtel', title: 'Airtel Money', caption: 'Add an Airtel number', badge: 'A', badgeBg: Color(0xFFE9222B), badgeFg: Colors.white),
    const PayMethod(id: 'visa', title: 'Visa ending 4242', caption: 'Expires 08/28', badge: 'VISA'),
    const PayMethod(id: 'wallet', title: 'FuelConnect Wallet', caption: '', icon: IconName.wallet),
    const PayMethod(id: 'cash', title: 'Cash on delivery', caption: 'Pay your delivery partner', icon: IconName.card),
  ];
  PayMethod get selectedPay => payMethods.firstWhere((m) => m.id == payId, orElse: () => payMethods.first);

  // ----- wallet / rewards --------------------------------------------------
  int walletBalance = 480000;
  int points = 2450;
  static const nextTierPoints = 3000;
  final List<WalletTx> txs = [
    const WalletTx('Fuel order', 'Stabex Kira Road', -191800),
    const WalletTx('Wallet top up', 'MTN Mobile Money', 300000),
    const WalletTx('Fuel order', 'Shell Lugogo', -153500),
  ];

  /// Returns an error message, or null when the payment can proceed.
  String? charge() {
    final total = orderTotal;
    if (payId == 'wallet') {
      if (walletBalance < total) return 'Your wallet balance is too low. Top up or pick another method.';
      walletBalance -= total;
    }
    txs.insert(0, WalletTx('Fuel order', 'Stabex Kira Road', -total));
    return null;
  }

  void completeDelivery() => points += orderTotal ~/ 1000;

  void topUp(int amount) {
    walletBalance += amount;
    txs.insert(0, WalletTx('Wallet top up', 'MTN Mobile Money', amount));
  }

  // ----- notifications -----------------------------------------------------
  final List<Notice> notices = [
    Notice(IconName.truck, 'Your fuel is on the way', 'Marcus has collected your order and will arrive in 12–16 minutes.', 'Now', true),
    Notice(IconName.check, 'Payment confirmed', 'Your payment of UGX 191,800 was successful.', '4 min', true),
    Notice(IconName.fuel, 'Prices dropped near you', 'Petrol is now UGX 5,180/L at Stabex Kira Road.', '2 hr', false),
    Notice(IconName.shield, 'Safety check complete', 'Your delivery partner has passed the pre-trip safety check.', 'Yesterday', false),
  ];
}

final app = AppState();
