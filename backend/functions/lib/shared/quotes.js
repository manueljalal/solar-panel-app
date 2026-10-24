"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.QUOTE_STATUSES = void 0;
exports.serializeQuote = serializeQuote;
const firestore_1 = require("firebase-admin/firestore");
/// new -> contacted -> closed (the vendor follows up by phone/WhatsApp).
exports.QUOTE_STATUSES = ["new", "contacted", "closed"];
function serializeQuote(snap) {
    const d = snap.data() ?? {};
    const millis = (t) => (t instanceof firestore_1.Timestamp ? t.toMillis() : null);
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
