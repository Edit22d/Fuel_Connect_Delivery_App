import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/core.dart';
import '../services/auth_service.dart';
import 'order_screens.dart' show VehicleTile;
import 'sheets.dart';

Widget _chevron() => const Ic(IconName.chevron, size: 18, color: FC.dim);

Widget _groupLabel(String t) => Padding(padding: const EdgeInsets.only(top: 26, bottom: 10), child: FcText(t, kind: Tx.label, color: FC.gold));

// ===========================================================================
// Orders
// ===========================================================================
class OrdersScreen extends StatefulWidget {
  final Go go;
  const OrdersScreen({super.key, required this.go});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _tab = 'Active';
  bool _searching = false;
  final _q = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Widget _history(HistoryOrder o) => Tap(
        onTap: () => widget.go(Screen.orderDetail),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: FC.line)),
          child: Row(children: [
            const IconBox(IconName.fuel),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText(o.station, kind: Tx.label), FcText('${o.date} · ${o.product}', kind: Tx.caption, color: FC.muted)])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [FcText(o.price, kind: Tx.label), Text('Completed', style: fs(8, color: FC.green, h: 1.5))]),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final hist = kHistory.where((o) => q.isEmpty || '${o.station} ${o.product} ${o.date}'.toLowerCase().contains(q)).toList();
    final showActive = _tab == 'Active' && q.isEmpty;
    return AppPage(
      nav: true,
      navCurrent: Screen.orders,
      go: widget.go,
      header: PageHeader(title: 'Your orders', action: RoundAction(IconName.search, onTap: () => setState(() => _searching = !_searching))),
      body: Narrow(gap: 0, padTop: 24, children: [
        if (_searching) Padding(padding: const EdgeInsets.only(bottom: 16), child: SearchBox(hint: 'Search your orders', controller: _q, onChanged: (v) => setState(() => _query = v))),
        Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: FC.line)),
          child: Row(children: [
            for (final t in ['Active', 'Completed', 'Cancelled'])
              Expanded(
                child: Tap(
                  onTap: () => setState(() => _tab = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _tab == t ? FC.gold : null, borderRadius: BorderRadius.circular(8)),
                    child: Text(t, style: fs(10.88, color: _tab == t ? FC.onGold : FC.muted, w: _tab == t ? FontWeight.w800 : FontWeight.w400, h: 1.2)),
                  ),
                ),
              ),
          ]),
        ),
        if (showActive)
          Tap(
            onTap: () => widget.go(Screen.tracking),
            child: Container(
              margin: const EdgeInsets.only(bottom: 22),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [al(FC.gold, .07), FC.surface]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF4C4322)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const LivePill('ON THE WAY'), Text('12–16 min', style: fs(9.6, color: FC.muted))]),
                const SizedBox(height: 18),
                Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: FC.gold, borderRadius: BorderRadius.circular(12)), child: const Center(child: Ic(IconName.truck, color: Color(0xFF111111)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText('${app.productName} · ${app.litres}L', kind: Tx.subtitle), const FcText('Stabex Kira Road', kind: Tx.caption, color: FC.muted)])),
                  const Ic(IconName.chevron, color: FC.muted),
                ]),
                const SizedBox(height: 14),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: const LinearProgressIndicator(value: .62, minHeight: 4, backgroundColor: FC.line, valueColor: AlwaysStoppedAnimation(FC.gold))),
                const SizedBox(height: 14),
                const FcText('Marcus is heading to your location', kind: Tx.caption, color: FC.muted),
              ]),
            ),
          ),
        if (_tab == 'Cancelled')
          const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: FcText('You have no cancelled orders.', color: FC.muted, align: TextAlign.center))
        else ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const FcText('Recent orders', kind: Tx.title), TextAction('View all', onTap: () => setState(() => _tab = 'Completed'))]),
          const SizedBox(height: 15),
          if (hist.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: FcText('No orders match your search.', color: FC.muted, align: TextAlign.center))
          else
            Column(children: gapped([for (final o in hist) _history(o)], 10)),
        ],
      ]),
    );
  }
}

