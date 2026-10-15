"use client";

import { useCallback, useEffect, useState } from "react";
import { formatDateTime, formatMoney, type Currency, type QuoteRequest } from "@solary/shared-types";
import { VendorShell } from "@/components/vendor_shell";
import { errorMessage, listQuoteRequests, respondToQuoteRequest } from "@/lib/api";

const STATUS_LABEL: Record<QuoteRequest["status"], [string, string]> = {
  submitted: ["Needs a reply", "pill pill-warning"],
  responded: ["Quoted", "pill pill-success"],
  declined: ["Declined", "pill"],
};

export default function QuotesPage() {
  return <VendorShell>{() => <Quotes />}</VendorShell>;
}

function Quotes() {
  const [requests, setRequests] = useState<QuoteRequest[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [replyingId, setReplyingId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const result = await listQuoteRequests();
      setRequests(result.data.requests);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load quote requests — try again."));
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <>
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20, marginBottom: 4 }}>Quote requests</h1>
          <p className="muted">Customers asking for a price on your products. Your reply shows in their app.</p>
        </div>
      </div>
      {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}
      {requests === null ? (
        <p className="muted">Loading…</p>
      ) : requests.length === 0 ? (
        <div className="empty-state">No quote requests yet.</div>
      ) : (
        requests.map((q) => {
          const [label, pill] = STATUS_LABEL[q.status];
          return (
            <div className="app-row" key={q.id}>
              <div className="app-row-main">
                <div className="app-row-title" style={{ display: "flex", gap: 8, alignItems: "center" }}>
                  {q.productTitle} <span className={pill}>{label}</span>
                </div>
                <div className="app-row-meta">
                  {q.customerName || "Guest"}
                  {q.customerPhone && (
                    <>
                      {" · "}
                      <a href={`tel:${q.customerPhone}`}>{q.customerPhone}</a>
                    </>
                  )}
                  {" · "}
                  {formatDateTime(q.createdAt)}
                </div>
                {q.note && <p style={{ margin: "8px 0 0", whiteSpace: "pre-wrap" }}>{q.note}</p>}
                {q.response && (
                  <p className="muted" style={{ margin: "8px 0 0" }}>
                    <strong>Your reply:</strong>{" "}
                    {q.response.price != null && formatMoney(q.response.price, q.response.currency ?? "USD")}
                    {q.response.message && ` — ${q.response.message}`}
                  </p>
                )}
                {replyingId === q.id && (
                  <ReplyForm
                    request={q}
                    onCancel={() => setReplyingId(null)}
                    onDone={() => {
                      setReplyingId(null);
                      load();
                    }}
                  />
                )}
              </div>
              {replyingId !== q.id && (
                <div className="app-row-actions">
                  <button className={q.status === "submitted" ? "btn btn-primary" : "btn btn-ghost"} onClick={() => setReplyingId(q.id)}>
                    {q.status === "submitted" ? "Reply" : "Edit reply"}
                  </button>
                </div>
              )}
            </div>
          );
        })
      )}
    </>
  );
}

function ReplyForm({ request, onCancel, onDone }: { request: QuoteRequest; onCancel: () => void; onDone: () => void }) {
  const [price, setPrice] = useState(request.response?.price?.toString() ?? "");
  const [currency, setCurrency] = useState<Currency>(request.response?.currency ?? "USD");
  const [message, setMessage] = useState(request.response?.message ?? "");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function send(action: "quote" | "decline") {
    setBusy(true);
    setError(null);
    try {
      await respondToQuoteRequest({
        requestId: request.id,
        action,
        ...(action === "quote" ? { price: Number(price), currency } : {}),
        message,
      });
      onDone();
    } catch (e) {
      setError(errorMessage(e, "Couldn't send your reply — try again."));
      setBusy(false);
    }
  }

  const priceValid = Number(price) > 0;

  return (
    <div className="detail">
      <div className="field-row">
        <div className="field">
          <label htmlFor={`price-${request.id}`}>Price</label>
          <input id={`price-${request.id}`} type="number" min={0} step="0.01" value={price} onChange={(e) => setPrice(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor={`cur-${request.id}`}>Currency</label>
          <select id={`cur-${request.id}`} value={currency} onChange={(e) => setCurrency(e.target.value as Currency)}>
            <option value="USD">USD</option>
            <option value="IQD">IQD</option>
          </select>
        </div>
      </div>
      <div className="field">
        <label htmlFor={`msg-${request.id}`}>Message (what&apos;s included, timeline…)</label>
        <textarea id={`msg-${request.id}`} value={message} onChange={(e) => setMessage(e.target.value)} maxLength={1000} />
      </div>
      {error && <p className="error-text">{error}</p>}
      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        <button className="btn btn-primary" disabled={busy || !priceValid} onClick={() => send("quote")}>
          Send quote
        </button>
        <button className="btn btn-danger" disabled={busy} onClick={() => send("decline")}>
          Decline
        </button>
        <button className="btn btn-ghost" disabled={busy} onClick={onCancel}>
          Cancel
        </button>
      </div>
    </div>
  );
}
