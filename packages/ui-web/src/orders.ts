import type { OrderStatus } from "./format";

/** An order as returned by vendor-listOrders / admin-listOrders. */
export interface PortalOrder {
  id: string;
  uid?: string;
  vendorId: string;
  vendorName: string;
  customerName: string;
  customerPhone: string;
  items: { productId: string; name: string; imageUrl: string; unitPrice: number; currency: string; qty: number; lineTotal: number }[];
  totals: Record<string, number>;
  paymentMethod: string;
  address: string;
  location: { latitude: number; longitude: number; address?: string } | null;
  note: string;
  status: OrderStatus;
  cancelReason: string | null;
  statusHistory: { status: OrderStatus; at: number | null; by: string }[];
  createdAt: number | null;
  updatedAt: number | null;
}

/** Short human-friendly order number from the doc id. */
export function orderNumber(id: string): string {
  return `#${id.slice(0, 6).toUpperCase()}`;
}
