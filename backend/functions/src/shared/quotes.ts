import { Timestamp, type DocumentSnapshot } from "firebase-admin/firestore";

/// new -> contacted -> closed (the vendor follows up by phone/WhatsApp).
export const QUOTE_STATUSES = ["new", "contacted", "closed"] as const;

export function serializeQuote(snap: DocumentSnapshot) {
  const d = snap.data() ?? {};
  const millis = (t: unknown) => (t instanceof Timestamp ? t.toMillis() : null);
  return {
    id: snap.id,
    customerName: d.customerName ?? "",
    customerPhone: d.customerPhone ?? "",
    productId: d.productId ?? null,
    productTitle: d.productTitle ?? "",
    productImageUrl: d.productImageUrl ?? "",
    vendorId: d.vendorId ?? null,
    // Requests from before vendorId existed only stored the vendor's name.
    vendorName: d.vendorName ?? d.vendor ?? "",
    note: d.note ?? "",
    status: (d.status === "submitted" ? "new" : d.status) ?? "new",
    createdAt: millis(d.createdAt),
  };
}
