"use client";

import { useEffect, useMemo, useState } from "react";
import { QUOTE_STATUS_LABEL, formatDate, whatsappLink, type QuoteStatus } from "@solary/ui-web";
import { AuthedPage } from "@/components/authed_page";
import { errorMessage, listQuoteRequests, type QuoteRequest } from "@/lib/api";

const FILTERS: (QuoteStatus | "all")[] = ["all", "new", "contacted", "closed"];

export default function QuotesPage() {
  const [requests, setRequests] = useState<QuoteRequest[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<QuoteStatus | "all">("all");

  useEffect(() => {
    listQuoteRequests()
      .then((r) => setRequests(r.data.requests))
      .catch((e) => setError(errorMessage(e, "Couldn't load quote requests — try again.")));
  }, []);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: requests?.length ?? 0 };
    for (const r of requests ?? []) c[r.status] = (c[r.status] ?? 0) + 1;
    return c;
  }, [requests]);

  const shown = (requests ?? []).filter((r) => filter === "all" || r.status === filter);

  return (
    <AuthedPage>
      <div className="content">
        <div className="page-header">
          <div>
            <h1 className="page-title">Quote requests</h1>
            <p className="page-sub">Price requests from shoppers to vendors. Vendors answer from their portal.</p>
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
            <strong>No quote requests</strong>
            {requests.length ? "Try another filter." : "Requests sent from product pages in the app show up here."}
          </div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Vendor</th>
                  <th>Customer</th>
                  <th>Message</th>
                  <th>Date</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {shown.map((r) => (
                  <tr key={r.id}>
                    <td className="cell-main">{r.productTitle}</td>
                    <td>{r.vendorName}</td>
                    <td>
                      <div className="cell-main">{r.customerName || "—"}</div>
                      {r.customerPhone && (
                        <div className="cell-sub">
                          <a className="link" href={whatsappLink(r.customerPhone)} target="_blank" rel="noreferrer">
                            {r.customerPhone}
                          </a>
                        </div>
                      )}
                    </td>
                    <td style={{ maxWidth: 300 }}>{r.note || <span className="muted">—</span>}</td>
                    <td>{formatDate(r.createdAt)}</td>
                    <td>
                      <span className={`status status-${r.status}`}>{QUOTE_STATUS_LABEL[r.status] ?? r.status}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AuthedPage>
  );
}
