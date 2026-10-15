import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import 'apply_banner.dart';
import 'learn_teaser.dart';
import 'wattage_calculator_card.dart';

/// Mixed-size layout for the "Featured" section: one large tile (the B2B
/// "Own a solar business?" apply card) beside two stacked smaller tiles
/// (wattage calculator + a Learn teaser) — instead of every featured item
/// getting an identical box. This asymmetry is the
/// structural difference from a uniform NxN grid.
class FeaturedMasonry extends StatelessWidget {
  const FeaturedMasonry({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 5, child: ApplyBanner(large: true)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                const Expanded(child: WattageCalculatorCard(compact: true)),
                const SizedBox(height: AppSpacing.md),
                const Expanded(child: LearnTeaser()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
