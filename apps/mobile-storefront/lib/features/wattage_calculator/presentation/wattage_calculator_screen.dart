import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/system_size_estimate.dart';

/// Real, working calculator — matches the reference PDF: two steppers
/// (daily usage, peak sunlight hours), live-updating recommendation.
class WattageCalculatorScreen extends StatefulWidget {
  const WattageCalculatorScreen({super.key});

  @override
  State<WattageCalculatorScreen> createState() => _WattageCalculatorScreenState();
}

class _WattageCalculatorScreenState extends State<WattageCalculatorScreen> {
  double _dailyUsage = 12;
  double _peakSun = 6;

  SystemSizeEstimate get _estimate =>
      SystemSizeEstimate.calculate(dailyUsageKwh: _dailyUsage, peakSunHours: _peakSun);

  @override
  Widget build(BuildContext context) {
    final estimate = _estimate;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.wattageCalculatorScreenTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.wattageCalculatorIntro,
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),
            _Stepper(
              title: l10n.dailyUsageTitle,
              subtitle: l10n.dailyUsageSubtitle,
              value: _dailyUsage,
              unit: l10n.unitKwh,
              step: 1,
              min: 1,
              max: 60,
              onChanged: (v) => setState(() => _dailyUsage = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Stepper(
              title: l10n.peakSunlightTitle,
              subtitle: l10n.peakSunlightSubtitle,
              value: _peakSun,
              unit: l10n.unitHours,
              step: 0.5,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => _peakSun = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.recommendedSystem, style: AppTypography.eyebrow),
                  const SizedBox(height: 8),
                  Text(
                    '${estimate.systemKw.toStringAsFixed(1)} kW',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: Colors.white24),
                  const SizedBox(height: 10),
                  Text(
                    l10n.panelEstimate(estimate.panelCount, estimate.panelWattage),
                    style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                ),
                child: Text(l10n.seeMatchingPanels, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                l10n.wattageDisclaimer,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMuted.copyWith(fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.step,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final double value;
  final String unit;
  final double step;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final display = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardTitle),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundButton(icon: Icons.remove, onTap: () => onChanged((value - step).clamp(min, max))),
              Text('$display $unit', style: AppTypography.h1.copyWith(fontSize: 22)),
              _RoundButton(icon: Icons.add, onTap: () => onChanged((value + step).clamp(min, max))),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: AppColors.ink900)),
      ),
    );
  }
}
