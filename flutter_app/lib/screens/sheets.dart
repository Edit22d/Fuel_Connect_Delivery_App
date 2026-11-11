import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/core.dart';
import '../services/auth_service.dart';

// ---------------------------------------------------------------------------
// Location (home pill / manual entry)
// ---------------------------------------------------------------------------
Future<bool?> showLocationSheet(BuildContext context) => showFcSheet<bool>(
      context,
      title: 'Where are you?',
      builder: (ctx) => const _LocationForm(),
    );

class _LocationForm extends StatefulWidget {
  const _LocationForm();
  @override
  State<_LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<_LocationForm> {
  final _c = TextEditingController();
  String? _err;
  static const _presets = ['Kololo, Kampala', 'Bukoto, Kampala', 'Ntinda, Kampala', 'Nakasero, Kampala', 'Muyenga, Kampala'];

  void _save(String v) {
    if (v.trim().length < 3) {
      setState(() => _err = 'Enter an area or street');
      return;
    }
    app.location = v.trim();
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in _presets)
            Tap(
              onTap: () => _save(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(color: FC.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: p == app.location ? FC.gold : FC.line)),
                child: Text(p, style: fs(10.88, color: p == app.location ? FC.gold : FC.muted)),
              ),
            ),
        ]),
        const SizedBox(height: 18),
        FcField(label: 'Area or street', hint: 'e.g. Bukoto Street, Kampala', icon: IconName.location, controller: _c, error: _err, action: TextInputAction.done, onSubmitted: _save),
        const SizedBox(height: 18),
        FcButton('Save location', onTap: () => _save(_c.text)),
      ]);
}

// ---------------------------------------------------------------------------
// Delivery address (checkout)
// ---------------------------------------------------------------------------
Future<bool?> showAddressSheet(BuildContext context) => showFcSheet<bool>(
      context,
      title: 'Delivery location',
      builder: (ctx) => const _AddressForm(),
    );

class _AddressForm extends StatefulWidget {
  const _AddressForm();
  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _c = TextEditingController();
  String? _err;

  void _set(String v) {
    if (v.trim().length < 3) {
      setState(() => _err = 'Enter a delivery address');
      return;
    }
    app.deliveryAddress = v.trim();
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FcText('SAVED PLACES', kind: Tx.label, color: FC.gold),
        const SizedBox(height: 10),
        for (final p in app.places)
          Tap(
            onTap: () => _set(p.address),
            child: Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.address == app.deliveryAddress ? al(FC.gold, .06) : FC.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.address == app.deliveryAddress ? FC.gold : FC.line),
              ),
              child: Row(children: [
                const IconBox(IconName.location),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText(p.label, kind: Tx.label), FcText(p.address, kind: Tx.caption, color: FC.muted)])),
              ]),
            ),
          ),
        const SizedBox(height: 9),
        FcField(label: 'Or type an address', hint: 'Street, building, landmark', icon: IconName.search, controller: _c, error: _err, action: TextInputAction.done, onSubmitted: _set),
        const SizedBox(height: 18),
        FcButton('Use this address', onTap: () => _set(_c.text)),
      ]);
}

// ---------------------------------------------------------------------------
// Add saved place
// ---------------------------------------------------------------------------
Future<bool?> showAddPlaceSheet(BuildContext context) => showFcSheet<bool>(context, title: 'Add a new place', builder: (ctx) => const _PlaceForm());

class _PlaceForm extends StatefulWidget {
  const _PlaceForm();
  @override
  State<_PlaceForm> createState() => _PlaceFormState();
}

class _PlaceFormState extends State<_PlaceForm> {
  final _l = TextEditingController();
  final _a = TextEditingController();
  String? _le, _ae;

  void _save() {
    setState(() {
      _le = _l.text.trim().isEmpty ? 'Give this place a name' : null;
      _ae = _a.text.trim().length < 3 ? 'Enter the address' : null;
    });
    if (_le != null || _ae != null) return;
    app.places.add(Place(_l.text.trim(), _a.text.trim()));
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _l.dispose();
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FcField(label: 'Name', hint: 'Home, Office, Gym…', icon: IconName.star, controller: _l, error: _le, action: TextInputAction.next),
        const SizedBox(height: 16),
        FcField(label: 'Address', hint: 'Street, building, landmark', icon: IconName.location, controller: _a, error: _ae, action: TextInputAction.done, onSubmitted: (_) => _save()),
        const SizedBox(height: 18),
        FcButton('Save place', onTap: _save),
      ]);
}

// ---------------------------------------------------------------------------
// Add vehicle
// ---------------------------------------------------------------------------
Future<bool?> showAddVehicleSheet(BuildContext context) => showFcSheet<bool>(context, title: 'Add vehicle', builder: (ctx) => const _VehicleForm());

