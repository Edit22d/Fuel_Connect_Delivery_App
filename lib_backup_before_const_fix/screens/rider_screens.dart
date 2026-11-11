import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/core.dart';
import '../core/rider_state.dart';
import '../services/auth_service.dart';

// ===========================================================================
// Rider / delivery-partner screens (from the Figma prototype)
//   registration → login → dashboard → deliveries → request → accept/reject
//   → navigate → confirm pickup → confirm delivery → earnings
// ===========================================================================

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------
PageHeader _riderHeader(String title, Go go, {Screen? back}) => PageHeader(
      title: title,
      goBack: back == null ? null : () => go(back),
      action: const _OnlineChip(),
    );

class _OnlineChip extends StatelessWidget {
  const _OnlineChip();
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: rider,
        builder: (context, _) {
          final on = rider.online;
          final col = on ? FC.green : FC.dim;
          return Tap(
            onTap: () {
              rider.toggleOnline();
              toast(context, rider.online ? 'You’re online. New delivery requests will appear here.' : 'You’re offline. You won’t receive new requests.');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: al(col, .11), borderRadius: BorderRadius.circular(20), border: Border.all(color: al(col, .35))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: col)),
                const SizedBox(width: 6),
                Text(on ? 'ONLINE' : 'OFFLINE', style: fs(8.96, color: col, w: FontWeight.w800, ls: .5, h: 1.2)),
              ]),
            ),
          );
        },
      );
}

class _RouteStop extends StatelessWidget {
  final IconName icon;
  final String title, caption;
  const _RouteStop(this.icon, this.title, this.caption);
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: al(FC.gold, .08)),
          child: Center(child: Ic(icon, size: 17, color: FC.gold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FcText(title, kind: Tx.label, maxLines: 1),
            FcText(caption, kind: Tx.caption, color: FC.muted, maxLines: 1),
          ]),
        ),
      ]);
}

class _JobCard extends StatelessWidget {
  final RiderJob job;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Panel(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const LivePill('NEW REQUEST'),
              Text('UGX ${fmt(job.pay)}', style: fs(14.4, color: FC.gold, w: FontWeight.w800, h: 1.2)),
            ]),
            const SizedBox(height: 14),
            _RouteStop(IconName.fuel, job.station, 'Pickup · ${job.pickupKm.toStringAsFixed(1)} km away'),
            Padding(padding: const EdgeInsets.only(left: 17.5), child: Container(width: 1, height: 14, color: FC.line)),
            _RouteStop(IconName.location, job.dropArea, 'Drop-off · ${job.tripKm.toStringAsFixed(1)} km trip'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: FC.line))),
              child: Row(children: [
                Expanded(child: FcText(job.productLine, kind: Tx.caption, color: FC.muted)),
                FcText('${job.minutes} min', kind: Tx.caption, color: FC.muted),
                const SizedBox(width: 8),
                const Ic(IconName.chevron, size: 16, color: FC.dim),
              ]),
            ),
          ]),
        ),
      );
}

/// Dotted L-route between a pickup and a drop-off pin on the dark map grid.
class _RouteMap extends StatelessWidget {
  final double height;

  const _RouteMap({this.height = 250});

  Widget _pin(IconName icon, bool gold) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold ? FC.gold : FC.ink,
          boxShadow: gold
              ? [BoxShadow(color: al(FC.gold, .14), spreadRadius: 6)]
              : null,
        ),
        child: Center(
          child: Ic(icon, size: 18, color: const Color(0xFF111111)),
        ),
      );


  @override
  Widget build(BuildContext context) => Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF13171A), borderRadius: BorderRadius.circular(18), border: Border.all(color: FC.line)),
        child: LayoutBuilder(builder: (c, cons) {
          final w = cons.maxWidth;
          final left = w * .24, top = 44.0, rw = w * .52, rh = height - 90;
          return Stack(children: [
            const Positioned.fill(child: MapGrid()),
            Positioned(left: left, top: top, child: RouteLine(width: rw, height: rh, stroke: 4, dotted: true)),
            Positioned(left: left - 18 + 2, top: top - 18, child: _pin(IconName.fuel, true)),
            Positioned(left: left + rw - 18, top: top + rh - 18, child: _pin(IconName.location, false)),
          ]);
        }),
      );
}

class _EarnPanel extends StatelessWidget {
  final String label, value, trailing;
  const _EarnPanel(this.label, this.value, this.trailing);
  @override
  Widget build(BuildContext context) => Panel(
        color: al(FC.gold, .05),
        border: al(FC.gold, .25),
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FcText(label, kind: Tx.caption, color: FC.muted),
              FcText(value, kind: Tx.title, color: FC.gold),
            ]),
          ),
          const SizedBox(width: 12),
          FcText(trailing, kind: Tx.caption, color: FC.muted),
        ]),
      );
}

