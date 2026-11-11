import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'icons.dart';
import 'data.dart';
import 'app_state.dart';

typedef Go = void Function(Screen screen, {bool root, bool replace});

// ---------------------------------------------------------------------------
// Basics
// ---------------------------------------------------------------------------
class Tap extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  const Tap({super.key, required this.onTap, required this.child});
  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
      );
}

class FcText extends StatelessWidget {
  final String text;
  final Tx kind;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final FontWeight? weight;
  const FcText(this.text, {super.key, this.kind = Tx.body, this.color, this.align, this.maxLines, this.weight});
  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: ts(context, kind, color: color ?? FC.ink, weight: weight),
      );
}

class TextAction extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? color;
  const TextAction(this.text, {super.key, this.onTap, this.color});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: Text(text, style: fs(11.52, color: color ?? FC.gold, w: FontWeight.w700))),
      );
}

enum BV { primary, outline, ghost, icon }

class FcButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final BV variant;
  final IconName? icon;
  final IconName? trailingIcon;
  final bool expand;
  final bool loading;
  const FcButton(this.label,
      {super.key, this.onTap, this.variant = BV.primary, this.icon, this.trailingIcon, this.expand = true, this.loading = false});
  const FcButton.icon(IconName ic, {super.key, this.onTap})
      : label = '',
        variant = BV.icon,
        icon = ic,
        trailingIcon = null,
        expand = false,
        loading = false;

  @override
  State<FcButton> createState() => _FcButtonState();
}

class _FcButtonState extends State<FcButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.variant;
    final isIcon = v == BV.icon;
    final enabled = widget.onTap != null && !widget.loading;
    final radius = BorderRadius.circular(12);
    Color fg;
    BoxDecoration? deco;
    switch (v) {
      case BV.primary:
        fg = FC.onGold;
        deco = BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [FC.gold, FC.goldDeep]),
          borderRadius: radius,
          boxShadow: [BoxShadow(color: al(FC.gold, .12), blurRadius: 32, offset: const Offset(0, 12))],
        );
        break;
      case BV.outline:
        fg = FC.gold;
        deco = BoxDecoration(borderRadius: radius, border: Border.all(color: FC.goldBorder));
        break;
      case BV.ghost:
        fg = FC.muted;
        deco = null;
        break;
      case BV.icon:
        fg = FC.ink;
        deco = BoxDecoration(color: FC.iconBtnBg, borderRadius: radius, border: Border.all(color: al(FC.overlay, .12)));
        break;
    }

    Widget content;
    if (isIcon) {
      content = Ic(widget.icon!, size: 18, color: fg);
    } else {
      final kids = <Widget>[];
      if (widget.loading) {
        kids.add(SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg)));
        kids.add(const SizedBox(width: 10));
      } else if (widget.icon != null) {
        kids.add(Ic(widget.icon!, size: 18, color: fg));
        kids.add(const SizedBox(width: 10));
      }
      kids.add(Flexible(child: Text(widget.label, textAlign: TextAlign.center, style: fs(12.64, color: fg, w: FontWeight.w800))));
      if (widget.trailingIcon != null) {
        kids.add(const SizedBox(width: 10));
        kids.add(Ic(widget.trailingIcon!, size: 18, color: fg, flipX: widget.trailingIcon == IconName.arrow && !kReproduceSourceQuirks));
      }
      content = Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: kids);
    }

    final box = Container(
      width: isIcon ? 42 : (widget.expand ? double.infinity : null),
      height: isIcon ? 42 : null,
      constraints: isIcon ? null : const BoxConstraints(minHeight: 52),
      padding: isIcon ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      decoration: deco,
      child: content,
    );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _down ? .98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Opacity(opacity: (widget.onTap == null && !widget.loading) ? .5 : 1, child: box),
        ),
      ),
    );
  }
}

class FcField extends StatefulWidget {
  final String label, hint;
  final IconName? icon;
  final bool password;
  final bool showToggle;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final String? error;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? action;
  final TextAlign labelAlign;
  final List<TextInputFormatter>? formatters;
  const FcField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.password = false,
    this.showToggle = false,
    this.keyboard,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.action,
    this.labelAlign = TextAlign.start,
    this.formatters,
  });
  @override
  State<FcField> createState() => _FcFieldState();
}

