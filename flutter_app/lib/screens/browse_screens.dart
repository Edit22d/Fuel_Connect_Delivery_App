import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/core.dart';
import '../services/auth_service.dart';
import 'sheets.dart';

// ===========================================================================
// Home
// ===========================================================================
class HomeScreen extends StatefulWidget {
  final Go go;
  const HomeScreen({super.key, required this.go});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _q = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Station> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kStations;
    return kStations.where((s) {
      final hay = '${s.name} ${s.brand} petrol diesel'.toLowerCase();
      return q.split(RegExp(r'\s+')).every(hay.contains);
    }).toList();
  }

  Widget _quick(BuildContext context, IconName icon, String label, Widget value, String pill) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF15181C), Color(0xFF0E1114)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FC.line),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: al(FC.gold, .09), borderRadius: BorderRadius.circular(10)),
            child: Ic(icon, color: FC.gold),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText(label, kind: Tx.label, color: FC.muted), value])),
          LivePill(pill),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final pad = cl(context, 20, 5, 70);
    final results = _results;
    final hero = ConstrainedBox(
      constraints: BoxConstraints(minHeight: wide ? 485 : 395),
      child: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/station-hero.jpg', fit: BoxFit.cover, alignment: const Alignment(0, .14))),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xF8080A0C), Color(0xAD080A0C), Color(0x66080A0C)], stops: [0, .62, 1]),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00080A0C), FC.black], stops: [.55, 1])),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(pad, topInset(context) + 26, math.max(pad, kRightInset), 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FcText('Good evening,', kind: Tx.caption, color: FC.muted),
                FcText(auth.profile.name, kind: Tx.subtitle),
              ]),
              Tap(
                onTap: () => widget.go(Screen.profile),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: FC.surface2, border: Border.all(color: const Color(0xFF6B5A1E))),
                  child: Text(auth.profile.initials, style: fs(11.2, color: FC.gold, w: FontWeight.w800, h: 1)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Tap(
              onTap: () async {
                await showLocationSheet(context);
                if (mounted) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xB8080A0C), borderRadius: BorderRadius.circular(20), border: Border.all(color: al(Colors.white, .1))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Ic(IconName.location, size: 16, color: FC.gold),
                  const SizedBox(width: 8),
                  Text(app.location, style: fs(10.56)),
                  const SizedBox(width: 8),
                  Ic(IconName.chevron, size: 15, color: FC.muted),
                ]),
              ),
            ),
            const SizedBox(height: 42),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 570),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: gapped([
                FcText('FUEL ON YOUR SCHEDULE', kind: Tx.label, color: FC.gold),
                const FcText('Running low?\nWe’re already close.', kind: Tx.display),
                FcText('Genuine fuel from trusted stations, delivered safely to you.', color: FC.muted),
                const SizedBox(height: 0),
                FcButton('Order fuel now', expand: false, trailingIcon: IconName.arrow, onTap: () => widget.go(Screen.station)),
              ], 13)),
            ),
          ]),
        ),
      ]),
    );

    final quick = LayoutBuilder(builder: (c, cons) {
      final one = vw(context) <= 380;
      final a = _quick(context, IconName.fuel, 'Petrol average',
          Text.rich(TextSpan(style: ts(context, Tx.subtitle), children: [const TextSpan(text: 'UGX 5,180 '), TextSpan(text: '/L', style: fs(10.4, color: FC.muted))])), '−2.4%');
      final b = _quick(context, IconName.clock, 'Avg. arrival', Text.rich(TextSpan(style: ts(context, Tx.subtitle), children: [const TextSpan(text: '22 '), TextSpan(text: 'min', style: fs(10.4, color: FC.muted))])), 'Live');
      if (one) return Column(children: [a, const SizedBox(height: 12), b]);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);
    });

    final list = results.isEmpty
        ? Padding(padding: EdgeInsets.symmetric(vertical: 24), child: FcText('No stations match your search.', color: FC.muted, align: TextAlign.center))
        : LayoutBuilder(builder: (c, cons) {
            final cols = wide ? 2 : 1;
            final w = (cons.maxWidth - 14 * (cols - 1)) / cols;
            return Wrap(spacing: 14, runSpacing: 14, children: [for (final s in results) SizedBox(width: w, child: StationCard(s, onTap: () => widget.go(Screen.station)))]);
          });

    return AppPage(
      nav: true,
      navCurrent: Screen.home,
      go: widget.go,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        hero,
        ContentSection(children: [
          SearchBox(hint: 'Search stations or fuel type', controller: _q, onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 22),
          quick,
          const SizedBox(height: 8),
          SectionHeading('Nearby stations', caption: 'Verified partners near you', trailing: TextAction('See all', onTap: () => widget.go(Screen.partners))),
          SizedBox(
            height: 81,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final p in kPartners) Padding(padding: const EdgeInsets.only(right: 9, bottom: 15), child: PartnerChip(p, onTap: () => widget.go(Screen.partners))),
            ]),
          ),
          const SizedBox(height: 8),
          list,
        ]),
      ]),
    );
  }
}