class _DetailBlock extends StatelessWidget {
  final String title;
  final List<List<String>> rows;
  const _DetailBlock(this.title, this.rows);
  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FcText(title, kind: Tx.label, color: FC.gold),
          const SizedBox(height: 14),
          ...gapped([for (final r in rows) KvRow(r[0], r[1])], 12),
        ]),
      );
}

class _Avatar extends StatelessWidget {
  final String text;
  final double size;
  const _Avatar(this.text, {this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: FC.gold),
        child: Text(text, style: fs(size * .27, color: const Color(0xFF111111), w: FontWeight.w800, h: 1)),
      );
}

class _ReasonList extends StatelessWidget {
  final List<String> reasons;
  final String selected;
  final ValueChanged<String> onPick;
  const _ReasonList({required this.reasons, required this.selected, required this.onPick});
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final r in reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Tap(
              onTap: () => onPick(r),
              child: Panel(
                radius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                border: selected == r ? FC.gold : FC.line,
                color: selected == r ? al(FC.gold, .06) : FC.surface,
                child: Row(children: [
                  RadioDot(selected: selected == r),
                  const SizedBox(width: 12),
                  Expanded(child: FcText(r, kind: Tx.label)),
                ]),
              ),
            ),
          ),
      ]);
}

// ===========================================================================
// Rider registration (3 steps)
// ===========================================================================
class RiderRegistrationScreen extends StatefulWidget {
  final Go go;
  const RiderRegistrationScreen({super.key, required this.go});
  @override
  State<RiderRegistrationScreen> createState() => _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState extends State<RiderRegistrationScreen> {
  int _step = 1;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _nid = TextEditingController();
  final _vType = TextEditingController();
  final _reg = TextEditingController();
  final _permit = TextEditingController();
  final Map<String, bool> _docs = {'National ID': false, 'Driving permit': false, 'Vehicle logbook': false, 'Profile photo': false};
  String? _nameErr, _phoneErr, _nidErr, _vTypeErr, _regErr, _permitErr, _formErr;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _nid, _vType, _reg, _permit]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _formErr = null;
      if (_step == 1) {
        _nameErr = Validators.name(_name.text);
        _phoneErr = Validators.phone(_phone.text);
        _nidErr = RegExp(r'^[A-Za-z0-9]{14}$').hasMatch(_nid.text.trim()) ? null : 'Enter your 14-character National ID number';
      } else if (_step == 2) {
        _vTypeErr = _vType.text.trim().length < 3 ? 'Enter your vehicle type' : null;
        _regErr = RegExp(r'^[A-Za-z]{3}\s?\d{3}[A-Za-z]$').hasMatch(_reg.text.trim()) ? null : 'Enter a valid plate, e.g. UBX 123A';
        _permitErr = _permit.text.trim().length < 5 ? 'Enter your driving permit number' : null;
      } else {
        _formErr = _docs.values.every((v) => v) ? null : 'Please add all four documents to submit your application.';
      }
    });
    if (_step == 1) return _nameErr == null && _phoneErr == null && _nidErr == null;
    if (_step == 2) return _vTypeErr == null && _regErr == null && _permitErr == null;
    return _formErr == null;
  }

  Future<void> _next() async {
    if (!_validate()) return;
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 700)); // POST /rider/register
    if (!mounted) return;
    setState(() => _busy = false);
    rider.applicationPending = true;
    toast(context, 'Application submitted. We’ll notify you once your documents are approved.', gold: true, seconds: 5);
    widget.go(Screen.riderLogin, replace: true);
  }

  Widget _progress() => Row(children: [
        for (var i = 1; i <= 3; i++) ...[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: i <= _step ? FC.gold : null, border: Border.all(color: i <= _step ? FC.gold : FC.dim)),
            child: i < _step ? const Ic(IconName.check, size: 15, color: Color(0xFF111111)) : Text('$i', style: fs(11, color: i <= _step ? const Color(0xFF111111) : FC.dim, w: FontWeight.w800, h: 1)),
          ),
          if (i < 3) Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: i < _step ? FC.gold : FC.line)),
        ],
      ]);

  Widget _uploadGrid() => LayoutBuilder(builder: (c, cons) {
        final w = (cons.maxWidth - 12) / 2;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final e in _docs.entries)
            SizedBox(
              width: w,
              child: Tap(
                onTap: () => setState(() => _docs[e.key] = !e.value),
                child: Panel(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                  border: e.value ? FC.green : FC.line,
                  color: e.value ? al(FC.green, .05) : FC.surface,
                  child: Column(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: al(e.value ? FC.green : FC.gold, .1)),
                      child: Center(child: Ic(e.value ? IconName.check : IconName.plus, size: 18, color: e.value ? FC.green : FC.gold)),
                    ),
                    const SizedBox(height: 10),
                    FcText(e.key, kind: Tx.label, align: TextAlign.center),
                    FcText(e.value ? 'Added · tap to remove' : 'Tap to upload', kind: Tx.caption, color: FC.muted, align: TextAlign.center),
                  ]),
                ),
              ),
            ),
        ]);
      });

  @override
  Widget build(BuildContext context) {
    final titles = ['Tell us about yourself', 'Vehicle and license', 'Verification documents'];
    return AppPage(
      header: PageHeader(
        title: 'Become a partner',
        goBack: () {
          if (_step > 1) {
            setState(() => _step--);
          } else {
            app.backOr(Screen.login);
          }
        },
      ),
      body: Narrow(gap: 20, children: [
        _progress(),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FcText('RIDER REGISTRATION · STEP $_step OF 3', kind: Tx.label, color: FC.gold),
          const SizedBox(height: 9),
          FcText(titles[_step - 1], kind: Tx.title),
          const SizedBox(height: 9),
          const FcText('Join FuelConnect’s certified delivery partner network.', color: FC.muted),
        ]),
        if (_step == 1) ...[
          FcField(label: 'Full legal name', hint: 'Your full name', icon: IconName.profile, controller: _name, error: _nameErr, action: TextInputAction.next),
          FcField(label: 'Phone number', hint: '+256 700 123 456', icon: IconName.phone, controller: _phone, keyboard: TextInputType.phone, error: _phoneErr, action: TextInputAction.next),
          FcField(label: 'National ID number', hint: 'CM00000000000000', icon: IconName.shield, controller: _nid, error: _nidErr, action: TextInputAction.done, onSubmitted: (_) => _next()),
        ],
        if (_step == 2) ...[
          FcField(label: 'Vehicle type', hint: 'Fuel delivery truck', icon: IconName.truck, controller: _vType, error: _vTypeErr, action: TextInputAction.next),
          FcField(label: 'Registration number', hint: 'UBX 123A', icon: IconName.card, controller: _reg, error: _regErr, action: TextInputAction.next),
          FcField(label: 'Driving permit number', hint: 'Permit number', icon: IconName.shield, controller: _permit, error: _permitErr, action: TextInputAction.done, onSubmitted: (_) => _next()),
        ],
        if (_step == 3) _uploadGrid(),
        if (_formErr != null) FormError(_formErr!),
        FcButton(_step < 3 ? 'Continue' : 'Submit application', loading: _busy, onTap: _next),
        FcButton('Already a partner? Sign in', variant: BV.ghost, onTap: () => widget.go(Screen.riderLogin)),
      ]),
    );
  }
}