class _FcFieldState extends State<FcField> {
  final _focus = FocusNode();
  bool _hide = true;
  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final err = widget.error != null;
    final border = err ? FC.danger : (_focus.hasFocus ? FC.focusBorder : FC.line);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, textAlign: widget.labelAlign, style: fs(10.88, color: FC.fieldLabel, w: FontWeight.w700, ls: .33)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
          child: Row(
            children: [
              if (widget.icon != null) ...[Ic(widget.icon!, size: 18, color: FC.muted), const SizedBox(width: 12)],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.password && _hide,
                  keyboardType: widget.keyboard,
                  textInputAction: widget.action,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  inputFormatters: widget.formatters,
                  autocorrect: !widget.password,
                  enableSuggestions: !widget.password,
                  style: fs(12.48, color: FC.ink, h: 1.3),
                  cursorColor: FC.gold,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: fs(12.48, color: FC.hint, h: 1.3),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (widget.password && widget.showToggle)
                Tap(
                  onTap: () => setState(() => _hide = !_hide),
                  child: Padding(padding: const EdgeInsets.only(left: 8), child: Ic(IconName.eye, size: 18, color: _hide ? FC.dim : FC.gold)),
                ),
            ],
          ),
        ),
        if (err) Padding(padding: const EdgeInsets.only(top: 6), child: Text(widget.error!, style: fs(11.52, color: FC.danger))),
      ],
    );
  }
}

class FormError extends StatelessWidget {
  final String message;
  const FormError(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: al(FC.danger, .06), borderRadius: BorderRadius.circular(12), border: Border.all(color: al(FC.danger, .25))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Ic(IconName.shield, size: 16, color: FC.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: fs(11.52, color: FC.danger))),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Brand
class Logo extends StatelessWidget {
  final bool compact;
  const Logo({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final mark = compact ? 34.0 : 56.0;

    return SizedBox(
      width: mark,
      height: mark,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Backgrounds
// ---------------------------------------------------------------------------
class ImageShade extends StatelessWidget {
  const ImageShade({super.key});
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0x1F000000), const Color(0x1A080A0C), FC.black],
            stops: const [0, .45, 1],
          ),
        ),
        child: const SizedBox.expand(),
      );
}

/// CSS-style `radial-gradient(circle at fx fy, ...)` (farthest-corner).
class Glow extends StatelessWidget {
  final double fx, fy;
  final List<Color> colors;
  final List<double> stops;
  const Glow({super.key, required this.fx, required this.fy, required this.colors, required this.stops});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, cons) {
        final w = cons.maxWidth.isFinite ? cons.maxWidth : vw(context);
        final h = cons.maxHeight.isFinite ? cons.maxHeight : vh(context);
        final cx = w * fx, cy = h * fy;
        final r = hypot2(math.max(cx, w - cx), math.max(cy, h - cy));
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(center: Alignment(fx * 2 - 1, fy * 2 - 1), radius: r / math.min(w, h), colors: colors, stops: stops),
          ),
          child: const SizedBox.expand(),
        );
      });
}

class _GridPainter extends CustomPainter {
  final Color bg;
  final double step;
  const _GridPainter(this.bg, this.step);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final p = Paint()..color = al(FC.overlay, .035);
    for (double x = 0; x < size.width; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.bg != bg || old.step != step;
}

class MapGrid extends StatelessWidget {
  final Color? bg;
  final double step;
  const MapGrid({super.key, this.bg, this.step = 28});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter(bg ?? FC.mapBg, step), child: const SizedBox.expand());
}

/// "L" shaped route (left + bottom border) with optional rounded corner/dots.
class _RoutePainter extends CustomPainter {
  final double stroke, radius;
  final bool dotted;
  const _RoutePainter(this.stroke, this.radius, this.dotted);
  @override
  void paint(Canvas canvas, Size s) {
    final half = stroke / 2;
    final path = Path()
      ..moveTo(half, 0)
      ..lineTo(half, s.height - half - radius)
      ..quadraticBezierTo(half, s.height - half, half + radius, s.height - half)
      ..lineTo(s.width, s.height - half);
    if (!dotted) {
      canvas.drawPath(path, Paint()..color = FC.gold..style = PaintingStyle.stroke..strokeWidth = stroke);
      return;
    }
    final dot = Paint()..color = FC.gold;
    for (final m in path.computeMetrics()) {
      for (double d = half; d < m.length; d += stroke * 2) {
        final t = m.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, half, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => true;
}

class RouteLine extends StatelessWidget {
  final double width, height, stroke, radius;
  final bool dotted;
  const RouteLine({super.key, required this.width, required this.height, this.stroke = 4, this.radius = 0, this.dotted = false});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(width, height), painter: _RoutePainter(stroke, radius, dotted));
}

// ---------------------------------------------------------------------------
// Pills, toggles, small atoms
// ---------------------------------------------------------------------------
class VerifiedPill extends StatelessWidget {
  final String text;
  final bool check;
  final double iconSize;
  const VerifiedPill(this.text, {super.key, this.check = false, this.iconSize = 12});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: al(FC.green, .12), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (check) ...[Ic(IconName.check, size: iconSize, color: FC.green), const SizedBox(width: 5)],
          Text(text, style: fs(8.96, color: FC.green, w: FontWeight.w700, h: 1.3)),
        ]),
      );
}