// ===========================================================================
// Order detail
// ===========================================================================
class OrderDetailScreen extends StatelessWidget {
  final Go go;
  const OrderDetailScreen({super.key, required this.go});
  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: PageHeader(title: 'Order #FC-29841', goBack: () => app.backOr(Screen.orders)),
      body: Narrow(gap: 16, children: [
        Container(
          padding: const EdgeInsets.only(bottom: 17),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FC.line))),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: FC.gold), child: const Center(child: Ic(IconName.check, size: 24, color: Color(0xFF111111)))),
            const SizedBox(width: 13),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText('Delivered successfully', kind: Tx.subtitle), FcText('29 May 2025 · 7:42 PM', kind: Tx.caption, color: FC.muted)]),
          ]),
        ),
        Container(
          padding: const EdgeInsets.only(top: 18),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: FC.line))),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/images/station-hero.jpg', width: 48, height: 48, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText('Stabex Kira Road', kind: Tx.label), FcText('Verified FuelConnect partner', kind: Tx.caption, color: FC.muted)])),
            Text('STABEX', style: fs(8, color: FC.gold, w: FontWeight.w900, ls: .96)),
          ]),
        ),
        Panel(
          padding: const EdgeInsets.all(17),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
            const FcText('DELIVERY SUMMARY', kind: Tx.label, color: FC.gold),
            const KvRow('Product', 'Premium petrol', size: 10.88),
            const KvRow('Quantity', '35 litres', size: 10.88),
            const KvRow('Vehicle', 'Toyota RAV4 · UBP 482M', size: 10.88),
            const KvRow('Delivered to', 'Acacia Mall, Kisementi', size: 10.88),
          ], 14)),
        ),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
            const KvRow('Fuel', 'UGX 181,300'),
            const KvRow('Delivery & service', 'UGX 10,500'),
            const TotalRow('Total paid', 'UGX 191,800'),
          ], 13)),
        ),
        FcButton('Reorder fuel', onTap: () => go(Screen.fuel)),
        FcButton('Get help with this order', variant: BV.outline, onTap: () => go(Screen.support)),
      ]),
    );
  }
}

// ===========================================================================
// Wallet
// ===========================================================================
class WalletScreen extends StatefulWidget {
  final Go go;
  const WalletScreen({super.key, required this.go});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Widget _action(IconName icon, String text, VoidCallback onTap) => Tap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(color: al(Colors.white, .07), borderRadius: BorderRadius.circular(10), border: Border.all(color: al(Colors.white, .12))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Ic(icon, size: 16), const SizedBox(width: 7), Text(text, style: fs(9.92, w: FontWeight.w700))]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AppPage(
      nav: true,
      navCurrent: Screen.wallet,
      go: widget.go,
      header: PageHeader(title: 'Wallet', action: RoundAction(IconName.star, onTap: () => widget.go(Screen.rewards))),
      body: ContentSection(maxWide: 720, children: [
        Container(
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(minHeight: 265),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF4F4421)),
            boxShadow: [BoxShadow(color: al(Colors.black, .35), blurRadius: 55, offset: const Offset(0, 22))],
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF26200E), Color(0xFF121316)], stops: [0, .62]),
          ),
          child: Stack(children: [
            const Positioned.fill(child: Glow(fx: .88, fy: 0, colors: [Color(0x38F5C72E), Color(0x00F5C72E)], stops: [0, .36])),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 217),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Logo(compact: true), Ic(IconName.wallet, color: FC.gold)]),
                    const SizedBox(height: 33),
                    const FcText('AVAILABLE BALANCE', kind: Tx.caption),
                    const SizedBox(height: 8),
                    Text('UGX ${fmt(app.walletBalance)}', style: fs(cl(context, 32, 7, 44.8), w: FontWeight.w800, ls: -1.6, h: 1.08)),
                  ]),
                  const SizedBox(height: 20),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    _action(IconName.plus, 'Top up', () async {
                      final ok = await showTopUpSheet(context);
                      if (ok == true && mounted) {
                        setState(() {});
                        toast(context, 'Wallet topped up. New balance UGX ${fmt(app.walletBalance)}.');
                      }
                    }),
                    _action(IconName.card, 'Methods', () => widget.go(Screen.payment)),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Tap(
          onTap: () => widget.go(Screen.rewards),
          child: Panel(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: FC.gold), child: const Center(child: Ic(IconName.star, color: Color(0xFF111111)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FcText('GOLD MEMBER · ${fmt(app.points)} POINTS', kind: Tx.label),
                FcText('${fmt(math.max(0, AppState.nextTierPoints - app.points))} points to your next fuel reward', kind: Tx.caption, color: FC.muted),
              ])),
              const Ic(IconName.chevron, color: FC.muted),
            ]),
          ),
        ),
        SectionHeading('Recent activity', trailing: TextAction('Statements', onTap: () => toast(context, 'Statements will be available once the backend is connected.'))),
        for (final t in app.txs)
          Container(
            constraints: const BoxConstraints(minHeight: 66),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FC.line))),
            child: Row(children: [
              IconBox(t.amount < 0 ? IconName.fuel : IconName.wallet, color: t.amount < 0 ? FC.gold : FC.green),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText(t.title, kind: Tx.label), FcText(t.subtitle, kind: Tx.caption, color: FC.muted)])),
              Text('UGX ${t.amount < 0 ? '−' : '+'}${fmt(t.amount.abs())}', style: fs(10.88, w: FontWeight.w700)),
            ]),
          ),
      ]),
    );
  }
}

