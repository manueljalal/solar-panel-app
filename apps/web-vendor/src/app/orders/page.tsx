"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ORDER_NEXT_STEP,
  ORDER_STATUS_LABEL,
  OrderDrawer,
  formatDate,
  formatTotals,
  orderNumber,
  type OrderStatus,
  type PortalOrder,
} from "@solary/ui-web";
import { errorMessage, listOrders, updateOrderStatus } from "@/lib/api";
import { VendorShell, useVendor } from "@/components/vendor_shell";

const FILTERS: (OrderStatus | "all")[] = ["all", "placed", "confirmed", "out_for_delivery", "delivered", "cancelled"];

function OrdersInner() {
  const { refreshCounts } = useVendor();
  const [orders, setOrders] = useState<PortalOrder[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<OrderStatus | "all">("all");
  const [search, setSearch] = useState("");
  const [openId, setOpenId] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      setOrders((await listOrders({})).data.orders);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load orders — try again."));
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: orders?.length ?? 0 };
    for (const o of orders ?? []) c[o.status] = (c[o.status] ?? 0) + 1;
    return c;
  }, [orders]);

  const shown = useMemo(() => {
    const q = search.trim().toLowerCase();
    return (orders ?? []).filter(
      (o) =>
        (filter === "all" || o.status === filter) &&
        (!q || `${orderNumber(o.id)} ${o.customerName} ${o.customerPhone} ${o.items.map((i) => i.name).join(" ")}`.toLowerCase().includes(q)),
    );
  }, [orders, filter, search]);

  async function change(order: PortalOrder, status: OrderStatus, reason?: string) {
    await updateOrderStatus({ orderId: order.id, status, reason });
    await load();
    refreshCounts();
  }

  async function quickAdvance(order: PortalOrder) {
    const next = ORDER_NEXT_STEP[order.status];
    if (!next) return;
    setBusyId(order.id);
    try {
      await change(order, next.status);
    } catch (e) {
      setError(errorMessage(e, "Couldn't update the order — try again."));
    } finally {
      setBusyId(null);
    }
  }

  const open = orders?.find((o) => o.id === openId) ?? null;

  return (
    <>
      <div className="page-header">
        <div>
          <h1 className="page-title">Orders</h1>
          <p className="page-sub">Cash-on-delivery orders from the Solary app. Confirm, deliver, collect payment.</p>
        </div>
        <button className="btn btn-ghost" onClick={() => void load()}>
          Refresh
        </button>
      </div>

      {error && <p className="error-text">{error}</p>}

      <div className="toolbar">
        <div className="tabs">
          {FILTERS.map((f) => (
            <button key={f} className={`tab ${filter === f ? "active" : ""}`} onClick={() => setFilter(f)}>
              {f === "all" ? "All" : ORDER_STATUS_LABEL[f]}
              <span className="tab-count">{counts[f] ?? 0}</span>
            </button>
          ))}
        </div>
        <span className="spacer" />
        <input className="search" placeholder="Search order, customer, product" value={search} onChange={(e) => setSearch(e.target.value)} />
      </div>

      {orders === null ? (
        <p className="muted">Loading…</p>
      ) : shown.length === 0 ? (
        <div className="empty-state">
          <strong>{orders.length ? "No orders here" : "No orders yet"}</strong>
          {orders.length ? "Try another filter." : "When a customer orders one of your products it shows up here."}
        </div>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Order</th>
                <th>Customer</th>
                <th>Items</th>
                <th className="num">Total</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {shown.map((o) => {
                const next = ORDER_NEXT_STEP[o.status];
                return (
                  <tr key={o.id} className="clickable" onClick={() => setOpenId(o.id)}>
                    <td>
                      <div className="cell-main">{orderNumber(o.id)}</div>
                      <div className="cell-sub">{formatDate(o.createdAt)}</div>
                    </td>
                    <td>
                      <div className="cell-main">{o.customerName || "—"}</div>
                      <div className="cell-sub">{o.customerPhone}</div>
                    </td>
                    <td>
                      <div>{o.items.map((i) => `${i.qty} × ${i.name}`).join(", ")}</div>
                    </td>
                    <td className="num cell-main">{formatTotals(o.totals)}</td>
                    <td>
                      <span className={`status status-${o.status}`}>{ORDER_STATUS_LABEL[o.status]}</span>
                    </td>
                    <td className="actions" onClick={(e) => e.stopPropagation()}>
                      {next && (
                        <button className="btn btn-primary btn-sm" disabled={busyId === o.id} onClick={() => quickAdvance(o)}>
                          {next.label}
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {open && <OrderDrawer order={open} onClose={() => setOpenId(null)} onChangeStatus={(s, r) => change(open, s, r)} />}
    </>
  );
}

export default function OrdersPage() {
  return (
    <VendorShell>
      <OrdersInner />
    </VendorShell>
  );
}
