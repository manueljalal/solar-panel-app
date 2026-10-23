import { HttpsError } from "firebase-functions/v2/https";

/// Order lifecycle. Payment is cash on delivery (no gateway yet), so there
/// is no "paid" state — an order is settled when it's delivered.
///
///   placed → confirmed → shipped → delivered
///      ↘         ↘          ↘
///                cancelled
export const ORDER_STATUSES = ["placed", "confirmed", "shipped", "delivered", "cancelled"] as const;
export type OrderStatus = (typeof ORDER_STATUSES)[number];

const NEXT: Record<OrderStatus, readonly OrderStatus[]> = {
  placed: ["confirmed", "cancelled"],
  confirmed: ["shipped", "cancelled"],
  shipped: ["delivered", "cancelled"],
  delivered: [],
  cancelled: [],
};

export function assertTransition(from: OrderStatus, to: OrderStatus): void {
  if (!NEXT[from].includes(to)) {
    throw new HttpsError("failed-precondition", `An order that is ${from} can't be marked ${to}.`);
  }
}

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;

/// Accepts what people actually type for an Iraqi mobile number —
/// "0750 123 4567", "00964750…", "+964 750-123-4567", in Western or
/// Eastern Arabic digits — and returns E.164. Anything that still isn't
/// E.164 after that is rejected.
export function normalizePhone(value: unknown): string {
  if (typeof value !== "string" || value.length > 40) {
    throw new HttpsError("invalid-argument", "Enter a phone number.");
  }
  let phone = value
    .replace(/[\u0660-\u0669]/g, (d) => String(d.charCodeAt(0) - 0x0660))
    .replace(/[\u06F0-\u06F9]/g, (d) => String(d.charCodeAt(0) - 0x06f0))
    .replace(/[\s\-().]/g, "");
  if (phone.startsWith("00")) phone = `+${phone.slice(2)}`;
  if (/^07\d{9}$/.test(phone)) phone = `+964${phone.slice(1)}`;
  if (!E164_PATTERN.test(phone)) {
    throw new HttpsError("invalid-argument", "Enter a valid phone number, e.g. 0750 123 4567.");
  }
  return phone;
}