// ===========================================================================
// Rewards
// ===========================================================================
class RewardsScreen extends StatefulWidget {
  final Go go;
  const RewardsScreen({super.key, required this.go});
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const _rewards = [('5L fuel credit', 1500), ('Free delivery', 800), ('10L fuel credit', 2800), ('UGX 20K off', 2000)];

  Future<void> _redeem(String name, int cost) async {
    if (app.points < cost) {
      toast(context, 'You need ${fmt(cost - app.points)} more points for this reward.');
      return;
    }
    final ok = await confirmDialog(context, title: 'Redeem $name?', body: 'This will use ${fmt(cost)} of your ${fmt(app.points)} points.', confirm: 'Redeem');
    if (ok && mounted) {
      setState(() => app.points -= cost);
      toast(context, '$name redeemed. It will apply to your next order.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = app.points;
    final left = math.max(0, AppState.nextTierPoints - p);
    return AppPage(
      background: const Glow(fx: .5, fy: .08, colors: [Color(0x14F5C72E), Color(0x00F5C72E)], stops: [0, .28]),
      header: PageHeader(title: 'FuelConnect Rewards', goBack: () => app.backOr(Screen.wallet)),
      body: Narrow(gap: 18, children: [
        Container(
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(minHeight: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF5C4C1C)),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF201D13), Color(0xFF101214)]),
          ),
          child: Stack(children: [
            const Positioned.fill(child: Glow(fx: .8, fy: .15, colors: [Color(0x2EF5C72E), Color(0x00F5C72E)], stops: [0, .30])),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: gapped([
                Text('GOLD', style: fs(9.6, color: FC.gold, w: FontWeight.w900, ls: 2.4)),
                const Ic(IconName.star, size: 36, color: FC.gold),
                FcText(fmt(p), kind: Tx.display, color: FC.gold),
                const FcText('AVAILABLE POINTS', kind: Tx.caption, color: FC.gold),
                ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: (p / AppState.nextTierPoints).clamp(0, 1).toDouble(), minHeight: 5, backgroundColor: FC.line, valueColor: const AlwaysStoppedAnimation(FC.gold))),
                FcText(left == 0 ? 'You have reached Platinum · Earn 1 point per UGX 1,000' : '${fmt(left)} points until Platinum · Earn 1 point per UGX 1,000', kind: Tx.caption, color: FC.gold, align: TextAlign.center),
              ], 12)),
            ),
          ]),
        ),
        const FcText('Redeem rewards', kind: Tx.title),
        LayoutBuilder(builder: (c, cons) {
          final w = (cons.maxWidth - 10) / 2;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final r in _rewards)
              SizedBox(
                width: w,
                child: Tap(
                  onTap: () => _redeem(r.$1, r.$2),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 120),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: FC.line)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Ic(IconName.drop, color: FC.gold),
                      const SizedBox(height: 8),
                      FcText(r.$1, kind: Tx.label, color: FC.gold, align: TextAlign.center),
                      const SizedBox(height: 8),
                      Text('${fmt(r.$2)} pts', style: fs(9.28, color: FC.muted)),
                    ]),
                  ),
                ),
              ),
          ]);
        }),
        Panel(
          padding: const EdgeInsets.all(17),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped([
            const FcText('HOW IT WORKS', kind: Tx.label, color: FC.gold),
            const KvRow('Order from any partner', 'Earn points', size: 10.88),
            const KvRow('Refer a friend', '+500 points', size: 10.88),
            const KvRow('Complete 5 deliveries', '+1,000 points', size: 10.88),
          ], 14)),
        ),
      ]),
    );
  }
}

