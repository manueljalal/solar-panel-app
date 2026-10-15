// End-to-end test of the order flow against the Firebase emulators — real
// callables, real Firestore transactions, real ID tokens. Run with:
//   npm run test:emulator      (from backend/functions, needs Java)
// emulators:exec sets FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST,
// so the Admin SDK below talks to the emulators, never a real project.
const { test, before } = require("node:test");
const assert = require("node:assert/strict");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

const PROJECT = process.env.GCLOUD_PROJECT || "demo-solary";
const FUNCTIONS = `http://127.0.0.1:5001/${PROJECT}/us-central1`;
const AUTH = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1`;

initializeApp({ projectId: PROJECT });
const db = getFirestore();
const auth = getAuth();

async function tokenFor(uid, claims) {
  const customToken = await auth.createCustomToken(uid, claims);
  const res = await fetch(`${AUTH}/accounts:signInWithCustomToken?key=fake`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ token: customToken, returnSecureToken: true }),
  });
  return (await res.json()).idToken;
}

async function guestToken() {
  const res = await fetch(`${AUTH}/accounts:signUp?key=fake`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ returnSecureToken: true }),
  });
  const body = await res.json();
  return { uid: body.localId, token: body.idToken };
}

/// Calls a callable; resolves to `result` or rejects with {status, message}.
async function call(name, data, token) {
  const res = await fetch(`${FUNCTIONS}/${name}`, {
    method: "POST",
    headers: { "content-type": "application/json", ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ data }),
  });
  const body = await res.json();
  if (body.error) {
    const err = new Error(body.error.message);
    err.status = body.error.status;
    throw err;
  }
  return body.result;
}

const ids = {};
let guest, vendorToken, otherVendorToken, adminToken;

before(async () => {
  for (const [id, data] of Object.entries({
    v1: { businessName: "Sun Co", status: "approved", rating: 0, reviewCount: 0 },
    v2: { businessName: "Volt Ltd", status: "approved", rating: 0, reviewCount: 0 },
    v3: { businessName: "Gone Inc", status: "suspended", rating: 0, reviewCount: 0 },
  })) {
    await db.collection("vendors").doc(id).set(data);
  }
  const products = {
    p1: { vendorId: "v1", name: "Panel 550W", price: 120.5, currency: "USD", inStock: true, sold: 0, rating: 0 },
    p2: { vendorId: "v1", name: "Inverter", price: 400, currency: "USD", inStock: true, sold: 0, rating: 0 },
    p3: { vendorId: "v2", name: "Battery", price: 900000, currency: "IQD", inStock: true, sold: 0, rating: 0 },
    p4: { vendorId: "v1", name: "Old stock", price: 10, currency: "USD", inStock: false, sold: 0, rating: 0 },
    p5: { vendorId: "v3", name: "Suspended", price: 10, currency: "USD", inStock: true, sold: 0, rating: 0 },
  };
  for (const [id, data] of Object.entries(products)) {
    await db.collection("products").doc(id).set({ ...data, createdAt: FieldValue.serverTimestamp() });
  }
  await db.collection("settings").doc("platform").set({ ordersEnabled: true, deliveryFee: { USD: 5, IQD: 5000 } });

  guest = await guestToken();
  vendorToken = await tokenFor("vendor-owner-1", { role: "vendor", vendorId: "v1" });
  otherVendorToken = await tokenFor("vendor-owner-2", { role: "vendor", vendorId: "v2" });
  adminToken = await tokenFor("admin-1", { role: "super_admin" });
});

const checkout = (overrides = {}) => ({
  checkoutId: "11111111-2222-3333-4444-555555555555",
  items: [
    { productId: "p1", quantity: 2 },
    { productId: "p3", quantity: 1 },
    { productId: "p2", quantity: 1 },
    { productId: "p1", quantity: 1 },
  ],
  contact: { name: "Ari Customer", phone: "+9647501234567" },
  address: { text: "Street 10, House 4", city: "Erbil" },
  paymentMethod: "cod",
  ...overrides,
});

test("guest checkout splits by vendor+currency with server-side prices", async () => {
  const { orderIds } = await call("storefront-placeOrder", checkout(), guest.token);
  assert.equal(orderIds.length, 2);
  ids.usdOrder = orderIds.find((id) => id.endsWith("v1_USD"));
  ids.iqdOrder = orderIds.find((id) => id.endsWith("v2_IQD"));

  const usd = (await db.collection("orders").doc(ids.usdOrder).get()).data();
  assert.equal(usd.customerId, guest.uid);
  assert.equal(usd.customerIsGuest, true);
  assert.equal(usd.items.find((i) => i.productId === "p1").quantity, 3, "duplicate lines merged");
  assert.equal(usd.subtotal, 761.5); // 3 × 120.5 + 400
  assert.equal(usd.deliveryFee, 5);
  assert.equal(usd.total, 766.5);
  assert.equal(usd.status, "placed");
  assert.equal(usd.paymentMethod, "cod");

  const iqd = (await db.collection("orders").doc(ids.iqdOrder).get()).data();
  assert.equal(iqd.total, 905000);
});

test("retrying the same checkout doesn't create duplicates", async () => {
  const { orderIds } = await call("storefront-placeOrder", checkout(), guest.token);
  assert.deepEqual(orderIds.sort(), [ids.usdOrder, ids.iqdOrder].sort());
  const all = await db.collection("orders").where("customerId", "==", guest.uid).get();
  assert.equal(all.size, 2);
});

test("checkout refuses out-of-stock, suspended vendors and bad input", async () => {
  const fresh = (items) => checkout({ checkoutId: `c-${Math.random().toString(36).slice(2, 12)}`, items });
  await assert.rejects(call("storefront-placeOrder", fresh([{ productId: "p4", quantity: 1 }]), guest.token), /out of stock/);
  await assert.rejects(call("storefront-placeOrder", fresh([{ productId: "p5", quantity: 1 }]), guest.token), /isn't taking orders/);
  await assert.rejects(call("storefront-placeOrder", fresh([{ productId: "nope", quantity: 1 }]), guest.token), /no longer available/);
  await assert.rejects(call("storefront-placeOrder", fresh([{ productId: "p1", quantity: 0 }]), guest.token), /Quantity/);
  await assert.rejects(call("storefront-placeOrder", checkout(), undefined), (e) => e.status === "UNAUTHENTICATED");
});

test("customer lists their own orders only", async () => {
  const mine = await call("storefront-listMyOrders", {}, guest.token);
  assert.equal(mine.orders.length, 2);
  assert.equal(typeof mine.orders[0].createdAt, "number");
  const other = await guestToken();
  assert.equal((await call("storefront-listMyOrders", {}, other.token)).orders.length, 0);
});

test("vendor sees and advances only its own orders", async () => {
  const { orders } = await call("vendor-listOrders", {}, vendorToken);
  assert.deepEqual(orders.map((o) => o.id), [ids.usdOrder]);

  await assert.rejects(
    call("vendor-updateOrderStatus", { orderId: ids.usdOrder, status: "confirmed" }, otherVendorToken),
    (e) => e.status === "NOT_FOUND",
  );
  await assert.rejects(
    call("vendor-updateOrderStatus", { orderId: ids.usdOrder, status: "installer_en_route" }, vendorToken),
    /Can't move/,
  );
  for (const status of ["confirmed", "installation_scheduled", "installer_en_route"]) {
    await call("vendor-updateOrderStatus", { orderId: ids.usdOrder, status }, vendorToken);
  }
  await assert.rejects(
    call("vendor-updateOrderStatus", { orderId: ids.usdOrder, status: "installed_verified" }, vendorToken),
    /Can't move/,
  );
});

test("customer can't review before confirming installation, then can once", async () => {
  await assert.rejects(
    call("storefront-submitReview", { orderId: ids.usdOrder, productId: "p1", rating: 5 }, guest.token),
    /installation is confirmed/,
  );
  await call("storefront-updateMyOrder", { orderId: ids.usdOrder, status: "installed_verified" }, guest.token);

  const order = (await db.collection("orders").doc(ids.usdOrder).get()).data();
  assert.deepEqual(order.statusHistory.map((h) => h.status), [
    "placed", "confirmed", "installation_scheduled", "installer_en_route", "installed_verified",
  ]);
  assert.equal((await db.collection("products").doc("p1").get()).data().sold, 3, "sale counted on verify");

  await call("storefront-submitReview", { orderId: ids.usdOrder, productId: "p1", rating: 4, comment: "Good" }, guest.token);
  await assert.rejects(
    call("storefront-submitReview", { orderId: ids.usdOrder, productId: "p1", rating: 5 }, guest.token),
    /already reviewed/,
  );
  await assert.rejects(
    call("storefront-submitReview", { orderId: ids.usdOrder, productId: "p3", rating: 5 }, guest.token),
    /isn't part of this order/,
  );
  const p1 = (await db.collection("products").doc("p1").get()).data();
  assert.equal(p1.rating, 4);
  assert.equal(p1.reviewCount, 1);
  assert.equal((await db.collection("vendors").doc("v1").get()).data().reviewCount, 1);
});

test("customer cancels a placed order; can't cancel twice", async () => {
  await call("storefront-updateMyOrder", { orderId: ids.iqdOrder, status: "cancelled" }, guest.token);
  await assert.rejects(call("storefront-updateMyOrder", { orderId: ids.iqdOrder, status: "cancelled" }, guest.token), /Can't move/);
});

test("dispute: customer opens, admin lists and resolves", async () => {
  await call("storefront-openDispute", { orderId: ids.usdOrder, reason: "Inverter makes a loud noise." }, guest.token);
  await assert.rejects(
    call("storefront-openDispute", { orderId: ids.usdOrder, reason: "Second complaint here." }, guest.token),
    /already an open issue/,
  );
  await assert.rejects(call("admin-listDisputes", {}, vendorToken), (e) => e.status === "PERMISSION_DENIED");

  const { disputes } = await call("admin-listDisputes", { status: "open" }, adminToken);
  assert.equal(disputes.length, 1);
  await call("admin-resolveDispute", { disputeId: disputes[0].id, outcome: "resolved", resolution: "Vendor replaced the fan." }, adminToken);
  const order = (await db.collection("orders").doc(ids.usdOrder).get()).data();
  assert.equal(order.disputeStatus, "resolved");
});

test("quote requests reach the vendor inbox and the answer reaches the customer", async () => {
  const { requestId } = await call("storefront-submitQuoteRequest", { productId: "p2", note: "Need 3 for a farm" }, guest.token);
  const inbox = await call("vendor-listQuoteRequests", {}, vendorToken);
  assert.deepEqual(inbox.requests.map((r) => r.id), [requestId]);
  assert.equal((await call("vendor-listQuoteRequests", {}, otherVendorToken)).requests.length, 0);

  await assert.rejects(
    call("vendor-respondToQuoteRequest", { requestId, action: "quote", price: 1000 }, otherVendorToken),
    (e) => e.status === "NOT_FOUND",
  );
  await call("vendor-respondToQuoteRequest", { requestId, action: "quote", price: 1100, currency: "USD", message: "Incl. install" }, vendorToken);
  const mine = await call("storefront-listMyQuoteRequests", {}, guest.token);
  assert.equal(mine.requests[0].status, "responded");
  assert.equal(mine.requests[0].response.price, 1100);
});

test("admin analytics and settings", async () => {
  const stats = await call("admin-getAnalytics", {}, adminToken);
  assert.equal(stats.ordersByStatus.installed_verified, 1);
  assert.equal(stats.ordersByStatus.cancelled, 1);
  assert.equal(stats.revenue30d.USD, 766.5);
  assert.equal(stats.vendors, 3);

  await call("admin-updateSettings", { ordersEnabled: false, deliveryFee: { USD: 7 } }, adminToken);
  const settings = await call("admin-getSettings", {}, adminToken);
  assert.equal(settings.deliveryFee.USD, 7);
  assert.equal(settings.deliveryFee.IQD, 5000, "untouched field kept");
  await assert.rejects(
    call("storefront-placeOrder", checkout({ checkoutId: "paused-checkout-0001" }), guest.token),
    /paused/,
  );
  await call("admin-updateSettings", { ordersEnabled: true }, adminToken);
});

test("vendor profile edit is limited to its own fields", async () => {
  await call("vendor-updateProfile", { city: "Duhok", phone: "+9647700000000" }, vendorToken);
  const v1 = (await db.collection("vendors").doc("v1").get()).data();
  assert.equal(v1.city, "Duhok");
  assert.equal(v1.status, "approved");
  await assert.rejects(call("vendor-updateProfile", { phone: "123" }, vendorToken), /international format/);
});

test("admin suspends a vendor business", async () => {
  await call("admin-setVendorStatus", { vendorId: "v2", status: "suspended" }, adminToken);
  await assert.rejects(
    call("storefront-placeOrder", checkout({ checkoutId: "suspended-vendor-01", items: [{ productId: "p3", quantity: 1 }] }), guest.token),
    /isn't taking orders/,
  );
});
