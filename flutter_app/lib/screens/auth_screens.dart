import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/core.dart';
import '../services/auth_service.dart';
import 'sheets.dart';

// ===========================================================================
// Splash
// ===========================================================================
class SplashScreen extends StatefulWidget {
  final Go go;
  const SplashScreen({super.key, required this.go});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1800), _next);
  }

  void _next() {
    if (mounted) widget.go(Screen.onboarding, replace: true);
  }

  @override
  void dispose() {
    _t?.cancel();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _t?.cancel();
        _next();
      },
      child: ColoredBox(
        color: FC.black,
        child: Stack(children: [
          Positioned.fill(
            child: Glow(fx: .5, fy: .37, colors: [Color(0xFF26220E), Color(0xFF0D0F11), FC.black], stops: [0, .34, .67]),
          ),
          Center(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: al(FC.gold, .08))),
            ),
          ),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Transform.scale(
  scale: 1.35,
  child: Image.asset(
    'assets/images/logo.png',
    width: 220,
    height: 220,
    fit: BoxFit.contain,
  ),
),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: FcText('Fuel, delivered wherever the road takes you.', kind: Tx.caption, color: FC.muted, align: TextAlign.center),
              ),
            ]),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: vh(context) * .09,
            child: Center(
              child: SizedBox(
                width: 84,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    color: FC.line,
                    child: AnimatedBuilder(
                      animation: _ac,
                      builder: (_, __) {
                        final t = Curves.easeInOut.transform(_ac.value);
                        final x = -37.8 + (83.16 + 37.8) * t;
                        return Transform.translate(
                          offset: Offset(x, 0),
                          child: Align(alignment: Alignment.centerLeft, child: Container(width: 37.8, color: FC.gold)),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Onboarding
// ===========================================================================
class OnboardingScreen extends StatefulWidget {
  final Go go;
  const OnboardingScreen({super.key, required this.go});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _i = 0;

  void _next() {
    if (_i == kSlides.length - 1) {
      widget.go(Screen.login);
    } else {
      setState(() => _i++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = kSlides[_i];
    final wide = isWide(context);
    final h = cl(context, 20, 5, 56);
    final image = Stack(fit: StackFit.expand, children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Image.asset(s.image, key: ValueKey(s.image), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      ),
      const ImageShade(),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Padding(
          padding: EdgeInsets.fromLTRB(h, topInset(context) + 24, math.max(h, kRightInset), 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 55,
  fit: BoxFit.contain,
),
            TextAction('Skip', onTap: () => widget.go(Screen.login)),
          ]),
        ),
      ),
    ]);

    final pad = cl(context, 22, 5, 64);
    final copy = LayoutBuilder(
      builder: (context, cons) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: cons.maxHeight),
          child: Padding(
            padding: wide ? EdgeInsets.symmetric(horizontal: vw(context) * .07, vertical: vw(context) * .09) : EdgeInsets.fromLTRB(pad, 10, pad, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FcText(s.eyebrow, kind: Tx.label, color: FC.gold),
                  const SizedBox(height: 15),
                  FcText(s.title, kind: Tx.display),
                  const SizedBox(height: 15),
                  ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500), child: FcText(s.body, color: FC.muted)),
                ]),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 18),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      for (var d = 0; d < kSlides.length; d++)
                        Tap(
                          onTap: () => setState(() => _i = d),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 7, top: 6, bottom: 6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: d == _i ? 28 : 7,
                              height: 7,
                              decoration: BoxDecoration(color: d == _i ? FC.gold : FC.dim, borderRadius: BorderRadius.circular(9)),
                            ),
                          ),
                        ),
                    ]),
                    FcButton(_i == kSlides.length - 1 ? 'Get started' : 'Continue', expand: false, trailingIcon: IconName.arrow, onTap: _next),
                  ]),
                ]),
              ],
            ),
          ),
        ),
      ),
    );

    if (wide) {
      return ColoredBox(
        color: FC.black,
        child: Row(children: [Expanded(flex: 56, child: image), Expanded(flex: 44, child: copy)]),
      );
    }
    return ColoredBox(
      color: FC.black,
      child: Column(children: [SizedBox(height: vh(context) * .56, child: image), Expanded(child: copy)]),
    );
  }
}

