// Order lifecycle shared by storefront/vendor/admin callables. Pure — no
// Firestore — so it can be unit-tested without the emulator (see
// backend/functions/test/order_status.test.js).

export const ORDER_STATUSES = [
  "placed",
  "confirmed",
  "installation_scheduled",
  "installer_en_route",
  "installed_verified",
  "cancelled",
] as const;
export type OrderStatus = (typeof ORDER_STATUSES)[number];

export type OrderActor = "customer" | "vendor" | "super_admin";

// The happy path, in order. Each step may only move forward one at a time
// for a vendor; an admin may jump anywhere (support/corrections).
const FORWARD: Record<OrderStatus, OrderStatus | null> = {
  placed: "confirmed",
  confirmed: "installation_scheduled",
  installation_scheduled: "installer_en_route",
  installer_en_route: "installed_verified",
  installed_verified: null,
  cancelled: null,
};

/// Whether `actor` may move an order from `from` to `to`.
///
/// - customer: cancel while still `placed` (before the vendor commits), and
///   confirm installation (`installer_en_route` → `installed_verified`) —
///   the "verified" in installed_verified is the customer's confirmation.
/// - vendor: one step forward up to `installer_en_route`, or cancel before
///   anyone is dispatched (`placed` / `confirmed`). A vendor can never mark
///   its own job as verified.
/// - super_admin: any change out of a non-final state, plus re-opening a
///   cancelled order is still refused (create a new one instead).
export function canTransition(actor: OrderActor, from: OrderStatus, to: OrderStatus): boolean {
  if (from === to) return false;
  if (from === "cancelled" || from === "installed_verified") return false;

  switch (actor) {
    case "customer":
      return (from === "placed" && to === "cancelled") || (from === "installer_en_route" && to === "installed_verified");
    case "vendor":
      if (to === "cancelled") return from === "placed" || from === "confirmed";
      return FORWARD[from] === to && to !== "installed_verified";
    case "super_admin":
      return true;
  }
}

/// Statuses a vendor can move to next — used by the portals to render only
/// the buttons that would succeed.
export function nextStatusesFor(actor: OrderActor, from: OrderStatus): OrderStatus[] {
  return ORDER_STATUSES.filter((to) => canTransition(actor, from, to));
}

export interface PricedLine {
  vendorId: string;
  currency: "USD" | "IQD";
}

/// Splits a cart into one order per (vendor, currency): each vendor fulfils
/// and tracks its own order, and a total is only meaningful in one
/// currency. Key order is stable (first appearance) so ids are
/// deterministic for the same cart.
export function groupLines<T extends PricedLine>(lines: T[]): Map<string, T[]> {
  const groups = new Map<string, T[]>();
  for (const line of lines) {
    const key = `${line.vendorId}_${line.currency}`;
    const group = groups.get(key);
    if (group) group.push(line);
    else groups.set(key, [line]);
  }
  return groups;
}

/// Money math in minor units so 0.1 + 0.2 never reaches the database.
export function sumMoney(values: number[]): number {
  return Math.round(values.reduce((acc, v) => acc + Math.round(v * 100), 0)) / 100;
}

/// New average after adding one rating of `stars` to `count` existing
/// ratings averaging `average`. Rounded to 2 decimals for display.
export function addRating(average: number, count: number, stars: number): { average: number; count: number } {
  const next = count + 1;
  return { average: Math.round(((average * count + stars) / next) * 100) / 100, count: next };
}
