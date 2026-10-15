"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { AuthedPage } from "@/components/authed_page";
import { errorMessage, getAnalytics, type Analytics } from "@/lib/api";

export default function DashboardPage() {
  const [stats, setStats] = useState<Analytics | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getAnalytics()
      .then((r) => setStats(r.data))
      .catch((e) => setError(errorMessage(e, "Couldn't load dashboard stats — try again.")));
  }, []);

  const v = (n: number | undefined) => (stats ? (n ?? 0) : "—");
  const activeOrders = stats
    ? stats.ordersByStatus.placed +
      stats.ordersByStatus.confirmed +
      stats.ordersByStatus.installation_scheduled +
      stats.ordersByStatus.installer_en_route
    : undefined;

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Dashboard</h1>
        <p className="muted" style={{ marginBottom: 20 }}>
          What needs attention today.
        </p>

        {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}

        <div className="stat-grid">
          <Link href="/vendors" className="card stat-card">
            <span className="stat-value">{v(stats?.pendingApplications)}</span>
            <span className="stat-label">Pending vendor applications</span>
          </Link>
          <Link href="/orders" className="card stat-card">
            <span className="stat-value">{v(stats?.ordersByStatus.placed)}</span>
            <span className="stat-label">New orders awaiting vendor</span>
          </Link>
          <Link href="/orders" className="card stat-card">
            <span className="stat-value">{v(activeOrders)}</span>
            <span className="stat-label">Orders in progress</span>
          </Link>
          <Link href="/disputes" className="card stat-card">
            <span className="stat-value">{v(stats?.openDisputes)}</span>
            <span className="stat-label">Open disputes</span>
          </Link>
          <Link href="/analytics" className="card stat-card">
            <span className="stat-value">{v(stats?.pendingQuotes)}</span>
            <span className="stat-label">Unanswered quote requests</span>
          </Link>
          <Link href="/users" className="card stat-card">
            <span className="stat-value">{v(stats?.users)}</span>
            <span className="stat-label">Registered users</span>
          </Link>
        </div>
      </div>
    </AuthedPage>
  );
}
