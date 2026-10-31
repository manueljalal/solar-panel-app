# Solary

A multi-vendor solar marketplace for Iraq: shoppers buy solar equipment from
approved vendors in a mobile app (cash on delivery), vendors run their
business from a web portal, and vendors trade with each other (Iraqi and
Chinese companies) in a B2B marketplace.

```
apps/
  mobile-storefront/   Flutter app for shoppers, plus the B2B marketplace for vendors
  web-vendor/          Next.js vendor portal (orders, products, quotes, company)
  web-admin/           Next.js super-admin console
backend/
  functions/           Firebase Cloud Functions (TypeScript, Node 22)
  firestore/           firestore.rules + firestore.indexes.json
  storage/             storage.rules
packages/
  ui-web/              Shared portal styles, formatting helpers, order drawer
scripts/               Firestore seed / cleanup scripts
```

Firebase project: `flutter-firebase-connect-ec83e` (us-central1). The project
also contains functions from an unrelated older app (`createHotel`, `chat`,
`getFaqs`, …); Solary's functions are the `solary` codebase and are all
prefixed `admin-`, `auth-`, `vendor-`, `bulk-` or `storefront-`.

## Roles

Role is a Firebase Auth custom claim, set only by Cloud Functions.

| Role | Where | How you get it |
|---|---|---|
| guest | mobile app | automatic anonymous sign-in; can browse |
| customer | mobile app | sign up: name, username, password, WhatsApp-verified phone |
| vendor | mobile app (B2B) + vendor portal | apply in the app → admin approves |
| super_admin | admin console | `admin-bootstrapSuperAdmin` (one-time) |

There is one credential for everyone: **username (or email) + password**,
with a WhatsApp OTP at sign-up and the first time a new device signs in.
Approving a vendor emails a one-time "set your password" link
(`/set-password` on the vendor portal); an admin can resend it.

## Main flows

**Shopping (cash on delivery).** Cart → Checkout (map location, address,
note) → `storefront-placeOrder`. Prices and stock are re-read on the server
and the cart is split into one order per vendor; each vendor gets an email.
Order lifecycle (`backend/functions/src/shared/orders.ts`):

```
placed → confirmed → out_for_delivery → delivered
   └──────┴──→ cancelled   (customer only while 'placed')
```

Delivering an order adds its quantities to each product's `sold` count.

**Quote requests.** Product page → "Request quote" → lands in that vendor's
portal inbox (`new → contacted → closed`).

**B2B marketplace (vendors only).** Wholesale offers with quantity price
tiers and bulk buy requests, written in English / Arabic / Sorani, with an
optional photo, category, and the company's country (Iraq / China). Shoppers
never see it.

## Data (Firestore)

| Collection | Written by | Client reads |
|---|---|---|
| `products`, `vendors`, `categories`, `banners`, `learnItems` | functions | public |
| `orders`, `bulkListings`, `bulkRequests` | functions | none (via callables) |
| `quoteRequests`, `vendorApplications` | functions | owner only |
| `users`, `usernames`, `phoneOtps`, `passwordSetupTokens` | functions | none |

All writes go through callables that validate input and derive identity from
the verified auth token. Images are uploaded through `vendor-uploadImage`,
which checks the real bytes and stores them under a per-account folder.

## Running locally

```bash
npm install                       # web apps + functions (npm workspaces)
npm run dev:admin                 # http://localhost:3000
npm run dev:vendor
cd apps/mobile-storefront && flutter run
```

Web apps read their Firebase config from `apps/<app>/.env.local`
(`NEXT_PUBLIC_FIREBASE_*`).

Tests:

```bash
cd apps/mobile-storefront && flutter test        # widget + unit tests
cd backend/functions && npx tsc --noEmit         # type-check functions
cd apps/web-admin && npx tsc --noEmit            # (same for web-vendor)
```

## Deploying

```bash
# web apps are static exports
(cd apps/web-admin && npm run build) && (cd apps/web-vendor && npm run build)
firebase deploy --only functions,firestore:rules,firestore:indexes,hosting:admin,hosting:vendor
```

`firebase.json` builds the functions before deploying. Secrets live in Secret
Manager (`firebase functions:secrets:set NAME`): `SMTP_USER`, `SMTP_PASS`,
`WHATSAPP_ACCESS_TOKEN`.

Hosting sites: `solary-admin-dev`, `solary-vendor-dev`.

## Security & reliability measures in place

- Deny-by-default Firestore and Storage rules; every write goes through a
  callable that validates input and takes identity from the auth token.
- Rate limits (Firestore sliding window, `shared/rate_limit.ts`) on sign-in
  (per IP + per-account lockout after 10 failures / 15 min), sign-up, OTP,
  set-password, orders, quote and service requests, uploads, B2B posts,
  vendor applications. OTP codes lock after 5 wrong tries and expire.
- Idempotent checkout (per-checkout `requestId`), transactional order
  state machine (`shared/order_rules.ts`), transactional username changes.
- Global `maxInstances: 20` cost cap; TTL cleanup of throwaway records.
- Security headers on both portals (CSP, HSTS, frame-ancestors none, ...).
- Composite indexes for every list query (`firestore.indexes.json`).
- CI: `.github/workflows/ci.yml` (functions tests, portal builds, Flutter
  analyze + tests).

## Release builds

- Android signing: `apps/mobile-storefront/android/key.properties`
  (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`; git-ignored).
- Google Maps keys: `ios/Flutter/MapsKey.xcconfig`
  (`GOOGLE_MAPS_API_KEY = ...`) and `android/local.properties`
  (`MAPS_API_KEY=...`); both git-ignored.
- Build with obfuscation:
  `flutter build appbundle --obfuscate --split-debug-info=build/symbols`
  and `flutter build ipa --obfuscate --split-debug-info=build/symbols`.

## Before a public launch

These need accounts or decisions from the owner:

- **Production Firebase project.** Everything runs on a dev project shared
  with an older app; move to a dedicated project before real customers.
- **Google Maps key** in Solary's own Cloud project (the current key
  belongs to another project and bills it).
- **App Check** (Firebase console + DeviceCheck/App Attest, Play
  Integrity), then enforce it on callables.
- **Crash reporting / analytics** (Crashlytics) and **push notifications**
  (needs an APNs key from the Apple Developer account).
- **Firestore backups** (point-in-time recovery + scheduled backups) and
  billing budget alerts.
- **Legal review** of /privacy and /terms; native-speaker review of the
  Arabic and Sorani text.
- **Paid courses**: payment provider, and moving episode playback behind a
  server check (video URLs are currently public).
- **Next.js 14 → 16** upgrade for the portals (build-time advisories only;
  the portals are static exports).
