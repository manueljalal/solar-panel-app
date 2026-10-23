# Solary platform — monorepo structure

Multi-vendor solar marketplace: a Flutter customer app plus admin and vendor
web portals, all on one Firebase backend. The public web storefront is still
a placeholder.

```
apps/
  web-admin/          Next.js — Super Admin console (vendors, orders, categories,
                        banners, Learn; users/disputes/analytics/settings TODO)
  web-vendor/          Next.js — Vendor portal (apply, sign in, products)
  web-storefront/      Next.js — Public customer marketplace (placeholder only)
  mobile-storefront/   Flutter — the customer-facing marketplace app (built out, live backend)

backend/
  functions/           Firebase Cloud Functions (TypeScript), grouped by
                        domain: src/admin, src/vendor, src/storefront,
                        src/auth, src/bulk, src/shared. Every client write goes
                        through one of these; public reads go direct to
                        Firestore
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
  (built) and eventually `apps/web-storefront` (placeholder).
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
- **Cart** — `features/cart/data/cart_controller.dart`, shared app-wide via
  `CartScope` and saved on the device. "Add to cart" on product detail adds a
  real item. The Cart tab has quantity controls, per-currency totals and
  Checkout. The nav bar's Cart icon shows a live item-count badge. See
  "Orders and checkout" below.
- **Search** — tapping the home search field opens a real search screen
  that filters the live product catalog as you type (debounced). Client-
  side filtering, not a search index — fine at 4 products, revisit if the
  catalog grows (see `features/search/data/search_repository.dart`).
- **Wattage calculator** — real, working sizing math
  (`features/wattage_calculator/domain/system_size_estimate.dart`):
  daily usage ÷ peak sun hours → system kW → panel count. Two steppers,
  live-updating result. Previously just a static card.
- **Vendor Apply** — a form that submits through `vendor-submitApplication`.
  Admins review applications on the web-admin Vendors page.
- **Request quote** — a bottom-sheet form that submits through
  `storefront-submitQuoteRequest`. No vendor or admin screen reads these
  yet (see Next steps).
- **Learn** — 5 real, written articles (not lorem ipsum), tappable into a
  detail screen.
- **Account** — shows the actual signed-in anonymous uid, proving auth is
  live and not just a background detail nobody sees.

**Still not done**: no screen reads `quoteRequests` yet, and product and
vendor images are still stock photos rather than vendor uploads.

## Orders and checkout

Checkout is **cash on delivery**, with no payment gateway, so the app never
collects card details.

- **Cart** — `CartController`, saved on the device
  (`features/cart/data/cart_storage.dart`) so it survives restarts. Lines are
  keyed by product id. Totals are kept per currency because products are
  priced in USD or IQD and the two are never added together.
- **Checkout** (`features/checkout/`) — name, phone, city, address and an
  optional note. Phone input accepts `0750…`, `00964…`, `+964…` and
  Eastern Arabic digits, and is normalized to E.164 on both the client and
  the server.
- **`storefront-placeOrder`** — the client sends only product ids and
  quantities. The function reads each product's price, name and vendor
  itself and rejects missing or out-of-stock products, so a tampered client
  can't change what it pays. It writes `orders/{id}` with `status: placed`,
  `vendorIds`, per-currency `totals`, and a `statusHistory`.
- **Orders tab** — a live query of the customer's own orders (the rules
  allow only `uid == auth.uid`), with a detail screen. An order can be
  cancelled from there until it's confirmed (`storefront-cancelOrder`).
- **Admin → Orders** (`apps/web-admin/src/app/orders`) — a live list per
  status. Moving an order along placed → confirmed → shipped → delivered,
  or cancelling it, goes through `admin-updateOrderStatus`, which enforces
  the allowed transitions and bumps each product's `sold` count on
  delivery.
- **Rules/indexes** — `orders` is readable by its customer, by any vendor
  in `vendorIds`, and by super_admin; nobody can write it from a client.
  Three composite indexes back the queries above.

**Deploy needed:** `firebase deploy --only functions,firestore:rules,firestore:indexes`.
Until then, Place order fails with a "try again" error.

## Status
- `apps/mobile-storefront` — home, product detail, company store, search,
  cart, checkout, orders and order detail, wattage calculator, Learn, bulk
  market, account (WhatsApp OTP sign-in/up), vendor apply/dashboard/product
  form. Trilingual (en / ar / ckb). `flutter analyze` shows no errors or
  warnings. `flutter test`: 19 pass, 4 fail. The failing tests
  (`auth_screens`, `carousel`, `masonry`, `product_detail`) were written for
  an older UI (username sign-in, hard-coded banners) and need rewriting.
- `apps/web-admin` — vendor applications, orders, categories, banners,
  Learn. Users, Disputes, Analytics and Settings are "Coming soon" pages.
- `apps/web-vendor` — apply, set password, sign in, product create/edit.
- `apps/web-storefront` — placeholder page only.
- `backend/functions` — `npm test` runs unit tests for the order rules.
  Nothing else in the backend has tests yet.

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
1. Deploy the order functions, rules and indexes (see above), then place a
   real order from a device and walk it through the admin Orders page.
2. Show vendors the orders that include their products in `web-vendor`
   (rules already allow reading by `vendorIds`; the
   `vendorIds`/`createdAt` index exists).
3. Notify on new orders (WhatsApp/email to vendor and admin), e.g. an
   `onDocumentCreated("orders/{id}")` trigger reusing `shared/mail` and
   `shared/whatsapp`.
4. Give `quoteRequests` a reader: they store the vendor's display name, not
   its id, so add `vendorId` first, then list them for vendors and admins.
5. Fill in the remaining admin pages (Users, Disputes, Analytics,
   Settings).
6. Rewrite the 4 out-of-date mobile widget tests.
7. Decide whether `web-storefront` is still wanted. Also replace the
   placeholder colors in `packages/ui-web` (see `docs/design-notes.md`).
8. Link anonymous sessions to the real account on sign-in
   (`linkWithCredential`), so a guest's orders stay with them.
