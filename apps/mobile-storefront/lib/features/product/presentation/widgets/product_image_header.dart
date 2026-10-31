import 'package:flutter/material.dart';
import '../../../../core/favorites/favorites_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/placeholder_image.dart';

/// Full-width product photo with a back button and the favourite toggle
/// floating over it — the top of the product detail screen.
class ProductImageHeader extends StatelessWidget {
  const ProductImageHeader({super.key, required this.imageUrl, required this.onBack, this.productId = ''});

  final String imageUrl;
  final String productId;
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
                if (productId.isNotEmpty)
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: FavoritesController.instance,
                    builder: (context, favs, _) => _RoundIconButton(
                      icon: favs.contains(productId) ? Icons.favorite : Icons.favorite_border,
                      color: favs.contains(productId) ? AppColors.accent : null,
                      onTap: () => FavoritesController.instance.toggle(productId),
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

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
          child: Icon(icon, size: 19, color: color ?? AppColors.ink900),
        ),
      ),
    );
  }
}
