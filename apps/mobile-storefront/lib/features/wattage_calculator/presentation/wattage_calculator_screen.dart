import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/solar_sizing.dart';

const _sun = Color(0xFFF2B65C);
const _daySoft = Color(0xFFFBF1E4);
const _nightColor = Color(0xFF3F4B8C);
const _nightSoft = Color(0xFFECEEF8);
const _deep = Color(0xFF0F241C);

/// Solar system calculator. A green header with a sun arc (the sun sits at
/// noon for on-grid and drifts toward dusk for battery systems), three
/// floating cards to pick the system type, sliders for the loads, and a
/// results panel that recomputes live — no form to submit.
class WattageCalculatorScreen extends StatefulWidget {
  const WattageCalculatorScreen({super.key});

  @override
  State<WattageCalculatorScreen> createState() => _WattageCalculatorScreenState();
}

enum _Unit { kw, amps }

class _WattageCalculatorScreenState extends State<WattageCalculatorScreen> {
  SystemType _type = SystemType.onGrid;
  Phase _phase = Phase.single;
  _Unit _unit = _Unit.kw;
  bool _withBattery = true;

  // Loads are held in the current unit; night hours in hours.
  double _day = 5;
  double _night = 2;
  double _hours = 10;

  bool get _battery => switch (_type) {
        SystemType.onGrid => false,
        SystemType.hybrid => _withBattery,
        SystemType.offGrid => true,
      };

  double get _step => _unit == _Unit.kw ? 0.5 : 1;
  double get _max => _unit == _Unit.kw ? 40 : 150;

  double _kw(double v) => _unit == _Unit.kw ? v : SolarSizing.ampsToKw(v, _phase);

  /// Switching unit keeps the same real load, re-expressed and snapped to
  /// the new unit's slider steps.
  void _setUnit(_Unit unit) {
    if (unit == _unit) return;
    final perAmp = SolarSizing.ampsToKw(1, _phase);
    double convert(double v) {
      final next = unit == _Unit.amps ? v / perAmp : v * perAmp;
      final step = unit == _Unit.kw ? 0.5 : 1.0;
      final max = unit == _Unit.kw ? 40.0 : 150.0;
      return ((next / step).round() * step).clamp(0, max).toDouble();
    }

    setState(() {
      _day = convert(_day);
      _night = convert(_night);
      _unit = unit;
    });
  }

