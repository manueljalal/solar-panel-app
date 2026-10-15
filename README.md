# Solary platform

Multi-vendor solar marketplace for Iraq: customers browse, order and get
systems installed; vendors list products and fulfil orders; a super admin
runs the platform. One Firebase backend, three clients.

```
apps/
  mobile-storefront/  Flutter — customer app (en / ar / ckb). Browsing, cart,
                      cash-on-delivery checkout, orders, reviews, quotes,
                      account, vendor apply + bulk market for vendors.
  web-vendor/         Next.js — vendor portal: products, orders, quote
                      requests, business profile.
  web-admin/          Next.js — super admin console: vendor applications,
                      orders, users, disputes, categories, banners, Learn,
                      analytics, settings.
  web-storefront/     Next.js — placeholder only (see "Open decisions").

backend/
  functions/          Cloud Functions (TypeScript). Callables are named
                      <group>-<name>: auth-*, storefront-*, vendor-*,
                      admin-*, bulk-*, plus one scheduled cleanup job.
  firestore/          firestore.rules + firestore.indexes.json
  storage/            storage.rules

packages/
  shared-types/       Order/quote/dispute/user types and money/date
                      formatting shared by the two web portals.
  ui-web/             Design tokens (placeholder).

scripts/              One-off Firestore seed / cleanup scripts.
```

## Roles

Role is a Firebase Auth custom claim; Firestore rules and every callable
key off `request.auth.token.role`.

- **customer** (no claim) — every visitor silently gets an anonymous
  account, so cart and checkout work without signing up. Signing up
  (username + password, phone verified over WhatsApp) is optional.
- **vendor** (`role: vendor`, `vendorId`) — granted when an admin approves
  a vendor application.
- **super_admin** — the first one via the one-time `/bootstrap` page; more
  via Users → "Make admin".

There is no separate vendor mobile app; vendors apply from the customer
app and run their business from `web-vendor`.

## How the main flows work

**Ordering (cash on delivery).** `storefront-placeOrder` re-reads every
price, stock flag and vendor status server-side, splits the cart into one
order per vendor and currency, and is idempotent per `checkoutId`. Status
changes all go through `shared/orders/order_store.ts`, which enforces who
may do what (`shared/orders/status.ts`):

| From → to | Who |
|---|---|
| placed → confirmed → installation_scheduled → installer_en_route | vendor (one step at a time) |
| placed / confirmed → cancelled | vendor |
| placed → cancelled | customer |
| installer_en_route → installed_verified | customer (confirms the job) |
| anything non-final → anything | super_admin (support override) |

Verifying an installation counts the sale on each product (`sold`, which
drives "Best sellers") and unlocks reviews.

**Reviews** are verified-purchase only (`storefront-submitReview`), one per
order line, and keep running averages on the product and the vendor.

**Disputes**: the customer reports a problem on an order
(`storefront-openDispute`); an admin resolves it with a written outcome the
customer sees, optionally cancelling the order.

**Quotes**: requests are tied to a product, land in that vendor's inbox
(`vendor-listQuoteRequests`), and the vendor's price/decline shows in the
customer's Account → My quotes.

**Accounts**: username + password; new devices and password resets are
verified by a WhatsApp code. Admins can suspend accounts (revokes sessions)
and suspend vendor businesses (no new orders, no bulk market). Customers
can delete their account from the app; their orders stay with the vendor
without their name or phone.

**Platform settings** (`settings/platform`, edited in admin → Settings):
pause ordering, delivery fee per currency, support contacts.

Data that carries contact details (users, orders, disputes, bulk posts) is
never client-readable; it goes through callables. Catalogue data
(vendors, products, categories, banners, Learn, reviews, settings) is
public-read. All writes go through callables.

## Firebase project

Default project: `flutter-firebase-connect-ec83e` (shared with an older,
unrelated app; Solary's collections don't overlap with it).

Secrets (Secret Manager, set with `firebase functions:secrets:set`):
`WHATSAPP_ACCESS_TOKEN`, `SMTP_USER`, `SMTP_PASS`.

Deploying:

```
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

New composite indexes (orders, quote requests, reviews, products by
category + sold) must be deployed before the matching screens work. The
scheduled `scheduled-cleanupExpiredAuthRecords` job needs Cloud Scheduler
(Blaze plan).

The web portals read their Firebase config from `NEXT_PUBLIC_FIREBASE_*`
env vars (`.env.local`, not committed) and are static exports deployed to
the `admin` / `vendor` hosting targets.

## Running and testing

```
npm install                          # repo root — installs all JS workspaces

# Backend
cd backend/functions
npm test                             # typecheck + unit tests
npm run test:emulator                # end-to-end callable tests on the
                                     # Firebase emulators (needs Java and
                                     # firebase-tools)

# Web portals
npm run dev:admin                    # or dev:vendor

# Mobile
cd apps/mobile-storefront
flutter pub get
flutter analyze
flutter test                         # offline widget/unit tests
flutter run
```

CI (`.github/workflows/ci.yml`) runs all of the above on every pull
request: backend unit + emulator tests, both portals' typecheck and static
build, and Flutter analyze/test (plus a check that generated localizations
are committed).

## Still to do

- **Online payments.** Checkout is cash on delivery only. Orders already
  carry `paymentMethod` / `paymentStatus`; adding Zain Cash / FastPay /
  Qi Card means a payment-session callable plus a webhook that marks the
  order paid.
- **Notifications.** Vendors aren't notified of new orders/quotes and
  customers aren't notified of status changes (FCM push or WhatsApp
  templates).
- **Staging project.** Everything runs against one shared production
  project; a separate staging project in `.firebaserc` would make
  testing deploys safe.
- **App Check** on the callables, to cut scripted abuse of public
  endpoints (needs console setup per app).
- **Firestore rules unit tests** (the emulator suite covers the
  callables, not the rules directly).
- **Lockfiles.** `package-lock.json` is gitignored, so CI and deploys
  resolve dependency versions fresh each time.

## Open decisions

- Whether `apps/web-storefront` (a browser storefront) is still wanted
  alongside the Flutter app. It is a placeholder page today.