// ===========================================================================
// Rider login
// ===========================================================================
class RiderLoginScreen extends StatefulWidget {
  final Go go;
  const RiderLoginScreen({super.key, required this.go});
  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  String? _phoneErr, _passErr, _formErr;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _phoneErr = Validators.phone(_phone.text);
      _passErr = _pass.text.isEmpty ? 'Enter your password' : null;
      _formErr = null;
    });
    if (_phoneErr != null || _passErr != null) return;
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 700)); // POST /rider/login
    if (!mounted) return;
    final ok = Validators.normalizePhone(_phone.text) == RiderState.demoPhone && _pass.text == RiderState.demoPassword;
    setState(() {
      _busy = false;
      if (!ok) {
        _formErr = rider.applicationPending
            ? 'Your application is still being reviewed. We’ll notify you as soon as it’s approved.'
            : 'Incorrect phone number or password.';
      }
    });
    if (!ok) return;
    rider.signIn();
    widget.go(Screen.riderDashboard, root: true);
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final visual = Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/station-card.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      const ImageShade(),
      Positioned(left: 24, top: topInset(context) + 24, child: const Logo(compact: true)),
      const Positioned(left: 24, bottom: 22, child: FcText('CERTIFIED DELIVERY PARTNERS', kind: Tx.label, color: FC.gold)),
    ]);
    final form = <Widget>[
      const FcText('RIDER PORTAL', kind: Tx.label, color: FC.gold),
      const FcText('Welcome back, partner.', kind: Tx.title),
      const FcText('Sign in to view and manage your deliveries.', color: FC.muted),
      FcField(label: 'Phone number', hint: '+256 700 123 456', icon: IconName.phone, controller: _phone, keyboard: TextInputType.phone, error: _phoneErr, action: TextInputAction.next),
      FcField(label: 'Password', hint: 'Enter your password', icon: IconName.shield, password: true, controller: _pass, error: _passErr, action: TextInputAction.done, onSubmitted: (_) => _submit()),
      Align(
        alignment: Alignment.centerRight,
        child: TextAction('Forgot password?', onTap: () => toast(context, 'Rider password resets will work once the backend is connected. For now, contact FuelConnect support.')),
      ),
      if (_formErr != null) FormError(_formErr!),
      FcButton('Sign in as rider', loading: _busy, onTap: _submit),
      FcButton('Register as a rider', variant: BV.outline, onTap: () => widget.go(Screen.riderRegistration)),
      if (kDemoMode) const FcText('Demo rider: +256 701 234 567 · Rider@2025', kind: Tx.caption, color: FC.dim, align: TextAlign.center),
    ];
    final pad = cl(context, 22, 6, 70);
    if (wide) {
      return ColoredBox(
        color: FC.black,
        child: Row(children: [
          SizedBox(width: vw(context) * .54, height: double.infinity, child: visual),
          Expanded(
            child: LayoutBuilder(
              builder: (c, cons) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cons.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: vw(context) * .08, vertical: vh(context) * .08),
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(form, 15))),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
    }
    return ColoredBox(
      color: FC.black,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: math.max(240, vh(context) * .30), child: visual),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 36 + bottomInset(context)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(form, 15)),
          ),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Rider dashboard
