# Solary platform — monorepo structure

Multi-vendor solar marketplace: 3 web apps (structure only) + 1 Flutter
customer marketplace app (built out), sharing one Firebase backend.

```
apps/
  web-admin/          Next.js — Super Admin console (structure only)
  web-vendor/          Next.js — Vendor/business owner portal (structure only)
  web-storefront/      Next.js — Public customer marketplace (structure only)
  mobile-storefront/   Flutter — the customer-facing marketplace app (built out)

backend/
  functions/           Firebase Cloud Functions (TypeScript), grouped by
                        role: src/admin, src/vendor, src/storefront, src/shared
  firestore/           firestore.rules + firestore.indexes.json

packages/
  shared-types/        TS models shared by the 3 web apps (User, Vendor,
                        Product, Order)
  ui-web/              Shared design tokens/components for the web apps

docs/
  design-notes.md      Design rationale (superseded in part — see below)
```

## Roles — important correction from the original plan
There is **no separate vendor mobile app**. Vendor onboarding is a card
inside the customer-facing marketplace app ("Own a solar business? →
Apply") — a form, not a login/dashboard product. A `mobile-vendor` Flutter
app was built and then deleted once this was clarified; don't recreate it
without checking with the user first.

- **customer** — browses/compares/buys, no auth wall. `apps/mobile-storefront`
  (built) and eventually `apps/web-storefront` (structure only).
- **vendor** — applies via the in-app "Apply" card; day-to-day business
  management (if it ever needs a dedicated UI) is a `apps/web-vendor`
  concern, not mobile.
- **super_admin** — approves vendors, manages categories, platform-wide
  orders/disputes/analytics. `apps/web-admin` only.

Role is a Firebase Auth custom claim (`shared/auth/roles.ts` on the
Functions side); Firestore rules key off `request.auth.token.role`.

## Status
- `apps/mobile-storefront` — real Flutter app, `flutter create` was run
  (not hand-faked). Home screen is built out: rotating promo banner
  carousel (dot indicators), search bar, Companies directory, wattage
  calculator card, vendor Apply banner, Best sellers product grid. No
  login screen — browsing is guest-first by design. All photography is
  real (Unsplash stock images via `NetworkImageWithFallback`, which falls
  back to a placeholder icon on load failure) — swap for real vendor/
  product uploads later. `flutter analyze` and `flutter test` both pass
  clean (see `test/widget_test.dart`, `test/carousel_test.dart`).
- `apps/web-admin`, `apps/web-vendor`, `apps/web-storefront` — folders,
  manifests, and route stubs only, untouched since the mobile pivot.
- `backend/`, `packages/` — structure and typed models only, no business
  logic wired up yet.

## Running the app
```
cd apps/mobile-storefront
flutter pub get
flutter run          # pick a simulator/device when prompted
flutter test         # widget_test.dart + carousel_test.dart
```
First iOS build compiles Firebase's native pods (gRPC-C++) from source and
takes several minutes; subsequent builds are fast (~15s).

## Next steps
1. `firebase init` / connect a real Firebase project; run
   `flutterfire configure` for mobile-storefront.
2. Build out the remaining storefront screens: product detail, cart,
   checkout, vendor Apply form, search/filter.
3. Fill in `backend/functions/src/*/index.ts` barrels with real callable
   functions per domain.
4. Decide whether `web-storefront` (browser) is still wanted alongside the
   Flutter app, or whether mobile is now the primary customer surface.
