"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";
import { AuthedPage } from "@/components/authed_page";

interface Counts {
  pending: number;
  approved: number;
  rejected: number;
  newOrders: number;
}

// One call, count() aggregations server-side — no documents downloaded.
const dashboardCounts = httpsCallable<void, Counts>(functions, "admin-dashboardCounts");

export default function DashboardPage() {
  const [counts, setCounts] = useState<Counts | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    dashboardCounts()
      .then((result) => setCounts(result.data))
      .catch(() => setError("Couldn't load dashboard stats — try again."));
  }, []);

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Dashboard</h1>
        <p className="muted" style={{ marginBottom: 20 }}>
          Platform overview.
        </p>

        {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}

        <div className="stat-grid">
          <Link href="/orders" className="card stat-card">
            <span className="stat-value">{counts ? counts.newOrders : "—"}</span>
            <span className="stat-label">New orders</span>
          </Link>
          <Link href="/vendors" className="card stat-card">
            <span className="stat-value">{counts ? counts.pending : "—"}</span>
            <span className="stat-label">Pending applications</span>
          </Link>
          <Link href="/vendors" className="card stat-card">
            <span className="stat-value">{counts ? counts.approved : "—"}</span>
            <span className="stat-label">Approved vendors</span>
          </Link>
          <Link href="/vendors" className="card stat-card">
            <span className="stat-value">{counts ? counts.rejected : "—"}</span>
            <span className="stat-label">Rejected applications</span>
          </Link>
        </div>
      </div>
    </AuthedPage>
  );
}
