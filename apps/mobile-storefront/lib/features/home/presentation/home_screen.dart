import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/placeholder_image.dart';

/// Marketplace home — structural rebuild (not a re-skin): a dense,
/// info-first layout instead of hero-banner-then-uniform-card-grid.
/// Specifically:
///  - a quick-action icon row right under search (category / quote /
///    top-rated), the way Alibaba surfaces its core flows immediately
///  - a mixed-size featured grid (one large tile + two stacked small ones)
///    instead of a uniform NxN grid
///  - a full-bleed banner that touches the search bar above it, no
///    floating card margin
///  - dense product cards with a rating+sold-count line baked into the
///    card, not just price below the image
/// No auth wall — browsing works as a guest from the first frame.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Solary', style: AppTypography.h1),
                          const SizedBox(height: 2),
                          Row(
                            children: const [
                              Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink600),
                              SizedBox(width: 3),
                              Text('Erbil, Iraq', style: AppTypography.bodyMuted),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.ink600),
                            ],
                          ),
                        ],
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none, size: 26, color: AppColors.ink900),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.searchBar),
                      boxShadow: AppShadows.card,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search panels, brands, packages',
                        prefixIcon: const Icon(Icons.search, color: AppColors.ink600),
                        suffixIcon: const Icon(Icons.tune, color: AppColors.ink600),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _QuickActionRow(),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            const SliverToBoxAdapter(child: _BannerCarousel()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SectionHeader(title: 'Companies'),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 172,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _companies.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
                      itemBuilder: (context, i) => _CompanyTile(company: _companies[i]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeader(title: 'Featured'),
                  const SizedBox(height: AppSpacing.md),
                  const _FeaturedMasonry(),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Best sellers', style: AppTypography.sectionTitle),
                      const _FilterChipRow(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ProductRow(product: _products[i]),
                  ),
                  childCount: _products.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

/// Three tap-targets surfaced immediately under search — Alibaba puts
/// "Source by category / Request quotation / Top ranking" here instead of
/// burying core flows under scrolling. Adapted for a solar marketplace.
class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow();

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.category_outlined, 'Browse\ncategories'),
      (Icons.request_quote_outlined, 'Request\na quote'),
      (Icons.emoji_events_outlined, 'Top rated\nvendors'),
    ];
    return Row(
      children: [
        for (final (icon, label) in actions) ...[
          Expanded(child: _QuickAction(icon: icon, label: label)),
          if (label != actions.last.$2) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.forest),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Banner {
  const _Banner(this.eyebrow, this.headline, this.cta, this.imageUrl);
  final String eyebrow;
  final String headline;
  final String cta;
  final String imageUrl;
}

const _banners = [
  _Banner(
    'LIMITED OFFER',
    'Zero down payment\non residential kits',
    'Get a quote',
    'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=800&q=80',
  ),
  _Banner(
    'NEW',
    'Battery storage,\nbuilt for outages',
    'Explore batteries',
    'https://images.unsplash.com/photo-1624397640148-949b1732bb0a?w=800&q=80',
  ),
  _Banner(
    'VETTED NETWORK',
    'Every vendor,\nsite-verified',
    'Meet the vendors',
    'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=800&q=80',
  ),
];

/// Full-bleed, edge-to-edge — no card margin, no rounded corners butting
/// against the page background. This is the one place the layout should
/// feel like it interrupts the page rather than floating on it.
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _BannerSlide(banner: _banners[i]),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.forest : AppColors.line,
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner});

  final _Banner banner;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NetworkImageWithFallback(url: banner.imageUrl, fallbackIcon: Icons.solar_power_outlined),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.forest.withValues(alpha: 0.92),
                AppColors.forest.withValues(alpha: 0.78),
                AppColors.forest.withValues(alpha: 0.15),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Text(banner.eyebrow, style: AppTypography.eyebrow),
              ),
              const SizedBox(height: 10),
              Text(
                banner.headline,
                style: AppTypography.sectionTitle.copyWith(
                  color: Colors.white,
                  height: 1.25,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(banner.cta, style: AppTypography.link.copyWith(color: AppColors.forest)),
                    const Icon(Icons.chevron_right, color: AppColors.forest, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.sectionTitle),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: const Text('See all', style: AppTypography.link),
        ),
      ],
    );
  }
}

class _Company {
  const _Company(this.name, this.city, this.rating, this.logoUrl);
  final String name;
  final String city;
  final double rating;
  final String logoUrl;
}

