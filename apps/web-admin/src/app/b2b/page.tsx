"use client";

import { useCallback, useEffect, useState } from "react";
import { formatDate, formatMoney } from "@solary/ui-web";
import { AuthedPage } from "@/components/authed_page";
import { closeBulkPost, errorMessage, listBulkPosts, type BulkPost } from "@/lib/api";

type Kind = "listing" | "request";

function summary(kind: Kind, p: BulkPost): string {
  if (kind === "listing" && p.tiers?.length) {
    const best = Math.min(...p.tiers.map((t) => t.unitPriceUsd));
    return `From ${formatMoney(best, "USD")} / ${p.unit} · min ${p.tiers[0].minQty} ${p.unit}`;
  }
  if (kind === "request") {
    const target = p.targetPriceUsd ? ` · target ${formatMoney(p.targetPriceUsd, "USD")} / ${p.unit}` : "";
    return `${p.quantity ?? "?"} ${p.unit} wanted${target}`;
  }
  return "";
}

export default function B2BPage() {
  const [kind, setKind] = useState<Kind>("listing");
  const [posts, setPosts] = useState<BulkPost[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async (k: Kind) => {
    setPosts(null);
    try {
      setPosts((await listBulkPosts({ kind: k })).data.posts);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load B2B posts — try again."));
    }
  }, []);

  useEffect(() => {
    void load(kind);
  }, [kind, load]);

  async function onClose(p: BulkPost) {
    if (!window.confirm(`Take down "${p.title}" by ${p.businessName}?`)) return;
    setBusyId(p.id);
    try {
      await closeBulkPost({ kind, id: p.id });
      await load(kind);
    } catch (e) {
      setError(errorMessage(e, "Couldn't take that post down — try again."));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <AuthedPage>
      <div className="content">
        <div className="page-header">
          <div>
            <h1 className="page-title">B2B posts</h1>
            <p className="page-sub">Wholesale offers and bulk requests between approved vendors (Iraq and China).</p>
          </div>
        </div>

        {error && <p className="error-text">{error}</p>}

        <div className="toolbar">
          <div className="tabs">
            <button className={`tab ${kind === "listing" ? "active" : ""}`} onClick={() => setKind("listing")}>
              Wholesale offers
            </button>
            <button className={`tab ${kind === "request" ? "active" : ""}`} onClick={() => setKind("request")}>
              Bulk requests
            </button>
          </div>
        </div>

        {posts === null ? (
          <p className="muted">Loading…</p>
        ) : posts.length === 0 ? (
          <div className="empty-state">
            <strong>No posts yet</strong>
            Vendors post these from the B2B marketplace in the app.
          </div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Post</th>
                  <th>Company</th>
                  <th>Posted</th>
                  <th>Status</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {posts.map((p) => (
                  <tr key={p.id}>
                    <td>
                      <div className="cell-media">
                        {p.imageUrl ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={p.imageUrl} alt="" className="thumb" />
                        ) : (
                          <div className="thumb thumb-empty">{p.title.charAt(0)}</div>
                        )}
                        <div>
                          <div className="cell-main">{p.title}</div>
                          <div className="cell-sub">{summary(kind, p)}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="cell-main">{p.businessName}</div>
                      <div className="cell-sub">
                        {p.country === "CN" ? "China" : "Iraq"} · {p.phone}
                      </div>
                    </td>
                    <td>{formatDate(p.createdAt)}</td>
                    <td>
                      <span className={`status status-${p.status}`}>{p.status}</span>
                    </td>
                    <td className="actions">
                      {p.status !== "closed" && (
                        <button className="btn btn-danger btn-sm" disabled={busyId === p.id} onClick={() => onClose(p)}>
                          Take down
                        </button>
                      )}
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
