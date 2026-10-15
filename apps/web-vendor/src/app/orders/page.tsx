"use client";

import { useCallback, useEffect, useState } from "react";
import {
  formatDateTime,
  formatMoney,
  ORDER_STATUSES,
  ORDER_STATUS_LABELS,
  vendorNextStatuses,
  type Order,
  type OrderStatus,
} from "@solary/shared-types";
import { VendorShell } from "@/components/vendor_shell";
import { errorMessage, listOrders, updateOrderStatus } from "@/lib/api";

const ACTION_LABEL: Partial<Record<OrderStatus, string>> = {
  confirmed: "Confirm order",
  installation_scheduled: "Mark installation scheduled",
  installer_en_route: "Installer on the way",
  cancelled: "Cancel",
};

function pillClass(status: OrderStatus): string {
  if (status === "installed_verified") return "pill pill-success";
  if (status === "cancelled") return "pill";
  if (status === "placed") return "pill pill-warning";
  return "pill pill-accent";
}

export default function OrdersPage() {
  return <VendorShell>{() => <Orders />}</VendorShell>;
}

function Orders() {
  const [status, setStatus] = useState<OrderStatus | "">("");
  const [orders, setOrders] = useState<Order[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [openId, setOpenId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const result = await listOrders(status ? { status } : {});
      setOrders(result.data.orders);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load your orders — try again."));
    }
  }, [status]);

  useEffect(() => {
    setOrders(null);
    load();
  }, [load]);

  async function advance(order: Order, to: OrderStatus) {
    let note = "";
    if (to === "cancelled") {
      const reason = window.prompt("Why are you cancelling? The customer will see this.");
      if (reason === null) return;
      note = reason;
    } else if (to === "installation_scheduled") {
      const when = window.prompt("When is the installation? (e.g. Sat 18 Oct, morning)");
      if (when === null) return;
      note = when;
    }
    setBusyId(order.id);
    setError(null);
    try {
      await updateOrderStatus({ orderId: order.id, status: to, note });
      await load();
    } catch (e) {
      setError(errorMessage(e, "Couldn't update that order — try again."));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20, marginBottom: 4 }}>Orders</h1>
          <p className="muted">
            Confirm new orders, schedule installation, and mark when the installer is on the way. The customer
            confirms the finished installation. Payment is cash on delivery.
          </p>
        </div>
      </div>

      <div className="toolbar">
        <select value={status} onChange={(e) => setStatus(e.target.value as OrderStatus | "")} aria-label="Status filter">
          <option value="">All orders</option>
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
        <div className="empty-state">No orders{status ? ` that are “${ORDER_STATUS_LABELS[status]}”` : " yet"}.</div>
      ) : (
        orders.map((order) => {
          const open = openId === order.id;
          const next = vendorNextStatuses(order.status);
          return (
            <div className="app-row" key={order.id}>
              <div className="app-row-main">
                <div className="app-row-title" style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
                  <button
                    onClick={() => setOpenId(open ? null : order.id)}
                    aria-expanded={open}
                    style={{ all: "unset", cursor: "pointer" }}
                  >
                    {open ? "▾" : "▸"} {order.contact.name} · {formatMoney(order.total, order.currency)}
                  </button>
                  <span className={pillClass(order.status)}>{ORDER_STATUS_LABELS[order.status]}</span>
                  {order.disputeStatus === "open" && <span className="pill pill-warning">Customer reported a problem</span>}
                </div>
                <div className="app-row-meta">
                  #{order.id.slice(0, 8).toUpperCase()} · {order.itemCount} item{order.itemCount === 1 ? "" : "s"} ·{" "}
                  {order.address.city} · {formatDateTime(order.createdAt)}
                </div>
                {open && (
                  <div className="detail">
                    <table className="line-items">
                      <tbody>
                        {order.items.map((item) => (
                          <tr key={item.productId}>
                            <td>
                              {item.quantity} × {item.name}
                            </td>
                            <td>{formatMoney(item.lineTotal, order.currency)}</td>
                          </tr>
                        ))}
                        <tr>
                          <td>Delivery</td>
                          <td>{formatMoney(order.deliveryFee, order.currency)}</td>
                        </tr>
                        <tr>
                          <td>
                            <strong>Collect in cash</strong>
                          </td>
                          <td>
                            <strong>{formatMoney(order.total, order.currency)}</strong>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                    <div>
                      <strong>Customer:</strong> {order.contact.name},{" "}
                      <a href={`tel:${order.contact.phone}`}>{order.contact.phone}</a> (
                      <a href={`https://wa.me/${order.contact.phone.replace("+", "")}`} target="_blank" rel="noreferrer">
                        WhatsApp
                      </a>
                      )
                    </div>
                    <div>
                      <strong>Address:</strong> {order.address.text}, {order.address.city}
                    </div>
                    {order.note && (
                      <div>
                        <strong>Customer note:</strong> {order.note}
                      </div>
                    )}
                    <div>
                      <strong>History:</strong>{" "}
                      {order.statusHistory
                        .map((h) => `${ORDER_STATUS_LABELS[h.status]} · ${formatDateTime(h.at)}${h.note ? ` — ${h.note}` : ""}`)
                        .join("  →  ")}
                    </div>
                  </div>
                )}
              </div>
              {next.length > 0 && (
                <div className="app-row-actions">
                  {next.map((to) => (
                    <button
                      key={to}
                      className={to === "cancelled" ? "btn btn-danger" : "btn btn-primary"}
                      disabled={busyId === order.id}
                      onClick={() => advance(order, to)}
                    >
                      {ACTION_LABEL[to]}
                    </button>
                  ))}
                </div>
              )}
            </div>
          );
        })
      )}
    </>
  );
}
