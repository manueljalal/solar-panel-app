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
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (_, _) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Bone(width: 96, height: 96, radius: AppSpacing.md),
            SizedBox(height: AppSpacing.sm),
            _Bone(width: 72, height: 14),
            SizedBox(height: 6),
            _Bone(width: 48, height: 12),
          ],
        ),
      ),
    );
  }
}

class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              _Bone(width: 88, height: 88, radius: AppSpacing.md),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: 140, height: 14),
                    SizedBox(height: 8),
                    _Bone(width: 90, height: 12),
                    SizedBox(height: 8),
                    _Bone(width: 60, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
