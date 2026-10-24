import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { db } from "../../shared/firebase";
import { cleanDocId, cleanText } from "../../shared/validation/sanitize";
import { smtpPass, smtpUser } from "../../shared/mail/send_mail";
import { sendNewOrderEmail } from "../../shared/mail/order_emails";
import type { OrderItem } from "../../shared/orders";

interface PlaceOrderInput {
  items: { productId: string; qty: number }[];
  address: string;
  location?: { latitude: number; longitude: number; address?: string } | null;
  note?: string;
}

const MAX_LINES = 50;
const MAX_QTY = 1000;

/// Cash-on-delivery checkout. Signed-in, non-anonymous customers only: the
/// order needs a verified phone the vendor can call. Prices, names and
/// stock come from the products collection — never from the client — and
/// the cart is split into one order per vendor, since each vendor confirms
/// and delivers its own part.
export const placeOrder = onCall<PlaceOrderInput>(
  { region: "us-central1", secrets: [smtpUser, smtpPass] },
  async (request) => {
    const auth = request.auth;
    if (!auth) throw new HttpsError("unauthenticated", "Sign in required.");
    if (auth.token.firebase?.sign_in_provider === "anonymous") {
      throw new HttpsError("failed-precondition", "Create an account to place an order.");
    }
    const uid = auth.uid;

    const user = (await db.collection("users").doc(uid).get()).data();
    if (!user?.phone) throw new HttpsError("failed-precondition", "Your account needs a verified phone number.");

    const address = cleanText(request.data?.address, "address", { max: 300, min: 3 });
    const note = cleanText(request.data?.note, "note", { max: 500, multiline: true });
    const rawLoc = request.data?.location;
    let location: { latitude: number; longitude: number; address: string } | null = null;
    if (rawLoc) {
      const { latitude, longitude } = rawLoc;
      if (
        typeof latitude !== "number" || typeof longitude !== "number" ||
        !(latitude >= -90 && latitude <= 90) || !(longitude >= -180 && longitude <= 180)
      ) {
        throw new HttpsError("invalid-argument", "location is invalid.");
      }
      location = { latitude, longitude, address: cleanText(rawLoc.address, "location address", { max: 300 }) };
    }

    // Merge duplicate lines, validate quantities.
    const rawItems = request.data?.items;
    if (!Array.isArray(rawItems) || rawItems.length === 0) throw new HttpsError("invalid-argument", "Your cart is empty.");
    if (rawItems.length > MAX_LINES) throw new HttpsError("invalid-argument", `At most ${MAX_LINES} products per order.`);
    const qtyById = new Map<string, number>();
    for (const raw of rawItems) {
      const id = cleanDocId(raw?.productId, "productId");
      const qty = raw?.qty;
      if (typeof qty !== "number" || !Number.isInteger(qty) || qty < 1 || qty > MAX_QTY) {
        throw new HttpsError("invalid-argument", `Quantity must be between 1 and ${MAX_QTY}.`);
      }
      qtyById.set(id, Math.min(MAX_QTY, (qtyById.get(id) ?? 0) + qty));
    }

    const productSnaps = await db.getAll(...[...qtyById.keys()].map((id) => db.collection("products").doc(id)));
    const byVendor = new Map<string, OrderItem[]>();
    for (const snap of productSnaps) {
      const p = snap.data();
      if (!snap.exists || !p) throw new HttpsError("not-found", "A product in your cart is no longer available.");
      if (p.inStock === false) throw new HttpsError("failed-precondition", `${p.name} is out of stock.`);
      if (typeof p.price !== "number" || !p.vendorId) {
        throw new HttpsError("failed-precondition", `${p.name ?? "A product"} can't be ordered right now.`);
      }
      const qty = qtyById.get(snap.id)!;
      const item: OrderItem = {
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

    const vendorSnaps = await db.getAll(...[...byVendor.keys()].map((id) => db.collection("vendors").doc(id)));
    const batch = db.batch();
    const created: { id: string; vendorId: string; vendorName: string; items: OrderItem[]; totals: Record<string, number> }[] = [];
    for (const vSnap of vendorSnaps) {
      const vendor = vSnap.data();
      if (!vSnap.exists || !vendor || vendor.status !== "approved") {
        throw new HttpsError("failed-precondition", "A seller in your cart is not accepting orders.");
      }
      const items = byVendor.get(vSnap.id)!;
      const totals: Record<string, number> = {};
      for (const i of items) totals[i.currency] = Math.round(((totals[i.currency] ?? 0) + i.lineTotal) * 100) / 100;
      const ref = db.collection("orders").doc();
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
        statusHistory: [{ status: "placed", at: Timestamp.now(), by: "customer" }],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      created.push({ id: ref.id, vendorId: vSnap.id, vendorName: vendor.businessName ?? "", items, totals });
    }
    await batch.commit();

    // Courtesy email to each vendor; never fails the order.
    await Promise.all(
      created.map(async (o) => {
        try {
          const app = await db.collection("vendorApplications").where("vendorId", "==", o.vendorId).limit(1).get();
          const email = app.docs[0]?.data().email as string | undefined;
          if (email) {
            await sendNewOrderEmail(email, o.vendorName, {
              id: o.id, items: o.items, totals: o.totals, customerName: user.name ?? "", address,
            });
          }
        } catch (err) {
          logger.warn("new-order email failed", { orderId: o.id, err: String(err) });
        }
      }),
    );

    return { orderIds: created.map((o) => o.id) };
  },
);
