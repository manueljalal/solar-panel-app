"use client";

import { useCallback, useEffect, useState } from "react";
import { httpsCallable } from "firebase/functions";
import { collection, getDocs } from "firebase/firestore";
import { db, functions } from "@/lib/firebase";
import { errorMessage, setVendorStatus } from "@/lib/api";
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
const resendSetup = httpsCallable<{ applicationId: string }, { ok: true }>(
  functions,
  "admin-resendPasswordSetup",
);

export default function VendorsPage() {
  const [tab, setTab] = useState<ApplicationStatus>("pending");
  const [applications, setApplications] = useState<VendorApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  // vendors/{id}.status for approved applications — "suspended" businesses
  // can't take new orders (see admin-setVendorStatus).
  const [vendorStatus, setVendorStatusMap] = useState<Record<string, string>>({});

  const load = useCallback(async (status: ApplicationStatus) => {
    setLoading(true);
    setError(null);
    try {
      const result = await listApplications({ status });
      setApplications(result.data.applications);
      if (status === "approved") {
        const snap = await getDocs(collection(db, "vendors"));
        setVendorStatusMap(Object.fromEntries(snap.docs.map((d) => [d.id, (d.data().status as string) ?? "approved"])));
      }
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

  async function onResend(app: VendorApplication) {
    setBusyId(app.id);
    setError(null);
    setNotice(null);
    try {
      await resendSetup({ applicationId: app.id });
      setNotice(`Setup link sent to ${app.email ?? "the applicant"}.`);
    } catch {
      setError("Couldn't send the setup link — try again.");
    } finally {
      setBusyId(null);
    }
  }

  async function onToggleSuspended(app: VendorApplication) {
    if (!app.vendorId) return;
    const suspend = vendorStatus[app.vendorId] !== "suspended";
    if (suspend && !window.confirm(`Suspend ${app.businessName}? They won't be able to take new orders or use the bulk market.`)) return;
    setBusyId(app.id);
    setError(null);
    try {
      await setVendorStatus({ vendorId: app.vendorId, status: suspend ? "suspended" : "approved" });
      setVendorStatusMap((m) => ({ ...m, [app.vendorId!]: suspend ? "suspended" : "approved" }));
    } catch (e) {
      setError(errorMessage(e, "Couldn't change that vendor's status."));
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

        {notice && <p style={{ marginBottom: 12 }}>{notice}</p>}

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
              : tab === "approved"
                ? (app) => {
                    const vendorId = app.vendorId;
                    const suspended = vendorId ? vendorStatus[vendorId] === "suspended" : false;
                    return (
                      <>
                        {suspended && <span className="pill pill-warning">Suspended</span>}
                        <button className="btn btn-ghost" disabled={busyId === app.id} onClick={() => onResend(app)}>
                          Resend setup link
                        </button>
                        {vendorId && (
                          <button
                            className={suspended ? "btn btn-ghost" : "btn btn-danger"}
                            disabled={busyId === app.id}
                            onClick={() => onToggleSuspended(app)}
                          >
                            {suspended ? "Restore" : "Suspend"}
                          </button>
                        )}
                      </>
                    );
                  }
                : undefined
          }
        />
      </div>
    </AuthedPage>
  );
}
