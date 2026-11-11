// Temporary stand-ins for the 4 screens that shell.dart expects but that are
// missing from the project. Replace them if you recover the originals.
import 'package:flutter/material.dart';
import '../core/core.dart';

// ===========================================================================
// Saved places
// ===========================================================================
class AddressesScreen extends StatelessWidget {
  final Go go;
  const AddressesScreen({super.key, required this.go});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: PageHeader(title: 'Saved places', goBack: () => app.backOr(Screen.profile)),
      body: Narrow(gap: 12, padTop: 20, children: [
        Panel(
          child: Row(children: [
            IconBox(IconName.location),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FcText('Current location', kind: Tx.subtitle),
                FcText(app.location, kind: Tx.caption, color: FC.muted),
              ]),
            ),
          ]),
        ),
        Panel(
          child: Row(children: [
            IconBox(IconName.home),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FcText('Delivery address', kind: Tx.subtitle),
                FcText(app.deliveryAddress, kind: Tx.caption, color: FC.muted),
              ]),
            ),
          ]),
        ),
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
      body: Narrow(gap: 12, padTop: 20, children: [
        for (final v in app.vehicles)
          Tap(
            onTap: () => setState(() => app.vehicleId = v.id),
            child: Panel(
              border: app.vehicleId == v.id ? FC.gold : null,
              child: Row(children: [
                IconBox(IconName.truck),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FcText(v.name, kind: Tx.subtitle),
                    FcText('${v.plate} · ${v.fuel} · ${v.color} · ${v.tank}', kind: Tx.caption, color: FC.muted),
                  ]),
                ),
                RadioDot(selected: app.vehicleId == v.id),
              ]),
            ),
          ),
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
    return AppPage(
      header: PageHeader(title: 'Help centre', goBack: () => app.backOr(Screen.profile)),
      body: Narrow(gap: 12, padTop: 20, children: [
        RoundFeature(IconName.phone),
        FcText('How can we help?', kind: Tx.title, align: TextAlign.center),
        FcText('Support options will appear here soon.', kind: Tx.body, color: FC.muted, align: TextAlign.center),
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
    return AppPage(
      header: PageHeader(title: 'Safety centre', goBack: () => app.backOr(Screen.profile)),
      body: Narrow(gap: 12, padTop: 20, children: [
        SafetyNote(title: 'Verified delivery partners', body: 'Every delivery partner is checked before they can accept orders.'),
        SafetyNote(title: 'Pre-trip safety check', body: 'Partners complete a safety check before collecting your fuel.'),
      ]),
    );
  }
}