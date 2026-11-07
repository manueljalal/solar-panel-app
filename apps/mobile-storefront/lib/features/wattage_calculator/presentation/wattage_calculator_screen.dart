import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/solar_sizing.dart';
import 'matching_panels_screen.dart';

const _sun = Color(0xFFF2B65C);
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
    final unit = _unit == _Unit.kw ? 'kW' : 'A';
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
                  _Group(
                    children: [
                      _ValueRow(
                        label: _type == SystemType.onGrid ? l10n.calcLoad : l10n.calcDayLoad,
                        value: _day,
                        unit: unit,
                        step: _step,
                        max: _max,
                        onChanged: (v) => setState(() => _day = v),
                      ),
                      if (_battery) ...[
                        _ValueRow(
                          label: l10n.calcNightLoad,
                          value: _night,
                          unit: unit,
                          step: _step,
                          max: _max,
                          onChanged: (v) => setState(() => _night = v),
                        ),
                        _ValueRow(
                          label: l10n.calcNightHours,
                          value: _hours,
                          unit: 'h',
                          step: 1,
                          min: 1,
                          max: 16,
                          onChanged: (v) => setState(() => _hours = v),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.calcResults, style: AppTypography.sectionTitle),
                  const SizedBox(height: AppSpacing.sm),
                  _Group(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: result.arrayKwp.toStringAsFixed(1),
                              style: AppTypography.h1.copyWith(fontSize: 34, height: 1),
                            ),
                            TextSpan(text: ' kWp', style: AppTypography.bodyMuted.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                          ]),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                      _ResultRow(
                        label: l10n.calcPanels,
                        value: l10n.calcPanelsCount(result.panelCount, SolarSizing.panelWattage),
                      ),
                      _ResultRow(
                        label: l10n.calcInverter,
                        value: '${_n(result.inverterKw)} kW',
                        detail: _phase == Phase.single ? l10n.calcSinglePhase : l10n.calcThreePhase,
                      ),
                      if (result.batteryCount > 0)
                        _ResultRow(
                          label: l10n.calcBatteries,
                          value: '${_n(result.batteryKwh)} kWh',
                          detail: '${result.batteryCount} × ${SolarSizing.batteryModuleKwh.toStringAsFixed(2)} kWh',
                        ),
                      _ResultRow(
                        label: l10n.calcDailyProduction,
                        value: '≈ ${_n(result.dailyProductionKwh)} kWh',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MatchingPanelsScreen(targetWattage: SolarSizing.panelWattage),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
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

  static String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
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
// ── Loads and results ───────────────────────────────────────────────────

/// White rounded group with hairlines between its rows.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: AppColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A load or duration: label, value with − / +, and a thin slider for big
/// jumps.
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.step,
    required this.max,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final double value;
  final String unit;
  final double step;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  void _nudge(int dir) => onChanged((value + dir * step).clamp(min, max).toDouble());

  @override
  Widget build(BuildContext context) {
    final shown = step < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600))),
              _StepButton(icon: Icons.remove, onTap: () => _nudge(-1)),
              SizedBox(
                width: 76,
                child: Text(
                  '$shown $unit',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.cardTitle.copyWith(fontSize: 15.5),
                ),
              ),
              _StepButton(icon: Icons.add, onTap: () => _nudge(1)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.line,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.08),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 0),
              tickMarkShape: SliderTickMarkShape.noTickMark,
              trackShape: const RectangularSliderTrackShape(),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value.clamp(min, max).toDouble(),
              min: min,
              max: max,
              divisions: ((max - min) / step).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.line)),
        child: Icon(icon, size: 16, color: AppColors.ink900),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMuted)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
              if (detail != null) Text(detail!, style: AppTypography.bodyMuted.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
