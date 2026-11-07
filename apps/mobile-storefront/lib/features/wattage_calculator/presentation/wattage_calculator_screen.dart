import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/solar_sizing.dart';

/// Solar system calculator, laid out the way installers ask the questions:
/// system type (on-grid / hybrid / off-grid), grid phase, then the load —
/// typed in kW or in amps read off the breaker. Hybrid and off-grid add a
/// night load and night hours so batteries can be sized. Results appear
/// after Calculate and then follow the inputs live.
class WattageCalculatorScreen extends StatefulWidget {
  const WattageCalculatorScreen({super.key});

  @override
  State<WattageCalculatorScreen> createState() => _WattageCalculatorScreenState();
}

enum _LoadUnit { kw, amps }

class _WattageCalculatorScreenState extends State<WattageCalculatorScreen> {
  SystemType _type = SystemType.onGrid;
  Phase _phase = Phase.single;
  _LoadUnit _unit = _LoadUnit.kw;
  bool _withBattery = true;
  bool _calculated = false;

  final _dayLoad = TextEditingController();
  final _nightLoad = TextEditingController();
  final _nightHours = TextEditingController(text: '10');
  final _scroll = ScrollController();
  final _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    for (final c in [_dayLoad, _nightLoad, _nightHours]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _dayLoad.dispose();
    _nightLoad.dispose();
    _nightHours.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Accepts Arabic-Indic / Persian digits and the Arabic decimal mark, as
  /// typed on Arabic and Kurdish keyboards.
  static double? _parse(String raw) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buf = StringBuffer();
    for (final ch in raw.trim().split('')) {
      final e = eastern.indexOf(ch);
      final p = persian.indexOf(ch);
      buf.write(e >= 0 ? '$e' : p >= 0 ? '$p' : (ch == '٫' || ch == ',') ? '.' : ch);
    }
    final v = double.tryParse(buf.toString());
    return v == null || v < 0 ? null : v;
  }

  double _kw(String raw) {
    final v = _parse(raw) ?? 0;
    return _unit == _LoadUnit.kw ? v : SolarSizing.ampsToKw(v, _phase);
  }

  bool get _battery => switch (_type) {
        SystemType.onGrid => false,
        SystemType.hybrid => _withBattery,
        SystemType.offGrid => true,
      };

  SizingInput get _input => SizingInput(
        type: _type,
        phase: _phase,
        dayLoadKw: _kw(_dayLoad.text),
        nightLoadKw: _kw(_nightLoad.text),
        nightHours: _parse(_nightHours.text) ?? 0,
        withBattery: _withBattery,
      );