// ===========================================================================
class RiderDashboardScreen extends StatelessWidget {
  final Go go;
  const RiderDashboardScreen({super.key, required this.go});

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning,' : (h < 17 ? 'Good afternoon,' : 'Good evening,');
  }

  Widget _stat(IconName icon, String label, String value) => Expanded(
        child: Panel(
          radius: 14,
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Ic(icon, size: 18, color: FC.gold),
            const SizedBox(height: 10),
            FcText(label, kind: Tx.caption, color: FC.muted, maxLines: 1),
            const SizedBox(height: 3),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: fs(13.6, w: FontWeight.w800, h: 1.2))),
          ]),
        ),
      );

  Widget _action(IconName icon, String label, VoidCallback onTap) => Expanded(
        child: Tap(
          onTap: onTap,
          child: Panel(
            radius: 14,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Ic(icon, color: FC.gold),
              const SizedBox(height: 8),
              FcText(label, kind: Tx.caption, align: TextAlign.center),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: rider,
        builder: (context, _) {
          final jobs = rider.jobs;
          return AppPage(
            header: _riderHeader('Rider dashboard', go),
            body: ContentSection(maxWide: 760, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FcText(_greeting, kind: Tx.caption, color: FC.muted),
                  FcText(rider.name, kind: Tx.title),
                ]),
                _Avatar(rider.initials, size: 48),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                _stat(IconName.wallet, 'Today’s earnings', 'UGX ${fmt(rider.todayEarnings)}'),
                const SizedBox(width: 10),
                _stat(IconName.truck, 'Deliveries', '${rider.todayDeliveries} completed'),
                const SizedBox(width: 10),
                _stat(IconName.star, 'Rating', '${rider.rating} / 5'),
              ]),
              if (rider.activeTrip != null) ...[
                const SizedBox(height: 18),
                Tap(
                  onTap: () => go(Screen.riderNavigation),
                  child: Panel(
                    color: al(FC.gold, .06),
                    border: al(FC.gold, .4),
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      const Ic(IconName.truck, color: FC.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const FcText('Trip in progress', kind: Tx.label, color: FC.gold),
                          FcText('#${rider.activeTrip!.id} · ${rider.activeTrip!.dropArea}', kind: Tx.caption, color: FC.muted),
                        ]),
                      ),
                      const Ic(IconName.chevron, size: 18, color: FC.gold),
                    ]),
                  ),
                ),
              ],
              SectionHeading(
                'Available nearby',
                caption: rider.online ? '${jobs.length} delivery ${jobs.length == 1 ? 'request' : 'requests'} in your area' : 'Go online to receive requests',
                trailing: TextAction('View all', onTap: () => go(Screen.riderDeliveries)),
              ),
              if (!rider.online)
                const Panel(child: FcText('You’re offline. Tap the ONLINE chip at the top to start receiving delivery requests.', color: FC.muted))
              else if (jobs.isEmpty)
                Panel(
                  child: Column(children: [
                    const FcText('You’re all caught up. New requests will appear here.', color: FC.muted, align: TextAlign.center),
                    TextAction('Refresh', onTap: rider.refreshJobs),
                  ]),
                )
              else
                _JobCard(
                  job: jobs.first,
                  onTap: () {
                    rider.select(jobs.first);
                    go(Screen.riderRequest);
                  },
                ),
              const SizedBox(height: 16),
              Row(children: [
                _action(IconName.location, 'Active trip', () {
                  if (rider.activeTrip == null) {
                    toast(context, 'You have no active trip. Accept a request first.');
                  } else {
                    go(Screen.riderNavigation);
                  }
                }),
                const SizedBox(width: 10),
                _action(IconName.wallet, 'Earnings', () => go(Screen.riderEarnings)),
                const SizedBox(width: 10),
                _action(IconName.phone, 'Support', () => go(Screen.support)),
              ]),
              const SizedBox(height: 22),
              FcButton('Sign out', variant: BV.ghost, onTap: () {
                rider.signOut();
                go(Screen.riderLogin, root: true);
              }),
            ]),
          );
        },
      );
}