// ===========================================================================
// Shared auth layout (image on top / left, form card)
// ===========================================================================
class _AuthLayout extends StatelessWidget {
  final List<Widget> children;
  const _AuthLayout({required this.children});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final visual = Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/pump.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      const ImageShade(),
      Positioned(left: 24, top: topInset(context) + 24, child: const Logo(compact: true)),
    ]);
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(children, 15)),
                      ),
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
          SizedBox(height: math.max(240, vh(context) * .34), child: visual),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 36 + bottomInset(context)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(children, 15)),
          ),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final String text;
  const _Divider(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Divider(color: FC.line, height: 1)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: FcText(text, kind: Tx.caption, color: FC.dim)),
        Expanded(child: Divider(color: FC.line, height: 1)),
      ]);
}

class _InlineLink extends StatelessWidget {
  final String lead, link;
  final VoidCallback onTap;
  const _InlineLink(this.lead, this.link, this.onTap);
  @override
  Widget build(BuildContext context) => Center(
        child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
          FcText(lead, kind: Tx.caption, color: FC.muted),
          const SizedBox(width: 4),
          Tap(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(link, style: fs(11.52, color: FC.gold, w: FontWeight.w700)))),
        ]),
      );
}

// ===========================================================================
// Sign in
// ===========================================================================
class LoginScreen extends StatefulWidget {
  final Go go;
  const LoginScreen({super.key, required this.go});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final r = await auth.signIn(_phone.text, _pass.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _formErr = r.error);
      return;
    }
    auth.startOtp(OtpPurpose.login, phone: _phone.text);
    widget.go(Screen.otp);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthLayout(children: [
      FcText('WELCOME BACK', kind: Tx.label, color: FC.gold),
      const FcText('Sign in to FuelConnect', kind: Tx.title),
      FcText('Fuel from trusted stations, delivered wherever you are.', color: FC.muted),
      FcField(label: 'Phone number', hint: '+256 700 123 456', icon: IconName.phone, controller: _phone, keyboard: TextInputType.phone, error: _phoneErr, action: TextInputAction.next),
      FcField(label: 'Password', hint: 'Enter your password', icon: IconName.shield, password: true, controller: _pass, error: _passErr, action: TextInputAction.done, onSubmitted: (_) => _submit()),
      Align(alignment: Alignment.centerRight, child: TextAction('Forgot password?', onTap: () => widget.go(Screen.forgot))),
      if (_formErr != null) FormError(_formErr!),
      FcButton('Sign in securely', loading: _busy, onTap: _submit),
      const _Divider('or continue with'),
      FcButton('Continue with Google', variant: BV.outline, onTap: () => toast(context, 'Google sign-in will be available once the backend is connected.')),
      _InlineLink('New to FuelConnect?', 'Create account', () => widget.go(Screen.signup)),
    ]);
  }
}

