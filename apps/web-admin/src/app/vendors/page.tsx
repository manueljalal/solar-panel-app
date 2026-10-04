"use client";

import { useCallback, useEffect, useState } from "react";
import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";
import { AuthedPage } from "@/components/authed_page";
import { ApplicationList, type ApplicationStatus, type VendorApplication } from "@/components/application_list";

const listApplications = httpsCallable<{ status?: ApplicationStatus }, { applications: VendorApplication[] }>(
  functions,
  "admin-listVendorApplications",
);
const approveApplication = httpsCallable<{ applicationId: string }, { vendorId: string }>(
  functions,
  "admin-approveVendorApplication",
);
const rejectApplication = httpsCallable<{ applicationId: string; reason?: string }, { ok: true }>(
  functions,
  "admin-rejectVendorApplication",
);

export default function VendorsPage() {
  const [tab, setTab] = useState<ApplicationStatus>("pending");
  const [applications, setApplications] = useState<VendorApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async (status: ApplicationStatus) => {
    setLoading(true);
    setError(null);
    try {
      const result = await listApplications({ status });
      setApplications(result.data.applications);
    } catch {
      setError("Couldn't load applications — try again.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load(tab);
  }, [tab, load]);

  async function onApprove(id: string) {
    setBusyId(id);
    try {
      await approveApplication({ applicationId: id });
      await load(tab);
    } catch {
      setError("Couldn't approve that application — try again.");
    } finally {
      setBusyId(null);
    }
  }

  async function onReject(id: string) {
    const reason = window.prompt("Reason for rejection (optional):") ?? undefined;
    setBusyId(id);
    try {
      await rejectApplication({ applicationId: id, reason });
      await load(tab);
    } catch {
      setError("Couldn't reject that application — try again.");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Vendors</h1>
        <p className="muted" style={{ marginBottom: 20 }}>
          Approve applications to grant a vendor account, or reject with a reason.
        </p>

        <div className="tabs">
          {(["pending", "approved", "rejected"] as const).map((s) => (
            <button key={s} className={`tab ${tab === s ? "active" : ""}`} onClick={() => setTab(s)}>
              {s[0].toUpperCase() + s.slice(1)}
            </button>
          ))}
        </div>

        <ApplicationList
          applications={applications}
          loading={loading}
          error={error}
          emptyLabel={`No ${tab} applications.`}
          renderActions={
            tab === "pending"
              ? (app) => (
                  <>
                    <button className="btn btn-ghost" disabled={busyId === app.id} onClick={() => onReject(app.id)}>
                      Reject
                    </button>
                    <button className="btn btn-primary" disabled={busyId === app.id} onClick={() => onApprove(app.id)}>
                      Approve
                    </button>
                  </>
                )
              : undefined
          }
        />
      </div>
    </AuthedPage>
  );
}