// ===========================================================================
// Available deliveries
// ===========================================================================
class RiderDeliveriesScreen extends StatefulWidget {
  final Go go;
  const RiderDeliveriesScreen({super.key, required this.go});
  @override
  State<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen> {
  static const _filters = ['Nearest', 'Highest pay', 'Shortest trip'];
  String _filter = 'Nearest';

  List<RiderJob> _sorted() {
    final l = List<RiderJob>.of(rider.jobs);
    switch (_filter) {
      case 'Highest pay':
        l.sort((a, b) => b.pay.compareTo(a.pay));
        break;
      case 'Shortest trip':
        l.sort((a, b) => a.tripKm.compareTo(b.tripKm));
        break;
      default:
        l.sort((a, b) => a.pickupKm.compareTo(b.pickupKm));
    }
    return l;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: rider,
        builder: (context, _) {
          final jobs = _sorted();
          return AppPage(
            header: _riderHeader('Available deliveries', widget.go, back: Screen.riderDashboard),
            body: ContentSection(maxWide: 760, children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Tap(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _filter == f ? al(FC.gold, .1) : FC.surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: _filter == f ? FC.gold : FC.line),
                          ),
                          child: Text(f, style: fs(11.52, color: _filter == f ? FC.gold : FC.muted, w: FontWeight.w700, h: 1.2)),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 18),
              if (!rider.online)
                const Panel(child: FcText('You’re offline. Go online to see delivery requests.', color: FC.muted))
              else if (jobs.isEmpty)
                Panel(
                  child: Column(children: [
                    const FcText('No requests right now. We’ll notify you when one comes in.', color: FC.muted, align: TextAlign.center),
                    TextAction('Refresh', onTap: rider.refreshJobs),
                  ]),
                )
              else
                ...gapped([
                  for (final j in jobs)
                    _JobCard(
                      job: j,
                      onTap: () {
                        rider.select(j);
                        widget.go(Screen.riderRequest);
                      },
                    ),
                ], 14),
            ]),
          );
        },
      );
}

// ===========================================================================
// Delivery request
// ===========================================================================
class RiderRequestScreen extends StatelessWidget {
  final Go go;
  const RiderRequestScreen({super.key, required this.go});

  @override
  Widget build(BuildContext context) {
    final j = rider.job;
    return AppPage(
      header: _riderHeader('Delivery request', go, back: Screen.riderDeliveries),
      body: Narrow(gap: 18, padTop: 22, children: [
        const _RouteMap(),
        _EarnPanel('ESTIMATED EARNINGS', 'UGX ${fmt(j.pay)}', '${j.minutes} min · ${j.totalKmLabel}'),
        _DetailBlock('ROUTE DETAILS', [
          ['Pickup', j.station],
          ['Customer', '${j.customer} · ${j.customerRating}'],
          ['Drop-off', j.dropAddress],
          ['Order', j.productLine],
          ['Vehicle', j.vehicle],
        ]),
        FcButton('Review request', onTap: () => go(Screen.riderDecision)),
      ]),
    );
  }
}

// ===========================================================================
// Accept or reject
// ===========================================================================
class RiderDecisionScreen extends StatefulWidget {
  final Go go;
  const RiderDecisionScreen({super.key, required this.go});
  @override
  State<RiderDecisionScreen> createState() => _RiderDecisionScreenState();
}