// ===========================================================================
// Create account
// ===========================================================================
class SignupScreen extends StatefulWidget {
  final Go go;
  const SignupScreen({super.key, required this.go});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String? _nameErr, _phoneErr, _emailErr, _passErr, _formErr;
  bool _agree = true, _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _nameErr = Validators.name(_name.text);
      _phoneErr = Validators.phone(_phone.text);
      _emailErr = Validators.email(_email.text);
      _passErr = Validators.password(_pass.text);
      _formErr = _agree ? null : 'Please accept the Terms of Service and Fuel Delivery Safety Policy to continue.';
    });
    if ([_nameErr, _phoneErr, _emailErr, _passErr, _formErr].any((e) => e != null)) return;
    setState(() => _busy = true);
    final r = await auth.signUp(name: _name.text, phone: _phone.text, email: _email.text, password: _pass.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _formErr = r.error);
      return;
    }
    auth.startOtp(OtpPurpose.signup, phone: _phone.text);
    widget.go(Screen.otp);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: PageHeader(title: 'Create account', goBack: () => app.backOr(Screen.login)),
      body: Narrow(gap: 20, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FcText('JOIN FUELCONNECT', kind: Tx.label, color: FC.gold),
          SizedBox(height: 9),
          FcText('Let’s get you moving.', kind: Tx.title),
          SizedBox(height: 9),
          FcText('Create an account for safe, trackable fuel delivery.', color: FC.muted),
        ]),
        FcField(label: 'Full name', hint: 'Your full name', icon: IconName.profile, controller: _name, error: _nameErr, action: TextInputAction.next),
        FcField(label: 'Phone number', hint: '+256 700 123 456', icon: IconName.phone, controller: _phone, keyboard: TextInputType.phone, error: _phoneErr, action: TextInputAction.next),
        FcField(label: 'Email address', hint: 'name@email.com', icon: IconName.card, controller: _email, keyboard: TextInputType.emailAddress, error: _emailErr, action: TextInputAction.next),
        FcField(label: 'Create password', hint: 'At least 8 characters', icon: IconName.shield, password: true, controller: _pass, error: _passErr, action: TextInputAction.done, onSubmitted: (_) => _submit()),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              activeColor: FC.gold,
              checkColor: FC.onGold,
              side: BorderSide(color: FC.dim),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: FcText('I agree to the Terms of Service and Fuel Delivery Safety Policy.', kind: Tx.caption, color: FC.muted)),
        ]),
        if (_formErr != null) FormError(_formErr!),
        FcButton('Create secure account', loading: _busy, onTap: _submit),
        _InlineLink('Already registered?', 'Sign in', () => app.backOr(Screen.login)),
      ]),
    );
  }
}

// ===========================================================================
// Forgot password
// ===========================================================================
class ForgotScreen extends StatefulWidget {
  final Go go;
  const ForgotScreen({super.key, required this.go});
  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _phone = TextEditingController();
  String? _err;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final v = Validators.phone(_phone.text);
    if (v != null) {
      setState(() => _err = v);
      return;
    }
    setState(() {
      _err = null;
      _busy = true;
    });
    final r = await auth.requestPasswordReset(_phone.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _err = r.error);
      return;
    }
    auth.startOtp(OtpPurpose.reset, phone: _phone.text);
    widget.go(Screen.otp);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: PageHeader(title: 'Reset password', goBack: () => app.backOr(Screen.login)),
      body: Narrow(gap: 20, padTop: vh(context) * .10, children: [
        const RoundFeature(IconName.shield),
        const FcText('Recover your account', kind: Tx.title, align: TextAlign.center),
        FcText('Enter your registered phone number. We’ll send you a secure reset code.', color: FC.muted, align: TextAlign.center),
        FcField(
          label: 'Phone number',
          hint: '+256 700 123 456',
          icon: IconName.phone,
          controller: _phone,
          keyboard: TextInputType.phone,
          labelAlign: TextAlign.center,
          error: _err,
          action: TextInputAction.done,
          onSubmitted: (_) => _send(),
        ),
        FcButton('Send reset code', loading: _busy, onTap: _send),
        FcButton('Return to sign in', variant: BV.ghost, onTap: () => app.backOr(Screen.login)),
      ]),
    );
  }
}

// ===========================================================================
// Verification (6 characters)
// ===========================================================================
class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) => n.copyWith(text: n.text.toUpperCase());
}

class CodeInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool error;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  const CodeInput({super.key, required this.controller, required this.focus, required this.error, required this.onChanged, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (c, cons) {
      final width = math.min(cons.maxWidth, 360.0);
      final box = (width - 10 * (kOtpLength - 1)) / kOtpLength;
      return Center(
        child: SizedBox(
          width: width,
          height: box,
          child: AnimatedBuilder(
            animation: Listenable.merge([controller, focus]),
            builder: (_, __) {
              final text = controller.text;
              final active = math.min(text.length, kOtpLength - 1);
              return Stack(children: [
                Row(children: [
                  for (var i = 0; i < kOtpLength; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Container(
                      width: box,
                      height: box,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FC.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: error ? FC.danger : (focus.hasFocus && i == active ? FC.gold : FC.line)),
                      ),
                      child: Text(i < text.length ? text[i] : '', style: fs(20.8, w: FontWeight.w700, h: 1)),
                    ),
                  ],
                ]),
                // One real input sits invisibly on top: gives paste, SMS autofill,
                // numeric keypad and backspace for free.
                Positioned.fill(
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    autofocus: true,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    keyboardType: kOtpAlphanumeric ? TextInputType.text : TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      kOtpAlphanumeric ? FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')) : FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(kOtpLength),
                      if (kOtpAlphanumeric) _UpperCase(),
                    ],
                    autofillHints: const [AutofillHints.oneTimeCode],
                    enableSuggestions: false,
                    autocorrect: false,
                    showCursor: false,
                    cursorColor: Colors.transparent,
                    style: const TextStyle(color: Colors.transparent, fontSize: 1),
                    decoration: const InputDecoration(border: InputBorder.none, counterText: '', contentPadding: EdgeInsets.zero),
                    onChanged: (_) => onChanged(),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
              ]);
            },
          ),
        ),
      );
    });
  }
}

class OtpScreen extends StatefulWidget {
  final Go go;
  const OtpScreen({super.key, required this.go});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _tick;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Opened from the menu without signing in first: start a demo challenge.
    if (!auth.hasPending) auth.startOtp(OtpPurpose.login, phone: AuthService.demoPhone);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _announce() {
    if (kDemoMode && auth.code != null && mounted) {
      toast(context, 'Demo mode · your code is ${auth.code}', gold: true, seconds: 25);
    }
  }

  Future<void> _verify() async {
    final code = _ctrl.text.trim();
    if (code.length < kOtpLength) {
      setState(() => _error = 'Enter all $kOtpLength characters of your code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    final r = auth.verifyOtp(code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _error = r.error);
      _ctrl.clear();
      _focus.requestFocus();
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    widget.go(r.purpose == OtpPurpose.reset ? Screen.newPassword : Screen.locationAccess, replace: true);
  }

  void _resend() {
    final p = auth.purpose ?? OtpPurpose.login;
    auth.startOtp(p, phone: auth.pendingPhone ?? AuthService.demoPhone);
    _ctrl.clear();
    setState(() => _error = null);
    _announce();
    _focus.requestFocus();
  }

  String _mmss(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final left = auth.secondsLeft;
    final resendIn = auth.resendIn;
    final phone = maskPhone(auth.pendingPhone ?? AuthService.demoPhone);
    return AppPage(
      header: PageHeader(
        title: 'Verification',
        goBack: () => app.backOr(auth.purpose == OtpPurpose.reset ? Screen.forgot : Screen.login),
      ),
      body: Narrow(gap: 20, padTop: vh(context) * .10, children: [
        const RoundFeature(IconName.phone),
        const FcText('Check your phone', kind: Tx.title, align: TextAlign.center),
        Column(children: [
          FcText('We sent a 6-digit security code to', color: FC.muted, align: TextAlign.center),
          FcText(phone, color: FC.ink, weight: FontWeight.w700, align: TextAlign.center),
        ]),
        CodeInput(
          controller: _ctrl,
          focus: _focus,
          error: _error != null,
          onChanged: () {
            if (_error != null) setState(() => _error = null);
          },
          onSubmit: _verify,
        ),
        if (_error != null) FcText(_error!, kind: Tx.caption, color: FC.danger, align: TextAlign.center),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FcText(left > 0 ? 'Code expires in ' : 'Code expired', kind: Tx.caption, color: FC.muted),
          if (left > 0) Text(_mmss(left), style: fs(11.52, color: FC.gold, w: FontWeight.w700)),
        ]),
        FcButton('Verify & continue', loading: _busy, onTap: _verify),
        FcButton(resendIn > 0 ? 'Send code again (${resendIn}s)' : 'Send code again', variant: BV.ghost, onTap: resendIn > 0 ? null : _resend),
      ]),
    );
  }
}

