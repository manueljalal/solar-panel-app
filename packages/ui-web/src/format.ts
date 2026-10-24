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