class LivePill extends StatelessWidget {
  final String text;
  const LivePill(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(color: al(FC.green, .11), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: fs(8.32, color: FC.green, w: FontWeight.w800, ls: .42, h: 1.3)),
      );
}

class FcToggle extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  const FcToggle({super.key, required this.on, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 22,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: on ? FC.gold : FC.toggleOff, borderRadius: BorderRadius.circular(20)),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: on ? const Color(0xFF151515) : Colors.white)),
        ),
      );
}

class RadioDot extends StatelessWidget {
  final bool selected;
  const RadioDot({super.key, required this.selected});
  @override
  Widget build(BuildContext context) => Container(
        width: 17,
        height: 17,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? FC.gold : FC.dim, width: selected ? 5 : 1)),
      );
}

class RoundAction extends StatelessWidget {
  final IconName icon;
  final VoidCallback? onTap;
  const RoundAction(this.icon, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(shape: BoxShape.circle, color: FC.surface, border: Border.all(color: FC.line)),
          child: Center(child: Ic(icon, size: 20)),
        ),
      );
}

class IconBox extends StatelessWidget {
  final IconName icon;
  final Color? color;
  final double size;
  final double radius;
  const IconBox(this.icon, {super.key, this.color, this.size = 38, this.radius = 10});
  @override
  Widget build(BuildContext context) {
    final c = color ?? FC.gold;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: al(c, .08), borderRadius: BorderRadius.circular(radius)),
      child: Center(child: Ic(icon, color: c)),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;
  const SectionHeading(this.title, {super.key, this.caption, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 15),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FcText(title, kind: Tx.title),
              if (caption != null) FcText(caption!, kind: Tx.caption, color: FC.muted),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

class SearchBox extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const SearchBox({super.key, required this.hint, required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: FC.searchBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FC.line),
          boxShadow: [BoxShadow(color: al(Colors.black, FC.shadowAlpha), blurRadius: 35, offset: const Offset(0, 10))],
        ),
        child: Row(children: [
          Ic(IconName.search, size: 19, color: FC.muted),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: fs(12.48, h: 1.3),
              cursorColor: FC.gold,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: fs(12.48, color: FC.hint, h: 1.3),
              ),
            ),
          ),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------
class ScrollFill extends StatelessWidget {
  final Widget child;
  const ScrollFill({super.key, required this.child});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (c, cons) => SingleChildScrollView(
          child: ConstrainedBox(constraints: BoxConstraints(minHeight: cons.maxHeight), child: IntrinsicHeight(child: child)),
        ),
      );
}

class PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? goBack;
  final Widget? action;
  const PageHeader({super.key, required this.title, this.goBack, this.action});
  @override
  Widget build(BuildContext context) {
    final h = cl(context, 18, 5, 54);
    final top = topInset(context);
    return Container(
      height: 76 + top,
      decoration: BoxDecoration(color: FC.headerBg, border: Border(bottom: BorderSide(color: al(FC.overlay, .06)))),
      child: Stack(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(h, top, math.max(h, kRightInset), 0),
          child: Row(children: [
            goBack != null ? FcButton.icon(IconName.arrow, onTap: goBack) : const Logo(compact: true),
            const Spacer(),
            if (action != null) action!,
          ]),
        ),
        Padding(
          padding: EdgeInsets.only(top: top, left: 96, right: 96),
          child: Center(child: FcText(title, kind: Tx.subtitle, maxLines: 1)),
        ),
      ]),
    );
  }
}

class _NavItem {
  final Screen screen;
  final IconName icon;
  final String label;
  const _NavItem(this.screen, this.icon, this.label);
}

const _navItems = [
  _NavItem(Screen.home, IconName.home, 'Home'),
  _NavItem(Screen.partners, IconName.fuel, 'Stations'),
  _NavItem(Screen.orders, IconName.orders, 'Orders'),
  _NavItem(Screen.wallet, IconName.wallet, 'Wallet'),
];

