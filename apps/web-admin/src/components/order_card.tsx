"use client";

import { useState } from "react";
import { formatDateTime, formatMoney, ORDER_STATUS_LABELS, type Order } from "@solary/shared-types";

export function statusPillClass(status: Order["status"]): string {
  if (status === "installed_verified") return "pill pill-success";
  if (status === "cancelled") return "pill";
  return "pill pill-accent";
}

/** One order as an expandable row: summary line, then items, delivery
 * details and status history. Actions are supplied by the page. */
export function OrderCard({ order, actions }: { order: Order; actions?: React.ReactNode }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="app-row">
      <div className="app-row-main">
        <div className="app-row-title" style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
          <button
            onClick={() => setOpen((o) => !o)}
            aria-expanded={open}
            style={{ all: "unset", cursor: "pointer" }}
          >
            {open ? "▾" : "▸"} {order.vendorName || "Unknown vendor"} · {formatMoney(order.total, order.currency)}
          </button>
          <span className={statusPillClass(order.status)}>{ORDER_STATUS_LABELS[order.status]}</span>
          {order.disputeStatus === "open" && <span className="pill pill-warning">Dispute open</span>}
        </div>
        <div className="app-row-meta">
          #{order.id.slice(0, 8).toUpperCase()} · {order.itemCount} item{order.itemCount === 1 ? "" : "s"} ·{" "}
          {order.contact.name} · {order.address.city} · {formatDateTime(order.createdAt)}
          {order.customerIsGuest && " · guest"}
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
                    <strong>Total (cash on delivery)</strong>
                  </td>
                  <td>
                    <strong>{formatMoney(order.total, order.currency)}</strong>
                  </td>
                </tr>
              </tbody>
            </table>
            <div>
              <strong>Deliver to:</strong> {order.contact.name}, <a href={`tel:${order.contact.phone}`}>{order.contact.phone}</a> —{" "}
              {order.address.text}, {order.address.city}
              {order.address.location && (
                <>
                  {" "}
                  (
                  <a
                    href={`https://www.openstreetmap.org/?mlat=${order.address.location.latitude}&mlon=${order.address.location.longitude}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    map
                  </a>
                  )
                </>
              )}
            </div>
            {order.note && (
              <div>
                <strong>Note:</strong> {order.note}
              </div>
            )}
            {order.disputeResolution && (
              <div>
                <strong>Dispute resolution:</strong> {order.disputeResolution}
              </div>
            )}
            <div>
              <strong>History:</strong>{" "}
              {order.statusHistory
                .map((h) => `${ORDER_STATUS_LABELS[h.status]} (${h.by}, ${formatDateTime(h.at)}${h.note ? ` — ${h.note}` : ""})`)
                .join(" → ")}
            </div>
          </div>
        )}
      </div>
      {actions && <div className="app-row-actions">{actions}</div>}
    </div>
  );
}
