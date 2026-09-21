# Design notes — moving off the reference UI

The reference screens (Solary marketplace PDF) read as AI-generated /
templated for a few concrete reasons, and the Flutter vendor app's theme
(`apps/mobile-vendor/lib/core/theme/`) is the first place fixing this:

## What was wrong
- **Single accent doing everything.** Gold (#c69049) was used for CTAs,
  section underlines, active tab indicators, and price highlights — no
  hierarchy between "this is the one thing to click" and decoration.
- **Pill radius on everything.** Buttons, banners, cards, tags — all fully
  rounded. Nothing reads as a distinct type of surface.
- **Flat centered icon tiles instead of real content.** Vendor cards,
  category tiles, and the wattage calculator step boxes all use the same
  centered-icon-over-label pattern. It's the generic "empty state" look
  used as if it were finished content.
- **No type scale.** Headline and body weight/size jumps are arbitrary;
  nothing signals reading order.

## What replaces it (see `apps/mobile-vendor/lib/core/theme/`)
- `app_colors.dart` — near-black ink for text/surfaces, forest green
  reserved for header/key panels only, amber accent used only on primary
  actions.
- `app_typography.dart` — real scale (display/h1/h2/body/label) with
  distinct weights and negative tracking on headings.
- `app_spacing.dart` — pill radius reserved for buttons/chips; cards and
  sheets get a modest 14–20px radius instead.
- `dashboard_screen.dart` — stats row + actionable "needs attention" list
  + left-aligned order rows, replacing the centered-tile pattern.

## Placeholders
Until real vendor/product photography exists, use
`shared/widgets/placeholder_image.dart` (`PlaceholderImage` /
`PlaceholderImage.avatar`) everywhere an image would go — never a
hardcoded asset file. Swap to `Image.network(url)` once real media URLs
exist.

## Next
Apply the same token set to `packages/ui-web` so the 3 web apps
(admin/vendor/storefront) inherit the same fix instead of reusing the
reference palette in `packages/ui-web/src/tokens/colors.ts` (currently
still a placeholder carried over from the old screens — flagged there).