  SizingResult get _result => SolarSizing.calculate(SizingInput(
        type: _type,
        phase: _phase,
        dayLoadKw: _kw(_day),
        nightLoadKw: _kw(_night),
        nightHours: _hours,
        withBattery: _withBattery,
      ));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unitLabel = _unit == _Unit.kw ? 'kW' : 'A';
    final result = _result;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSunken,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeaderWithTypes(
              type: _type,
              onType: (t) => setState(() => _type = t),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Card(
                    child: Column(
                      children: [
                        _OptionRow(
                          label: l10n.calcPhase,
                          child: _Toggle<Phase>(
                            value: _phase,
                            segmentWidth: 104,
                            onChanged: (p) => setState(() => _phase = p),
                            options: [
                              (Phase.single, l10n.calcSinglePhase),
                              (Phase.three, l10n.calcThreePhase),
                            ],
                          ),
                        ),
                        const _Hairline(),
                        _OptionRow(
                          label: l10n.calcUnit,
                          child: _Toggle<_Unit>(
                            value: _unit,
                            segmentWidth: 64,
                            onChanged: _setUnit,
                            options: const [(_Unit.kw, 'kW'), (_Unit.amps, 'A')],
                          ),
                        ),
                        if (_type == SystemType.hybrid) ...[
                          const _Hairline(),
                          _OptionRow(
                            label: l10n.calcIncludeBattery,
                            leading: const Icon(Icons.battery_charging_full_rounded, size: 20, color: AppColors.primary),
                            child: Switch.adaptive(
                              value: _withBattery,
                              activeTrackColor: AppColors.primary,
                              onChanged: (v) => setState(() => _withBattery = v),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LoadCard(
                    icon: _type == SystemType.onGrid ? Icons.bolt_rounded : Icons.wb_sunny_rounded,
                    color: _type == SystemType.onGrid ? AppColors.primary : AppColors.accent,
                    soft: _type == SystemType.onGrid ? AppColors.primarySoft : _daySoft,
                    title: _type == SystemType.onGrid ? l10n.calcLoad : l10n.calcDayLoad,
                    hint: _type == SystemType.onGrid ? l10n.calcOnGridLoadHint : l10n.calcDayLoadHint,
                    value: _day,
                    unit: unitLabel,
                    step: _step,
                    max: _max,
                    onChanged: (v) => setState(() => _day = v),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _battery
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: _LoadCard(
                              icon: Icons.nightlight_round,
                              color: _nightColor,
                              soft: _nightSoft,
                              title: l10n.calcNightLoad,
                              hint: l10n.calcNightLoadHint,
                              value: _night,
                              unit: unitLabel,
                              step: _step,
                              max: _max,
                              onChanged: (v) => setState(() => _night = v),
                              footer: _SubSlider(
                                icon: Icons.schedule_rounded,
                                label: l10n.calcNightHours,
                                value: _hours,
                                color: _nightColor,
                                onChanged: (v) => setState(() => _hours = v),
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ResultsPanel(result: result, phase: _phase),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                    ),
                    child: Text(l10n.seeMatchingPanels, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.wattageDisclaimer,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMuted.copyWith(fontSize: 11.5),
                  ),
                  SizedBox(height: AppSpacing.xl + MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────

class _HeaderWithTypes extends StatelessWidget {
  const _HeaderWithTypes({required this.type, required this.onType});

  final SystemType type;
  final ValueChanged<SystemType> onType;

  static const _cardHeight = 118.0;
  static const _overlap = 46.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, subtitle, sunAt) = switch (type) {
      SystemType.onGrid => (l10n.calcOnGridTitle, l10n.calcOnGridSubtitle, 0.5),
      SystemType.hybrid => (l10n.calcHybridTitle, l10n.calcHybridSubtitle, 0.72),
      SystemType.offGrid => (l10n.calcOffGridTitle, l10n.calcOffGridSubtitle, 0.9),
    };

    return Stack(
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, bottom: _overlap + 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, _deep],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4, end: AppSpacing.lg),
                    child: Row(
                      children: [
                        const BackButton(color: Colors.white),
                        Text(
                          l10n.wattageCalculatorScreenTitle,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: sunAt),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOutCubic,
                      builder: (context, p, _) => CustomPaint(painter: _SkyPainter(p)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: AlignmentDirectional.topStart,
                        children: [...previous, ?current],
                      ),
                      child: Column(
                        key: ValueKey(type),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.25),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _cardHeight - _overlap),
          ],
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: 0,
          height: _cardHeight,
          child: Row(
            children: [
              for (final (t, icon, label, hint) in [
                (SystemType.onGrid, Icons.electric_meter_outlined, l10n.calcOnGrid, l10n.calcOnGridHint),
                (SystemType.hybrid, Icons.battery_charging_full_rounded, l10n.calcHybrid, l10n.calcHybridHint),
                (SystemType.offGrid, Icons.solar_power_outlined, l10n.calcOffGrid, l10n.calcOffGridHint),
              ]) ...[
                if (t != SystemType.onGrid) const SizedBox(width: 10),
                Expanded(
                  child: _TypeCard(
                    icon: icon,
                    label: label,
                    hint: hint,
                    selected: t == type,
                    onTap: () => onType(t),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Dashed sun path over a horizon with a small panel array; the sun sits
/// at [p] along the arc (0 = sunrise, 1 = sunset).
class _SkyPainter extends CustomPainter {
  _SkyPainter(this.p);

  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height - 14;
    final rect = Rect.fromLTRB(size.width * 0.12, 6, size.width * 0.88, horizonY * 2 - 6);

    // Dashed arc.
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const segments = 28;
    for (var i = 0; i < segments; i += 2) {
      canvas.drawArc(rect, math.pi + math.pi * i / segments, math.pi / segments, false, dash);
    }

    // Horizon.
    canvas.drawLine(
      Offset(size.width * 0.06, horizonY),
      Offset(size.width * 0.94, horizonY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 1,
    );

    // Sun with a soft glow.
    final angle = math.pi + math.pi * p;
    final sun = Offset(
      rect.center.dx + rect.width / 2 * math.cos(angle),
      rect.center.dy + rect.height / 2 * math.sin(angle),
    );
    canvas.drawCircle(
      sun,
      30,
      Paint()
        ..shader = RadialGradient(
          colors: [_sun.withValues(alpha: 0.45), _sun.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: sun, radius: 30)),
    );
    canvas.drawCircle(sun, 10, Paint()..color = _sun);

    // Three tilted panels standing on the horizon.
    final panelFill = Paint()..color = Colors.white.withValues(alpha: 0.16);
    final panelLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final x = size.width * 0.5 - 54 + i * 38;
      final path = Path()
        ..moveTo(x, horizonY - 4)
        ..lineTo(x + 30, horizonY - 4)
        ..lineTo(x + 38, horizonY - 22)
        ..lineTo(x + 8, horizonY - 22)
        ..close();
      canvas.drawPath(path, panelFill);
      canvas.drawPath(path, panelLine);
      canvas.drawLine(Offset(x + 15, horizonY - 4), Offset(x + 23, horizonY - 22), panelLine);
      canvas.drawLine(Offset(x + 4, horizonY - 13), Offset(x + 34, horizonY - 13), panelLine);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.p != p;
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: selected ? Colors.white : AppColors.primary),
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardTitle.copyWith(fontSize: 13.5),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMuted.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inputs ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => Container(height: 1, color: AppColors.line);
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.child, this.leading});

  final String label;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
          Expanded(child: Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 14.5))),
          child,
        ],
      ),
    );
  }
}

/// Segmented pill with a sliding white indicator.
class _Toggle<T> extends StatelessWidget {
  const _Toggle({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.segmentWidth,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final double segmentWidth;

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.$1 == value);
    final dir = Directionality.of(context) == TextDirection.rtl ? -1 : 1;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(999)),
      child: SizedBox(
        width: segmentWidth * options.length,
        height: 34,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment(dir * (options.length == 1 ? 0 : -1 + 2 * index / (options.length - 1)), 0),
              child: Container(
                width: segmentWidth,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
              ),
            ),
            Row(
              children: [
                for (final (v, label) in options)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(v),
                    child: SizedBox(
                      width: segmentWidth,
                      child: Center(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontSize: 13,
                            fontWeight: v == value ? FontWeight.w700 : FontWeight.w500,
                            color: v == value ? AppColors.ink900 : AppColors.ink600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadCard extends StatelessWidget {
  const _LoadCard({
    required this.icon,
    required this.color,
    required this.soft,
    required this.title,
    required this.hint,
    required this.value,
    required this.unit,
    required this.step,
    required this.max,
    required this.onChanged,
    this.footer,
  });

  final IconData icon;
  final Color color;
  final Color soft;
  final String title;
  final String hint;
  final double value;
  final String unit;
  final double step;
  final double max;
  final ValueChanged<double> onChanged;
  final Widget? footer;

  void _nudge(int dir) => onChanged((value + dir * step).clamp(0, max).toDouble());

  @override
  Widget build(BuildContext context) {
    final shown = step < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                    Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMuted.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: shown, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
                  TextSpan(text: ' $unit', style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w600)),
                ]),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _RoundIcon(icon: Icons.remove_rounded, color: color, onTap: () => _nudge(-1)),
              Expanded(
                child: SliderTheme(
                  data: _sliderTheme(color),
                  child: Slider(
                    value: value.clamp(0, max).toDouble(),
                    max: max,
                    divisions: (max / step).round(),
                    onChanged: onChanged,
                  ),
                ),
              ),
              _RoundIcon(icon: Icons.add_rounded, color: color, onTap: () => _nudge(1)),
            ],
          ),
          if (footer != null) ...[const _Hairline(), footer!],
        ],
      ),
    );
  }
}

SliderThemeData _sliderTheme(Color color) => SliderThemeData(
      trackHeight: 6,
      activeTrackColor: color,
      inactiveTrackColor: color.withValues(alpha: 0.14),
      thumbColor: color,
      overlayColor: color.withValues(alpha: 0.12),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
      tickMarkShape: SliderTickMarkShape.noTickMark,
      showValueIndicator: ShowValueIndicator.never,
    );

class _SubSlider extends StatelessWidget {
  const _SubSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.ink600),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          Expanded(
            child: SliderTheme(
              data: _sliderTheme(color).copyWith(trackHeight: 4),
              child: Slider(
                value: value,
                min: 1,
                max: 16,
                divisions: 15,
                onChanged: onChanged,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} h',
            textDirection: TextDirection.ltr,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 34, height: 34, child: Icon(icon, size: 20, color: color)),
      ),
    );
  }
}

// ── Results ─────────────────────────────────────────────────────────────

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({required this.result, required this.phase});

