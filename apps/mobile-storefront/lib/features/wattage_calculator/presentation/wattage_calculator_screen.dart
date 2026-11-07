import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/solar_sizing.dart';

/// Solar system calculator: pick the system type, set the connection and
/// the loads, and the recommended system below updates as you go.
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

  /// Switching unit keeps the same real load, re-expressed in the new unit.
  void _setUnit(_Unit unit) {
    if (unit == _unit) return;
    final perAmp = SolarSizing.ampsToKw(1, _phase);
    final step = unit == _Unit.kw ? 0.5 : 1.0;
    final max = unit == _Unit.kw ? 40.0 : 150.0;
    double convert(double v) {
      final next = unit == _Unit.amps ? v / perAmp : v * perAmp;
      return ((next / step).round() * step).clamp(0, max).toDouble();
    }

    setState(() {
      _day = convert(_day);
      _night = convert(_night);
      _unit = unit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = _unit == _Unit.kw ? 'kW' : 'A';
    final result = SolarSizing.calculate(SizingInput(
      type: _type,
      phase: _phase,
      dayLoadKw: _kw(_day),
      nightLoadKw: _kw(_night),
      nightHours: _hours,
      withBattery: _withBattery,
    ));
    final description = switch (_type) {
      SystemType.onGrid => l10n.calcOnGridSubtitle,
      SystemType.hybrid => l10n.calcHybridSubtitle,
      SystemType.offGrid => l10n.calcOffGridSubtitle,
    };

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.wattageCalculatorScreenTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          _Segmented<SystemType>(
            value: _type,
            onChanged: (t) => setState(() => _type = t),
            options: [
              (SystemType.onGrid, l10n.calcOnGrid),
              (SystemType.hybrid, l10n.calcHybrid),
              (SystemType.offGrid, l10n.calcOffGrid),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(description, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          _Group(
            children: [
              _Row(
                label: l10n.calcPhase,
                trailing: _Segmented<Phase>(
                  compact: true,
                  value: _phase,
                  onChanged: (p) => setState(() => _phase = p),
                  options: [(Phase.single, l10n.calcSinglePhase), (Phase.three, l10n.calcThreePhase)],
                ),
              ),
              _Row(
                label: l10n.calcUnit,
                trailing: _Segmented<_Unit>(
                  compact: true,
                  value: _unit,
                  onChanged: _setUnit,
                  options: const [(_Unit.kw, 'kW'), (_Unit.amps, 'A')],
                ),
              ),
              if (_type == SystemType.hybrid)
                _Row(
                  label: l10n.calcIncludeBattery,
                  trailing: Switch.adaptive(
                    value: _withBattery,
                    activeTrackColor: AppColors.primary,
                    onChanged: (v) => setState(() => _withBattery = v),
                  ),
                ),
            ],
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
            onPressed: () => Navigator.of(context).maybePop(),
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
        ],
      ),
    );
  }

  static String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

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
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
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

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600))),
          trailing,
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

/// Plain segmented control: muted track, the selected option on a white pill.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
    this.compact = false,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final (v, label) in options)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 8, vertical: compact ? 6 : 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: v == value ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: v == value
                  ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))]
                  : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontSize: compact ? 13 : 14,
                fontWeight: v == value ? FontWeight.w700 : FontWeight.w500,
                color: v == value ? AppColors.ink900 : AppColors.ink600,
              ),
            ),
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(11)),
      child: compact
          ? Row(mainAxisSize: MainAxisSize.min, children: children)
          : Row(children: [for (final c in children) Expanded(child: c)]),
    );
  }
}
