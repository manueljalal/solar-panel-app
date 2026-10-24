"use client";

import { useEffect, useState } from "react";
import {
  CANCELLABLE,
  ORDER_NEXT_STEP,
  ORDER_STATUS_LABEL,
  formatDateTime,
  formatMoney,
  formatTotals,
  whatsappLink,
  type OrderStatus,
} from "./format";
import { orderNumber, type PortalOrder } from "./orders";

/** Right-hand detail panel for one order: items, delivery, contact, history
 * and the actions the viewer may take. Used by the vendor and admin portals;
 * the caller supplies what "advance" and "cancel" do. */
export function OrderDrawer({
  order,
  onClose,
  onChangeStatus,
  showVendor = false,
}: {
  order: PortalOrder;
  onClose: () => void;
  onChangeStatus: (status: OrderStatus, reason?: string) => Promise<void>;
  showVendor?: boolean;
}) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const next = ORDER_NEXT_STEP[order.status];
  const canCancel = CANCELLABLE.includes(order.status);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  async function run(status: OrderStatus, reason?: string) {
    setBusy(true);
    setError(null);
    try {
      await onChangeStatus(status, reason);
    } catch (e) {
      setError((e as { message?: string }).message ?? "Couldn't update the order — try again.");
    } finally {
      setBusy(false);
    }
  }

  function cancel() {
    const reason = window.prompt("Reason for cancelling (shown to the customer):");
    if (reason === null) return;
    void run("cancelled", reason.trim());
  }

  const mapUrl = order.location
    ? `https://www.google.com/maps?q=${order.location.latitude},${order.location.longitude}`
    : null;

  return (
    <>
      <div className="drawer-backdrop" onClick={onClose} />
      <aside className="drawer" role="dialog" aria-label={`Order ${orderNumber(order.id)}`}>
        <div className="drawer-head">
          <div>
            <h2 className="drawer-title">Order {orderNumber(order.id)}</h2>
            <span className={`status status-${order.status}`}>{ORDER_STATUS_LABEL[order.status]}</span>
          </div>
          <button className="icon-btn" onClick={onClose} aria-label="Close">×</button>
        </div>

        <div className="drawer-body">
          {error && <p className="error-text" style={{ marginTop: 0 }}>{error}</p>}

          <div className="line-items">
            {order.items.map((i) => (
              <div className="line-item" key={i.productId}>
                {i.imageUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={i.imageUrl} alt="" className="thumb" />
                ) : (
                  <div className="thumb thumb-empty">·</div>
                )}
                <div className="grow">
                  <div className="cell-main">{i.name}</div>
                  <div className="cell-sub">
                    {i.qty} × {formatMoney(i.unitPrice, i.currency)}
                  </div>
                </div>
                <div className="cell-main">{formatMoney(i.lineTotal, i.currency)}</div>
              </div>
            ))}
            <div className="line-total">
              <span>Total · cash on delivery</span>
              <span>{formatTotals(order.totals)}</span>
            </div>
          </div>

          <dl className="kv">
            {showVendor && (
              <>
                <dt>Vendor</dt>
                <dd>{order.vendorName}</dd>
              </>
            )}
            <dt>Customer</dt>
            <dd>{order.customerName || "—"}</dd>
            <dt>Phone</dt>
            <dd>
              {order.customerPhone ? (
                <>
                  <a className="link" href={`tel:${order.customerPhone}`}>{order.customerPhone}</a>
                  {" · "}
                  <a className="link" href={whatsappLink(order.customerPhone)} target="_blank" rel="noreferrer">WhatsApp</a>
                </>
              ) : "—"}
            </dd>
            <dt>Deliver to</dt>
            <dd>
              {order.address}
              {mapUrl && (
                <>
                  {" · "}
                  <a className="link" href={mapUrl} target="_blank" rel="noreferrer">Map</a>
                </>
              )}
            </dd>
            {order.note && (
              <>
                <dt>Note</dt>
                <dd>{order.note}</dd>
              </>
            )}
            {order.status === "cancelled" && order.cancelReason && (
              <>
                <dt>Cancel reason</dt>
                <dd>{order.cancelReason}</dd>
              </>
            )}
            <dt>Placed</dt>
            <dd>{formatDateTime(order.createdAt)}</dd>
          </dl>

          <div className="section-title" style={{ marginTop: 0 }}>History</div>
          <ul className="timeline">
            {order.statusHistory.map((h, idx) => (
              <li key={idx}>
                {ORDER_STATUS_LABEL[h.status] ?? h.status} · {formatDateTime(h.at)} · by {h.by.replace("_", " ")}
              </li>
            ))}
          </ul>
        </div>

        {(next || canCancel) && (
          <div className="drawer-foot">
            {canCancel && (
              <button className="btn btn-danger" disabled={busy} onClick={cancel}>
                Cancel order
              </button>
            )}
            {next && (
              <button className="btn btn-primary" disabled={busy} onClick={() => run(next.status)}>
                {next.label}
              </button>
            )}
          </div>
        )}
      </aside>
    </>
  );
}
