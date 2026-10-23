"use client";

import { useEffect, useState } from "react";
import { httpsCallable } from "firebase/functions";
import { collection, limit, onSnapshot, orderBy, query, where, type Timestamp } from "firebase/firestore";
import { db, functions } from "@/lib/firebase";
import { AuthedPage } from "@/components/authed_page";

type OrderStatus = "placed" | "confirmed" | "shipped" | "delivered" | "cancelled";

interface OrderLine {
  productId: string;
  name: string;
  quantity: number;
  unitPrice: number;
  currency: string;
  lineTotal: number;
}

interface Order {
  id: string;
  status: OrderStatus;
  items: OrderLine[];
  totals: Record<string, number>;
  contact: { name: string; phone: string };
  delivery: { city: string; address: string; note?: string };
  createdAt: Timestamp | null;
}

const updateOrderStatus = httpsCallable<{ orderId: string; status: OrderStatus }, { ok: true }>(
  functions,
  "admin-updateOrderStatus",
);

const STATUSES: OrderStatus[] = ["placed", "confirmed", "shipped", "delivered", "cancelled"];
const LABELS: Record<OrderStatus, string> = {
  placed: "New",
  confirmed: "Confirmed",
  shipped: "Shipped",
  delivered: "Delivered",
  cancelled: "Cancelled",
};

// Mirrors backend/functions/src/shared/orders/order_status.ts — the server
// enforces it; this only decides which buttons to show.
const NEXT: Record<OrderStatus, { status: OrderStatus; label: string }[]> = {
  placed: [{ status: "confirmed", label: "Confirm" }],
  confirmed: [{ status: "shipped", label: "Mark shipped" }],
  shipped: [{ status: "delivered", label: "Mark delivered" }],
  delivered: [],
  cancelled: [],
};

function money(amount: number, currency: string): string {
  const n = amount.toLocaleString("en-US", { maximumFractionDigits: 2 });
  return currency === "USD" ? `$${n}` : `${currency} ${n}`;
}

function totals(t: Record<string, number>): string {
  return Object.entries(t)
    .sort(([a], [b]) => (a === "USD" ? -1 : b === "USD" ? 1 : a.localeCompare(b)))
    .map(([currency, amount]) => money(amount, currency))
    .join(" + ");
}

export default function OrdersPage() {
  const [tab, setTab] = useState<OrderStatus>("placed");
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  // Live query (rules let super_admin read every order), so a new order or
  // a customer's cancel shows up without a reload. Uses the
  // (status, createdAt desc) index in firestore.indexes.json.
  useEffect(() => {
    setLoading(true);
    setError(null);
    const q = query(collection(db, "orders"), where("status", "==", tab), orderBy("createdAt", "desc"), limit(100));
    return onSnapshot(
      q,
      (snap) => {
        setOrders(snap.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Order, "id">) })));
        setLoading(false);
      },
      () => {
        setError("Couldn't load orders — try again.");
        setLoading(false);
      },
    );
  }, [tab]);

  async function onChange(order: Order, status: OrderStatus) {
    if (status === "cancelled" && !window.confirm(`Cancel order ${order.id.slice(0, 6).toUpperCase()}?`)) return;
    setBusyId(order.id);
    setError(null);
    try {
      await updateOrderStatus({ orderId: order.id, status });
    } catch {
      setError("Couldn't update that order — it may have changed. Try again.");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Orders</h1>
        <p className="muted" style={{ marginBottom: 20 }}>
          Cash-on-delivery orders from the storefront app. Confirm with the customer by phone, then move each order
          along as it ships.
        </p>

        <div className="tabs">
          {STATUSES.map((s) => (
            <button key={s} className={`tab ${tab === s ? "active" : ""}`} onClick={() => setTab(s)}>
              {LABELS[s]}
            </button>
          ))}
        </div>

        {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}
        {loading ? (
          <p className="muted">Loading…</p>
        ) : orders.length === 0 ? (
          <div className="empty-state">No {LABELS[tab].toLowerCase()} orders.</div>
        ) : (
          <div>
            {orders.map((order) => (
              <div className="app-row" key={order.id}>
                <div style={{ flex: 1 }}>
                  <div className="app-row-title">
                    #{order.id.slice(0, 6).toUpperCase()} · {totals(order.totals ?? {})}
                  </div>
                  <div className="app-row-meta">
                    {order.contact?.name} · <a href={`tel:${order.contact?.phone}`}>{order.contact?.phone}</a>
                    {order.createdAt ? ` · ${order.createdAt.toDate().toLocaleString()}` : ""}
                  </div>
                  <div className="app-row-meta">
                    {order.delivery?.address}, {order.delivery?.city}
                  </div>
                  {order.delivery?.note && <div className="app-row-meta">Note: {order.delivery.note}</div>}
                  <div className="app-row-meta">
                    {(order.items ?? [])
                      .map((i) => `${i.quantity} × ${i.name} (${money(i.lineTotal, i.currency)})`)
                      .join(" · ")}
                  </div>
                </div>
                {order.status !== "delivered" && order.status !== "cancelled" && (
                  <div className="app-row-actions">
                    <button
                      className="btn btn-ghost"
                      disabled={busyId === order.id}
                      onClick={() => onChange(order, "cancelled")}
                    >
                      Cancel
                    </button>
                    {NEXT[order.status].map((next) => (
                      <button
                        key={next.status}
                        className="btn btn-primary"
                        disabled={busyId === order.id}
                        onClick={() => onChange(order, next.status)}
                      >
                        {next.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </AuthedPage>
  );
}