class BottomNav extends StatelessWidget {
  final Screen? current;
  final Go go;
  const BottomNav({super.key, required this.current, required this.go});
  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final padH = wide ? 30.0 : math.max(12.0, (vw(context) - 850) / 2);
    final inset = bottomInset(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 720 : double.infinity),
        child: ClipRRect(
          borderRadius: wide ? const BorderRadius.vertical(top: Radius.circular(18)) : BorderRadius.zero,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 11, sigmaY: 11),
            child: Container(
              height: 72 + inset,
              padding: EdgeInsets.fromLTRB(padH, 5, padH, 5 + inset),
              decoration: BoxDecoration(
                color: FC.navBg,
                border: Border(
                  top: BorderSide(color: FC.line),
                  left: wide ? BorderSide(color: FC.line) : BorderSide.none,
                  right: wide ? BorderSide(color: FC.line) : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  for (final i in _navItems)
                    Expanded(
                      child: Tap(
                        onTap: () => go(i.screen, root: true),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Ic(i.icon, size: 19, color: current == i.screen ? FC.gold : FC.dim),
                          const SizedBox(height: 4),
                          Text(i.label, style: fs(8.64, color: current == i.screen ? FC.gold : FC.dim, h: 1.2)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable page with optional header and fixed bottom navigation.
class AppPage extends StatelessWidget {
  final Widget? header;
  final Widget body;
  final bool nav;
  final Screen? navCurrent;
  final Go? go;
  final Widget? background;
  const AppPage({super.key, this.header, required this.body, this.nav = false, this.navCurrent, this.go, this.background});
  @override
  Widget build(BuildContext context) => ColoredBox(
        color: FC.black,
        child: Stack(children: [
          if (background != null) Positioned.fill(child: background!),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (header != null) header!,
                body,
                if (nav) SizedBox(height: 82 + bottomInset(context)),
              ]),
            ),
          ),
          if (nav && go != null) Positioned(left: 0, right: 0, bottom: 0, child: BottomNav(current: navCurrent, go: go!)),
        ]),
      );
}

class ContentSection extends StatelessWidget {
  final List<Widget> children;
  final double maxWide;
  const ContentSection({super.key, required this.children, this.maxWide = 980});
  @override
  Widget build(BuildContext context) {
    final pad = cl(context, 18, 5, 64);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide(context) ? maxWide : double.infinity),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

class Narrow extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final double? padTop;
  const Narrow({super.key, required this.children, this.gap = 20, this.padTop});
  @override
  Widget build(BuildContext context) {
    final pad = cl(context, 20, 6, 50);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, padTop ?? 34, pad, 48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(children, gap)),
        ),
      ),
    );
  }
}

class RoundFeature extends StatelessWidget {
  final IconName icon;
  final double size;
  const RoundFeature(this.icon, {super.key, this.size = 28});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(shape: BoxShape.circle, color: al(FC.gold, .1), border: Border.all(color: al(FC.gold, .2))),
          child: Center(child: Ic(icon, size: size, color: FC.gold)),
        ),
      );
}

class SafetyNote extends StatelessWidget {
  final String title, body;
  final Color? bodyColor;
  const SafetyNote({super.key, required this.title, required this.body, this.bodyColor});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: al(FC.green, .05), borderRadius: BorderRadius.circular(12), border: Border.all(color: al(FC.green, .18))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Ic(IconName.shield, color: FC.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FcText(title, kind: Tx.label, color: FC.green),
              const SizedBox(height: 3),
              FcText(body, kind: Tx.caption, color: bodyColor ?? FC.muted),
            ]),
          ),
        ]),
      );
}

/// Surface card with the standard 1px line border.
class Panel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? color;
  final Color? border;
  const Panel({super.key, required this.child, this.radius = 18, this.padding = const EdgeInsets.all(18), this.color, this.border});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: color ?? FC.surface, borderRadius: BorderRadius.circular(radius), border: Border.all(color: border ?? FC.line)),
        child: child,
      );
}

/// Key/value row used in receipts and summaries.
class KvRow extends StatelessWidget {
  final String k, v;
  final double size;
  const KvRow(this.k, this.v, {super.key, this.size = 11.52});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Flexible(child: Text(k, style: fs(size, color: FC.muted))),
        const SizedBox(width: 20),
        Flexible(child: Text(v, textAlign: TextAlign.right, style: fs(size, color: FC.ink, w: FontWeight.w700))),
      ]);
}

