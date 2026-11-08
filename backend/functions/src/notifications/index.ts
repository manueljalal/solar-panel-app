import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import { notify } from "../shared/notify";

// Status changes are watched on the documents themselves rather than in
// each callable, so every path that moves an order or request (vendor
// portal, admin console, customer cancel) notifies the customer the same
// way, and a new path can't forget to.

const ORDER_NOTIFY = ["confirmed", "out_for_delivery", "delivered", "cancelled"];
const SERVICE_NOTIFY = ["scheduled", "completed", "cancelled"];

const millis = (v: unknown) => (v as { toMillis?: () => number } | null)?.toMillis?.() ?? null;

export const onOrderStatus = onDocumentUpdated({ document: "orders/{orderId}", region: "us-central1" }, async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status || !ORDER_NOTIFY.includes(after.status)) return;
  // A customer who cancels their own order doesn't need to be told.
  const history = (after.statusHistory ?? []) as { status: string; by: string }[];
  if (after.status === "cancelled" && history[history.length - 1]?.by === "customer") return;
  await notify(after.uid, "order_status", {
    orderId: event.params.orderId,
    status: after.status,
    vendorName: after.vendorName ?? "",
  }).catch((err) => logger.error("order notification failed", { orderId: event.params.orderId, err: String(err) }));
});

export const onServiceStatus = onDocumentUpdated({ document: "serviceRequests/{id}", region: "us-central1" }, async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || !SERVICE_NOTIFY.includes(after.status)) return;
  const statusChanged = before.status !== after.status;
  const rescheduled = after.status === "scheduled" && millis(before.scheduledFor) !== millis(after.scheduledFor);
  if (!statusChanged && !rescheduled) return;
  await notify(after.uid, "service_status", {
    requestId: event.params.id,
    status: after.status,
    serviceType: after.type ?? "",
    scheduledFor: millis(after.scheduledFor),
    vendorName: after.vendorName ?? "",
  }).catch((err) => logger.error("service notification failed", { id: event.params.id, err: String(err) }));
});

export const onQuoteStatus = onDocumentUpdated({ document: "quoteRequests/{id}", region: "us-central1" }, async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status || after.status !== "contacted") return;
  await notify(after.uid, "quote_status", {
    requestId: event.params.id,
    status: after.status,
    vendorName: after.vendorName ?? "",
    productTitle: after.productTitle ?? "",
  }).catch((err) => logger.error("quote notification failed", { id: event.params.id, err: String(err) }));
});
