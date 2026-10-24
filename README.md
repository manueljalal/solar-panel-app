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

## Before a public launch

These need decisions or accounts from the owner, so they are not done in code:

- **Map tiles.** The location picker uses `tile.openstreetmap.org`, whose
  usage policy doesn't allow production apps. Switch to a tile provider with
  an API key (MapTiler, Stadia, Mapbox, …) in
  `apps/mobile-storefront/lib/shared/location/location_picker_screen.dart`.
- **App Check.** Not enabled; callables currently accept requests from any
  client. Enable it in the Firebase console and in the apps.
- **Production project.** Everything runs on a dev project shared with an
  older app. Create a dedicated production Firebase project and hosting
  sites before launch.
- **Online payments.** Checkout is cash on delivery only.
