"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";
import { AuthedPage } from "@/components/authed_page";
import type { ApplicationStatus, VendorApplication } from "@/components/application_list";

const listApplications = httpsCallable<{ status?: ApplicationStatus }, { applications: VendorApplication[] }>(
  functions,
  "admin-listVendorApplications",
);

interface Counts {
  pending: number;
  approved: number;
  rejected: number;
}

export default function DashboardPage() {
  const [counts, setCounts] = useState<Counts | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([
      listApplications({ status: "pending" }),
      listApplications({ status: "approved" }),
      listApplications({ status: "rejected" }),
    ])
      .then(([pending, approved, rejected]) =>
        setCounts({
          pending: pending.data.applications.length,
          approved: approved.data.applications.length,
          rejected: rejected.data.applications.length,
        }),
      )
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