const _companies = [
  _Company(
    'SunBridge Energy',
    'Erbil',
    4.9,
    'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=400&q=80',
  ),
  _Company(
    'Helios Power Co.',
    'Sulaymaniyah',
    4.8,
    'https://images.unsplash.com/photo-1497440001374-f26997328c1b?w=400&q=80',
  ),
  _Company(
    'GreenTech Iraq',
    'Basra',
    4.7,
    'https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=400&q=80',
  ),
];

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company});

  final _Company company;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: SizedBox(
                width: 96,
                height: 96,
                child: NetworkImageWithFallback(url: company.logoUrl, fallbackIcon: Icons.storefront_outlined),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            company.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(company.city, style: AppTypography.bodyMuted, overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.star, size: 12, color: AppColors.gold),
              const SizedBox(width: 2),
              Text('${company.rating}', style: AppTypography.bodyMuted),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mixed-size layout: one large featured tile (wattage calculator, the
/// thing most people want first) beside two stacked smaller tiles —
/// instead of every "featured" item getting an identical box. This
/// asymmetry is the actual structural change from the uniform grid.
class _FeaturedMasonry extends StatelessWidget {
  const _FeaturedMasonry();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 5, child: _WattageCalculatorCard()),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                const Expanded(child: _ApplyBanner()),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _LearnTeaser(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A third, smaller tile in the featured cluster — pulls in the Learn
/// content instead of leaving it a separate, disconnected section.
class _LearnTeaser extends StatelessWidget {
  const _LearnTeaser();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.menu_book_outlined, size: 20, color: AppColors.ink900),
          Text(
            'Choosing the right wattage',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(fontSize: 12.5),
          ),
          Text('4 min read', style: AppTypography.bodyMuted.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

/// Wattage calculator — a gauge dial, not an icon-in-a-circle. Fills the
/// larger masonry cell so it reads as the anchor tile of the cluster.
class _WattageCalculatorCard extends StatelessWidget {
  const _WattageCalculatorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CustomPaint(
              painter: _DialPainter(progress: 0.62),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '2.5',
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.0),
                    ),
                    Text('kW', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wattage calculator',
                style: AppTypography.sectionTitle.copyWith(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Two questions, sized system.',
                style: AppTypography.bodyMuted.copyWith(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Try it', style: AppTypography.link.copyWith(color: AppColors.gold)),
                  const Icon(Icons.arrow_forward, color: AppColors.gold, size: 14),
                ],
              ),
            ],
          ),
        ],
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
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.36, 4.71, false, track);

    final fill = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.36, 4.71 * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Vendor onboarding lives here — a card, not a separate app. A real photo
/// carries the tile; the ask sits directly on the image, not beside a
/// generic glyph.
class _ApplyBanner extends StatelessWidget {
  const _ApplyBanner();

  static const _imageUrl = 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600&q=80';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkImageWithFallback(url: _imageUrl, fallbackIcon: Icons.storefront_outlined),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Own a solar\nbusiness?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, height: 1.15),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: AppColors.accentInkOnGold, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sort, size: 16, color: AppColors.ink600),
        const SizedBox(width: 4),
        Text('Best match', style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Product {
  const _Product(this.imageUrl, this.spec, this.brand, this.title, this.vendor, this.price, this.rating, this.sold);
  final String imageUrl;
  final String spec;
  final String brand;
  final String title;
  final String vendor;
  final String price;
  final double rating;
  final int sold;
}

// NOTE: these are stock solar-equipment photos as visual placeholders —
// verified to actually load (many random Unsplash photo IDs 404). They
// read as "solar equipment," not as literal photos of each SKU; real
// per-product photography comes from vendor listing uploads later.
const _products = [
  _Product(
    'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=400&q=80',
    '450W',
    'JinkoSolar',
    'Tiger Neo Mono Panel',
    'SunBridge Energy',
    '\$189',
    4.9,
    312,
  ),
  _Product(
    'https://images.unsplash.com/photo-1624397640148-949b1732bb0a?w=400&q=80',
    '5kWh',
    'Huawei',
    'LUNA2000 Battery Unit',
    'Helios Power Co.',
    '\$1,240',
    4.8,
    87,
  ),
  _Product(
    'https://images.unsplash.com/photo-1592833159155-c62df1b65634?w=400&q=80',
    '6kW',
    'Growatt',
    'Hybrid Grid Inverter',
    'GreenTech Iraq',
    '\$860',
    4.7,
    54,
  ),
  _Product(
    'https://images.unsplash.com/photo-1613665813446-82a78c468a1d?w=400&q=80',
    '400W',
    'Canadian Solar',
    'HiKu6 Mono Panel',
    'SunBridge Energy',
    '\$164',
    4.6,
    203,
  ),
];

/// Dense list-style row (not a card in a grid) — image, spec/brand
/// eyebrow, title, vendor, then a rating+sold line baked directly into
/// the row like a real marketplace listing, with price pinned to the
/// trailing edge. Closer to how Alibaba/Amazon actually lay out results
/// than a Pinterest-style photo grid.
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppSpacing.sm)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: SizedBox(
                width: 92,
                height: 92,
                child: NetworkImageWithFallback(url: product.imageUrl, fallbackIcon: Icons.solar_power_outlined),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${product.spec} · ${product.brand}', style: AppTypography.eyebrow),
                const SizedBox(height: 2),
                Text(product.title, style: AppTypography.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product.vendor, style: AppTypography.bodyMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 13, color: AppColors.gold),
                    const SizedBox(width: 2),
                    Text('${product.rating}', style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.ink400, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${product.sold} sold', style: AppTypography.bodyMuted),
                    const Spacer(),
                    Icon(Icons.favorite_border, size: 17, color: AppColors.ink400),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(product.price, style: AppTypography.price),
        ],
      ),
    );
  }
}