// ===========================================================================
// Notifications
// ===========================================================================
class NotificationsScreen extends StatefulWidget {
  final Go go;
  const NotificationsScreen({super.key, required this.go});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return AppPage(
      nav: true,
      navCurrent: Screen.notifications,
      go: widget.go,
      header: PageHeader(title: 'Notifications', action: TextAction('Mark read', onTap: () => setState(() {
            for (final n in app.notices) {
              n.fresh = false;
            }
          }))),
      body: ContentSection(children: [
        const FcText('TODAY', kind: Tx.label, color: FC.gold),
        const SizedBox(height: 10),
        for (final n in app.notices)
          Tap(
            onTap: () {
              setState(() => n.fresh = false);
              if (n.icon == IconName.truck) widget.go(Screen.tracking);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FC.line))),
              child: Stack(clipBehavior: Clip.none, children: [
                if (n.fresh) Positioned(left: -8, top: 6, child: Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: FC.gold))),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconBox(n.icon),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText(n.title, kind: Tx.label), FcText(n.body, kind: Tx.caption, color: FC.muted)])),
                  const SizedBox(width: 12),
                  Text(n.time, style: fs(8.8, color: FC.dim)),
                ]),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ===========================================================================
// Settings / profile
// ===========================================================================
class ProfileScreen extends StatefulWidget {
  final Go go;
  const ProfileScreen({super.key, required this.go});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Widget _row(IconName icon, String label, {VoidCallback? onTap, Widget? trailing, bool last = false}) => Tap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 57),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: FC.line))),
          child: Row(children: [
            Ic(icon, color: FC.gold),
            const SizedBox(width: 12),
            Expanded(child: FcText(label, kind: Tx.label)),
            trailing ?? _chevron(),
          ]),
        ),
      );

  Widget _group(List<Widget> rows) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: FC.line)),
        child: Column(children: rows),
      );

  @override
  Widget build(BuildContext context) {
    final pr = auth.profile;
    return AppPage(
      nav: true,
      navCurrent: Screen.profile,
      go: widget.go,
      header: const PageHeader(title: 'Settings'),
      body: Narrow(gap: 0, padTop: 24, children: [
        Container(
          padding: const EdgeInsets.only(top: 6, bottom: 25),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FC.line))),
          child: Row(children: [
            Container(width: 58, height: 58, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: FC.surface2, border: Border.all(color: const Color(0xFF6B5A1E))), child: Text(pr.initials, style: fs(14, color: FC.gold, w: FontWeight.w800, h: 1))),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText(pr.name, kind: Tx.title), FcText('${pr.email} · ${maskPhone(pr.phone)}', kind: Tx.caption, color: FC.muted)])),
            Tap(
              onTap: () async {
                await showEditProfileSheet(context);
                if (mounted) setState(() {});
              },
              child: const Padding(padding: EdgeInsets.all(6), child: Ic(IconName.chevron, color: FC.muted)),
            ),
          ]),
        ),
        _groupLabel('PREFERENCES'),
        _group([
          _row(IconName.bell, 'Push notifications', trailing: FcToggle(on: app.pushOn, onTap: () => setState(() => app.pushOn = !app.pushOn))),
          _row(IconName.location, 'Location services', trailing: FcToggle(on: app.locationOn, onTap: () => setState(() => app.locationOn = !app.locationOn))),
          _row(IconName.card, 'Wallet & payment methods', onTap: () => widget.go(Screen.wallet)),
          _row(IconName.star, 'Rewards & referrals', onTap: () => widget.go(Screen.rewards), last: true),
        ]),
        _groupLabel('DELIVERY'),
        _group([
          _row(IconName.location, 'Saved places', onTap: () => widget.go(Screen.addresses)),
          _row(IconName.truck, 'My vehicles', onTap: () => widget.go(Screen.vehicles)),
          _row(IconName.bell, 'Notification centre', onTap: () => widget.go(Screen.notifications), last: true),
        ]),
        _groupLabel('ACCOUNT & SECURITY'),
        _group([
          _row(IconName.profile, 'Personal details', onTap: () async {
            await showEditProfileSheet(context);
            if (mounted) setState(() {});
          }),
          _row(IconName.shield, 'Safety & security', onTap: () => widget.go(Screen.safety)),
          _row(IconName.phone, 'Help & support', onTap: () => widget.go(Screen.support), last: true),
        ]),
        const SizedBox(height: 26),
        FcButton('Log out', variant: BV.outline, onTap: () {
          auth.signOut();
          widget.go(Screen.login, root: true);
        }),
        const SizedBox(height: 18),
        const FcText('FuelConnect version 1.0.0', kind: Tx.caption, color: FC.muted, align: TextAlign.center),
      ]),
    );
  }
}