/// "Total" row. In the source CSS it inherits the TotalEnergies gradient.
class TotalRow extends StatelessWidget {
  final String label, value;
  const TotalRow(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          gradient: kReproduceSourceQuirks ? kTotalGradient : null,
          border: Border(top: BorderSide(color: FC.line)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: fs(13.6, color: FC.ink)),
          Text(value, style: fs(13.6, color: FC.ink, w: FontWeight.w700)),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Station + partner widgets
// ---------------------------------------------------------------------------
class PartnerMonogram extends StatelessWidget {
  final Partner p;
  final double size;
  final double font;
  const PartnerMonogram(this.p, {super.key, this.size = 44, this.font = 16});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: toneColor(p.tone),
          gradient: p.tone == 'total' ? kTotalGradient : null,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(p.name.substring(0, 1), style: fs(font, color: p.tone == 'shell' ? FC.onGold : Colors.white, w: FontWeight.w900, h: 1)),
      );
}

class PartnerChip extends StatelessWidget {
  final Partner p;
  final VoidCallback onTap;
  const PartnerChip(this.p, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 92, minHeight: 66),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: toneColor(p.tone) ?? FC.surface,
            gradient: p.tone == 'total' ? kTotalGradient : null,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: FC.line),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(p.name.substring(0, 1), style: fs(11.52, color: Colors.white, w: FontWeight.w900, h: 1)),
            const SizedBox(width: 8),
            Text(p.name, style: fs(9.28, color: p.tone == 'shell' ? FC.onGold : FC.ink, w: FontWeight.w700)),
          ]),
        ),
      );
}

class StationCard extends StatelessWidget {
  final Station s;
  final VoidCallback onTap;
  const StationCard(this.s, {super.key, required this.onTap});

  Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: FC.tagBg, borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: fs(8.8, color: FC.tagText, h: 1.3)),
      );

  @override
  Widget build(BuildContext context) {
    final frac = vw(context) <= 380 ? .34 : .38;
    return Tap(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(minHeight: 158),
        decoration: BoxDecoration(color: FC.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: FC.line)),
        child: LayoutBuilder(builder: (c, cons) {
          final imgW = cons.maxWidth * frac;
          return Stack(children: [
            Positioned(left: 0, top: 0, bottom: 0, width: imgW, child: Image.asset(s.image, fit: BoxFit.cover)),
            Padding(
              padding: EdgeInsets.only(left: imgW),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Stack(clipBehavior: Clip.none, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(s.brand, style: fs(8, color: FC.gold, w: FontWeight.w900, ls: .96)),
                    const SizedBox(height: 5),
                    Padding(padding: const EdgeInsets.only(right: 36), child: FcText(s.name, kind: Tx.subtitle)),
                    const SizedBox(height: 8),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Ic(IconName.location, size: 13, color: FC.muted),
                      const SizedBox(width: 4),
                      Flexible(child: Text('${s.distance} · ${s.eta}', style: fs(11.52, color: FC.muted))),
                    ]),
                    const SizedBox(height: 14),
                    Wrap(spacing: 6, runSpacing: 6, children: [_tag('Petrol 5,180'), _tag('Diesel 4,960')]),
                  ]),
                  Positioned(
                    top: 17,
                    right: 0,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Ic(IconName.star, size: 13, color: FC.gold),
                      const SizedBox(width: 4),
                      Text(s.rating, style: fs(9.92, color: FC.gold)),
                    ]),
                  ),
                ]),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback: toast, sheet, dialog
// ---------------------------------------------------------------------------
void toast(BuildContext context, String msg, {bool gold = false, int seconds = 4}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: seconds),
    backgroundColor: FC.surface2,
    elevation: 0,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: gold ? const Color(0xFF554A25) : FC.line)),
    content: Text(msg, style: fs(12, color: gold ? FC.gold : FC.ink, w: FontWeight.w600, h: 1.4)),
  ));
}

Future<R?> showFcSheet<R>(BuildContext context, {required String title, required Widget Function(BuildContext) builder}) {
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FC.surface,
    barrierColor: Colors.black54,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      side: BorderSide(color: FC.line),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, 28 + bottomInset(ctx)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: FC.line, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            FcText(title, kind: Tx.title),
            const SizedBox(height: 16),
            builder(ctx),
          ]),
        ),
      ),
    ),
  );
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String body, String confirm = 'Confirm'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: FC.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: FC.line)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FcText(title, kind: Tx.subtitle),
            const SizedBox(height: 8),
            FcText(body, kind: Tx.body, color: FC.muted),
            const SizedBox(height: 20),
            FcButton(confirm, onTap: () => Navigator.of(ctx).pop(true)),
            const SizedBox(height: 4),
            FcButton('Cancel', variant: BV.ghost, onTap: () => Navigator.of(ctx).pop(false)),
          ]),
        ),
      ),
    ),
  );
  return r ?? false;
}