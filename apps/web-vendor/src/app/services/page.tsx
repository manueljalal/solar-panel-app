"use client";

import { useCallback, useEffect, useState } from "react";
import {
  SERVICE_STATUS_LABEL,
  SERVICE_TYPE_LABEL,
  formatDate,
  fromDateInput,
  toDateInput,
  whatsappLink,
  type PortalServiceRequest,
} from "@solary/ui-web";
import { errorMessage, listServiceJobs, updateServiceJob } from "@/lib/api";
import { VendorShell } from "@/components/vendor_shell";

function pillClass(s: PortalServiceRequest["status"]) {
  return `status status-${s === "new" ? "new" : s === "scheduled" ? "confirmed" : s === "completed" ? "delivered" : "cancelled"}`;
}

function JobsInner() {
  const [jobs, setJobs] = useState<PortalServiceRequest[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [dates, setDates] = useState<Record<string, string>>({});

  const load = useCallback(async () => {
    try {
      const list = (await listServiceJobs()).data.jobs;
      setJobs(list);
      setDates(Object.fromEntries(list.map((j) => [j.id, toDateInput(j.scheduledFor ?? j.preferredDate)])));
    } catch (e) {
      setError(errorMessage(e, "Couldn't load your service jobs — try again."));
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function update(job: PortalServiceRequest, status: "scheduled" | "completed") {
    setBusyId(job.id);
    setError(null);
    try {
      await updateServiceJob({ id: job.id, status, scheduledFor: fromDateInput(dates[job.id] ?? "") });
      await load();
    } catch (e) {
      setError(errorMessage(e, "Couldn't update that job — try again."));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <div className="page-header">
        <div>
          <h1 className="page-title">Service jobs</h1>
          <p className="page-sub">Installation and cleaning visits Solary assigned to you. Call the customer, set the date, mark it done.</p>
        </div>
      </div>

      {error && <p className="error-text">{error}</p>}

      {jobs === null ? (
        <p className="muted">Loading…</p>
      ) : jobs.length === 0 ? (
        <div className="empty-state">
          <strong>No service jobs yet</strong>
          When Solary assigns you an installation or cleaning, it shows up here.
        </div>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Service</th>
                <th>Customer</th>
                <th>Where</th>
                <th>Visit date</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {jobs.map((j) => {
                const closed = j.status === "completed" || j.status === "cancelled";
                const mapUrl = j.location ? `https://www.google.com/maps?q=${j.location.latitude},${j.location.longitude}` : null;
                return (
                  <tr key={j.id}>
                    <td>
                      <div className="cell-main">{SERVICE_TYPE_LABEL[j.type]}</div>
                      <div className="cell-sub">
                        {j.type === "cleaning" && j.panelCount ? `${j.panelCount} panels` : ""}
                        {j.type === "installation" && j.systemSizeKw ? `${j.systemSizeKw} kW` : ""}
                      </div>
                    </td>
                    <td>
                      <div className="cell-main">{j.customerName || "—"}</div>
                      <div className="cell-sub">
                        <a className="link" href={`tel:${j.customerPhone}`}>{j.customerPhone}</a>
                        {" · "}
                        <a className="link" href={whatsappLink(j.customerPhone)} target="_blank" rel="noreferrer">WhatsApp</a>
                      </div>
                    </td>
                    <td style={{ maxWidth: 260 }}>
                      {j.address}
                      {mapUrl && (
                        <>
                          {" · "}
                          <a className="link" href={mapUrl} target="_blank" rel="noreferrer">Map</a>
                        </>
                      )}
                      {j.note && <div className="cell-sub">{j.note}</div>}
                    </td>
                    <td>
                      {closed ? (
                        formatDate(j.scheduledFor)
                      ) : (
                        <input
                          type="date"
                          className="search"
                          style={{ minWidth: 0 }}
                          value={dates[j.id] ?? ""}
                          onChange={(e) => setDates((d) => ({ ...d, [j.id]: e.target.value }))}
                        />
                      )}
                    </td>
                    <td>
                      <span className={pillClass(j.status)}>{SERVICE_STATUS_LABEL[j.status]}</span>
                    </td>
                    <td className="actions">
                      {!closed && (
                        <>
                          <button
                            className="btn btn-ghost btn-sm"
                            disabled={busyId === j.id || !dates[j.id]}
                            onClick={() => update(j, "scheduled")}
                          >
                            Save date
                          </button>{" "}
                          <button className="btn btn-primary btn-sm" disabled={busyId === j.id} onClick={() => update(j, "completed")}>
                            Mark done
                          </button>
                        </>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}

export default function ServicesPage() {
  return (
    <VendorShell>
      <JobsInner />
    </VendorShell>
  );
}