// ===========================================================================
// New password (create / change) with confirmation
// ===========================================================================
class NewPasswordScreen extends StatefulWidget {
  final Go go;
  const NewPasswordScreen({super.key, required this.go});
  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  String? _err1, _err2, _form;
  bool _busy = false, _done = false;

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _err1 = Validators.password(_p1.text);
      _err2 = _p2.text.isEmpty ? 'Confirm your new password' : (_p2.text != _p1.text ? 'Passwords don’t match' : null);
      _form = null;
    });
    if (_err1 != null || _err2 != null) return;
    setState(() => _busy = true);
    final r = await auth.resetPassword(_p1.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.ok) {
      setState(() => _form = r.error);
      return;
    }
    setState(() => _done = true);
  }

  Widget _rule(String text, bool ok) => Row(children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(shape: BoxShape.circle, color: ok ? al(FC.green, .15) : Colors.transparent, border: Border.all(color: ok ? FC.green : FC.dim)),
          child: ok ? Center(child: Ic(IconName.check, size: 11, color: FC.green)) : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: FcText(text, kind: Tx.caption, color: ok ? FC.ink : FC.muted)),
      ]);

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return AppPage(
        header: const PageHeader(title: 'New password'),
        body: Narrow(gap: 20, padTop: vh(context) * .10, children: [
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FC.gold, FC.goldDeep]), boxShadow: [BoxShadow(color: al(FC.gold, .18), blurRadius: 45, offset: const Offset(0, 14))]),
              child: Center(child: Ic(IconName.check, size: 44, color: FC.onGold)),
            ),
          ),
          const FcText('Password updated', kind: Tx.title, align: TextAlign.center),
          FcText('Your password has been changed. Sign in with your new password to continue.', color: FC.muted, align: TextAlign.center),
          FcButton('Back to sign in', onTap: () => widget.go(Screen.login, root: true)),
        ]),
      );
    }

    final p = _p1.text;
    final strength = Validators.strength(p);
    final strengthLabel = ['', 'Weak', 'Fair', 'Good', 'Strong'][strength];
    final strengthColor = strength <= 1 ? FC.danger : (strength == 4 ? FC.green : FC.gold);
    final match = _p2.text.isNotEmpty;
    final matches = _p2.text == _p1.text;

    return AppPage(
      header: PageHeader(title: 'New password', goBack: () => app.backOr(Screen.login)),
      body: Narrow(gap: 20, children: [
        const RoundFeature(IconName.shield),
        const FcText('Create a new password', kind: Tx.title, align: TextAlign.center),
        FcText('Choose a strong password you haven’t used before. You’ll use it to sign in to FuelConnect.', color: FC.muted, align: TextAlign.center),
        FcField(label: 'New password', hint: 'At least 8 characters', icon: IconName.shield, password: true, showToggle: true, controller: _p1, error: _err1, action: TextInputAction.next, onChanged: (_) => setState(() {})),
        if (p.isNotEmpty)
          Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 4, decoration: BoxDecoration(color: i < strength ? strengthColor : FC.line, borderRadius: BorderRadius.circular(4)))),
            ],
            const SizedBox(width: 10),
            Text(strengthLabel, style: fs(10.88, color: strengthColor, w: FontWeight.w700)),
          ]),
        FcField(label: 'Confirm new password', hint: 'Re-enter your password', icon: IconName.shield, password: true, showToggle: true, controller: _p2, error: _err2, action: TextInputAction.done, onChanged: (_) => setState(() {}), onSubmitted: (_) => _submit()),
        if (match && _err2 == null) FcText(matches ? 'Passwords match' : 'Passwords don’t match yet', kind: Tx.caption, color: matches ? FC.green : FC.danger),
        Panel(
          radius: 12,
          padding: const EdgeInsets.all(14),
          child: Column(children: gapped([
            _rule('At least 8 characters', Validators.hasLen(p)),
            _rule('Includes a letter and a number', Validators.hasLetterAndNumber(p)),
            _rule('Both fields match', match && matches && p.isNotEmpty),
          ], 10)),
        ),
        if (_form != null) FormError(_form!),
        if (_form != null && !auth.resetVerified) FcButton('Start password reset', variant: BV.outline, onTap: () => widget.go(Screen.forgot, replace: true)),
        FcButton('Update password', loading: _busy, onTap: _submit),
        FcButton('Cancel and return to sign in', variant: BV.ghost, onTap: () => widget.go(Screen.login, root: true)),
      ]),
    );
  }
}