// ===========================================================================
// Saved places
// ===========================================================================
class AddressesScreen extends StatefulWidget {
  final Go go;
  const AddressesScreen({super.key, required this.go});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: PageHeader(title: 'Saved places', goBack: () => app.backOr(Screen.profile)),
      body: Narrow(gap: 20, children: [
        Column(children: gapped([
          for (final p in app.places)
            Tap(
              onTap: () {
                app.deliveryAddress = p.address;
                toast(context, '${p.label} set as your delivery location.');
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: FC.line)),
                child: Row(children: [
                  const IconBox(IconName.location),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText(p.label, kind: Tx.label), FcText(p.address, kind: Tx.caption, color: FC.muted)])),
                  _chevron(),
                ]),
              ),
            ),
        ], 9)),
        FcButton('Add a new place', icon: IconName.plus, onTap: () async {
          final ok = await showAddPlaceSheet(context);
          if (ok == true && mounted) setState(() {});
        }),
      ]),
    );
  }
}

// ===========================================================================
// My vehicles
// ===========================================================================
class VehiclesScreen extends StatefulWidget {
  final Go go;
  const VehiclesScreen({super.key, required this.go});
  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: PageHeader(title: 'My vehicles', goBack: () => app.backOr(Screen.profile)),
      body: Narrow(gap: 20, children: [
        Column(children: gapped([
          for (var i = 0; i < app.vehicles.length; i++)
            VehicleTile(
              v: app.vehicles[i],
              selected: i == 0,
              caption: app.vehicles[i].listCaption,
              trailing: i == 0
                  ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: al(FC.gold, .1), borderRadius: BorderRadius.circular(20)), child: Text('DEFAULT', style: fs(8, color: FC.gold, w: FontWeight.w800, ls: .4, h: 1.2)))
                  : _chevron(),
              onTap: () => setState(() {
                final v = app.vehicles.removeAt(i);
                app.vehicles.insert(0, v);
                app.vehicleId = v.id;
              }),
            ),
        ], 10)),
        FcButton('Add vehicle', icon: IconName.plus, onTap: () async {
          final ok = await showAddVehicleSheet(context);
          if (ok == true && mounted) setState(() {});
        }),
        const SafetyNote(title: 'Why vehicle details matter', body: 'We prevent fuel mix-ups and help drivers identify your vehicle.'),
      ]),
    );
  }
}