class _RiderDecisionScreenState extends State<RiderDecisionScreen> {
  static const _reasons = ['Too far away', 'Low fuel or equipment issue', 'Ending my shift', 'Other reason'];
  bool _rejecting = false;
  String _reason = '';
  int _left = 42;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_left <= 1) {
        _t?.cancel();
        toast(context, 'That request expired. Pick another delivery.');
        widget.go(Screen.riderDeliveries, replace: true);
        return;
      }
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String get _clock => '00:${_left.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final j = rider.job;
    return AppPage(
      header: _riderHeader('Accept delivery', widget.go, back: Screen.riderRequest),
      body: Narrow(gap: 18, padTop: 22, children: [
        Center(
          child: Column(children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _left <= 10 ? FC.danger : const Color(0xFF4D4321), width: 2)),
              child: Text(_clock, style: fs(20, color: _left <= 10 ? FC.danger : FC.gold, w: FontWeight.w800, h: 1)),
            ),
            const SizedBox(height: 8),
            const FcText('Request expires soon', kind: Tx.caption, color: FC.muted),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FcText('DELIVERY #${j.id}', kind: Tx.label, color: FC.gold),
          const SizedBox(height: 9),
          FcText(_rejecting ? 'Reject this request?' : 'Ready to take this delivery?', kind: Tx.title),
          const SizedBox(height: 9),
          FcText(
            _rejecting
                ? 'Select a reason so we can improve future delivery matches.'
                : 'You’ll collect ${j.litres}L of ${j.product.toLowerCase()} from ${j.station} and deliver it to ${j.dropArea}.',
            color: FC.muted,
          ),
        ]),
        if (_rejecting)
          _ReasonList(reasons: _reasons, selected: _reason, onPick: (r) => setState(() => _reason = r))
        else
          _EarnPanel('YOU’LL EARN', 'UGX ${fmt(j.pay)}', '${j.totalKmLabel} total'),
        FcButton(
          _rejecting ? 'Confirm rejection' : 'Accept delivery',
          onTap: _rejecting && _reason.isEmpty
              ? null
              : () {
                  if (_rejecting) {
                    rider.reject();
                    widget.go(Screen.riderDeliveries);
                  } else {
                    rider.accept();
                    widget.go(Screen.riderPickup);
                  }
                },
        ),
        FcButton(_rejecting ? 'Go back' : 'Reject request', variant: BV.outline, onTap: () => setState(() {
              _rejecting = !_rejecting;
              _reason = '';
            })),
      ]),
    );
  }
}

// ===========================================================================
// Navigate to customer
// ===========================================================================
class RiderNavigationScreen extends StatefulWidget {
  final Go go;
  const RiderNavigationScreen({super.key, required this.go});
  @override
  State<RiderNavigationScreen> createState() => _RiderNavigationScreenState();
}

class _RiderNavigationScreenState extends State<RiderNavigationScreen> {
  static const _pos = [Offset(.58, .24), Offset(.49, .35), Offset(.41, .46), Offset(.34, .55)];
  static const _turns = [
    ['350 M', 'Turn right onto Acacia Avenue'],
    ['900 M', 'Continue straight on Kira Road'],
    ['200 M', 'Turn left at Kisementi roundabout'],
    ['50 M', 'Your destination is on the right'],
  ];
  static const _eta = [8, 6, 4, 2];
  static const _km = ['3.2 km', '2.1 km', '1.2 km', '0.5 km'];
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _i < 3) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Widget _map(BuildContext context) => Container(
        color: const Color(0xFF13171A),
        child: LayoutBuilder(builder: (c, cons) {
          final w = cons.maxWidth, h = cons.maxHeight;
          final p = _pos[_i];
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
                left: w * p.dx,
                top: h * p.dy,
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
                  FcButton.icon(IconName.arrow, onTap: () => widget.go(Screen.riderDashboard, root: true)),
                  Text('Navigate to customer', style: fs(12, w: FontWeight.w700)),
                  const SizedBox(width: 42), // the global menu icon sits here
                ]),
              ),
            ]),
          );
        }),
      );

  Widget _sheet(BuildContext context, {required bool handle}) {
    final j = rider.job;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
      if (handle) Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: FC.line, borderRadius: BorderRadius.circular(4)))),
      Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: al(FC.gold, .1), borderRadius: BorderRadius.circular(16)),
          child: const Center(child: Ic(IconName.arrow, size: 26, color: FC.gold)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FcText('NEXT TURN · ${_turns[_i][0]}', kind: Tx.caption, color: FC.muted),
            FcText(_turns[_i][1], kind: Tx.title),
          ]),
        ),
      ]),
      Panel(
        radius: 12,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          _Avatar(j.customerInitials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FcText(j.customer, kind: Tx.label),
              FcText('${j.vehicle} · ${j.plate}', kind: Tx.caption, color: FC.muted, maxLines: 1),
            ]),
          ),
          FcButton.icon(IconName.phone, onTap: () => toast(context, 'Calling the customer will work once the backend shares contact details.')),
        ]),
      ),
      _EarnPanel('ESTIMATED ARRIVAL', '${_eta[_i]} minutes', _km[_i]),
      FcButton('I’ve arrived', onTap: () => widget.go(Screen.riderDelivery)),
    ], 16));
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
            child: LayoutBuilder(
              builder: (c, cons) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cons.maxHeight),
                  child: Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: vw(context) * .05, vertical: vh(context) * .08), child: _sheet(context, handle: false))),
                ),
              ),
            ),
          ),
        ]),
      );
    }
    final mapH = vh(context) * .46;
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
// Confirm pickup
// ===========================================================================
class RiderPickupScreen extends StatefulWidget {
  final Go go;
  const RiderPickupScreen({super.key, required this.go});
  @override
  State<RiderPickupScreen> createState() => _RiderPickupScreenState();
}

