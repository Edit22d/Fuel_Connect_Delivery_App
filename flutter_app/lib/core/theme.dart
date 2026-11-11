import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Project switches
// ---------------------------------------------------------------------------

/// The original Figma Make CSS has two visual accidents: forward buttons use
/// the LEFT-pointing "arrow" icon, and the "Total" row in price summaries picks
/// up the TotalEnergies red-to-blue gradient (a `.total` class collision).
/// `true` reproduces the design exactly as exported. Set `false` to fix both.
const bool kReproduceSourceQuirks = true;

/// No SMS gateway yet: when true, the verification code is shown in a toast.
/// Turn off once the backend sends real codes.
const bool kDemoMode = true;

/// Verification code length and charset.
const int kOtpLength = 6;
const bool kOtpAlphanumeric = false;

/// Right-hand space reserved for the floating menu icon (top-right corner).
const double kRightInset = 64;

class FC {
  FC._();
  static const ink = Color(0xFFF8F8F5);
  static const muted = Color(0xFF8C9095);
  static const dim = Color(0xFF5C6066);
  static const black = Color(0xFF080A0C);
  static const surface = Color(0xFF101317);
  static const surface2 = Color(0xFF171A1F);
  static const line = Color(0xFF262A30);
  static const gold = Color(0xFFF5C72E);
  static const goldDeep = Color(0xFFDBA918);
  static const green = Color(0xFF55C68B);
  static const danger = Color(0xFFF36969);
  static const onGold = Color(0xFF111111);
}

/// Colour [c] at opacity [o] (0..1) without version-specific Color APIs.
Color al(Color c, double o) => c.withAlpha((o * 255).round());

// ---------------------------------------------------------------------------
// Responsive helpers (CSS clamp / vw / dvh equivalents)
// ---------------------------------------------------------------------------
double vw(BuildContext c) => MediaQuery.sizeOf(c).width;
double vh(BuildContext c) => MediaQuery.sizeOf(c).height;
double topInset(BuildContext c) => MediaQuery.viewPaddingOf(c).top;
double bottomInset(BuildContext c) => MediaQuery.viewPaddingOf(c).bottom;
bool isWide(BuildContext c) => vw(c) >= 760;
double cl(BuildContext c, double min, double pct, double max) =>
    (vw(c) * pct / 100).clamp(min, max).toDouble();

// ---------------------------------------------------------------------------
// Typography (Plus Jakarta Sans, sizes taken from the CSS rem values)
// ---------------------------------------------------------------------------
TextStyle fs(double size,
        {Color color = FC.ink,
        FontWeight w = FontWeight.w400,
        double ls = 0,
        double h = 1.5}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, color: color, fontWeight: w, letterSpacing: ls, height: h);

enum Tx { display, title, subtitle, body, caption, label }

TextStyle ts(BuildContext c, Tx k, {Color color = FC.ink, FontWeight? weight}) {
  switch (k) {
    case Tx.display:
      {
        final s = vw(c) <= 380 ? 30.4 : cl(c, 32, 8, 53.6);
        return fs(s, color: color, w: weight ?? FontWeight.w800, ls: -0.05 * s, h: 1.08);
      }
    case Tx.title:
      {
        final s = cl(c, 20, 5, 26.4);
        return fs(s, color: color, w: weight ?? FontWeight.w800, ls: -0.035 * s, h: 1.2);
      }
    case Tx.subtitle:
      return fs(16, color: color, w: weight ?? FontWeight.w700, ls: -0.32, h: 1.3);
    case Tx.body:
      return fs(14.4, color: color, w: weight ?? FontWeight.w400);
    case Tx.caption:
      return fs(11.52, color: color, w: weight ?? FontWeight.w400);
    case Tx.label:
      return fs(10.88, color: color, w: weight ?? FontWeight.w700, ls: 0.65, h: 1.4);
  }
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: FC.black,
    colorScheme: const ColorScheme.dark(
      primary: FC.gold,
      onPrimary: FC.onGold,
      surface: FC.surface,
      onSurface: FC.ink,
      error: FC.danger,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: FC.gold,
      selectionColor: al(FC.gold, .25),
      selectionHandleColor: FC.gold,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: FC.ink, displayColor: FC.ink),
  );
}

// ---------------------------------------------------------------------------
// Small utilities
// ---------------------------------------------------------------------------
String fmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

List<Widget> gapped(List<Widget> items, double g) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    if (i > 0) out.add(SizedBox(height: g));
    out.add(items[i]);
  }
  return out;
}

double hypot2(double a, double b) => math.sqrt(a * a + b * b);