  bool get _hasLoad => _input.dayLoadKw > 0 || (_battery && _input.nightLoadKw > 0);

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!_hasLoad) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).calcEnterLoad)));
      return;
    }
    setState(() => _calculated = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, title, subtitle) = switch (_type) {
      SystemType.onGrid => (Icons.power_outlined, l10n.calcOnGridTitle, l10n.calcOnGridSubtitle),
      SystemType.hybrid => (Icons.bolt, l10n.calcHybridTitle, l10n.calcHybridSubtitle),
      SystemType.offGrid => (Icons.solar_power_outlined, l10n.calcOffGridTitle, l10n.calcOffGridSubtitle),
    };
    final unitSuffix = _unit == _LoadUnit.kw ? 'kW' : 'A';

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.wattageCalculatorScreenTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.bodyMuted),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Segmented<SystemType>(
              value: _type,
              onChanged: (v) => setState(() => _type = v),
              options: [
                (SystemType.onGrid, Icons.power_outlined, l10n.calcOnGrid),
                (SystemType.hybrid, Icons.bolt, l10n.calcHybrid),
                (SystemType.offGrid, Icons.solar_power_outlined, l10n.calcOffGrid),
              ],
            ),
            if (_type == SystemType.hybrid) ...[
              const SizedBox(height: AppSpacing.md),
              _Section(
                title: l10n.calcBatteryOption,
                child: Row(
                  children: [
                    const Icon(Icons.battery_charging_full_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(l10n.calcIncludeBattery, style: AppTypography.body)),
                    Switch.adaptive(
                      value: _withBattery,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) => setState(() => _withBattery = v),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: l10n.calcPhase,
              child: _Choices<Phase>(
                value: _phase,
                onChanged: (v) => setState(() => _phase = v),
                options: [
                  (Phase.single, Icons.electric_bolt_outlined, l10n.calcSinglePhase),
                  (Phase.three, Icons.view_week_outlined, l10n.calcThreePhase),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: l10n.calcLoadEntry,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Choices<_LoadUnit>(
                    value: _unit,
                    onChanged: (v) => setState(() => _unit = v),
                    options: [
                      (_LoadUnit.kw, Icons.flash_on_outlined, 'kW'),
                      (_LoadUnit.amps, Icons.electrical_services_outlined, l10n.calcAmps),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _NumberField(
                    controller: _dayLoad,
                    icon: _type == SystemType.onGrid ? Icons.power_outlined : Icons.wb_sunny_outlined,
                    label: _type == SystemType.onGrid ? l10n.calcLoad : l10n.calcDayLoad,
                    suffix: unitSuffix,
                  ),
                  if (_battery) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _NumberField(
                      controller: _nightLoad,
                      icon: Icons.nightlight_outlined,
                      label: l10n.calcNightLoad,
                      suffix: unitSuffix,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _NumberField(
                      controller: _nightHours,
                      icon: Icons.schedule_outlined,
                      label: l10n.calcNightHours,
                      suffix: 'h',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_outlined, size: 20),
              label: Text(l10n.calcCalculate, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
              ),
            ),
            if (_calculated && _hasLoad) ...[
              const SizedBox(height: AppSpacing.lg),
              _Results(key: _resultsKey, result: SolarSizing.calculate(_input), phase: _phase),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                ),
                child: Text(l10n.seeMatchingPanels, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.wattageDisclaimer,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted.copyWith(fontSize: 11.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// The three-way system type switch: one rounded track, the selected
/// option filled.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({required this.value, required this.options, required this.onChanged});

  final T value;
  final List<(T, IconData, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (final (v, icon, label) in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: v == value ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(icon, size: 20, color: v == value ? Colors.white : AppColors.ink600),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: v == value ? Colors.white : AppColors.ink600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill choices (phase, load unit).
class _Choices<T> extends StatelessWidget {
  const _Choices({required this.value, required this.options, required this.onChanged});

  final T value;
  final List<(T, IconData, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (v, icon, label) in options)
          GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: v == value ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: v == value ? AppColors.primary : AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: v == value ? Colors.white : AppColors.ink900),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: v == value ? Colors.white : AppColors.ink900,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.icon, required this.label, required this.suffix});

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫]'))],
      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.ink600),
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.surfaceSunken,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({super.key, required this.result, required this.phase});

  final SizingResult result;
  final Phase phase;

  static String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <(IconData, String, String)>[
      (
        Icons.solar_power_outlined,
        l10n.calcPanels,
        '${result.panelCount} × ${SolarSizing.panelWattage}W  ·  ${_n(result.arrayKwp)} kWp',
      ),
      (
        Icons.electrical_services_outlined,
        l10n.calcInverter,
        '${_n(result.inverterKw)} kW  ·  ${phase == Phase.single ? l10n.calcSinglePhase : l10n.calcThreePhase}',
      ),
      if (result.batteryCount > 0)
        (
          Icons.battery_charging_full_outlined,
          l10n.calcBatteries,
          '${result.batteryCount} × ${_n(SolarSizing.batteryModuleKwh)} kWh  ·  ${_n(result.batteryKwh)} kWh',
        ),
      (Icons.wb_sunny_outlined, l10n.calcDailyProduction, '≈ ${_n(result.dailyProductionKwh)} kWh'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.calcResults, style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Container(height: 1, color: Colors.white12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 20, color: Colors.white70),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].$2, style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        // Figures and units read left-to-right in every language.
                        Text(
                          rows[i].$3,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