// ===========================================================================
// Partner stations
// ===========================================================================
class PartnersScreen extends StatefulWidget {
  final Go go;
  const PartnersScreen({super.key, required this.go});
  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final _q = TextEditingController();
  String _query = '';
  String _filter = 'All';
  static const _filters = ['All', 'Nearest', 'Best price', 'Open now'];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Station> get _results {
    var l = kStations.where((s) => _query.trim().isEmpty || '${s.name} ${s.brand}'.toLowerCase().contains(_query.trim().toLowerCase())).toList();
    if (_filter == 'Nearest') l.sort((a, b) => a.km.compareTo(b.km));
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final results = _results;
    return AppPage(
      nav: true,
      navCurrent: Screen.partners,
      go: widget.go,
      header: PageHeader(title: 'Partner stations', goBack: () => app.backOr(Screen.home), action: RoundAction(IconName.profile, onTap: () => widget.go(Screen.profile))),
      body: ContentSection(maxWide: 2000, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FcText('VERIFIED NETWORK', kind: Tx.label, color: FC.gold),
          const SizedBox(height: 8),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: const FcText('Choose a station you trust.', kind: Tx.title)),
          const SizedBox(height: 8),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: FcText('Compare live prices, delivery times, and verified product availability across Kampala.', color: FC.muted)),
        ]),
        const SizedBox(height: 18),
        SearchBox(hint: 'Search by station, area or fuel', controller: _q, onChanged: (v) => setState(() => _query = v)),
        const SizedBox(height: 18),
        SizedBox(
          height: 34,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final f in _filters)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tap(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: f == _filter ? FC.gold : FC.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: f == _filter ? FC.gold : FC.line),
                    ),
                    child: Text(f, style: fs(9.92, color: f == _filter ? FC.onGold : FC.muted, w: f == _filter ? FontWeight.w800 : FontWeight.w400, h: 1.2)),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (c, cons) {
          final cols = wide ? 3 : 2;
          final w = (cons.maxWidth - 10 * (cols - 1)) / cols;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (var i = 0; i < kPartners.length; i++)
              SizedBox(
                width: w,
                child: Tap(
                  onTap: () => widget.go(Screen.station),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 86),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: FC.line)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        PartnerMonogram(kPartners[i]),
                        const SizedBox(width: 11),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          FcText(kPartners[i].name, kind: Tx.subtitle, maxLines: 1),
                          FcText('${i + 3} stations nearby', kind: Tx.caption, color: FC.muted),
                        ])),
                      ]),
                      const SizedBox(height: 3),
                      const Padding(padding: EdgeInsets.only(left: 55), child: VerifiedPill('Partner', check: true)),
                    ]),
                  ),
                ),
              ),
          ]);
        }),
        const SectionHeading('Available near you', caption: 'Sorted by fastest delivery'),
        if (results.isEmpty)
          Padding(padding: EdgeInsets.symmetric(vertical: 24), child: FcText('No stations match your search.', color: FC.muted, align: TextAlign.center))
        else
          LayoutBuilder(builder: (c, cons) {
            final cols = wide ? 2 : 1;
            final w = (cons.maxWidth - 14 * (cols - 1)) / cols;
            return Wrap(spacing: 14, runSpacing: 14, children: [for (final s in results) SizedBox(width: w, child: StationCard(s, onTap: () => widget.go(Screen.station)))]);
          }),
      ]),
    );
  }
}

