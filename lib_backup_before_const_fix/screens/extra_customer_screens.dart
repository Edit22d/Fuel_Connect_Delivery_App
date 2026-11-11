import 'package:flutter/material.dart';
import '../core/core.dart';
import '../core/extras_state.dart';
import '../services/auth_service.dart';

// Screens that exist in the Figma prototype but were missing in Flutter:
//   • Order confirmed   • Edit profile   • App settings
// (Cancel order already lives in order_screens.dart and is only wired in.)

Widget _chevron() => const Ic(IconName.chevron, size: 18, color: FC.dim);

Widget _sectionLabel(String t) => Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 10),
      child: FcText(t, kind: Tx.label, color: FC.gold),
    );

/// Gold ringed badge used on the confirmation style screens.
class _OrbitBadge extends StatelessWidget {
  final IconName icon;
  const _OrbitBadge(this.icon);
  @override
  Widget build(BuildContext context) => Center(
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
              child: Center(child: Ic(icon, size: 44, color: const Color(0xFF111111))),
            ),
          ),
        ),
      );
}

// ===========================================================================
// Order confirmed
// ===========================================================================
class OrderConfirmationScreen extends StatelessWidget {
  final Go go;
  const OrderConfirmationScreen({super.key, required this.go});

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
                  const _OrbitBadge(IconName.check),
                  const FcText('PAYMENT CONFIRMED', kind: Tx.label, color: FC.gold, align: TextAlign.center),
                  const FcText('Your order is confirmed.', kind: Tx.display, align: TextAlign.center),
                  FcText('Stabex Kira Road is preparing your fuel. We’ll assign a certified delivery partner shortly.', color: FC.muted, align: TextAlign.center),
                  Panel(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: const Column(children: [
                      FcText('ORDER NUMBER', kind: Tx.caption, color: FC.muted),
                      SizedBox(height: 4),
                      FcText('#FC-29841', kind: Tx.title),
                    ]),
                  ),
                  Panel(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: gapped([
                      KvRow(app.productName, '${app.litres} litres', size: 10.88),
                      KvRow('Deliver to', app.deliveryAddress, size: 10.88),
                      const KvRow('Estimated arrival', '18–24 minutes', size: 10.88),
                      KvRow('Total paid', 'UGX ${fmt(app.orderTotal)}', size: 10.88),
                    ], 11)),
                  ),
                  Panel(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      const Ic(IconName.bell, color: FC.gold),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          FcText('We’ll keep you updated', kind: Tx.label),
                          FcText('You’ll receive an alert when your rider collects the fuel.', kind: Tx.caption, color: FC.muted),
                        ]),
                      ),
                    ]),
                  ),
                  FcButton('Track my order', onTap: () => go(Screen.tracking)),
                  FcButton('Back to home', variant: BV.ghost, onTap: () => go(Screen.home, root: true)),
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
// Edit profile
// ===========================================================================
class EditProfileScreen extends StatefulWidget {
  final Go go;
  const EditProfileScreen({super.key, required this.go});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: auth.profile.name);
  late final _email = TextEditingController(text: auth.profile.email);
  late final _emergency = TextEditingController(text: extras.emergencyContact);
  String? _nameErr, _emailErr, _emergencyErr;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _emergency.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _nameErr = Validators.name(_name.text);
      _emailErr = Validators.email(_email.text);
      _emergencyErr = _emergency.text.trim().isEmpty ? null : Validators.phone(_emergency.text);
    });
    if (_nameErr != null || _emailErr != null || _emergencyErr != null) return;
    setState(() => _busy = true);
    await auth.updateProfile(_name.text.trim(), _email.text.trim());
    extras.emergencyContact = _emergency.text.trim();
    extras.changed();
    if (!mounted) return;
    setState(() => _busy = false);
    toast(context, 'Your profile has been updated.', gold: true);
    app.backOr(Screen.profile);
  }

  @override
  Widget build(BuildContext context) {
    final pr = auth.profile;
    return AppPage(
      header: PageHeader(title: 'Edit profile', goBack: () => app.backOr(Screen.profile)),
      body: Narrow(gap: 20, children: [
        Column(children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: FC.surface2, border: Border.all(color: const Color(0xFF6B5A1E))),
            child: Text(pr.initials, style: fs(22, color: FC.gold, w: FontWeight.w800, h: 1)),
          ),
          const SizedBox(height: 6),
          TextAction('Change photo', onTap: () => toast(context, 'Photo upload will be available once the backend is connected.')),
        ]),
        FcField(label: 'Full name', hint: 'Joel Kato', icon: IconName.profile, controller: _name, error: _nameErr, action: TextInputAction.next),
        // The phone number is the sign-in identity, so changing it needs a
        // verification code. It is shown read-only here.
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FcText('Phone number', kind: Tx.label, color: FC.muted),
          const SizedBox(height: 8),
          Panel(
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              const Ic(IconName.phone, size: 18, color: FC.dim),
              const SizedBox(width: 12),
              Expanded(child: FcText(maskPhone(pr.phone), kind: Tx.body)),
              const VerifiedPill('VERIFIED', check: true),
            ]),
          ),
          const SizedBox(height: 6),
          const FcText('To change your number, contact FuelConnect support.', kind: Tx.caption, color: FC.muted),
        ]),
        FcField(label: 'Email address', hint: 'joel.kato@email.com', icon: IconName.card, controller: _email, keyboard: TextInputType.emailAddress, error: _emailErr, action: TextInputAction.next),
        FcField(label: 'Emergency contact', hint: '+256 772 000 000', icon: IconName.phone, controller: _emergency, keyboard: TextInputType.phone, error: _emergencyErr, action: TextInputAction.done, onSubmitted: (_) => _save()),
        FcButton('Save changes', loading: _busy, onTap: _save),
      ]),
    );
  }
}

