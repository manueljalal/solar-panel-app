/// Pure order-lifecycle rules (no Firestore), so they can be unit tested.
///   placed -> confirmed -> out_for_delivery -> delivered
/// cancelled from placed (anyone involved) or confirmed (vendor/admin).
export const ORDER_STATUSES = ["placed", "confirmed", "out_for_delivery", "delivered", "cancelled"] as const;
export type OrderStatus = (typeof ORDER_STATUSES)[number];
export type ActorRole = "customer" | "vendor" | "super_admin";

const NEXT: Record<OrderStatus, OrderStatus[]> = {
  placed: ["confirmed", "cancelled"],
  confirmed: ["out_for_delivery", "cancelled"],
  out_for_delivery: ["delivered"],
  delivered: [],
  cancelled: [],
};

/// Why a transition is refused, or null if it's allowed.
export function transitionError(current: OrderStatus, next: OrderStatus, role: ActorRole): string | null {
  if (!NEXT[current].includes(next)) return `An order that is '${current}' can't become '${next}'.`;
  if (role === "customer" && !(next === "cancelled" && current === "placed")) {
    return "This order can no longer be cancelled from the app.";
  }
  return null;
}
