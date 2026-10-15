import { httpsCallable } from "firebase/functions";
import { FirebaseError } from "firebase/app";
import type { Dispute, Order, OrderStatus, UserSummary } from "@solary/shared-types";
import { functions } from "./firebase";

// Typed wrappers for the admin-* callables (backend/functions/src/admin).

export const listOrders = httpsCallable<{ status?: OrderStatus; vendorId?: string }, { orders: Order[] }>(
  functions,
  "admin-listOrders",
);
export const updateOrderStatus = httpsCallable<{ orderId: string; status: OrderStatus; note?: string }, { ok: true }>(
  functions,
  "admin-updateOrderStatus",
);
export const listDisputes = httpsCallable<{ status?: Dispute["status"] }, { disputes: Dispute[] }>(
  functions,
  "admin-listDisputes",
);
export const resolveDispute = httpsCallable<
  { disputeId: string; outcome: "resolved" | "rejected"; resolution: string; cancelOrder?: boolean },
  { ok: true }
>(functions, "admin-resolveDispute");
export const listUsers = httpsCallable<{ query?: string; before?: number }, { users: UserSummary[]; hasMore: boolean }>(
  functions,
  "admin-listUsers",
);
export const setUserDisabled = httpsCallable<{ uid: string; disabled: boolean }, { ok: true }>(
  functions,
  "admin-setUserDisabled",
);
export const setAdminRole = httpsCallable<{ uid: string; admin: boolean }, { ok: true }>(functions, "admin-setAdminRole");
export const setVendorStatus = httpsCallable<{ vendorId: string; status: "approved" | "suspended" }, { ok: true }>(
  functions,
  "admin-setVendorStatus",
);

export interface Analytics {
  users: number;
  vendors: number;
  products: number;
  openDisputes: number;
  pendingApplications: number;
  pendingQuotes: number;
  ordersByStatus: Record<OrderStatus, number>;
  revenue30d: Record<string, number>;
  ordersByDay: Record<string, number>;
  recentOrdersTruncated: boolean;
}
export const getAnalytics = httpsCallable<void, Analytics>(functions, "admin-getAnalytics");

export interface PlatformSettings {
  ordersEnabled: boolean;
  deliveryFee: { USD: number; IQD: number };
  supportPhone: string;
  supportEmail: string;
}
export const getSettings = httpsCallable<void, PlatformSettings>(functions, "admin-getSettings");
export const updateSettings = httpsCallable<Partial<PlatformSettings>, PlatformSettings>(functions, "admin-updateSettings");

/** The server's message for deliberate errors, else a generic fallback. */
export function errorMessage(e: unknown, fallback: string): string {
  if (e instanceof FirebaseError && e.code !== "functions/internal" && e.message && e.message !== "internal") {
    return e.message;
  }
  return fallback;
}
