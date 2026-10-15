// Order shapes as returned by the order callables (storefront-listMyOrders,
// vendor-listOrders, admin-listOrders). Timestamps arrive as epoch millis.
// Mirrors backend/functions/src/storefront/orders/place_order.ts.

export const ORDER_STATUSES = [
  "placed",
  "confirmed",
  "installation_scheduled",
  "installer_en_route",
  "installed_verified",
  "cancelled",
] as const;
export type OrderStatus = (typeof ORDER_STATUSES)[number];

export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  placed: "Placed",
  confirmed: "Confirmed",
  installation_scheduled: "Installation scheduled",
  installer_en_route: "Installer on the way",
  installed_verified: "Installed",
  cancelled: "Cancelled",
};

export type Currency = "USD" | "IQD";

export interface OrderLineItem {
  productId: string;
  name: string;
  imageUrl: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
  currency: Currency;
}

export interface OrderStatusChange {
  status: OrderStatus;
  at: number | null;
  by: "customer" | "vendor" | "super_admin";
  note: string;
}

export interface Order {
  id: string;
  checkoutId: string;
  customerId: string;
  customerIsGuest: boolean;
  contact: { name: string; phone: string };
  address: { text: string; city: string; location: { latitude: number; longitude: number } | null };
  note: string;
  vendorId: string;
  vendorName: string;
  items: OrderLineItem[];
  itemCount: number;
  currency: Currency;
  subtotal: number;
  deliveryFee: number;
  total: number;
  /** Only cash on delivery for now. */
  paymentMethod: "cod";
  paymentStatus: "unpaid" | "paid";
  status: OrderStatus;
  statusHistory: OrderStatusChange[];
  disputeStatus: "open" | "resolved" | "rejected" | null;
  disputeResolution?: string;
  createdAt: number | null;
  updatedAt: number | null;
}

/// Next statuses a vendor may set — mirrors canTransition's vendor branch
/// in backend/functions/src/shared/orders/status.ts (the server re-checks).
export function vendorNextStatuses(from: OrderStatus): OrderStatus[] {
  switch (from) {
    case "placed":
      return ["confirmed", "cancelled"];
    case "confirmed":
      return ["installation_scheduled", "cancelled"];
    case "installation_scheduled":
      return ["installer_en_route"];
    default:
      return [];
  }
}

export function formatMoney(amount: number, currency: Currency | string): string {
  const fixed = Number.isInteger(amount) ? amount.toLocaleString("en-US") : amount.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  return currency === "USD" ? `$${fixed}` : `${currency} ${fixed}`;
}

export function formatDateTime(millis: number | null | undefined): string {
  if (!millis) return "—";
  return new Date(millis).toLocaleString("en-GB", { dateStyle: "medium", timeStyle: "short" });
}

export interface QuoteRequest {
  id: string;
  uid: string;
  productId: string | null;
  vendorId: string | null;
  productTitle: string;
  vendor: string;
  note: string;
  customerName: string;
  customerPhone: string;
  status: "submitted" | "responded" | "declined";
  response: { price: number | null; currency: Currency | null; message: string; respondedAt: number | null } | null;
  createdAt: number | null;
}

export interface Dispute {
  id: string;
  orderId: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  vendorId: string;
  vendorName: string;
  orderStatus: OrderStatus;
  reason: string;
  status: "open" | "resolved" | "rejected";
  resolution: string | null;
  createdAt: number | null;
  resolvedAt: number | null;
}
