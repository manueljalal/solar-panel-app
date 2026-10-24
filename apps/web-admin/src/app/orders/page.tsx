"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ORDER_STATUS_LABEL,
  OrderDrawer,
  formatDate,
  formatTotals,
  orderNumber,
  type OrderStatus,
  type PortalOrder,
} from "@solary/ui-web";
import { AuthedPage } from "@/components/authed_page";
import { errorMessage, listOrders, updateOrderStatus } from "@/lib/api";

const FILTERS: (OrderStatus | "all")[] = ["all", "placed", "confirmed", "out_for_delivery", "delivered", "cancelled"];

export default function OrdersPage() {
  const [orders, setOrders] = useState<PortalOrder[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<OrderStatus | "all">("all");
  const [search, setSearch] = useState("");
  const [openId, setOpenId] = useState<string | null>(null);

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
        (!q || `${orderNumber(o.id)} ${o.vendorName} ${o.customerName} ${o.customerPhone}`.toLowerCase().includes(q)),
    );
  }, [orders, filter, search]);

  const open = orders?.find((o) => o.id === openId) ?? null;

  return (
    <AuthedPage>
      <div className="content">
        <div className="page-header">
          <div>
            <h1 className="page-title">Orders</h1>
            <p className="page-sub">Every cash-on-delivery order across vendors. Open one to step in if it&apos;s stuck.</p>
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
          <input className="search" placeholder="Search order, vendor, customer" value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>

        {orders === null ? (
          <p className="muted">Loading…</p>
        ) : shown.length === 0 ? (
          <div className="empty-state">
            <strong>No orders here</strong>
            {orders.length ? "Try another filter." : "Orders placed in the app will show up here."}
          </div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Order</th>
                  <th>Vendor</th>
                  <th>Customer</th>
                  <th>Items</th>
                  <th className="num">Total</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {shown.map((o) => (
                  <tr key={o.id} className="clickable" onClick={() => setOpenId(o.id)}>
                    <td>
                      <div className="cell-main">{orderNumber(o.id)}</div>
                      <div className="cell-sub">{formatDate(o.createdAt)}</div>
                    </td>
                    <td>{o.vendorName}</td>
                    <td>
                      <div className="cell-main">{o.customerName || "—"}</div>
                      <div className="cell-sub">{o.customerPhone}</div>
                    </td>
                    <td>{o.items.reduce((s, i) => s + i.qty, 0)}</td>
                    <td className="num cell-main">{formatTotals(o.totals)}</td>
                    <td>
                      <span className={`status status-${o.status}`}>{ORDER_STATUS_LABEL[o.status]}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {open && (
          <OrderDrawer
            order={open}
            showVendor
            onClose={() => setOpenId(null)}
            onChangeStatus={async (status, reason) => {
              await updateOrderStatus({ orderId: open.id, status, reason });
              await load();
            }}
          />
        )}
      </div>
    </AuthedPage>
  );
}
