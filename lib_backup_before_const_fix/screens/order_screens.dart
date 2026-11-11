import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/core.dart';
import 'sheets.dart';

Widget _stepIntro(String step, String title, {String? body}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FcText(step, kind: Tx.label, color: FC.gold),
      const SizedBox(height: 9),
      FcText(title, kind: Tx.title),
      if (body != null) ...[const SizedBox(height: 9), FcText(body, color: FC.muted)],
    ]);

// ===========================================================================
// Fuel
// ===========================================================================
class FuelScreen extends StatefulWidget {
  final Go go;
  const FuelScreen({super.key, required this.go});
  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  Widget _round(IconName icon, VoidCallback onTap) => Tap(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF191914), border: Border.all(color: const Color(0xFF4F4627))),
          child: Center(child: Ic(icon, color: FC.gold)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = app.litres;
    return AppPage(
      header: PageHeader(title: 'Build your order', goBack: () => app.backOr(Screen.station)),
      body: Narrow(gap: 22, children: [
        _stepIntro('STEP 1 OF 4 · FUEL', 'Select fuel type'),
        Row(children: [
          for (final f in ['Petrol', 'Diesel', 'Power'])
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: f == 'Power' ? 0 : 9),
                child: Tap(
                  onTap: () => setState(() => app.fuelType = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
                    decoration: BoxDecoration(
                      color: app.fuelType == f ? al(FC.gold, .07) : FC.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: app.fuelType == f ? FC.gold : FC.line),
                    ),
                    child: Column(children: [
                      Ic(f == 'Power' ? IconName.drop : IconName.fuel, color: app.fuelType == f ? FC.gold : FC.muted),
                      const SizedBox(height: 7),
                      FcText(f, kind: Tx.label, color: app.fuelType == f ? FC.gold : FC.ink),
                      const SizedBox(height: 7),
                      FcText('UGX ${fmt(AppState.prices[f]!)}/L', kind: Tx.caption, color: FC.muted),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              FcText('QUANTITY', kind: Tx.label),
              FcText('How much should we deliver?', kind: Tx.caption, color: FC.muted),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _round(IconName.minus, () => setState(() => app.litres = math.max(5, l - 5))),
              Column(children: [
                Text('$l', style: fs(41.6, w: FontWeight.w700, h: 1.1, ls: -1)),
                Text('litres', style: fs(10.4, color: FC.muted)),
              ]),
              _round(IconName.plus, () => setState(() => app.litres = math.min(100, l + 5))),
            ]),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(value: l / 100, minHeight: 5, backgroundColor: FC.line, valueColor: const AlwaysStoppedAnimation(FC.gold)),
            ),
            Row(children: [
              for (final a in [15, 25, 35, 50])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: a == 50 ? 0 : 7),
                    child: Tap(
                      onTap: () => setState(() => app.litres = a),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFF0D0F12), borderRadius: BorderRadius.circular(9), border: Border.all(color: l == a ? FC.gold : FC.line)),
                        child: Text('${a}L', style: fs(10.4, color: l == a ? FC.gold : FC.muted, h: 1.3)),
                      ),
                    ),
                  ),
                ),
            ]),
          ], 20)),
        ),
        const SafetyNote(title: 'Certified safe delivery', body: 'Delivered in sealed, metered equipment by trained partners.'),
        Container(
          padding: const EdgeInsets.only(top: 20),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: FC.line))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FcText('Estimated fuel total', kind: Tx.caption, color: FC.muted),
                FcText('UGX ${fmt(app.fuelTotal)}', kind: Tx.title),
              ]),
            ),
            FcButton('Continue', expand: false, trailingIcon: IconName.arrow, onTap: () => widget.go(Screen.vehicle)),
          ]),
        ),
      ]),
    );
  }
}

