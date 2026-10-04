import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// A single labeled stat in the spec row (e.g. "450W" / "Power") —
/// matches the reference PDF's product-page stat strip.
class ProductSpec {
  const ProductSpec(this.value, this.label);
  final String value;
  final String label;
}

/// Row of key specs shown as a strip of value-over-label pairs, divided
/// by hairlines — not another card, just inline stats.
class ProductSpecRow extends StatelessWidget {
  const ProductSpecRow({super.key, required this.specs});

  final List<ProductSpec> specs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final spec in specs) ...[
          Expanded(
            child: Column(
              children: [
                Text(spec.value, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(spec.label, style: AppTypography.bodyMuted.copyWith(fontSize: 11)),
              ],
            ),
          ),
          if (spec != specs.last)
            Container(width: 1, height: 30, color: AppColors.line),
        ],
      ],
    );
  }
}
