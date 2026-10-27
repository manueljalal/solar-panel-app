import { httpsCallable } from "firebase/functions";
import type { OrderStatus, PortalOrder, PortalServiceRequest, QuoteStatus } from "@solary/ui-web";
import { functions } from "./firebase";

export interface QuoteRequest {
  id: string;
  customerName: string;
  customerPhone: string;
  productId: string | null;
  productTitle: string;
  productImageUrl: string;
  note: string;
  status: QuoteStatus;
  createdAt: number | null;
}

export const listOrders = httpsCallable<{ status?: OrderStatus }, { orders: PortalOrder[] }>(functions, "vendor-listOrders");
export const updateOrderStatus = httpsCallable<{ orderId: string; status: OrderStatus; reason?: string }, { ok: true }>(
  functions,
  "vendor-updateOrderStatus",
);
export const listQuoteRequests = httpsCallable<void, { requests: QuoteRequest[] }>(functions, "vendor-listQuoteRequests");
export const updateQuoteRequest = httpsCallable<{ id: string; status: QuoteStatus }, { ok: true }>(
  functions,
  "vendor-updateQuoteRequest",
);
export const updateProfile = httpsCallable<
  { businessName: string; city: string; address?: string; description?: string; logoUrl?: string },
  { ok: true }
>(functions, "vendor-updateProfile");
export const deleteProduct = httpsCallable<{ productId: string }, { ok: true }>(functions, "vendor-deleteProduct");

export const listServiceJobs = httpsCallable<void, { jobs: PortalServiceRequest[] }>(functions, "vendor-listServiceJobs");
export const updateServiceJob = httpsCallable<
  { id: string; status: "scheduled" | "completed"; scheduledFor?: number | null },
  { ok: true }
>(functions, "vendor-updateServiceJob");

/** Callable errors carry a readable message for HttpsErrors; anything else
 * (network, INTERNAL) falls back to [fallback]. */
export function errorMessage(err: unknown, fallback: string): string {
  const e = err as { code?: string; message?: string };
  if (!e?.message || e.code === "functions/internal" || e.message === "INTERNAL") return fallback;
  return e.message;
}