// ===========================================================================
// Vehicle
// ===========================================================================
class VehicleScreen extends StatefulWidget {
  final Go go;
  const VehicleScreen({super.key, required this.go});
  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class VehicleTile extends StatelessWidget {
  final Vehicle v;
  final bool selected;
  final String caption;
  final Widget trailing;
  final VoidCallback onTap;
  const VehicleTile({super.key, required this.v, required this.selected, required this.caption, required this.trailing, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: selected ? al(FC.gold, .06) : FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? FC.gold : FC.line)),
          child: Row(children: [
            Container(
              width: 58,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF353A40), Color(0xFF171A1D)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(v.visual, style: fs(8.8, color: FC.gold, w: FontWeight.w900, ls: .7, h: 1)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText(v.name, kind: Tx.subtitle), FcText(caption, kind: Tx.caption, color: FC.muted)])),
            const SizedBox(width: 12),
            trailing,
          ]),
        ),
      );
}

class _VehicleScreenState extends State<VehicleScreen> {
  @override
  Widget build(BuildContext context) {
    final v = app.selectedVehicle;
    final ok = app.fuelClass(app.fuelType) == v.fuel;
    return AppPage(
      header: PageHeader(title: 'Select vehicle', goBack: () => app.backOr(Screen.fuel)),
      body: Narrow(gap: 20, children: [
        _stepIntro('STEP 2 OF 4 · VEHICLE', 'Which vehicle are we fueling?', body: 'This helps your delivery partner identify you and confirm the correct fuel type.'),
        Column(children: gapped([
          for (final x in app.vehicles)
            VehicleTile(v: x, selected: x.id == v.id, caption: x.selectCaption, trailing: RadioDot(selected: x.id == v.id), onTap: () => setState(() => app.vehicleId = x.id)),
        ], 10)),
        Align(
          alignment: Alignment.centerLeft,
          child: Tap(
            onTap: () async {
              final added = await showAddVehicleSheet(context);
              if (added == true && mounted) setState(() => app.vehicleId = app.vehicles.last.id);
            },
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Ic(IconName.plus, color: FC.gold),
              const SizedBox(width: 6),
              Text('Add another vehicle', style: fs(11.2, color: FC.gold, w: FontWeight.w700)),
            ])),
          ),
        ),
        ok
            ? SafetyNote(title: 'Fuel compatibility check', body: 'Selected vehicle uses ${v.fuel.toLowerCase()}. Your order is compatible.')
            : Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: al(FC.danger, .06), borderRadius: BorderRadius.circular(12), border: Border.all(color: al(FC.danger, .25))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Ic(IconName.shield, color: FC.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const FcText('Fuel compatibility check', kind: Tx.label, color: FC.danger),
                      const SizedBox(height: 3),
                      FcText('Selected vehicle uses ${v.fuel.toLowerCase()}, but your order is ${app.fuelType.toLowerCase()}. Change the fuel or pick another vehicle.', kind: Tx.caption, color: FC.muted),
                    ]),
                  ),
                ]),
              ),
        FcButton('Confirm vehicle', onTap: ok ? () => widget.go(Screen.checkout) : null),
      ]),
    );
  }
}

// ===========================================================================
// Delivery details
// ===========================================================================
class CheckoutScreen extends StatefulWidget {
  final Go go;
  const CheckoutScreen({super.key, required this.go});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final _note = TextEditingController(text: app.deliveryNote);