class _VehicleForm extends StatefulWidget {
  const _VehicleForm();
  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _n = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  final _t = TextEditingController();
  String _fuel = 'Petrol';
  String? _ne, _pe;

  void _save() {
    setState(() {
      _ne = _n.text.trim().length < 2 ? 'Enter the make and model' : null;
      _pe = _p.text.trim().length < 4 ? 'Enter the number plate' : null;
    });
    if (_ne != null || _pe != null) return;
    final name = _n.text.trim();
    final tank = _t.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    app.vehicles.add(Vehicle(
      id: 'v${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      plate: _p.text.trim().toUpperCase(),
      fuel: _fuel,
      color: _c.text.trim(),
      tank: tank.isEmpty ? '' : '${tank}L',
      visual: name.split(' ').last.toUpperCase().substring(0, name.split(' ').last.length.clamp(1, 5).toInt()),
    ));
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _n.dispose();
    _p.dispose();
    _c.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FcField(label: 'Make & model', hint: 'Toyota Prado', icon: IconName.truck, controller: _n, error: _ne, action: TextInputAction.next),
        const SizedBox(height: 14),
        FcField(label: 'Number plate', hint: 'UBA 123X', icon: IconName.card, controller: _p, error: _pe, action: TextInputAction.next, formatters: [LengthLimitingTextInputFormatter(10)]),
        const SizedBox(height: 14),
        const FcText('FUEL TYPE', kind: Tx.label, color: Color(0xFFC7C8C9)),
        const SizedBox(height: 8),
        Row(children: [
          for (final f in ['Petrol', 'Diesel'])
            Expanded(
              child: Tap(
                onTap: () => setState(() => _fuel = f),
                child: Container(
                  margin: EdgeInsets.only(right: f == 'Petrol' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _fuel == f ? al(FC.gold, .07) : FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _fuel == f ? FC.gold : FC.line)),
                  child: Text(f, style: fs(11.52, color: _fuel == f ? FC.gold : FC.muted, w: FontWeight.w700)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: FcField(label: 'Colour (optional)', hint: 'Black', controller: _c, action: TextInputAction.next)),
          const SizedBox(width: 12),
          Expanded(child: FcField(label: 'Tank, litres', hint: '60', controller: _t, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)])),
        ]),
        const SizedBox(height: 18),
        FcButton('Add vehicle', onTap: _save),
      ]);
}

// ---------------------------------------------------------------------------
// Wallet top up
// ---------------------------------------------------------------------------
Future<bool?> showTopUpSheet(BuildContext context) => showFcSheet<bool>(context, title: 'Top up wallet', builder: (ctx) => const _TopUpForm());

class _TopUpForm extends StatefulWidget {
  const _TopUpForm();
  @override
  State<_TopUpForm> createState() => _TopUpFormState();
}

class _TopUpFormState extends State<_TopUpForm> {
  final _c = TextEditingController();
  String? _err;
  static const _presets = [50000, 100000, 200000, 500000];

  void _go() {
    final v = int.tryParse(_c.text.replaceAll(',', '')) ?? 0;
    if (v < 5000) {
      setState(() => _err = 'Minimum top up is UGX 5,000');
      return;
    }
    if (v > 5000000) {
      setState(() => _err = 'Maximum top up is UGX 5,000,000');
      return;
    }
    app.topUp(v);
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          for (final p in _presets)
            Expanded(
              child: Tap(
                onTap: () => setState(() => _c.text = p.toString()),
                child: Container(
                  margin: const EdgeInsets.only(right: 7),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFF0D0F12), borderRadius: BorderRadius.circular(9), border: Border.all(color: _c.text == p.toString() ? FC.gold : FC.line)),
                  child: Text('${p ~/ 1000}K', style: fs(10.4, color: _c.text == p.toString() ? FC.gold : FC.muted)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        FcField(label: 'Amount (UGX)', hint: 'Enter amount', icon: IconName.wallet, controller: _c, keyboard: TextInputType.number, error: _err, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)], onChanged: (_) => setState(() => _err = null), action: TextInputAction.done, onSubmitted: (_) => _go()),
        const SizedBox(height: 8),
        FcText('Charged to MTN Mobile Money +256 700 ••• 456', kind: Tx.caption, color: FC.muted),
        const SizedBox(height: 18),
        FcButton('Top up', onTap: _go),
      ]);
}

// ---------------------------------------------------------------------------
// Edit profile
// ---------------------------------------------------------------------------
Future<bool?> showEditProfileSheet(BuildContext context) => showFcSheet<bool>(context, title: 'Personal details', builder: (ctx) => const _ProfileForm());

class _ProfileForm extends StatefulWidget {
  const _ProfileForm();
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final _n = TextEditingController(text: auth.profile.name);
  late final _e = TextEditingController(text: auth.profile.email);
  String? _ne, _ee;