/// ===========================================================================
// App settings
// ===========================================================================
class AppSettingsScreen extends StatefulWidget {
  final Go go;
  const AppSettingsScreen({super.key, required this.go});
  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  Widget _row(IconName icon, String label, {VoidCallback? onTap, Widget? trailing, bool last = false}) => Tap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 57),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: FC.line))),
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

  Future<void> _changePassword() async {
    final ok = await confirmDialog(
      context,
      title: 'Change password',
      body: 'We’ll send a verification code to ${maskPhone(auth.profile.phone)} so you can set a new password.',
      confirm: 'Send code',
    );
    if (!ok || !mounted) return;
    final r = await auth.requestPasswordReset(auth.profile.phone);
    if (!mounted) return;
    if (!r.ok) {
      toast(context, r.error ?? 'We couldn’t start the password change. Try again.');
      return;
    }
    auth.startOtp(OtpPurpose.reset, phone: auth.profile.phone);
    widget.go(Screen.otp);
  }

  Future<void> _pickLanguage() async {
    await showFcSheet<void>(
      context,
      title: 'Language',
      builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final l in ExtrasState.languages)
          Tap(
            onTap: () {
              extras.language = l;
              extras.changed();
              Navigator.of(ctx).pop();
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: FC.line))),
              child: Row(children: [
                Expanded(child: FcText(l, kind: Tx.label)),
                RadioDot(selected: extras.language == l),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        FcText('More languages are coming soon. Screens stay in English for now.', kind: Tx.caption, color: FC.muted),
      ]),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: PageHeader(title: 'App settings', goBack: () => app.backOr(Screen.profile)),
      body: Narrow(gap: 0, padTop: 8, children: [
        _sectionLabel('APPEARANCE'),
        _group([
          _row(IconName.star, 'Dark mode', last: true, trailing: FcToggle(on: app.isDark, onTap: () => setState(() => app.toggleTheme()))),
        ]),
        _sectionLabel('NOTIFICATIONS'),
        _group([
          _row(IconName.bell, 'Order updates', trailing: FcToggle(on: extras.orderUpdatesOn, onTap: () => setState(() => extras.orderUpdatesOn = !extras.orderUpdatesOn))),
          _row(IconName.star, 'Offers and promotions', last: true, trailing: FcToggle(on: extras.promosOn, onTap: () => setState(() => extras.promosOn = !extras.promosOn))),
        ]),
        _sectionLabel('SECURITY'),
        _group([
          _row(IconName.shield, 'Biometric sign in', trailing: FcToggle(on: extras.biometricOn, onTap: () => setState(() => extras.biometricOn = !extras.biometricOn))),
          _row(IconName.shield, 'Change password', onTap: _changePassword, last: true),
        ]),
        _sectionLabel('GENERAL'),
        _group([
          _row(IconName.location, 'Language · ${extras.language}', onTap: _pickLanguage),
          _row(IconName.card, 'Currency · UGX', last: true, onTap: () => toast(context, 'Ugandan shilling (UGX) is the only supported currency for now.')),
        ]),
      ]),
    );
  }
}