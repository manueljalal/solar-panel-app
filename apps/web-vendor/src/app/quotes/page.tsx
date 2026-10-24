"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { QUOTE_STATUS_LABEL, formatDate, whatsappLink, type QuoteStatus } from "@solary/ui-web";
import { errorMessage, listQuoteRequests, updateQuoteRequest, type QuoteRequest } from "@/lib/api";
import { VendorShell, useVendor } from "@/components/vendor_shell";

const FILTERS: (QuoteStatus | "all")[] = ["new", "contacted", "closed", "all"];

function QuotesInner() {
  const { refreshCounts } = useVendor();
  const [requests, setRequests] = useState<QuoteRequest[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<QuoteStatus | "all">("new");
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setRequests((await listQuoteRequests()).data.requests);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load quote requests — try again."));
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: requests?.length ?? 0 };
    for (const r of requests ?? []) c[r.status] = (c[r.status] ?? 0) + 1;
    return c;
  }, [requests]);

  const shown = (requests ?? []).filter((r) => filter === "all" || r.status === filter);

  async function setStatus(r: QuoteRequest, status: QuoteStatus) {
    setBusyId(r.id);
    try {
      await updateQuoteRequest({ id: r.id, status });
      await load();
      refreshCounts();
    } catch (e) {
      setError(errorMessage(e, "Couldn't update that request — try again."));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quote requests</h1>
          <p className="page-sub">Shoppers asking for a price on your products. Call or WhatsApp them, then mark it.</p>
        </div>
      </div>

      {error && <p className="error-text">{error}</p>}

      <div className="toolbar">
        <div className="tabs">
          {FILTERS.map((f) => (
            <button key={f} className={`tab ${filter === f ? "active" : ""}`} onClick={() => setFilter(f)}>
              {f === "all" ? "All" : QUOTE_STATUS_LABEL[f]}
              <span className="tab-count">{counts[f] ?? 0}</span>
            </button>
          ))}
        </div>
      </div>

      {requests === null ? (
        <p className="muted">Loading…</p>
      ) : shown.length === 0 ? (
        <div className="empty-state">
          <strong>Nothing here</strong>
          {requests.length ? "Try another filter." : "Quote requests from the app will show up here."}
        </div>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Product</th>
                <th>Customer</th>
                <th>Message</th>
                <th>Date</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {shown.map((r) => (
                <tr key={r.id}>
                  <td>
                    <div className="cell-media">
                      {r.productImageUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={r.productImageUrl} alt="" className="thumb" />
                      ) : (
                        <div className="thumb thumb-empty">{r.productTitle.charAt(0)}</div>
                      )}
                      <div className="cell-main">{r.productTitle}</div>
                    </div>
                  </td>
                  <td>
                    <div className="cell-main">{r.customerName || "—"}</div>
                    {r.customerPhone && (
                      <div className="cell-sub">
                        <a className="link" href={`tel:${r.customerPhone}`}>{r.customerPhone}</a>
                        {" · "}
                        <a className="link" href={whatsappLink(r.customerPhone)} target="_blank" rel="noreferrer">WhatsApp</a>
                      </div>
                    )}
                  </td>
                  <td style={{ maxWidth: 320 }}>{r.note || <span className="muted">—</span>}</td>
                  <td>{formatDate(r.createdAt)}</td>
                  <td>
                    <span className={`status status-${r.status}`}>{QUOTE_STATUS_LABEL[r.status]}</span>
                  </td>
                  <td className="actions">
                    {r.status === "new" && (
                      <button className="btn btn-primary btn-sm" disabled={busyId === r.id} onClick={() => setStatus(r, "contacted")}>
                        Mark contacted
                      </button>
                    )}
                    {r.status !== "closed" && (
                      <>
                        {" "}
                        <button className="btn btn-ghost btn-sm" disabled={busyId === r.id} onClick={() => setStatus(r, "closed")}>
                          Close
                        </button>
                      </>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}

export default function QuotesPage() {
  return (
    <VendorShell>
      <QuotesInner />
    </VendorShell>
  );
}
