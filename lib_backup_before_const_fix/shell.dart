import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'core/core.dart';
import 'screens/account_screens.dart';
import 'screens/auth_screens.dart';
import 'screens/browse_screens.dart';
import 'screens/extra_customer_screens.dart';
import 'screens/order_screens.dart';
import 'screens/rider_screens.dart';

/// Hosts the active screen and the top-right menu (the original "prototype
/// navigator", now collapsed behind an icon so it never covers the design).
class Shell extends StatelessWidget {
  const Shell({super.key});

  Widget _screen(Screen s) {
    final go = app.go;
    switch (s) {
      case Screen.splash:
        return SplashScreen(go: go);
      case Screen.onboarding:
        return OnboardingScreen(go: go);
      case Screen.login:
        return LoginScreen(go: go);
      case Screen.signup:
        return SignupScreen(go: go);
      case Screen.forgot:
        return ForgotScreen(go: go);
      case Screen.otp:
        return OtpScreen(go: go);
      case Screen.newPassword:
        return NewPasswordScreen(go: go);
      case Screen.locationAccess:
        return LocationAccessScreen(go: go);
      case Screen.home:
        return HomeScreen(go: go);
      case Screen.partners:
        return PartnersScreen(go: go);
      case Screen.station:
        return StationScreen(go: go);
      case Screen.fuel:
        return FuelScreen(go: go);
      case Screen.vehicle:
        return VehicleScreen(go: go);
      case Screen.checkout:
        return CheckoutScreen(go: go);
      case Screen.payment:
        return PaymentScreen(go: go);
      case Screen.tracking:
        return TrackingScreen(go: go);
      case Screen.success:
        return SuccessScreen(go: go);
      case Screen.orders:
        return OrdersScreen(go: go);
      case Screen.orderDetail:
        return OrderDetailScreen(go: go);
      case Screen.wallet:
        return WalletScreen(go: go);
      case Screen.rewards:
        return RewardsScreen(go: go);
      case Screen.notifications:
        return NotificationsScreen(go: go);
      case Screen.profile:
        return ProfileScreen(go: go);
      case Screen.addresses:
        return AddressesScreen(go: go);
      case Screen.vehicles:
        return VehiclesScreen(go: go);
      case Screen.support:
        return SupportScreen(go: go);
      case Screen.safety:
        return SafetyScreen(go: go);
      case Screen.orderConfirmation:
        return OrderConfirmationScreen(go: go);
      case Screen.cancelOrder:
        return CancelOrderScreen(go: go);
      case Screen.editProfile:
        return EditProfileScreen(go: go);
      case Screen.appSettings:
        return AppSettingsScreen(go: go);
      case Screen.riderRegistration:
        return RiderRegistrationScreen(go: go);
      case Screen.riderLogin:
        return RiderLoginScreen(go: go);
      case Screen.riderDashboard:
        return RiderDashboardScreen(go: go);
      case Screen.riderDeliveries:
        return RiderDeliveriesScreen(go: go);
      case Screen.riderRequest:
        return RiderRequestScreen(go: go);
      case Screen.riderDecision:
        return RiderDecisionScreen(go: go);
      case Screen.riderNavigation:
        return RiderNavigationScreen(go: go);
      case Screen.riderPickup:
        return RiderPickupScreen(go: go);
      case Screen.riderDelivery:
        return RiderDeliveryScreen(go: go);
      case Screen.riderEarnings:
        return RiderEarningsScreen(go: go);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => PopScope(
        canPop: !app.canGoBack,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) app.back();
        },
        child: Scaffold(
          backgroundColor: FC.black,
          body: Stack(children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(key: ValueKey(app.current), child: _screen(app.current)),
              ),
            ),
            ScreenMenu(current: app.current, go: app.go),
          ]),
        ),
      ),
    );
  }
}

class ScreenMenu extends StatefulWidget {
  final Screen current;
  final Go go;
  const ScreenMenu({super.key, required this.current, required this.go});
  @override
  State<ScreenMenu> createState() => _ScreenMenuState();
}

class _ScreenMenuState extends State<ScreenMenu> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final top = topInset(context) + 17;
    final panelTop = top + 42 + 8;
    final panelW = math.min(310.0, vw(context) - 28);
    final panelMaxH = math.min(620.0, vh(context) - panelTop - 24);
    return Stack(children: [
      if (_open) Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _open = false), child: const ColoredBox(color: Color(0x66000000)))),
      if (_open)
        Positioned(
          top: panelTop,
          right: 14,
          width: panelW,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                constraints: BoxConstraints(maxHeight: panelMaxH),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xF70D0F12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: FC.line),
                  boxShadow: [BoxShadow(color: al(Colors.black, .55), blurRadius: 70, offset: const Offset(0, 24))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(3, 2, 3, 13),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FC.line))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText('PROTOTYPE', kind: Tx.label, color: FC.gold), FcText('FuelConnect screens', kind: Tx.subtitle)]),
                      Container(
                        constraints: const BoxConstraints(minWidth: 28),
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: al(FC.gold, .1)),
                        child: Text('${kMenuEntries.length}', style: fs(9.92, color: FC.gold, w: FontWeight.w800, h: 1)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: LayoutBuilder(builder: (c, cons) {
                        final w = (cons.maxWidth - 7) / 2;
                        return Wrap(spacing: 7, runSpacing: 7, children: [
                          for (var i = 0; i < kMenuEntries.length; i++) _item(i, w),
                        ]);
                      }),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      Positioned(
        top: top,
        right: 14,
        child: Semantics(
          button: true,
          label: _open ? 'Close screen menu' : 'Open screen menu',
          child: Tap(
            onTap: () => setState(() => _open = !_open),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xF0131518),
                border: Border.all(color: const Color(0xFF554A25)),
                boxShadow: [BoxShadow(color: al(Colors.black, .35), blurRadius: 36, offset: const Offset(0, 12))],
              ),
              child: Center(
                child: _open ? Transform.rotate(angle: math.pi / 4, child: const Ic(IconName.plus, size: 20, color: FC.gold)) : const Ic(IconName.menu, size: 20, color: FC.gold),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _item(int i, double w) {
    final e = kMenuEntries[i];
    final active = widget.current == e.screen;
    return SizedBox(
      width: w,
      child: Tap(
        onTap: () {
          setState(() => _open = false);
          widget.go(e.screen, root: true);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: active ? al(FC.gold, .08) : FC.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? FC.gold : FC.line)),
          child: Row(children: [
            Text((i + 1).toString().padLeft(2, '0'), style: fs(8.32, color: FC.dim, h: 1.2)),
            const SizedBox(width: 7),
            Expanded(child: Text(e.label, style: fs(9.92, color: active ? FC.gold : FC.muted, w: FontWeight.w700, h: 1.25))),
            if (active) const Ic(IconName.check, size: 14, color: FC.gold),
          ]),
        ),
      ),
    );
  }
}
