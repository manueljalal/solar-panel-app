import { httpsCallable } from "firebase/functions";
import type { OrderStatus, PortalOrder, QuoteStatus } from "@solary/ui-web";
import { functions } from "./firebase";

export interface PlatformStats {
  users: number;
  vendors: number;
  products: number;
  pendingApplications: number;
  orders: { placed: number; confirmed: number; outForDelivery: number; delivered: number; cancelled: number };
  newQuotes: number;
  bulkListings: number;
  bulkRequests: number;
}

export interface AdminUser {
  id: string;
  name: string;
  username: string;
  phone: string;
  email: string;
  role: "customer" | "vendor" | "super_admin";
  vendorName: string | null;
  createdAt: number | null;
  lastSignInAt: number | null;
}

export interface AdminProduct {
  id: string;
  name: string;
  brand: string;
  spec: string;
  category: string;
  price: number;
  currency: string;
  imageUrl: string;
  inStock: boolean;
  sold: number;
  vendorId: string | null;
  vendorName: string;
  createdAt: number | null;
}

export interface BulkPost {
  id: string;
  title: string;
  businessName: string;
  country: "IQ" | "CN";
  phone: string;
  status: string;
  unit: string;
  quantity: number | null;
  tiers: { minQty: number; unitPriceUsd: number }[] | null;
  targetPriceUsd: number | null;
  imageUrl: string;
  createdAt: number | null;
}

export interface QuoteRequest {
  id: string;
  customerName: string;
  customerPhone: string;
  productTitle: string;
  productImageUrl: string;
  vendorName: string;
  note: string;
  status: QuoteStatus;
  createdAt: number | null;
}

export const getStats = httpsCallable<void, PlatformStats>(functions, "admin-getStats");
export const listOrders = httpsCallable<{ status?: OrderStatus }, { orders: PortalOrder[] }>(functions, "admin-listOrders");
export const updateOrderStatus = httpsCallable<{ orderId: string; status: OrderStatus; reason?: string }, { ok: true }>(
  functions,
  "admin-updateOrderStatus",
);
export const listUsers = httpsCallable<void, { users: AdminUser[] }>(functions, "admin-listUsers");
export const listProducts = httpsCallable<void, { products: AdminProduct[] }>(functions, "admin-listProducts");
export const removeProduct = httpsCallable<{ productId: string }, { ok: true }>(functions, "admin-removeProduct");
export const listBulkPosts = httpsCallable<{ kind: "listing" | "request" }, { posts: BulkPost[] }>(
  functions,
  "admin-listBulkPosts",
);
export const closeBulkPost = httpsCallable<{ kind: "listing" | "request"; id: string }, { ok: true }>(
  functions,
  "admin-closeBulkPost",
);
export const listQuoteRequests = httpsCallable<void, { requests: QuoteRequest[] }>(functions, "admin-listQuoteRequests");

export function errorMessage(err: unknown, fallback: string): string {
  const e = err as { code?: string; message?: string };
  if (!e?.message || e.code === "functions/internal" || e.message === "INTERNAL") return fallback;
  return e.message;
}