  @override
  void dispose() {
    app.deliveryNote = _note.text;
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: app.scheduledAt ?? TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))));
    if (t != null && mounted) {
      setState(() {
        app.scheduled = true;
        app.scheduledAt = t;
      });
    }
  }

  Widget _choice(IconName icon, String title, String sub, bool active, VoidCallback onTap) => Expanded(
        child: Tap(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: active ? al(FC.gold, .06) : FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? FC.gold : FC.line)),
            child: Row(children: [
              Ic(icon, color: active ? FC.gold : FC.muted),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [FcText(title, kind: Tx.label, color: active ? FC.gold : FC.ink), FcText(sub, kind: Tx.caption, color: FC.muted)])),
            ]),
          ),
        ),
      );

  Widget _map(BuildContext context) => Container(
        height: 265,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF15191C), borderRadius: BorderRadius.circular(18), border: Border.all(color: FC.line)),
        child: LayoutBuilder(builder: (c, cons) {
          final w = cons.maxWidth, h = cons.maxHeight;
          return Stack(children: [
            const Positioned.fill(child: MapGrid(bg: Color(0xFF15191C))),
            Positioned(
              left: w * .33,
              top: h * .20,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..multiply(Matrix4.skewX(-25 * math.pi / 180))
                  ..multiply(Matrix4.rotationZ(-10 * math.pi / 180)),
                child: const RouteLine(width: 150, height: 90, stroke: 4, radius: 24),
              ),
            ),
            Positioned(
              left: w * .54,
              top: h * .27,
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: FC.gold,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(21), topRight: Radius.circular(21), bottomRight: Radius.circular(21), bottomLeft: Radius.circular(4)),
                    boxShadow: [BoxShadow(color: al(FC.gold, .12), spreadRadius: 7)],
                  ),
                  child: Transform.rotate(angle: math.pi / 4, child: const Center(child: Ic(IconName.location, color: FC.onGold))),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Tap(
                onTap: () async {
                  await showAddressSheet(context);
                  if (mounted) setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(color: const Color(0xEB0C0E11), borderRadius: BorderRadius.circular(12), border: Border.all(color: FC.line)),
                  child: Row(children: [
                    const Ic(IconName.location, size: 17, color: FC.gold),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const FcText('DELIVERY LOCATION', kind: Tx.caption, color: FC.muted),
                      FcText(app.deliveryAddress, kind: Tx.label, maxLines: 1),
                    ])),
                    const Ic(IconName.chevron, size: 16, color: FC.muted),
                  ]),
                ),
              ),
            ),
          ]);
        }),
      );

  @override
  Widget build(BuildContext context) {
    final nowSel = !app.scheduled;
    final sched = app.scheduledAt == null ? 'Choose a time' : 'Today, ${MaterialLocalizations.of(context).formatTimeOfDay(app.scheduledAt!)}';
    return AppPage(
      header: PageHeader(title: 'Delivery details', goBack: () => app.backOr(Screen.vehicle)),
      body: Narrow(gap: 22, children: [
        _stepIntro('STEP 3 OF 4 · DELIVERY', 'Where should we meet you?'),
        _map(context),
        const FcText('Delivery time', kind: Tx.subtitle),
        Row(children: [
          _choice(IconName.clock, 'Deliver now', '18–24 min', nowSel, () => setState(() => app.scheduled = false)),
          const SizedBox(width: 10),
          _choice(IconName.calendar, 'Schedule', sched, !nowSel, _pickTime),
        ]),
        FcField(label: 'Delivery note (optional)', hint: 'Vehicle color, parking level...', controller: _note, onChanged: (v) => app.deliveryNote = v),
        Container(
          padding: const EdgeInsets.only(top: 18),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: FC.line))),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/images/station-hero.jpg', width: 48, height: 48, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FcText('Stabex Kira Road', kind: Tx.label),
              FcText('${app.productName} · ${app.litres} litres', kind: Tx.caption, color: FC.muted),
            ])),
            FcText('UGX ${fmt(app.fuelTotal)}', kind: Tx.subtitle),
          ]),
        ),
        FcButton('Review payment', onTap: () => widget.go(Screen.payment)),
      ]),
    );
  }
}

// ===========================================================================
// Payment
// ===========================================================================
class PaymentScreen extends StatefulWidget {
  final Go go;
  const PaymentScreen({super.key, required this.go});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _busy = false;