class _RiderPickupScreenState extends State<RiderPickupScreen> {
  static const _items = ['Station attendant verified order', 'Meter reading matches quantity', 'Tank sealed and safety checked'];
  final List<bool> _checks = [false, false, false];
  final _code = TextEditingController();
  String? _codeErr;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_checks.every((v) => v)) return;
    if (_code.text.trim().length != 6) {
      setState(() => _codeErr = 'Enter the 6-digit pickup code from the station');
      return;
    }
    setState(() => _codeErr = null);
    // POST /rider/deliveries/{id}/pickup { code }
    widget.go(Screen.riderNavigation);
  }

  @override
  Widget build(BuildContext context) {
    final j = rider.job;
    return AppPage(
      header: _riderHeader('Confirm pickup', widget.go, back: Screen.riderDecision),
      body: Narrow(gap: 18, padTop: 22, children: [
        Row(children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: al(FC.gold, .08), borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Ic(IconName.fuel, size: 30, color: FC.gold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FcText(j.station, kind: Tx.title),
              FcText('Order #${j.id} · ${j.product}', kind: Tx.caption, color: FC.muted),
            ]),
          ),
        ]),
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(children: [
            const FcText('COLLECT EXACTLY', kind: Tx.label, color: FC.muted),
            const SizedBox(height: 6),
            Text('${j.litres}.0', style: fs(46, color: FC.gold, w: FontWeight.w800, h: 1)),
            const SizedBox(height: 4),
            const FcText('LITRES', kind: Tx.label, color: FC.muted),
          ]),
        ),
        Column(children: [
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Tap(
                onTap: () => setState(() => _checks[i] = !_checks[i]),
                child: Panel(
                  radius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  border: _checks[i] ? FC.green : FC.line,
                  color: _checks[i] ? al(FC.green, .05) : FC.surface,
                  child: Row(children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _checks[i] ? FC.green : null, border: Border.all(color: _checks[i] ? FC.green : FC.dim)),
                      child: _checks[i] ? const Center(child: Ic(IconName.check, size: 13, color: Color(0xFF111111))) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: FcText(_items[i], kind: Tx.label)),
                  ]),
                ),
              ),
            ),
        ]),
        FcField(
          label: 'Station pickup code',
          hint: 'Enter 6-digit code',
          icon: IconName.shield,
          controller: _code,
          keyboard: TextInputType.number,
          error: _codeErr,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          action: TextInputAction.done,
          onSubmitted: (_) => _confirm(),
        ),
        if (kDemoMode) const FcText('Demo mode: any 6 digits are accepted.', kind: Tx.caption, color: FC.dim),
        FcButton('Confirm fuel pickup', onTap: _checks.every((v) => v) ? _confirm : null),
      ]),
    );
  }
}

// ===========================================================================
// Confirm delivery (+ completed state)
// ===========================================================================
class RiderDeliveryScreen extends StatefulWidget {
  final Go go;
  const RiderDeliveryScreen({super.key, required this.go});
  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  final _code = TextEditingController();
  String? _codeErr, _formErr;
  bool _photo = false, _busy = false;
  RiderJob? _done;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _codeErr = _code.text.trim().length == 4 ? null : 'Enter the customer’s 4-digit delivery code';
      _formErr = _photo ? null : 'Add a delivery photo to verify the drop-off.';
    });
    if (_codeErr != null || _formErr != null) return;
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 700)); // POST /rider/deliveries/{id}/deliver
    if (!mounted) return;
    final j = rider.job;
    rider.completeDelivery();
    setState(() {
      _busy = false;
      _done = j;
    });
  }

  Widget _completed(BuildContext context, RiderJob j) {
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
                  const FcText('Delivery completed.', kind: Tx.display, align: TextAlign.center),
                  FcText('UGX ${fmt(j.pay)} has been added to your rider earnings.', color: FC.muted, align: TextAlign.center),
                  Panel(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: gapped([
                      KvRow('Order', '#${j.id}', size: 10.88),
                      KvRow('Delivered', '${j.litres}L ${j.product}', size: 10.88),
                      KvRow('Today’s total', 'UGX ${fmt(rider.todayEarnings)}', size: 10.88),
                    ], 11)),
                  ),
                  FcButton('Back to dashboard', onTap: () => widget.go(Screen.riderDashboard, root: true)),
                  FcButton('View earnings', variant: BV.ghost, onTap: () => widget.go(Screen.riderEarnings)),
                ], 19)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_done != null) return _completed(context, _done!);
    final j = rider.job;
    return AppPage(
      header: _riderHeader('Confirm delivery', widget.go, back: Screen.riderNavigation),
      body: Narrow(gap: 18, padTop: 22, children: [
        Row(children: [
          _Avatar(j.customerInitials, size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FcText(j.customer, kind: Tx.title),
              FcText(j.dropAddress, kind: Tx.caption, color: FC.muted),
            ]),
          ),
        ]),
        _DetailBlock('DELIVERY CHECK', [
          ['Product', j.product],
          ['Quantity', '${j.litres} litres'],
          ['Vehicle', '${j.vehicle.split(' ').skip(1).join(' ')} · ${j.plate}'],
        ]),
        FcField(
          label: 'Customer delivery code',
          hint: 'Enter customer’s 4-digit code',
          icon: IconName.shield,
          controller: _code,
          keyboard: TextInputType.number,
          error: _codeErr,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          action: TextInputAction.done,
        ),
        if (kDemoMode) const FcText('Demo mode: any 4 digits are accepted.', kind: Tx.caption, color: FC.dim),
        Tap(
          onTap: () => setState(() => _photo = !_photo),
          child: Panel(
            radius: 14,
            padding: const EdgeInsets.all(14),
            border: _photo ? FC.green : FC.line,
            color: _photo ? al(FC.green, .05) : FC.surface,
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: al(_photo ? FC.green : FC.gold, .1)),
                child: Center(child: Ic(_photo ? IconName.check : IconName.plus, size: 18, color: _photo ? FC.green : FC.gold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FcText(_photo ? 'Delivery photo added' : 'Add delivery photo', kind: Tx.label),
                  FcText(_photo ? 'Tap to remove' : 'Required for delivery verification', kind: Tx.caption, color: FC.muted),
                ]),
              ),
            ]),
          ),
        ),
        if (_formErr != null) FormError(_formErr!),
        FcButton('Confirm safe delivery', loading: _busy, onTap: _confirm),
      ]),
    );
  }
}