  Future<void> _save() async {
    setState(() {
      _ne = Validators.name(_n.text);
      _ee = Validators.email(_e.text);
    });
    if (_ne != null || _ee != null) return;
    await auth.updateProfile(_n.text.trim(), _e.text.trim());
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _n.dispose();
    _e.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FcField(label: 'Full name', hint: 'Joel Kato', icon: IconName.profile, controller: _n, error: _ne, action: TextInputAction.next),
        const SizedBox(height: 14),
        FcField(label: 'Email address', hint: 'you@example.com', icon: IconName.orders, controller: _e, keyboard: TextInputType.emailAddress, error: _ee, action: TextInputAction.done, onSubmitted: (_) => _save()),
        const SizedBox(height: 8),
        FcText('Phone: ${maskPhone(auth.profile.phone)}', kind: Tx.caption, color: FC.muted),
        const SizedBox(height: 18),
        FcButton('Save changes', onTap: _save),
      ]);
}

// ---------------------------------------------------------------------------
// Add mobile-money method
// ---------------------------------------------------------------------------
Future<bool?> showAddPaySheet(BuildContext context) => showFcSheet<bool>(context, title: 'Add payment method', builder: (ctx) => const _PayForm());

class _PayForm extends StatefulWidget {
  const _PayForm();
  @override
  State<_PayForm> createState() => _PayFormState();
}

class _PayFormState extends State<_PayForm> {
  final _c = TextEditingController();
  String _prov = 'MTN Mobile Money';
  String? _err;

  void _save() {
    final n = Validators.normalizePhone(_c.text);
    if (n == null) {
      setState(() => _err = 'Enter a valid Uganda number');
      return;
    }
    final mtn = _prov.startsWith('MTN');
    app.payMethods.add(PayMethod(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      title: _prov,
      caption: maskPhone(n),
      badge: mtn ? 'MTN' : 'A',
      badgeBg: mtn ? const Color(0xFFFFCB05) : const Color(0xFFE9222B),
      badgeFg: mtn ? const Color(0xFF171717) : Colors.white,
    ));
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          for (final p in ['MTN Mobile Money', 'Airtel Money'])
            Expanded(
              child: Tap(
                onTap: () => setState(() => _prov = p),
                child: Container(
                  margin: EdgeInsets.only(right: p.startsWith('MTN') ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _prov == p ? al(FC.gold, .07) : FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _prov == p ? FC.gold : FC.line)),
                  child: Text(p, style: fs(10.88, color: _prov == p ? FC.gold : FC.muted, w: FontWeight.w700)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        FcField(label: 'Mobile money number', hint: '+256 700 000 000', icon: IconName.phone, controller: _c, keyboard: TextInputType.phone, error: _err, action: TextInputAction.done, onSubmitted: (_) => _save()),
        const SizedBox(height: 18),
        FcButton('Add method', onTap: _save),
      ]);
}

// ---------------------------------------------------------------------------
// Support chat (local scripted replies until a backend exists)
// ---------------------------------------------------------------------------
Future<void> showSupportChat(BuildContext context, {String? topic}) =>
    showFcSheet<void>(context, title: 'Chat with support', builder: (ctx) => _Chat(topic: topic));

class _Chat extends StatefulWidget {
  final String? topic;
  const _Chat({this.topic});
  @override
  State<_Chat> createState() => _ChatState();
}

class _ChatState extends State<_Chat> {
  final _c = TextEditingController();
  final List<(bool, String)> _msgs = [(false, 'Hi! I’m the FuelConnect support assistant. How can I help?')];

  @override
  void initState() {
    super.initState();
    if (widget.topic != null) {
      _msgs.add((true, widget.topic!));
      _msgs.add((false, 'Thanks — an agent will join this chat shortly. Meanwhile, tell us your order number if you have one.'));
    }
  }

  void _send() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add((true, t));
      _msgs.add((false, 'Got it. A delivery support agent has been notified and will reply here.'));
      _c.clear();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: vh(context) * .4),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final m in _msgs)
                Align(
                  alignment: m.$1 ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    constraints: BoxConstraints(maxWidth: vw(context) * .7),
                    decoration: BoxDecoration(color: m.$1 ? FC.gold : FC.surface2, borderRadius: BorderRadius.circular(14)),
                    child: Text(m.$2, style: fs(12, color: m.$1 ? FC.onGold : FC.ink, h: 1.4)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: FcField(label: '', hint: 'Type your message', controller: _c, action: TextInputAction.send, onSubmitted: (_) => _send())),
          const SizedBox(width: 10),
          Padding(padding: const EdgeInsets.only(top: 19), child: FcButton.icon(IconName.chevron, onTap: _send)),
        ]),
      ]);
}