  final SizingResult result;
  final Phase phase;

  static const _maxGlyphs = 24;

  static String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shownPanels = math.min(result.panelCount, _maxGlyphs);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, _deep],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, size: 16, color: _sun),
              const SizedBox(width: 6),
              Text(l10n.calcResults, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: result.arrayKwp),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: v.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, height: 1),
                  ),
                  const TextSpan(
                    text: ' kWp',
                    style: TextStyle(color: Colors.white60, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ]),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.calcPanelsCount(result.panelCount, SolarSizing.panelWattage),
            style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          // One glyph per panel, so the size of the array is felt at a glance.
          Wrap(
            spacing: 5,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < shownPanels; i++) const _PanelGlyph(),
              if (result.panelCount > shownPanels)
                Text(
                  '+${result.panelCount - shownPanels}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.electrical_services_rounded,
                    label: l10n.calcInverter,
                    value: '${_n(result.inverterKw)} kW',
                    detail: phase == Phase.single ? l10n.calcSinglePhase : l10n.calcThreePhase,
                  ),
                ),
                if (result.batteryCount > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      icon: Icons.battery_charging_full_rounded,
                      label: l10n.calcBatteries,
                      value: '${_n(result.batteryKwh)} kWh',
                      detail: '${result.batteryCount} × ${SolarSizing.batteryModuleKwh.toStringAsFixed(2)} kWh',
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    icon: Icons.wb_sunny_outlined,
                    label: l10n.calcDailyProduction,
                    value: '${_n(result.dailyProductionKwh)} kWh',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelGlyph extends StatelessWidget {
  const _PanelGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5B8DEF), Color(0xFF2C4FA8)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.8),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value, this.detail});

  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _sun),
          const SizedBox(height: 8),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
