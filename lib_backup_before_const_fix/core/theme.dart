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

/// App colours. Every name now returns the dark or the light value depending
/// on [dark], which AppState.setDarkMode() flips. Because the values change at
/// runtime they are getters, so they can no longer be used inside `const`.
class FC {
  FC._();

  /// true = dark palette (original), false = light palette.
  static bool dark = true;
  static Color _c(int d, int l) => Color(dark ? d : l);

  // ----- original palette (dark values are exactly your originals) ---------
  static Color get ink => _c(0xFFF8F8F5, 0xFF15171A);
  static Color get muted => _c(0xFF8C9095, 0xFF5F656C);
  static Color get dim => _c(0xFF5C6066, 0xFF8D9299);
  static Color get black => _c(0xFF080A0C, 0xFFF6F5F2);
  static Color get surface => _c(0xFF101317, 0xFFFFFFFF);
  static Color get surface2 => _c(0xFF171A1F, 0xFFF0EEEA);
  static Color get line => _c(0xFF262A30, 0xFFE2DFD8);
  static Color get gold => _c(0xFFF5C72E, 0xFFB88A00);
  static Color get goldDeep => _c(0xFFDBA918, 0xFF9C7300);
  static Color get green => _c(0xFF55C68B, 0xFF1F9D63);
  static Color get danger => _c(0xFFF36969, 0xFFD94545);
  static Color get onGold => _c(0xFF111111, 0xFF111111);

  // ----- colours that were hardcoded inside widgets.dart -------------------
  static Color get fieldLabel => _c(0xFFC7C8C9, 0xFF4A4F55);
  static Color get hint => _c(0xFF5F646A, 0xFF9AA0A6);
  static Color get goldBorder => _c(0xFF4B4324, 0xFFD9C27A);
  static Color get focusBorder => _c(0xFF7B6725, 0xFFB99A2E);
  static Color get iconBtnBg => _c(0xC20C0E11, 0xE6FFFFFF);
  static Color get overlay => dark ? Colors.white : Colors.black;
  static Color get mapBg => _c(0xFF13171A, 0xFFE9E7E1);
  static Color get headerBg => _c(0xD1080A0C, 0xE6F6F5F2);
  static Color get navBg => _c(0xF00D0F12, 0xF2FFFFFF);
  static Color get searchBg => _c(0xFF121519, 0xFFFFFFFF);
  static Color get toggleOff => _c(0xFF353940, 0xFFC9CCD1);
  static Color get tagBg => _c(0xFF1B1E22, 0xFFEFEDE8);
  static Color get tagText => _c(0xFFC9CACC, 0xFF4A4F55);
  static double get shadowAlpha => dark ? .28 : .08;
}

/// Forces every widget (including `const` ones) to rebuild so the new palette
/// is picked up straight away. Widget state is kept.
void rebuildApp() {
  void visit(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
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
        {Color? color,
        FontWeight w = FontWeight.w400,
        double ls = 0,
        double h = 1.5}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, color: color ?? FC.ink, fontWeight: w, letterSpacing: ls, height: h);

enum Tx { display, title, subtitle, body, caption, label }

TextStyle ts(BuildContext c, Tx k, {Color? color, FontWeight? weight}) {
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

/// Builds the theme for the palette that is currently active (FC.dark).
ThemeData buildTheme() {
  final base = ThemeData(
    brightness: FC.dark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: FC.black,
    colorScheme: ColorScheme(
      brightness: FC.dark ? Brightness.dark : Brightness.light,
      primary: FC.gold,
      onPrimary: FC.onGold,
      secondary: FC.gold,
      onSecondary: FC.onGold,
      surface: FC.surface,
      onSurface: FC.ink,
      error: FC.danger,
      onError: Colors.white,
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