// ===========================================================================
// Earnings
// ===========================================================================
class RiderEarningsScreen extends StatefulWidget {
  final Go go;
  const RiderEarningsScreen({super.key, required this.go});
  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  Future<void> _withdraw() async {
    if (rider.available <= 0) {
      toast(context, 'You have no earnings available to withdraw yet.');
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Withdraw earnings',
      body: 'UGX ${fmt(rider.available)} will be sent to your MTN Mobile Money number.',
      confirm: 'Withdraw',
    );
    if (!ok || !mounted) return;
    final amount = rider.withdraw();
    setState(() {});
    toast(context, 'UGX ${fmt(amount)} is on its way to your MTN Mobile Money.', gold: true);
  }

  Widget _stat(String label, String value) => Expanded(
        child: Panel(
          radius: 14,
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FcText(label, kind: Tx.caption, color: FC.muted, maxLines: 1),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: fs(13.6, w: FontWeight.w800, h: 1.2))),
          ]),
        ),
      );

  String _k(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(n >= 100000 ? 0 : 1)}K' : '$n';

  Widget _chart() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final bars = rider.weekBars;
    final best = bars.reduce(math.max);
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      child: SizedBox(
        height: 160,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < bars.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: bars[i] / 100,
                        child: Container(decoration: BoxDecoration(color: bars[i] == best ? FC.gold : al(FC.gold, .3), borderRadius: BorderRadius.circular(6))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(days[i], style: fs(9.6, color: FC.muted, h: 1)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppPage(
        header: _riderHeader('My earnings', widget.go, back: Screen.riderDashboard),
        body: ContentSection(maxWide: 760, children: [
          Panel(
            color: al(FC.gold, .05),
            border: al(FC.gold, .25),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const FcText('AVAILABLE TO WITHDRAW', kind: Tx.caption, color: FC.muted),
              const SizedBox(height: 6),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: FcText('UGX ${fmt(rider.available)}', kind: Tx.display)),
              const SizedBox(height: 16),
              FcButton('Withdraw earnings', onTap: _withdraw),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _stat('This week', 'UGX ${_k(rider.weekTotal)}'),
            const SizedBox(width: 10),
            _stat('Deliveries', '${rider.weekTrips}'),
            const SizedBox(width: 10),
            _stat('Avg. per trip', 'UGX ${_k(rider.avgPerTrip)}'),
          ]),
          const SizedBox(height: 14),
          _chart(),
          SectionHeading('Recent earnings', trailing: TextAction('Statement', onTap: () => toast(context, 'Earnings statements will be available once the backend is connected.'))),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < rider.recent.length; i++)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(border: i == rider.recent.length - 1 ? null : const Border(bottom: BorderSide(color: FC.line))),
                  child: Row(children: [
                    const IconBox(IconName.truck),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        FcText(rider.recent[i].station, kind: Tx.label, maxLines: 1),
                        FcText(rider.recent[i].when, kind: Tx.caption, color: FC.muted, maxLines: 1),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text('+ UGX ${fmt(rider.recent[i].amount)}', style: fs(11.52, color: FC.green, w: FontWeight.w700, h: 1.2)),
                  ]),
                ),
            ]),
          ),
        ]),
      );
}
