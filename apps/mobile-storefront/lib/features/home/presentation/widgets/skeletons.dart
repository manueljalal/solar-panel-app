import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

/// Grey placeholder shapes shown while the home screen's Firestore reads are
/// in flight. They carry no data, so nothing fake is ever shown as real.
class _Bone extends StatelessWidget {
  const _Bone({this.width, required this.height, this.radius = AppSpacing.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class CompanyRowSkeleton extends StatelessWidget {
  const CompanyRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (_, _) => const SizedBox(
          width: 68,
          child: Column(
            children: [
              _Bone(width: 60, height: 60, radius: 30),
              SizedBox(height: 8),
              _Bone(width: 48, height: 11),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column placeholder matching the product grid's tiles.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile() => const Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _Bone(height: double.infinity, radius: 14),
          ),
          SizedBox(height: 8),
          _Bone(width: 110, height: 14),
          SizedBox(height: 6),
          _Bone(width: 60, height: 13),
        ],
      ),
    );
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Row(
            children: [
              tile(),
              const SizedBox(width: AppSpacing.md),
              tile(),
            ],
          ),
        ),
      ),
    );
  }
}