  Widget _icon(PayMethod m) => Container(
        width: 44,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: m.badgeBg ?? const Color(0xFF252930), borderRadius: BorderRadius.circular(8)),
        child: m.icon != null ? Ic(m.icon!) : Text(m.badge, style: fs(10.4, color: m.badgeFg ?? FC.ink, w: FontWeight.w800, h: 1)),
      );

  Future<void> _pay() async {
    final err = app.charge();
    if (err != null) {
      toast(context, err);
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _busy = false);
    widget.go(Screen.tracking);
  }

  @override
  Widget build(BuildContext context) {
    final total = app.orderTotal;
    return AppPage(
      header: PageHeader(title: 'Payment', goBack: () => app.backOr(Screen.checkout)),
      body: Narrow(gap: 22, children: [
        _stepIntro('STEP 4 OF 4 · PAYMENT', 'Choose payment method'),
        Column(children: gapped([
          for (final m in app.payMethods)
            Tap(
              onTap: () => setState(() => app.payId = m.id),
              child: Container(
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: app.payId == m.id ? al(FC.gold, .05) : FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: app.payId == m.id ? FC.gold : FC.line)),
                child: Row(children: [
                  _icon(m),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FcText(m.title, kind: Tx.label),
                    FcText(m.id == 'wallet' ? 'Balance UGX ${fmt(app.walletBalance)}' : m.caption, kind: Tx.caption, color: FC.muted),
                  ])),
                  RadioDot(selected: app.payId == m.id),
                ]),
              ),
            ),
        ], 10)),
        Align(
          alignment: Alignment.centerLeft,
          child: Tap(
            onTap: () async {
              final ok = await showAddPaySheet(context);
              if (ok == true && mounted) setState(() => app.payId = app.payMethods.last.id);
            },
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Ic(IconName.plus, color: FC.gold),
              const SizedBox(width: 6),
              Text('Add new payment method', style: fs(11.2, color: FC.gold, w: FontWeight.w700)),
            ])),
          ),
        ),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
            const FcText('Order summary', kind: Tx.subtitle),
            KvRow('${app.productName} · ${app.litres}L', 'UGX ${fmt(app.fuelTotal)}'),
            KvRow('Delivery fee', 'UGX ${fmt(AppState.deliveryFee)}'),
            KvRow('Service fee', 'UGX ${fmt(AppState.serviceFee)}'),
            TotalRow('Total', 'UGX ${fmt(total)}'),
          ], 13)),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Ic(IconName.shield, size: 16, color: FC.green),
          SizedBox(width: 6),
          FcText('Encrypted and protected payment', kind: Tx.caption, color: FC.muted),
        ]),
        FcButton('Confirm & pay UGX ${fmt(total)}', loading: _busy, onTap: _pay),
      ]),
    );
  }
}

