"use client";

import { useCallback, useEffect, useState } from "react";
import { ORDER_STATUSES, ORDER_STATUS_LABELS, type Order, type OrderStatus } from "@solary/shared-types";
import { AuthedPage } from "@/components/authed_page";
import { OrderCard } from "@/components/order_card";
import { errorMessage, listOrders, updateOrderStatus } from "@/lib/api";

const FINAL: OrderStatus[] = ["installed_verified", "cancelled"];

export default function OrdersPage() {
  const [status, setStatus] = useState<OrderStatus | "">("");
  const [orders, setOrders] = useState<Order[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const result = await listOrders(status ? { status } : {});
      setOrders(result.data.orders);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load orders — try again."));
    }
  }, [status]);

  useEffect(() => {
    setOrders(null);
    load();
  }, [load]);

  async function onChange(order: Order, to: OrderStatus) {
    const note = window.prompt(`Move order to "${ORDER_STATUS_LABELS[to]}". Note for the record (optional):`);
    if (note === null) return;
    setBusyId(order.id);
    setError(null);
    try {
      await updateOrderStatus({ orderId: order.id, status: to, note });
      await load();
    } catch (e) {
      setError(errorMessage(e, "Couldn't update that order."));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Orders</h1>
        <p className="muted" style={{ marginBottom: 20 }}>
          Every order on the platform, newest first. Payment is cash on delivery. Vendors move their own orders
          forward; use the override below only to correct or support.
        </p>

        <div className="toolbar">
          <select value={status} onChange={(e) => setStatus(e.target.value as OrderStatus | "")} aria-label="Status filter">
            <option value="">All statuses</option>
            {ORDER_STATUSES.map((s) => (
              <option key={s} value={s}>
                {ORDER_STATUS_LABELS[s]}
              </option>
            ))}
          </select>
          <button className="btn btn-ghost" onClick={load}>
            Refresh
          </button>
        </div>

        {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}
        {orders === null ? (
          <p className="muted">Loading…</p>
        ) : orders.length === 0 ? (
          <div className="empty-state">No orders{status ? ` with status “${ORDER_STATUS_LABELS[status]}”` : ""}.</div>
        ) : (
          orders.map((order) => (
            <OrderCard
              key={order.id}
              order={order}
              actions={
                FINAL.includes(order.status) ? undefined : (
                  <select
                    aria-label="Override status"
                    disabled={busyId === order.id}
                    value=""
                    onChange={(e) => e.target.value && onChange(order, e.target.value as OrderStatus)}
                  >
                    <option value="">Set status…</option>
                    {ORDER_STATUSES.filter((s) => s !== order.status).map((s) => (
                      <option key={s} value={s}>
                        {ORDER_STATUS_LABELS[s]}
                      </option>
                    ))}
                  </select>
                )
              }
            />
          ))
        )}
      </div>
    </AuthedPage>
  );
}
