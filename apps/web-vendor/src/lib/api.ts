import { httpsCallable } from "firebase/functions";
import { FirebaseError } from "firebase/app";
import type { Currency, Order, OrderStatus, QuoteRequest } from "@solary/shared-types";
import { functions } from "./firebase";

// Typed wrappers for the vendor-* order/quote/profile callables
// (backend/functions/src/vendor).

export const listOrders = httpsCallable<{ status?: OrderStatus }, { orders: Order[] }>(functions, "vendor-listOrders");
export const updateOrderStatus = httpsCallable<{ orderId: string; status: OrderStatus; note?: string }, { ok: true }>(
  functions,
  "vendor-updateOrderStatus",
);
export const listQuoteRequests = httpsCallable<void, { requests: QuoteRequest[] }>(functions, "vendor-listQuoteRequests");
export const respondToQuoteRequest = httpsCallable<
  { requestId: string; action: "quote" | "decline"; price?: number; currency?: Currency; message?: string },
  { ok: true }
>(functions, "vendor-respondToQuoteRequest");

export interface VendorProfileInput {
  businessName?: string;
  city?: string;
  address?: string;
  phone?: string;
  description?: string;
  logoUrl?: string;
}
export const updateProfile = httpsCallable<VendorProfileInput, { ok: true }>(functions, "vendor-updateProfile");

/** The server's message for deliberate errors, else a generic fallback. */
export function errorMessage(e: unknown, fallback: string): string {
  if (e instanceof FirebaseError && e.code !== "functions/internal" && e.message && e.message !== "internal") {
    return e.message;
  }
  return fallback;
}
