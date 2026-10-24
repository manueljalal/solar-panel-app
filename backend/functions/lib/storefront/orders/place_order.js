"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.placeOrder = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_functions_1 = require("firebase-functions");
const firebase_1 = require("../../shared/firebase");
const sanitize_1 = require("../../shared/validation/sanitize");
const send_mail_1 = require("../../shared/mail/send_mail");
const order_emails_1 = require("../../shared/mail/order_emails");
const MAX_LINES = 50;
const MAX_QTY = 1000;
/// Cash-on-delivery checkout. Signed-in, non-anonymous customers only: the
/// order needs a verified phone the vendor can call. Prices, names and
/// stock come from the products collection — never from the client — and
/// the cart is split into one order per vendor, since each vendor confirms
/// and delivers its own part.
exports.placeOrder = (0, https_1.onCall)({ region: "us-central1", secrets: [send_mail_1.smtpUser, send_mail_1.smtpPass] }, async (request) => {
    const auth = request.auth;
    if (!auth)
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    if (auth.token.firebase?.sign_in_provider === "anonymous") {
        throw new https_1.HttpsError("failed-precondition", "Create an account to place an order.");
    }
    const uid = auth.uid;
    const user = (await firebase_1.db.collection("users").doc(uid).get()).data();
    if (!user?.phone)
        throw new https_1.HttpsError("failed-precondition", "Your account needs a verified phone number.");
    const address = (0, sanitize_1.cleanText)(request.data?.address, "address", { max: 300, min: 3 });
    const note = (0, sanitize_1.cleanText)(request.data?.note, "note", { max: 500, multiline: true });
    const rawLoc = request.data?.location;
    let location = null;
    if (rawLoc) {
        const { latitude, longitude } = rawLoc;
        if (typeof latitude !== "number" || typeof longitude !== "number" ||
            !(latitude >= -90 && latitude <= 90) || !(longitude >= -180 && longitude <= 180)) {
            throw new https_1.HttpsError("invalid-argument", "location is invalid.");
        }
        location = { latitude, longitude, address: (0, sanitize_1.cleanText)(rawLoc.address, "location address", { max: 300 }) };
    }
    // Merge duplicate lines, validate quantities.
    const rawItems = request.data?.items;
    if (!Array.isArray(rawItems) || rawItems.length === 0)
        throw new https_1.HttpsError("invalid-argument", "Your cart is empty.");
    if (rawItems.length > MAX_LINES)
        throw new https_1.HttpsError("invalid-argument", `At most ${MAX_LINES} products per order.`);
    const qtyById = new Map();
    for (const raw of rawItems) {
        const id = (0, sanitize_1.cleanDocId)(raw?.productId, "productId");
        const qty = raw?.qty;
        if (typeof qty !== "number" || !Number.isInteger(qty) || qty < 1 || qty > MAX_QTY) {
            throw new https_1.HttpsError("invalid-argument", `Quantity must be between 1 and ${MAX_QTY}.`);
        }
        qtyById.set(id, Math.min(MAX_QTY, (qtyById.get(id) ?? 0) + qty));
    }
    const productSnaps = await firebase_1.db.getAll(...[...qtyById.keys()].map((id) => firebase_1.db.collection("products").doc(id)));
    const byVendor = new Map();
    for (const snap of productSnaps) {
        const p = snap.data();
        if (!snap.exists || !p)
            throw new https_1.HttpsError("not-found", "A product in your cart is no longer available.");
        if (p.inStock === false)
            throw new https_1.HttpsError("failed-precondition", `${p.name} is out of stock.`);
        if (typeof p.price !== "number" || !p.vendorId) {
            throw new https_1.HttpsError("failed-precondition", `${p.name ?? "A product"} can't be ordered right now.`);
        }
        const qty = qtyById.get(snap.id);
        const item = {
            productId: snap.id,
            name: p.name ?? "",
            imageUrl: p.imageUrl ?? "",
            unitPrice: p.price,
            currency: p.currency ?? "USD",
            qty,
            lineTotal: Math.round(p.price * qty * 100) / 100,
        };
        byVendor.set(p.vendorId, [...(byVendor.get(p.vendorId) ?? []), item]);
    }
    const vendorSnaps = await firebase_1.db.getAll(...[...byVendor.keys()].map((id) => firebase_1.db.collection("vendors").doc(id)));
    const batch = firebase_1.db.batch();
    const created = [];
    for (const vSnap of vendorSnaps) {
        const vendor = vSnap.data();
        if (!vSnap.exists || !vendor || vendor.status !== "approved") {
            throw new https_1.HttpsError("failed-precondition", "A seller in your cart is not accepting orders.");
        }
        const items = byVendor.get(vSnap.id);
        const totals = {};
        for (const i of items)
            totals[i.currency] = Math.round(((totals[i.currency] ?? 0) + i.lineTotal) * 100) / 100;
        const ref = firebase_1.db.collection("orders").doc();
        batch.set(ref, {
            uid,
            customerName: user.name ?? "",
            customerPhone: user.phone,
            vendorId: vSnap.id,
            vendorName: vendor.businessName ?? "",
            items,
            totals,
            paymentMethod: "cod",
            address,
            location,
            note,
            status: "placed",
            statusHistory: [{ status: "placed", at: firestore_1.Timestamp.now(), by: "customer" }],
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        created.push({ id: ref.id, vendorId: vSnap.id, vendorName: vendor.businessName ?? "", items, totals });
    }
    await batch.commit();
    // Courtesy email to each vendor; never fails the order.
    await Promise.all(created.map(async (o) => {
        try {
            const app = await firebase_1.db.collection("vendorApplications").where("vendorId", "==", o.vendorId).limit(1).get();
            const email = app.docs[0]?.data().email;
            if (email) {
                await (0, order_emails_1.sendNewOrderEmail)(email, o.vendorName, {
                    id: o.id, items: o.items, totals: o.totals, customerName: user.name ?? "", address,
                });
            }
        }
        catch (err) {
            firebase_functions_1.logger.warn("new-order email failed", { orderId: o.id, err: String(err) });
        }
    }));
    return { orderIds: created.map((o) => o.id) };
});
