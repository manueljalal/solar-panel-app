# Solary platform — monorepo structure

Multi-vendor solar marketplace: 3 web apps (structure only) + 1 Flutter
customer marketplace app (built out, connected to a real Firebase backend).

```
apps/
  web-admin/          Next.js — Super Admin console (structure only)
  web-vendor/          Next.js — Vendor/business owner portal (structure only)
  web-storefront/      Next.js — Public customer marketplace (structure only)
  mobile-storefront/   Flutter — the customer-facing marketplace app (built out, live backend)

backend/
  functions/           Firebase Cloud Functions (TypeScript), grouped by
                        role: src/admin, src/vendor, src/storefront, src/shared
                        — still empty stubs; storefront reads go direct from
                        the Flutter app to Firestore for now (see below)
  firestore/           firestore.rules (deployed live) + firestore.indexes.json

packages/
  shared-types/        TS models shared by the 3 web apps (User, Vendor,
                        Product, Order)
  ui-web/              Shared design tokens/components for the web apps

scripts/
  seed-firestore.mjs   One-time script that seeded the live `vendors` and
                        `products` collections — rerun after `npm install`
                        in scripts/ if the database needs reseeding

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
Anonymous auth is now wired up (see below) — every guest silently gets a
real `uid` with no role claim, and `role()` in the rules treats that as
`'customer'`. Setting `role` to `'vendor'`/`'super_admin'` still requires
the Admin SDK.

## Firebase backend — now real, not scaffolding

**Project**: `flutter-firebase-connect-ec83e` (an existing project on the
account, shared with an unrelated earlier app — its `chat_messages`,
`cities`, `faqs` collections are untouched; Solary only added `vendors` and
`products`). Set as the default project in `.firebaserc`.

**What's live right now**:
- `firestore.rules` deployed — public read on `vendors`/`products`, deny
  everything else (writes go through the Admin SDK / a future Function
  only).
- `vendors` (3 docs) and `products` (4 docs) seeded via
  `scripts/seed-firestore.mjs`, matching what was previously hardcoded in
  the Flutter app.
- `apps/mobile-storefront/lib/firebase_options.dart`,
  `ios/Runner/GoogleService-Info.plist`, and
  `android/app/google-services.json` generated via `flutterfire configure`
  against the registered `solary_marketplace` iOS/Android apps on that
  project.
- The app calls `Firebase.initializeApp()` in `main.dart` and reads
  Companies/Products live via `HomeRepository`
  (`lib/features/home/data/home_repository.dart`), which falls back to the
  hardcoded lists in `domain/` on any read error (offline, misconfigured
  project) so the screen never renders blank.
- **Verified live, not just "should work"**: a vendor's rating was changed
  directly in Firestore via a script, and the running app picked up the
  new value (and re-sorted) on next load — confirmed by screenshot, not
  assumed.
- **Anonymous auth** — enabled in the console, wired up in
  `lib/core/auth/auth_repository.dart`. `main.dart` fires
  `AuthRepository().ensureSignedIn()` right after `Firebase.initializeApp()`
  (fire-and-forget — browsing never waits on it). **Verified live**: the
  Firebase user count on the project went from 2 → 3 immediately after a
  fresh launch, and the new account has no email/password, confirming it's
  a real anonymous sign-in, not a stub.
- `firestore.rules` updated so a signed-in user (anonymous included) can
  create/update their own `users/{uid}` doc, but can never set `role` on
  it themselves (still Admin-SDK-only) — deployed, but not yet exercised
  by client code since no feature writes a user doc yet (cart/orders will
  be the first).

## Every screen is real now — no dead buttons

As of this pass, every tap target on the storefront app does something
real. Previously the home screen looked complete but almost nothing on it
was wired up (search, nav tabs, Apply, the calculator, Add to cart —
all no-ops). That's fixed:

- **Bottom nav** (`core/navigation/root_shell.dart`) — Home/Learn/Cart/
  Orders/Account are 5 real, distinct screens behind an `IndexedStack`
  (each keeps its scroll state when you switch away). Previously only
  Home existed; the other 4 tabs did nothing.
- **Cart** — real in-memory state (`features/cart/data/cart_controller.dart`),
  shared app-wide via `CartScope`. "Add to cart" on product detail adds a
  real item; the Cart tab shows it with quantity controls and a live
  subtotal; the nav bar's Cart icon shows a live item-count badge.
  In-memory only — cleared on app restart; not yet backed by Firestore
  (see Next steps).
- **Search** — tapping the home search field opens a real search screen
  that filters the live product catalog as you type (debounced). Client-
  side filtering, not a search index — fine at 4 products, revisit if the
  catalog grows (see `features/search/data/search_repository.dart`).
- **Wattage calculator** — real, working sizing math
  (`features/wattage_calculator/domain/system_size_estimate.dart`):
  daily usage ÷ peak sun hours → system kW → panel count. Two steppers,
  live-updating result. Previously just a static card.
- **Vendor Apply** — a real form that writes to a new `vendorApplications`
  Firestore collection (rules deployed, public write gated to the
  submitter's own uid). No admin-side UI reads these yet — an honest gap,
  not hidden.
- **Request quote** — a real form (bottom sheet) that writes to a new
  `quoteRequests` collection, same pattern/same gap as vendor applications.
- **Learn** — 5 real, written articles (not lorem ipsum), tappable into a
  detail screen.
- **Account** — shows the actual signed-in anonymous uid, proving auth is
  live and not just a background detail nobody sees.

**Still not done, stated plainly**: Checkout doesn't exist — the Cart
screen's "Checkout" button says so via a SnackBar instead of pretending.
Cart state isn't persisted (Firestore-backed cart is the natural next
step, now that a uid exists to key it on). `quoteRequests` and
`vendorApplications` have no vendor/admin-facing UI yet — submissions go
into Firestore and stay there. No real vendor-uploaded photography
(product/vendor images are still the same verified-working stock photos).
No Cloud Functions — the `backend/functions/src/*` folders are still
empty barrels; every write above goes directly from the client, gated by
Firestore rules rather than server-side logic.

## Status
- `apps/mobile-storefront` — 12 screens built (home, product detail,
  cart, search, wattage calculator, vendor apply, quote request, learn ×2,
  orders, account), all reachable through real navigation, all reading or
  writing live Firestore where that makes sense. `flutter analyze` clean;
  `flutter test` — **9 passing** (up from 5 — added cart flow, bottom-nav
  tab coverage, search filtering, wattage-calculator math) + 2 integration
  tests against real Firestore, skipped by default (see below).
- `apps/web-admin`, `apps/web-vendor`, `apps/web-storefront` — folders,
  manifests, and route stubs only, untouched since the mobile pivot.
- `backend/functions/`, `packages/` — structure and typed models only, no
  Cloud Functions logic wired up yet.

## Running the app
```
cd apps/mobile-storefront
flutter pub get
flutter run          # pick a simulator/device when prompted
flutter test         # unit/widget tests, fully offline (fake repository)
```
First iOS build compiles Firebase's native pods (gRPC-C++) from source and
takes several minutes; subsequent builds are fast (~15–30s).

To run the tests that hit the real Firestore project (needs network +
`firebase login` on the machine):
```
flutter test test/home_repository_integration_test.dart --dart-define=RUN_INTEGRATION=true
```
Note: this only works via `flutter run`/`flutter drive` on a real
device/simulator, not the plain `flutter test` VM runner — Firebase's
platform channels aren't available there.

## Re-seeding Firestore
```
cd scripts
npm install
node seed-firestore.mjs
```
Uses Application Default Credentials (`firebase login` / `gcloud auth
application-default login`) — no service account key file needed or
checked in.

## Next steps
1. Build cart + checkout screens; wire "Add to cart" (currently a no-op
   button on the product detail screen) — there's now a real `uid` from
   anonymous auth to attach a cart to.
2. Fill in `backend/functions/src/*/index.ts` — first candidates: a
   `submitVendorApplication` callable (the home screen's "Apply" card has
   no destination yet) and a checkout-session function once cart exists.
3. Build out the remaining storefront screens: vendor profile page,
   search/filter results.
4. When real accounts matter (order history persisting past a reinstall,
   etc.), add the anonymous → email/phone upgrade path via
   `linkWithCredential` — noted but not built in `auth_repository.dart`.
5. Decide whether `web-storefront` (browser) is still wanted alongside the
   Flutter app, or whether mobile is now the primary customer surface.
