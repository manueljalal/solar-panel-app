/// Which translated copy set a banner slide uses — resolved to actual
/// strings at render time via AppLocalizations (see banner_carousel.dart),
/// since a top-level `const` list can't hold locale-aware text directly.
enum HomeBannerCopy { zeroDown, batteryStorage, vettedVendors }

/// A single slide in the home screen's promo carousel. Only the image and
/// which copy set to show are data here — the actual text is translated.
class HomeBanner {
  const HomeBanner({required this.copy, required this.imageUrl});

  final HomeBannerCopy copy;
  final String imageUrl;
}

// NOTE: hardcoded placeholder content — replace with a real Firestore-backed
// promo feed once the backend exists (see backend/functions/src/storefront).
const homeBanners = [
  HomeBanner(
    copy: HomeBannerCopy.zeroDown,
    imageUrl: 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=800&q=80',
  ),
  HomeBanner(
    copy: HomeBannerCopy.batteryStorage,
    imageUrl: 'https://images.unsplash.com/photo-1624397640148-949b1732bb0a?w=800&q=80',
  ),
  HomeBanner(
    copy: HomeBannerCopy.vettedVendors,
    imageUrl: 'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=800&q=80',
  ),
];