// ===========================================================================
// Live tracking
// ===========================================================================
class TrackingScreen extends StatefulWidget {
  final Go go;
  const TrackingScreen({super.key, required this.go});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  int _p = 1;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (mounted) setState(() => _p = math.min(3, _p + 1));
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Widget _map(BuildContext context) {
    return Container(
      color: const Color(0xFF13171A),
      child: LayoutBuilder(builder: (c, cons) {
        final w = cons.maxWidth, h = cons.maxHeight;
        final pos = [const Offset(.56, .25), const Offset(.56, .25), const Offset(.43, .42), const Offset(.34, .54)][_p];
        return ClipRect(
          child: Stack(children: [
            const Positioned.fill(child: MapGrid()),
            Positioned(
              left: -w * .15,
              top: h * .45,
              width: w * 1.3,
              height: 22,
              child: Transform.rotate(angle: -12 * math.pi / 180, child: Container(decoration: const BoxDecoration(color: Color(0xFF2C3034), boxShadow: [BoxShadow(color: Color(0xFF1B1F23), spreadRadius: 8)]))),
            ),
            Positioned(
              left: w * .57,
              top: -h * .05,
              width: 22,
              height: h * 1.1,
              child: Transform.rotate(angle: 16 * math.pi / 180, child: Container(decoration: const BoxDecoration(color: Color(0xFF2C3034), boxShadow: [BoxShadow(color: Color(0xFF1B1F23), spreadRadius: 8)]))),
            ),
            Positioned(left: w * .30, top: h * .27, child: Transform.rotate(angle: -12 * math.pi / 180, child: const RouteLine(width: 190, height: 115, stroke: 5, dotted: true))),
            Positioned(
              left: w * .27,
              top: h * .62,
              child: Container(width: 43, height: 43, decoration: const BoxDecoration(shape: BoxShape.circle, color: FC.ink), child: const Center(child: Ic(IconName.location, color: Color(0xFF111111)))),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              left: w * pos.dx,
              top: h * pos.dy,
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(shape: BoxShape.circle, color: FC.gold, boxShadow: [BoxShadow(color: al(FC.gold, .12), spreadRadius: 8)]),
                child: const Center(child: Ic(IconName.truck, color: Color(0xFF111111))),
              ),
            ),
            Positioned(
              top: topInset(context) + 17,
              left: 18,
              right: 18,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                FcButton.icon(IconName.arrow, onTap: () => widget.go(Screen.home, root: true)),
                Text('Live order', style: fs(12, w: FontWeight.w700)),
                const SizedBox(width: 42), // the global top-right menu icon sits here
              ]),
            ),
          ]),
        );
      }),
    );
  }

  Widget _timelineItem(String label, int i, bool last) {
    final done = i <= _p;
    final check = i < _p;
    return SizedBox(
      height: 38,
      child: Stack(children: [
        if (!last) Positioned(left: 10, top: 20, child: Container(width: 1, height: 22, color: FC.line)),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 28,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 21,
                height: 21,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: done ? FC.gold : null, border: Border.all(color: done ? FC.gold : FC.dim)),
                child: check ? const Ic(IconName.check, size: 13, color: Color(0xFF111111)) : Text('${i + 1}', style: fs(8.8, color: done ? const Color(0xFF111111) : FC.dim, h: 1)),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Padding(padding: const EdgeInsets.only(top: 3), child: FcText(label, kind: Tx.label, color: done ? FC.ink : FC.dim)),
        ]),
      ]),
    );
  }

  Widget _sheet(BuildContext context, {required bool handle}) {
    const steps = ['Order confirmed', 'Fuel collected', 'Arriving at your location', 'Delivery complete'];
    final title = _p == 1 ? 'Fuel is on the way' : (_p == 2 ? 'Your driver is nearby' : 'Driver has arrived');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
      if (handle) Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: FC.line, borderRadius: BorderRadius.circular(4)))),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const LivePill('LIVE'),
            const SizedBox(height: 8),
            FcText(title, kind: Tx.title),
            FcText(_p == 3 ? 'Meet your driver at the delivery point.' : 'Estimated arrival in 12–16 minutes', kind: Tx.caption, color: FC.muted),
          ]),
        ),
        const SizedBox(width: 12),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4D4321))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_p == 3 ? '0' : (_p == 2 ? '5' : '14'), style: fs(22.4, color: FC.gold, w: FontWeight.w700, h: 1)),
            Text('MIN', style: fs(7.68, color: FC.gold, w: FontWeight.w800, h: 1.2)),
          ]),
        ),
      ]),
      Panel(
        radius: 12,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 44, height: 44, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: FC.gold), child: Text('MK', style: fs(12, color: const Color(0xFF111111), w: FontWeight.w800, h: 1))),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText('Marcus K.', kind: Tx.label), FcText('Certified delivery partner · 4.9', kind: Tx.caption, color: FC.muted)])),
          FcButton.icon(IconName.phone, onTap: () => toast(context, 'Calling Marcus K. will work once the backend shares driver contact details.')),
        ]),
      ),
      Column(children: [for (var i = 0; i < steps.length; i++) _timelineItem(steps[i], i, i == steps.length - 1)]),
      _p == 3
          ? FcButton('Confirm delivery', onTap: () {
              app.completeDelivery();
              widget.go(Screen.success, replace: true);
            })
          : FcButton('Preview arrival', variant: BV.outline, onTap: () => setState(() => _p = 3)),
    ], 18));
  }

  @override
  Widget build(BuildContext context) {
    final pad = cl(context, 20, 6, 54);
    if (isWide(context)) {
      return ColoredBox(
        color: FC.black,
        child: Row(children: [
          Expanded(flex: 56, child: _map(context)),
          Expanded(
            flex: 44,
            child: LayoutBuilder(builder: (c, cons) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: cons.maxHeight),
                    child: Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: vw(context) * .05, vertical: vh(context) * .08), child: _sheet(context, handle: false))),
                  ),
                )),
          ),
        ]),
      );
    }
    final mapH = vh(context) * .5;
    return ColoredBox(
      color: FC.black,
      child: Stack(children: [
        Positioned(left: 0, right: 0, top: 0, height: mapH, child: _map(context)),
        Positioned.fill(
          child: SingleChildScrollView(
            child: Column(children: [
              SizedBox(height: mapH - 25),
              Container(
                constraints: BoxConstraints(minHeight: vh(context) - (mapH - 25)),
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 34 + bottomInset(context)),
                decoration: const BoxDecoration(color: FC.black, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: _sheet(context, handle: true),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ===========================================================================
// Delivery complete
// ===========================================================================
class SuccessScreen extends StatefulWidget {
  final Go go;
  const SuccessScreen({super.key, required this.go});
  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    final pad = cl(context, 22, 6, 50);
    return ColoredBox(
      color: FC.black,
      child: Stack(children: [
        const Positioned.fill(child: Glow(fx: .5, fy: .18, colors: [Color(0x14F5C72E), Color(0x00F5C72E)], stops: [0, .30])),
        SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, vh(context) * .09 + topInset(context), pad, 40 + bottomInset(context)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
                  Center(
                    child: Container(
                      width: 132,
                      height: 132,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: al(FC.gold, .13)),
                        boxShadow: [BoxShadow(color: al(FC.gold, .025), spreadRadius: 18), BoxShadow(color: al(FC.gold, .015), spreadRadius: 36)],
                      ),
                      child: Center(
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: FC.gold, boxShadow: [BoxShadow(color: al(FC.gold, .18), blurRadius: 45, offset: const Offset(0, 14))]),
                          child: const Center(child: Ic(IconName.check, size: 44, color: Color(0xFF111111))),
                        ),
                      ),
                    ),
                  ),
                  const FcText('Delivery complete.', kind: Tx.display, align: TextAlign.center),
                  FcText('${app.litres} litres of ${app.productName.toLowerCase()} were delivered safely to your location.', color: FC.muted, align: TextAlign.center),
                  Panel(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: gapped([
                      const KvRow('Order ID', '#FC-29841', size: 10.88),
                      KvRow('Total paid', 'UGX ${fmt(app.orderTotal)}', size: 10.88),
                      KvRow('Payment', app.selectedPay.title, size: 10.88),
                    ], 11)),
                  ),
                  const FcText('How was your delivery?', kind: Tx.subtitle, align: TextAlign.center),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var s = 1; s <= 5; s++)
                      Tap(
                        onTap: () => setState(() => _rating = s),
                        child: Padding(padding: EdgeInsets.only(left: s == 1 ? 0 : 9), child: Ic(IconName.star, size: 26, color: FC.gold, filled: s <= _rating)),
                      ),
                  ]),
                  FcButton('Back to home', onTap: () => widget.go(Screen.home, root: true)),
                  FcButton('View receipt', variant: BV.ghost, onTap: () => widget.go(Screen.orders, root: true)),
                ], 19)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ===========================================================================
// Cancel order (NEW)
// ===========================================================================
class CancelOrderScreen extends StatefulWidget {
  final Go go;
  const CancelOrderScreen({super.key, required this.go});
  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  static const int _cancelFee = 8000;
  static const _reasons = [
    'Delivery is taking too long',
    'I changed my mind',
    'Incorrect delivery location',
    'Ordered the wrong fuel or quantity',
    'Other reason',
  ];

  String _reason = '';
  bool _cancelled = false;

  @override
  Widget build(BuildContext context) => _cancelled ? _done(context) : _form(context);

  // ---------------------------------------------------------------- form
  Widget _form(BuildContext context) {
    final paid = app.orderTotal;
    final refund = paid - _cancelFee;
    return AppPage(
      header: PageHeader(title: 'Cancel order', goBack: () => widget.go(Screen.tracking)),
      body: Narrow(gap: 20, children: [
        // order summary
        Panel(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: al(FC.gold, .08), border: Border.all(color: FC.gold)),
              child: const Center(child: Ic(IconName.truck, color: FC.gold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const LivePill('ON THE WAY'),
                const SizedBox(height: 6),
                FcText('${app.productName} · ${app.litres}L', kind: Tx.subtitle),
                const FcText('Stabex Kira Road · Order #FC-29841', kind: Tx.caption, color: FC.muted),
              ]),
            ),
            const FcText('12–16 min', kind: Tx.label, color: FC.gold),
          ]),
        ),

        // intro
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          FcText('CANCEL DELIVERY', kind: Tx.label, color: FC.gold),
          SizedBox(height: 9),
          FcText('Why are you cancelling?', kind: Tx.title),
          SizedBox(height: 9),
          FcText('Your feedback helps us improve the FuelConnect experience.', color: FC.muted),
        ]),

        // reasons
        Column(
          children: gapped([
            for (final r in _reasons)
              Tap(
                onTap: () => setState(() => _reason = r),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _reason == r ? al(FC.gold, .06) : FC.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _reason == r ? FC.gold : FC.line),
                  ),
                  child: Row(children: [
                    RadioDot(selected: _reason == r),
                    const SizedBox(width: 12),
                    Expanded(child: FcText(r, kind: Tx.label, color: _reason == r ? FC.gold : FC.ink)),
                  ]),
                ),
              ),
          ], 10),
        ),

        // fee warning
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: al(FC.danger, .06), borderRadius: BorderRadius.circular(12), border: Border.all(color: al(FC.danger, .25))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Ic(IconName.shield, color: FC.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FcText('Your fuel has already been collected', kind: Tx.label, color: FC.danger),
                const SizedBox(height: 3),
                FcText(
                  'A UGX ${fmt(_cancelFee)} cancellation fee applies because your delivery partner has collected the fuel and started the trip.',
                  kind: Tx.caption,
                  color: FC.muted,
                ),
              ]),
            ),
          ]),
        ),

        // refund summary
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
            const FcText('Refund summary', kind: Tx.subtitle),
            KvRow('Amount paid', 'UGX ${fmt(paid)}'),
            KvRow('Cancellation fee', '− UGX ${fmt(_cancelFee)}'),
            TotalRow('You’ll receive', 'UGX ${fmt(refund)}'),
            FcText('Refunded to ${app.selectedPay.title} within 24 hours.', kind: Tx.caption, color: FC.muted),
          ], 13)),
        ),

        FcButton('Confirm cancellation', onTap: _reason.isEmpty ? null : () => setState(() => _cancelled = true)),
        FcButton('Keep my order', variant: BV.outline, onTap: () => widget.go(Screen.tracking)),
        const FcText('Need help instead? Contact FuelConnect support.', kind: Tx.caption, color: FC.muted, align: TextAlign.center),
      ]),
    );
  }

  // ---------------------------------------------------------- cancelled
  Widget _done(BuildContext context) {
    final pad = cl(context, 22, 6, 50);
    final refund = app.orderTotal - _cancelFee;
    return ColoredBox(
      color: FC.black,
      child: Stack(children: [
        const Positioned.fill(child: Glow(fx: .5, fy: .18, colors: [Color(0x14F5C72E), Color(0x00F5C72E)], stops: [0, .30])),
        SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, vh(context) * .09 + topInset(context), pad, 40 + bottomInset(context)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
                  Center(
                    child: Container(
                      width: 132,
                      height: 132,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: al(FC.gold, .13)),
                        boxShadow: [BoxShadow(color: al(FC.gold, .025), spreadRadius: 18), BoxShadow(color: al(FC.gold, .015), spreadRadius: 36)],
                      ),
                      child: Center(
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: FC.gold, boxShadow: [BoxShadow(color: al(FC.gold, .18), blurRadius: 45, offset: const Offset(0, 14))]),
                          child: const Center(child: Ic(IconName.minus, size: 40, color: Color(0xFF111111))),
                        ),
                      ),
                    ),
                  ),
                  const FcText('ORDER CANCELLED', kind: Tx.label, color: FC.gold, align: TextAlign.center),
                  const FcText('Your order has been cancelled.', kind: Tx.display, align: TextAlign.center),
                  const FcText(
                    'We’ve notified Stabex Kira Road and your delivery partner. Your refund is being processed.',
                    color: FC.muted,
                    align: TextAlign.center,
                  ),
                  Panel(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: gapped([
                      const KvRow('Order ID', '#FC-29841', size: 10.88),
                      KvRow('Refund amount', 'UGX ${fmt(refund)}', size: 10.88),
                      KvRow('Refund method', app.selectedPay.title, size: 10.88),
                      const KvRow('Expected refund', 'Within 24 hours', size: 10.88),
                    ], 11)),
                  ),
                  Panel(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      const Ic(IconName.clock, color: FC.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                          FcText('Refund in progress', kind: Tx.label),
                          FcText('We’ll send a notification when the refund is complete.', kind: Tx.caption, color: FC.muted),
                        ]),
                      ),
                    ]),
                  ),
                  FcButton('Back to home', onTap: () => widget.go(Screen.home, root: true)),
                  FcButton('View my orders', variant: BV.ghost, onTap: () => widget.go(Screen.orders, root: true)),
                ], 19)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}