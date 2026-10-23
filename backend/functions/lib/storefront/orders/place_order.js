"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.placeOrder = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../../shared/firebase");
const order_status_1 = require("../../shared/orders/order_status");
const sanitize_1 = require("../../shared/validation/sanitize");
const MAX_LINES = 30;
const MAX_QUANTITY = 999;
/// Any signed-in user (anonymous guests included — checkout is never
/// gated behind a real account, see AuthRepository). The client sends only
/// product ids and quantities; every price, name and vendor on the order is
/// read here from the `products` doc, so a tampered client can't change
/// what it pays. Payment is cash on delivery — no gateway is wired up.
///
/// One order can span several vendors: `vendorIds` lists them so each
/// vendor (and the rules' vendor read path) can find the orders that
/// include their products. Totals are kept per currency because products
/// are priced in USD or IQD and the two are never summed together.
exports.placeOrder = (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;
    const input = request.data ?? {};
    if (!Array.isArray(input.items) || input.items.length === 0) {
        throw new https_1.HttpsError("invalid-argument", "Your cart is empty.");
    }
    if (input.items.length > MAX_LINES) {
        throw new https_1.HttpsError("invalid-argument", `An order can have at most ${MAX_LINES} different products.`);
    }
    // Merge duplicate lines so one product can't appear twice on an order.
    const quantities = new Map();
    for (const line of input.items) {
        const productId = (0, sanitize_1.cleanDocId)(line?.productId, "productId");
        const quantity = line?.quantity;
        if (!Number.isInteger(quantity) || quantity < 1 || quantity > MAX_QUANTITY) {
            throw new https_1.HttpsError("invalid-argument", `Quantity must be between 1 and ${MAX_QUANTITY}.`);
        }
        quantities.set(productId, (quantities.get(productId) ?? 0) + quantity);
    }
    for (const quantity of quantities.values()) {
        if (quantity > MAX_QUANTITY) {
            throw new https_1.HttpsError("invalid-argument", `Quantity must be between 1 and ${MAX_QUANTITY}.`);
        }
    }
    const contact = {
        name: (0, sanitize_1.cleanText)(input.contact?.name, "Name", { max: 80, min: 2 }),
        phone: (0, order_status_1.normalizePhone)(input.contact?.phone),
    };
    const delivery = {
        city: (0, sanitize_1.cleanText)(input.delivery?.city, "City", { max: 60, min: 2 }),
        address: (0, sanitize_1.cleanText)(input.delivery?.address, "Address", { max: 300, min: 5, multiline: true }),
        note: (0, sanitize_1.cleanText)(input.delivery?.note, "Delivery note", { max: 500, multiline: true }),
    };
    const productIds = [...quantities.keys()];
    const productSnaps = await firebase_1.db.getAll(...productIds.map((id) => firebase_1.db.collection("products").doc(id)));
    const vendorIds = new Set();
    const totals = {};
    const items = productSnaps.map((snap) => {
        const data = snap.data();
        if (!snap.exists || !data) {
            throw new https_1.HttpsError("not-found", "A product in your cart is no longer available. Remove it and try again.");
        }
        if (data.inStock === false) {
            throw new https_1.HttpsError("failed-precondition", `${data.name ?? "A product"} is out of stock. Remove it and try again.`);
        }
        const price = typeof data.price === "number" ? data.price : NaN;
        if (!Number.isFinite(price) || price <= 0) {
            throw new https_1.HttpsError("failed-precondition", `${data.name ?? "A product"} has no price yet — request a quote instead.`);
        }
        const quantity = quantities.get(snap.id);
        const currency = typeof data.currency === "string" ? data.currency : "USD";
        const lineTotal = Math.round(price * quantity * 100) / 100;
        totals[currency] = Math.round(((totals[currency] ?? 0) + lineTotal) * 100) / 100;
        if (typeof data.vendorId === "string")
            vendorIds.add(data.vendorId);
        return {
            productId: snap.id,
            vendorId: typeof data.vendorId === "string" ? data.vendorId : null,
            name: data.name ?? "Untitled product",
            nameI18n: data.nameI18n ?? null,
            imageUrl: data.imageUrl ?? "",
            unitPrice: price,
            currency,
            quantity,
            lineTotal,
        };
    });
    const orderRef = firebase_1.db.collection("orders").doc();
    await orderRef.set({
        uid,
        status: "placed",
        paymentMethod: "cash_on_delivery",
        items,
        itemCount: items.reduce((sum, item) => sum + item.quantity, 0),
        vendorIds: [...vendorIds],
        totals,
        contact,
        delivery,
        statusHistory: [{ status: "placed", at: new Date(), by: "customer" }],
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { orderId: orderRef.id, totals };
});