// ===========================================================================
// Station detail
// ===========================================================================
class StationScreen extends StatefulWidget {
  final Go go;
  const StationScreen({super.key, required this.go});
  @override
  State<StationScreen> createState() => _StationScreenState();
}

class _StationScreenState extends State<StationScreen> {
  Widget _stat(IconName icon, String value, String label, {bool last = false}) => Expanded(
        child: Container(
          decoration: BoxDecoration(border: last ? null : Border(right: BorderSide(color: FC.line))),
          child: Column(children: [
            Ic(icon, color: FC.gold),
            const SizedBox(height: 4),
            FcText(value, kind: Tx.subtitle),
            const SizedBox(height: 4),
            FcText(label, kind: Tx.caption, color: FC.muted),
          ]),
        ),
      );

  Widget _product(String name, String sub, String price, IconName icon) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: FC.line)),
        child: Row(children: [
          IconBox(icon),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FcText(name, kind: Tx.subtitle), FcText(sub, kind: Tx.caption, color: FC.muted)])),
          FcText(price, kind: Tx.subtitle, color: FC.gold),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final coverH = math.max(360.0, vh(context) * (wide ? .58 : .47));
    final pad = cl(context, 18, 5, 50);
    final tpad = cl(context, 20, 6, 70);
    final cover = SizedBox(
      height: coverH,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/station-hero.jpg', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x40000000), Color(0x00000000), Colors.black], stops: [0, .3, 1]),
          ),
        ),
        Positioned(
          top: topInset(context) + 18,
          left: pad,
          right: math.max(pad, kRightInset),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            FcButton.icon(IconName.arrow, onTap: () => app.backOr(Screen.home)),
            Tap(
              onTap: () {
                setState(() => app.stationSaved = !app.stationSaved);
                toast(context, app.stationSaved ? 'Station saved to your favourites.' : 'Removed from favourites.');
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: const Color(0xC20C0E11), borderRadius: BorderRadius.circular(12), border: Border.all(color: al(Colors.white, .12))),
                child: Center(child: Ic(IconName.star, size: 18, color: app.stationSaved ? FC.gold : FC.ink, filled: app.stationSaved)),
              ),
            ),
          ]),
        ),
        Positioned(
          left: tpad,
          right: tpad,
          bottom: 26,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const VerifiedPill('Verified partner', check: true, iconSize: 14),
            const SizedBox(height: 8),
            FcText('STABEX', kind: Tx.label, color: FC.gold),
            const SizedBox(height: 8),
            const FcText('Stabex Kira Road', kind: Tx.display),
            const SizedBox(height: 8),
            FcText('Kira Road, Kampala · Open 24 hours', kind: Tx.caption, color: FC.muted),
          ]),
        ),
      ]),
    );

    return AppPage(
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        cover,
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Padding(
              padding: EdgeInsets.fromLTRB(tpad, 8, tpad, 44 + bottomInset(context)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: FC.line))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _stat(IconName.star, '4.9', '320 reviews'),
                    _stat(IconName.location, '1.8 km', 'Distance'),
                    _stat(IconName.clock, '18–24', 'Minutes', last: true),
                  ]),
                ),
                SectionHeading('Available products', trailing: const VerifiedPill('Best price nearby')),
                _product('Premium Petrol', '95 octane · cleaner performance', 'UGX 5,180/L', IconName.fuel),
                const SizedBox(height: 10),
                _product('Ultra Diesel', 'High efficiency · low sulphur', 'UGX 4,960/L', IconName.fuel),
                const SizedBox(height: 22),
                FcButton('Choose fuel', trailingIcon: IconName.arrow, onTap: () => widget.go(Screen.fuel)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