// ===========================================================================
// Help centre
// ===========================================================================
class SupportScreen extends StatelessWidget {
  final Go go;
  const SupportScreen({super.key, required this.go});
  @override
  Widget build(BuildContext context) {
    const topics = ['Track my delivery', 'Payment or refund issue', 'Change or cancel an order', 'Fuel quality concern', 'Account and security'];
    return AppPage(
      header: PageHeader(title: 'Help centre', goBack: () => app.backOr(Screen.profile)),
      body: Narrow(gap: 18, children: [
        Container(
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints(minHeight: 230),
          decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFF504522))),
          child: Stack(children: [
            const Positioned.fill(child: Glow(fx: .5, fy: 0, colors: [Color(0x1FF5C72E), Color(0x00F5C72E)], stops: [0, .55])),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Ic(IconName.phone, size: 30, color: FC.gold),
                  const SizedBox(height: 11),
                  const FcText('How can we help?', kind: Tx.title, align: TextAlign.center),
                  const SizedBox(height: 11),
                  const FcText('Our delivery support team is available 24/7.', color: FC.muted, align: TextAlign.center),
                  const SizedBox(height: 11),
                  FcButton('Chat with support', expand: false, onTap: () => showSupportChat(context)),
                ]),
              ),
            ),
          ]),
        ),
        const FcText('POPULAR TOPICS', kind: Tx.label, color: FC.gold),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: FC.line)),
          child: Column(children: [
            for (var i = 0; i < topics.length; i++)
              Tap(
                onTap: () => showSupportChat(context, topic: topics[i]),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 57),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(border: i == topics.length - 1 ? null : const Border(bottom: BorderSide(color: FC.line))),
                  child: Row(children: [const Ic(IconName.phone, color: FC.gold), const SizedBox(width: 12), Expanded(child: FcText(topics[i], kind: Tx.label)), _chevron()]),
                ),
              ),
          ]),
        ),
        Tap(
          onTap: () => go(Screen.safety),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: al(FC.danger, .06), borderRadius: BorderRadius.circular(12), border: Border.all(color: al(FC.danger, .25))),
            child: Row(children: [
              const Ic(IconName.shield, color: FC.danger),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText('Safety or emergency?', kind: Tx.label, color: FC.danger), FcText('Open the FuelConnect Safety Centre', kind: Tx.caption, color: FC.danger)])),
              const Ic(IconName.chevron, color: FC.danger),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ===========================================================================
// Safety centre
// ===========================================================================
class SafetyScreen extends StatelessWidget {
  final Go go;
  const SafetyScreen({super.key, required this.go});
  @override
  Widget build(BuildContext context) {
    const tiles = [
      ('Verified fuel', 'Sourced directly from partner stations', IconName.fuel),
      ('Trained drivers', 'Identity and safety checks completed', IconName.profile),
      ('Sealed equipment', 'Calibrated tanks and tamper seals', IconName.shield),
      ('Live tracking', 'Shareable trip and driver details', IconName.location),
    ];
    return AppPage(
      header: PageHeader(title: 'Safety centre', goBack: () => app.backOr(Screen.profile)),
      body: Narrow(gap: 18, children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(children: gapped([
            const RoundFeature(IconName.shield, size: 30),
            const FcText('Your safety comes first.', kind: Tx.title, align: TextAlign.center),
            const FcText('Every delivery is handled by trained partners using certified metered equipment and verified station fuel.', color: FC.muted, align: TextAlign.center),
          ], 13)),
        ),
        LayoutBuilder(builder: (c, cons) {
          final w = (cons.maxWidth - 10) / 2;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final t in tiles)
              SizedBox(
                width: w,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 145),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: FC.line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Ic(t.$3, color: FC.gold),
                    const SizedBox(height: 9),
                    FcText(t.$1, kind: Tx.label),
                    const SizedBox(height: 9),
                    FcText(t.$2, kind: Tx.caption, color: FC.muted),
                  ]),
                ),
              ),
          ]);
        }),
        Tap(
          onTap: () async {
            try {
              await launchUrl(Uri.parse('tel:999'));
            } catch (_) {
              if (context.mounted) toast(context, 'Call 999 for Uganda emergency services.');
            }
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: al(FC.danger, .06), borderRadius: BorderRadius.circular(12), border: Border.all(color: al(FC.danger, .25))),
            child: Row(children: [
              const Ic(IconName.phone, color: FC.danger),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText('Emergency assistance', kind: Tx.label, color: FC.danger), FcText('Call Uganda emergency services · 999', kind: Tx.caption, color: FC.danger)])),
              const Ic(IconName.chevron, color: FC.danger),
            ]),
          ),
        ),
      ]),
    );
  }
}
