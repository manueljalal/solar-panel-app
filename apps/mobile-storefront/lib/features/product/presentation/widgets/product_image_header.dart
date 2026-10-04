import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/placeholder_image.dart';

/// Full-width product photo with a back button and favorite/share actions
/// floating over it — the top of the product detail screen.
class ProductImageHeader extends StatelessWidget {
  const ProductImageHeader({super.key, required this.imageUrl, required this.onBack});

  final String imageUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: NetworkImageWithFallback(url: imageUrl, fallbackIcon: Icons.solar_power_outlined),
        ),
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIconButton(icon: Icons.arrow_back, onTap: onBack),
                Row(
                  children: [
                    _RoundIconButton(icon: Icons.favorite_border, onTap: () {}),
                    const SizedBox(width: 8),
                    _RoundIconButton(icon: Icons.ios_share, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 19, color: AppColors.ink900),
        ),
      ),
    );
  }
}