// ===========================================================================
// Location access
// ===========================================================================
class LocationAccessScreen extends StatelessWidget {
  final Go go;
  const LocationAccessScreen({super.key, required this.go});

  Widget _map(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      const MapGrid(bg: Color(0xFF121619), step: 30),
      LayoutBuilder(builder: (c, cons) {
        final cx = cons.maxWidth / 2, cy = cons.maxHeight * .47;
        Widget ring(double d) => Positioned(
              left: cx - d / 2,
              top: cy - d / 2,
              child: Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: al(FC.gold, .18)))),
            );
        return Stack(children: [
          ring(310),
          ring(180),
          Positioned(
            left: cx - 34,
            top: cy - 34,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FC.gold,
                boxShadow: [
                  BoxShadow(color: al(FC.gold, .1), spreadRadius: 12),
                  BoxShadow(color: al(Colors.black, .35), blurRadius: 45, offset: const Offset(0, 18)),
                ],
              ),
              child: Center(child: Ic(IconName.location, size: 30, color: FC.onGold)),
            ),
          ),
        ]);
      }),
      DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00080A0C), FC.black], stops: [.3, 1])),
      ),
    ]);
  }

  Widget _section(BuildContext context) {
    final pad = cl(context, 22, 6, 50);
    Widget point(IconName i, String t) => Row(children: [
          Ic(i, size: 20, color: FC.gold),
          const SizedBox(width: 12),
          Expanded(child: Text(t, style: fs(11.52, color: const Color(0xFFC7C9CB)))),
        ]);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 12, pad, 38 + bottomInset(context)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: gapped([
            FcText('PRECISE & SECURE', kind: Tx.label, color: FC.gold),
            const FcText('Enable your location', kind: Tx.title),
            FcText('We use your location to show nearby partner stations, accurate delivery fees, and live driver tracking.', color: FC.muted),
            Column(children: gapped([
              point(IconName.fuel, 'Nearby verified stations'),
              point(IconName.truck, 'Accurate arrival estimates'),
              point(IconName.shield, 'Used only while ordering'),
            ], 12)),
            FcButton('Allow location access', onTap: () {
              app.locationOn = true;
              go(Screen.home, root: true);
            }),
            FcButton('Enter address manually', variant: BV.ghost, onTap: () async {
              final ok = await showLocationSheet(context);
              if (ok == true) go(Screen.home, root: true);
            }),
          ], 16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isWide(context)) {
      return ColoredBox(
        color: FC.black,
        child: Row(children: [
          Expanded(flex: 55, child: _map(context)),
          Expanded(flex: 45, child: Center(child: SingleChildScrollView(child: _section(context)))),
        ]),
      );
    }
    return ColoredBox(
      color: FC.black,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: math.max(300, vh(context) * .42), child: _map(context)),
          _section(context),
        ]),
      ),
    );
  }
}