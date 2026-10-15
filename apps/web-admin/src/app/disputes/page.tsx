"use client";

import { useCallback, useEffect, useState } from "react";
import { formatDateTime, ORDER_STATUS_LABELS, type Dispute } from "@solary/shared-types";
import { AuthedPage } from "@/components/authed_page";
import { errorMessage, listDisputes, resolveDispute } from "@/lib/api";

type Tab = "open" | "resolved" | "rejected";

export default function DisputesPage() {
  const [tab, setTab] = useState<Tab>("open");
  const [disputes, setDisputes] = useState<Dispute[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [resolving, setResolving] = useState<Dispute | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const result = await listDisputes({ status: tab });
      setDisputes(result.data.disputes);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load disputes — try again."));
    }
  }, [tab]);

  useEffect(() => {
    setDisputes(null);
    load();
  }, [load]);

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Disputes</h1>
        <p className="muted" style={{ marginBottom: 20 }}>
          Problems customers reported on an order. Your resolution is shown to the customer on that order.
        </p>

        <div className="tabs">
          {(["open", "resolved", "rejected"] as const).map((s) => (
            <button key={s} className={`tab ${tab === s ? "active" : ""}`} onClick={() => setTab(s)}>
              {s[0].toUpperCase() + s.slice(1)}
            </button>
          ))}
        </div>

        {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}
        {disputes === null ? (
          <p className="muted">Loading…</p>
        ) : disputes.length === 0 ? (
          <div className="empty-state">No {tab} disputes.</div>
        ) : (
          disputes.map((d) => (
            <div className="app-row" key={d.id}>
              <div className="app-row-main">
                <div className="app-row-title">
                  {d.customerName || "Customer"} vs {d.vendorName || "vendor"}
                </div>
                <div className="app-row-meta">
                  Order #{d.orderId.slice(0, 8).toUpperCase()} · was {ORDER_STATUS_LABELS[d.orderStatus]} ·{" "}
                  <a href={`tel:${d.customerPhone}`}>{d.customerPhone}</a> · {formatDateTime(d.createdAt)}
                </div>
                <p style={{ margin: "8px 0 0", whiteSpace: "pre-wrap" }}>{d.reason}</p>
                {d.resolution && (
                  <p className="muted" style={{ margin: "8px 0 0" }}>
                    <strong>Resolution ({formatDateTime(d.resolvedAt)}):</strong> {d.resolution}
                  </p>
                )}
                {resolving?.id === d.id && (
                  <ResolveForm
                    dispute={d}
                    onCancel={() => setResolving(null)}
                    onDone={() => {
                      setResolving(null);
                      load();
                    }}
                  />
                )}
              </div>
              {d.status === "open" && resolving?.id !== d.id && (
                <div className="app-row-actions">
                  <button className="btn btn-primary" onClick={() => setResolving(d)}>
                    Resolve
                  </button>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </AuthedPage>
  );
}

function ResolveForm({ dispute, onCancel, onDone }: { dispute: Dispute; onCancel: () => void; onDone: () => void }) {
  const [resolution, setResolution] = useState("");
  const [outcome, setOutcome] = useState<"resolved" | "rejected">("resolved");
  const [cancelOrder, setCancelOrder] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const orderIsFinal = dispute.orderStatus === "cancelled" || dispute.orderStatus === "installed_verified";

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await resolveDispute({ disputeId: dispute.id, outcome, resolution, cancelOrder: cancelOrder && !orderIsFinal });
      onDone();
    } catch (err) {
      setError(errorMessage(err, "Couldn't save the resolution."));
      setBusy(false);
    }
  }

  return (
    <form className="detail" onSubmit={submit}>
      <div className="field">
        <label htmlFor={`res-${dispute.id}`}>Resolution (shown to the customer)</label>
        <textarea id={`res-${dispute.id}`} value={resolution} onChange={(e) => setResolution(e.target.value)} required minLength={3} />
      </div>
      <div className="toolbar" style={{ marginBottom: 0 }}>
        <select value={outcome} onChange={(e) => setOutcome(e.target.value as "resolved" | "rejected")} aria-label="Outcome">
          <option value="resolved">Resolved in the customer&apos;s favour</option>
          <option value="rejected">Rejected — no action needed</option>
        </select>
        {!orderIsFinal && (
          <label className="checkbox-row">
            <input type="checkbox" checked={cancelOrder} onChange={(e) => setCancelOrder(e.target.checked)} />
            Also cancel the order
          </label>
        )}
      </div>
      {error && <p className="error-text">{error}</p>}
      <div style={{ display: "flex", gap: 8 }}>
        <button className="btn btn-primary" disabled={busy || resolution.trim().length < 3}>
          Save
        </button>
        <button className="btn btn-ghost" type="button" onClick={onCancel}>
          Cancel
        </button>
      </div>
    </form>
  );
}
