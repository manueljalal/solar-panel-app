"use client";

import { useEffect, useState } from "react";
import { formatMoney, ORDER_STATUSES, ORDER_STATUS_LABELS } from "@solary/shared-types";
import { AuthedPage } from "@/components/authed_page";
import { errorMessage, getAnalytics, type Analytics } from "@/lib/api";

function lastNDays(n: number): string[] {
  const days: string[] = [];
  const today = new Date();
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate() - i));
    days.push(d.toISOString().slice(0, 10));
  }
  return days;
}

export default function AnalyticsPage() {
  const [stats, setStats] = useState<Analytics | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getAnalytics()
      .then((r) => setStats(r.data))
      .catch((e) => setError(errorMessage(e, "Couldn't load analytics — try again.")));
  }, []);

  const days = lastNDays(30);
  const counts = days.map((d) => stats?.ordersByDay[d] ?? 0);
  const max = Math.max(1, ...counts);
  const totalOrders = stats ? Object.values(stats.ordersByStatus).reduce((a, b) => a + b, 0) : 0;

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Analytics</h1>
        <p className="muted" style={{ marginBottom: 20 }}>Platform totals and the last 30 days of orders.</p>
        {error && <p className="error-text">{error}</p>}
        {!stats && !error && <p className="muted">Loading…</p>}
        {stats && (
          <>
            <div className="stat-grid">
              <Stat value={totalOrders} label="Orders (all time)" />
              <Stat value={formatMoney(stats.revenue30d.USD ?? 0, "USD")} label="Completed sales, 30 days (USD)" />
              <Stat value={formatMoney(stats.revenue30d.IQD ?? 0, "IQD")} label="Completed sales, 30 days (IQD)" />
              <Stat value={stats.users} label="Registered users" />
              <Stat value={stats.vendors} label="Vendors" />
              <Stat value={stats.products} label="Products" />
            </div>

            <h2 className="section-title">Orders per day (last 30 days)</h2>
            <div className="card">
              <div className="bar-chart" role="img" aria-label="Orders per day for the last 30 days">
                {counts.map((c, i) => (
                  <div
                    key={days[i]}
                    className="bar"
                    title={`${days[i]}: ${c} order${c === 1 ? "" : "s"}`}
                    style={{ height: `${Math.max(2, (c / max) * 100)}%`, opacity: c ? 0.85 : 0.15 }}
                  />
                ))}
              </div>
              <div className="muted" style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginTop: 6 }}>
                <span>{days[0]}</span>
                <span>peak {max === 1 && !counts.some(Boolean) ? 0 : max}/day</span>
                <span>{days[days.length - 1]}</span>
              </div>
              {stats.recentOrdersTruncated && (
                <p className="muted" style={{ fontSize: 12 }}>Showing the most recent 2,000 orders only.</p>
              )}
            </div>

            <h2 className="section-title">Orders by status</h2>
            <div className="table-wrap">
              <table className="table">
                <tbody>
                  {ORDER_STATUSES.map((s) => (
                    <tr key={s}>
                      <td>{ORDER_STATUS_LABELS[s]}</td>
                      <td style={{ textAlign: "right" }}>{stats.ordersByStatus[s] ?? 0}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </div>
    </AuthedPage>
  );
}

function Stat({ value, label }: { value: React.ReactNode; label: string }) {
  return (
    <div className="card stat-card">
      <span className="stat-value">{value}</span>
      <span className="stat-label">{label}</span>
    </div>
  );
}
