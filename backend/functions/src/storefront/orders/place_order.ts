import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { readSettings } from "../../shared/orders/settings";
import { groupLines, sumMoney } from "../../shared/orders/status";
import { cleanEnum, cleanText } from "../../shared/validation/sanitize";

interface PlaceOrderInput {
  /// Client-generated id for this checkout attempt (a UUID). Retrying the
  /// same checkout — e.g. after a timeout — returns the orders the first
  /// attempt created instead of placing them twice.
  checkoutId: string;
  items: { productId: string; quantity: number }[];
  contact: { name: string; phone: string };
  address: { text: string; city: string; latitude?: number; longitude?: number };
  note?: string;
  /// Only cash on delivery for now — online payment providers are a
  /// separate piece of work (see README "Payments").
  paymentMethod: "cod";
}

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
const CHECKOUT_ID_PATTERN = /^[A-Za-z0-9-]{8,64}$/;
const MAX_LINES = 50;
const MAX_QUANTITY = 999;

interface Line {
  productId: string;
  vendorId: string;
  name: string;
  nameI18n: Record<string, string> | null;
  imageUrl: string;
  unitPrice: number;
  currency: "USD" | "IQD";
  quantity: number;
  lineTotal: number;
}

/// Any signed-in user, guests (anonymous accounts) included — checkout is
/// deliberately not behind a sign-up wall; the contact phone is what the
/// vendor uses to arrange delivery.
///
/// Prices, names and stock come from the products collection here, never
/// from the client. A cart spanning several vendors (or currencies) becomes
/// one order per vendor+currency, all sharing `checkoutId`.
export const placeOrder = onCall<PlaceOrderInput>({ region: "us-central1" }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const uid = request.auth.uid;
  const isGuest = request.auth.token.firebase?.sign_in_provider === "anonymous";
  const input = request.data ?? ({} as PlaceOrderInput);

  const checkoutId = input.checkoutId;
  if (typeof checkoutId !== "string" || !CHECKOUT_ID_PATTERN.test(checkoutId)) {
    throw new HttpsError("invalid-argument", "checkoutId is invalid.");
  }
  cleanEnum(input.paymentMethod ?? "cod", ["cod"] as const, "paymentMethod");

  const contactName = cleanText(input.contact?.name, "Name", { max: 80, min: 1 });
  const contactPhone = cleanText(input.contact?.phone, "Phone", { max: 20, min: 1 });
  if (!E164_PATTERN.test(contactPhone)) {
    throw new HttpsError("invalid-argument", "Phone must be in international format, e.g. +9647501234567.");
  }
  const addressText = cleanText(input.address?.text, "Address", { max: 300, min: 3, multiline: true });
  const city = cleanText(input.address?.city, "City", { max: 80, min: 1 });
  const note = cleanText(input.note, "Note", { max: 500, multiline: true });
  const { latitude, longitude } = input.address ?? {};
  const location =
    typeof latitude === "number" && typeof longitude === "number" &&
    Math.abs(latitude) <= 90 && Math.abs(longitude) <= 180
      ? { latitude, longitude }
      : null;

  // Merge duplicate product lines and validate quantities.
  if (!Array.isArray(input.items) || input.items.length === 0) {
    throw new HttpsError("invalid-argument", "Your cart is empty.");
  }
  if (input.items.length > MAX_LINES) {
    throw new HttpsError("invalid-argument", `At most ${MAX_LINES} different products per order.`);
  }
  const quantities = new Map<string, number>();
  for (const item of input.items) {
    if (typeof item?.productId !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(item.productId)) {
      throw new HttpsError("invalid-argument", "A cart item is invalid.");
    }
    if (!Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > MAX_QUANTITY) {
      throw new HttpsError("invalid-argument", `Quantity must be between 1 and ${MAX_QUANTITY}.`);
    }
    const total = (quantities.get(item.productId) ?? 0) + item.quantity;
    if (total > MAX_QUANTITY) throw new HttpsError("invalid-argument", `Quantity must be at most ${MAX_QUANTITY}.`);
    quantities.set(item.productId, total);
  }

  const settings = await readSettings();
  if (!settings.ordersEnabled) {
    throw new HttpsError("unavailable", "Ordering is paused right now. Please try again later.");
  }

  const productIds = [...quantities.keys()];
  const productSnaps = await db.getAll(...productIds.map((id) => db.collection("products").doc(id)));
  const lines: Line[] = productSnaps.map((snap, i) => {
    const p = snap.data();
    if (!snap.exists || !p) {
      throw new HttpsError("failed-precondition", "A product in your cart is no longer available. Remove it and try again.");
    }
    if (p.inStock === false) {
      throw new HttpsError("failed-precondition", `"${p.name}" is out of stock. Remove it and try again.`);
    }
    const quantity = quantities.get(productIds[i])!;
    const unitPrice = typeof p.price === "number" ? p.price : 0;
    return {
      productId: snap.id,
      vendorId: p.vendorId as string,
      name: (p.name as string) ?? "",
      nameI18n: (p.nameI18n as Record<string, string>) ?? null,
      imageUrl: (p.imageUrl as string) ?? "",
      unitPrice,
      currency: p.currency === "IQD" ? "IQD" : "USD",
      quantity,
      lineTotal: sumMoney([unitPrice * quantity]),
    };
  });

  const vendorIds = [...new Set(lines.map((l) => l.vendorId))];
  const vendorSnaps = await db.getAll(...vendorIds.map((id) => db.collection("vendors").doc(id)));
  const vendorNames = new Map<string, string>();
  vendorSnaps.forEach((snap) => {
    const v = snap.data();
    if (!snap.exists || !v || (v.status && v.status !== "approved")) {
      throw new HttpsError("failed-precondition", "A seller in your cart isn't taking orders right now.");
    }
    vendorNames.set(snap.id, (v.businessName as string) ?? "");
  });

  const groups = [...groupLines(lines).entries()];
  const refs = groups.map(([key]) => db.collection("orders").doc(`${checkoutId}_${key}`));

  const orderIds = await db.runTransaction(async (tx) => {
    const existing = await tx.getAll(...refs);
    if (existing.some((s) => s.exists)) {
      // Same checkout retried: only the original caller may see it.
      if (existing.some((s) => s.exists && s.data()!.customerId !== uid)) {
        throw new HttpsError("already-exists", "checkoutId already used.");
      }
      return existing.filter((s) => s.exists).map((s) => s.id);
    }

    const now = Timestamp.now();
    groups.forEach(([, group], i) => {
      const { vendorId, currency } = group[0];
      const subtotal = sumMoney(group.map((l) => l.lineTotal));
      const deliveryFee = settings.deliveryFee[currency];
      tx.create(refs[i], {
        checkoutId,
        customerId: uid,
        customerIsGuest: isGuest,
        contact: { name: contactName, phone: contactPhone },
        address: { text: addressText, city, location },
        note,
        vendorId,
        vendorName: vendorNames.get(vendorId) ?? "",
        items: group.map(({ vendorId: _v, ...line }) => line),
        itemCount: group.reduce((n, l) => n + l.quantity, 0),
        currency,
        subtotal,
        deliveryFee,
        total: sumMoney([subtotal, deliveryFee]),
        paymentMethod: "cod",
        paymentStatus: "unpaid",
        status: "placed",
        statusHistory: [{ status: "placed", at: now, by: "customer", byUid: uid, note: "" }],
        disputeStatus: null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    return refs.map((r) => r.id);
  });

  return { orderIds };
});
