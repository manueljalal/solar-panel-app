/** "$1,240" / "$1,240.50" / "IQD 400,000". */
export function formatMoney(amount: number, currency: string): string {
  const n = amount.toLocaleString("en-US", {
    minimumFractionDigits: Number.isInteger(amount) ? 0 : 2,
    maximumFractionDigits: 2,
  });
  return currency === "USD" ? `$${n}` : `${currency} ${n}`;
}

/** Totals in several currencies, never added together: "$300 + IQD 25,000". */
export function formatTotals(totals: Record<string, number>): string {
  const parts = Object.entries(totals).map(([c, a]) => formatMoney(a, c));
  return parts.length ? parts.join(" + ") : "—";
}

/** Adds per-currency totals of many orders. */
export function sumTotals(list: Record<string, number>[]): Record<string, number> {
  const out: Record<string, number> = {};
  for (const t of list) for (const [c, a] of Object.entries(t)) out[c] = Math.round(((out[c] ?? 0) + a) * 100) / 100;
  return out;
}

export function formatDate(millis: number | null | undefined): string {
  if (!millis) return "—";
  return new Date(millis).toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
}

export function formatDateTime(millis: number | null | undefined): string {
  if (!millis) return "—";
  return new Date(millis).toLocaleString("en-GB", {
    day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit",
  });
}

export type OrderStatus = "placed" | "confirmed" | "out_for_delivery" | "delivered" | "cancelled";

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
  placed: "New",
  confirmed: "Confirmed",
  out_for_delivery: "Out for delivery",
  delivered: "Delivered",
  cancelled: "Cancelled",
};

/** The next step a vendor/admin can take, with its button label. */
export const ORDER_NEXT_STEP: Partial<Record<OrderStatus, { status: OrderStatus; label: string }>> = {
  placed: { status: "confirmed", label: "Confirm order" },
  confirmed: { status: "out_for_delivery", label: "Mark out for delivery" },
  out_for_delivery: { status: "delivered", label: "Mark delivered" },
};

export const CANCELLABLE: OrderStatus[] = ["placed", "confirmed"];

export type QuoteStatus = "new" | "contacted" | "closed";
export const QUOTE_STATUS_LABEL: Record<QuoteStatus, string> = {
  new: "New",
  contacted: "Contacted",
  closed: "Closed",
};

/** WhatsApp chat link for an E.164 phone. */
export function whatsappLink(phone: string): string {
  return `https://wa.me/${phone.replace(/\D/g, "")}`;
}

export type ServiceType = "installation" | "cleaning";
export type ServiceStatus = "new" | "scheduled" | "completed" | "cancelled";

export const SERVICE_TYPE_LABEL: Record<ServiceType, string> = {
  installation: "Installation",
  cleaning: "Panel cleaning",
};

export const SERVICE_STATUS_LABEL: Record<ServiceStatus, string> = {
  new: "New",
  scheduled: "Scheduled",
  completed: "Completed",
  cancelled: "Cancelled",
};

/** A service request as returned to admins and assigned vendors. */
export interface PortalServiceRequest {
  id: string;
  type: ServiceType;
  status: ServiceStatus;
  address: string;
  location: { latitude: number; longitude: number; address?: string } | null;
  city: string;
  preferredDate: number | null;
  scheduledFor: number | null;
  panelCount: number | null;
  systemSizeKw: number | null;
  note: string;
  vendorId: string | null;
  vendorName: string | null;
  createdAt: number | null;
  customerName: string;
  customerPhone: string;
  adminNote: string;
}

/** "2026-10-30" for an <input type="date">, from epoch millis. */
export function toDateInput(millis: number | null | undefined): string {
  if (!millis) return "";
  const d = new Date(millis);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

/** Epoch millis (local noon, so time zones never shift the day) from an <input type="date"> value. */
export function fromDateInput(value: string): number | null {
  if (!value) return null;
  const [y, m, d] = value.split("-").map(Number);
  return new Date(y, m - 1, d, 12).getTime();
}
