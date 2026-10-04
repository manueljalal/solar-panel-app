import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../wattage_calculator/presentation/wattage_calculator_screen.dart';

/// Wattage calculator — a gauge dial, not an icon-in-a-circle. Fills the
/// larger cell of the Featured masonry so it reads as the anchor tile of
/// the cluster. Tapping it opens the real calculator.
class WattageCalculatorCard extends StatelessWidget {
  const WattageCalculatorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WattageCalculatorScreen()),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CustomPaint(
                  painter: _DialPainter(progress: 0.62),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '2.5',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1.0),
                        ),
                        Text('kW', style: TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.wattageCalculatorTitle,
                style: AppTypography.sectionTitle.copyWith(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.wattageCalculatorSubtitle,
                style: AppTypography.bodyMuted.copyWith(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.tryIt, style: AppTypography.link.copyWith(color: AppColors.accent, fontSize: 12)),
                  const Icon(Icons.arrow_forward, color: AppColors.accent, size: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a partial-ring gauge (like a fuel/battery dial) behind the kW
/// readout — a real instrument face, not a decorative circle.
class _DialPainter extends CustomPainter {
  _DialPainter({required this.progress});

  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.36, 4.71, false, track);

    final fill = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.36, 4.71 * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => oldDelegate.progress != progress;
}
