"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { collection, getDocs, query, where } from "firebase/firestore";
import {
  SERVICE_STATUS_LABEL,
  SERVICE_TYPE_LABEL,
  formatDate,
  formatDateTime,
  fromDateInput,
  toDateInput,
  whatsappLink,
  type PortalServiceRequest,
  type ServiceStatus,
} from "@solary/ui-web";
import { AuthedPage } from "@/components/authed_page";
import { db } from "@/lib/firebase";
import { errorMessage, listServiceRequests, updateServiceRequest } from "@/lib/api";

const FILTERS: (ServiceStatus | "all")[] = ["new", "scheduled", "completed", "cancelled", "all"];

function ServiceDrawer({
  request,
  vendors,
  onClose,
  onSaved,
}: {
  request: PortalServiceRequest;
  vendors: { id: string; name: string; city: string }[];
  onClose: () => void;
  onSaved: () => Promise<void>;
}) {
  const [vendorId, setVendorId] = useState(request.vendorId ?? "");
  const [date, setDate] = useState(toDateInput(request.scheduledFor ?? request.preferredDate));
  const [note, setNote] = useState(request.adminNote);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function save(status?: ServiceStatus) {
    setBusy(true);
    setError(null);
    try {
      await updateServiceRequest({
        id: request.id,
        vendorId,
        scheduledFor: fromDateInput(date),
        adminNote: note,
        ...(status ? { status } : {}),
      });
      await onSaved();
    } catch (e) {
      setError(errorMessage(e, "Couldn't save — try again."));
    } finally {
      setBusy(false);
    }
  }

  const closed = request.status === "completed" || request.status === "cancelled";
  const mapUrl = request.location ? `https://www.google.com/maps?q=${request.location.latitude},${request.location.longitude}` : null;

  return (
    <>
      <div className="drawer-backdrop" onClick={onClose} />
      <aside className="drawer" role="dialog" aria-label="Service request">
        <div className="drawer-head">
          <div>
            <h2 className="drawer-title">{SERVICE_TYPE_LABEL[request.type]}</h2>
            <span className={`status status-${request.status === "new" ? "new" : request.status === "scheduled" ? "confirmed" : request.status === "completed" ? "delivered" : "cancelled"}`}>
              {SERVICE_STATUS_LABEL[request.status]}
            </span>
          </div>
          <button className="icon-btn" onClick={onClose} aria-label="Close">×</button>
        </div>
        <div className="drawer-body">
          {error && <p className="error-text" style={{ marginTop: 0 }}>{error}</p>}
          <dl className="kv">
            <dt>Customer</dt>
            <dd>{request.customerName || "—"}</dd>
            <dt>Phone</dt>
            <dd>
              <a className="link" href={`tel:${request.customerPhone}`}>{request.customerPhone}</a>
              {" · "}
              <a className="link" href={whatsappLink(request.customerPhone)} target="_blank" rel="noreferrer">WhatsApp</a>
            </dd>
            <dt>Address</dt>
            <dd>
              {request.address}
              {request.city ? `, ${request.city}` : ""}
              {mapUrl && (
                <>
                  {" · "}
                  <a className="link" href={mapUrl} target="_blank" rel="noreferrer">Map</a>
                </>
              )}
            </dd>
            <dt>Preferred</dt>
            <dd>{request.preferredDate ? formatDate(request.preferredDate) : "Any day"}</dd>
            {request.type === "cleaning" && request.panelCount && (
              <>
                <dt>Panels</dt>
                <dd>{request.panelCount}</dd>
              </>
            )}
            {request.type === "installation" && request.systemSizeKw && (
              <>
                <dt>System size</dt>
                <dd>{request.systemSizeKw} kW</dd>
              </>
            )}
            {request.note && (
              <>
                <dt>Note</dt>
                <dd>{request.note}</dd>
              </>
            )}
            <dt>Requested</dt>
            <dd>{formatDateTime(request.createdAt)}</dd>
          </dl>

          <div className="stack">
            <div className="field">
              <label htmlFor="vendor">Assigned vendor</label>
              <select id="vendor" value={vendorId} onChange={(e) => setVendorId(e.target.value)} disabled={closed}>
                <option value="">Not assigned (Solary team)</option>
                {vendors.map((v) => (
                  <option key={v.id} value={v.id}>
                    {v.name}
                    {v.city ? ` — ${v.city}` : ""}
                  </option>
                ))}
              </select>
            </div>
            <div className="field">
              <label htmlFor="date">Visit date</label>
              <input id="date" type="date" value={date} onChange={(e) => setDate(e.target.value)} disabled={closed} />
            </div>
            <div className="field">
              <label htmlFor="note">Internal note</label>
              <textarea id="note" rows={3} value={note} onChange={(e) => setNote(e.target.value)} />
            </div>
          </div>
        </div>
        <div className="drawer-foot">
          {!closed && (
            <button className="btn btn-danger" disabled={busy} onClick={() => save("cancelled")}>
              Cancel request
            </button>
          )}
          <button className="btn btn-ghost" disabled={busy} onClick={() => save()}>
            Save
          </button>
          {request.status === "new" && (
            <button className="btn btn-primary" disabled={busy || !date} onClick={() => save("scheduled")}>
              Schedule
            </button>
          )}
          {request.status === "scheduled" && (
            <button className="btn btn-primary" disabled={busy} onClick={() => save("completed")}>
              Mark completed
            </button>
          )}
        </div>
      </aside>
    </>
  );
}

export default function ServicesPage() {
  const [requests, setRequests] = useState<PortalServiceRequest[] | null>(null);
  const [vendors, setVendors] = useState<{ id: string; name: string; city: string }[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<ServiceStatus | "all">("new");
  const [openId, setOpenId] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setRequests((await listServiceRequests()).data.requests);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load service requests — try again."));
    }
  }, []);

  useEffect(() => {
    void load();
    getDocs(query(collection(db, "vendors"), where("status", "==", "approved")))
      .then((snap) =>
        setVendors(
          snap.docs
            .map((d) => ({ id: d.id, name: (d.data().businessName as string) ?? "", city: (d.data().city as string) ?? "" }))
            .sort((a, b) => a.name.localeCompare(b.name)),
        ),
      )
      .catch(() => {});
  }, [load]);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: requests?.length ?? 0 };
    for (const r of requests ?? []) c[r.status] = (c[r.status] ?? 0) + 1;
    return c;
  }, [requests]);

  const shown = (requests ?? []).filter((r) => filter === "all" || r.status === filter);
  const open = requests?.find((r) => r.id === openId) ?? null;

  return (
    <AuthedPage>
      <div className="content">
        <div className="page-header">
          <div>
            <h1 className="page-title">Service requests</h1>
            <p className="page-sub">Installation and panel-cleaning bookings from the app. Schedule a visit and assign a vendor.</p>
          </div>
          <button className="btn btn-ghost" onClick={() => void load()}>
            Refresh
          </button>
        </div>

        {error && <p className="error-text">{error}</p>}

        <div className="toolbar">
          <div className="tabs">
            {FILTERS.map((f) => (
              <button key={f} className={`tab ${filter === f ? "active" : ""}`} onClick={() => setFilter(f)}>
                {f === "all" ? "All" : SERVICE_STATUS_LABEL[f]}
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
            {requests.length ? "Try another filter." : "Bookings from the app's Services tab show up here."}
          </div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Service</th>
                  <th>Customer</th>
                  <th>Where</th>
                  <th>Date</th>
                  <th>Vendor</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {shown.map((r) => (
                  <tr key={r.id} className="clickable" onClick={() => setOpenId(r.id)}>
                    <td>
                      <div className="cell-main">{SERVICE_TYPE_LABEL[r.type]}</div>
                      <div className="cell-sub">{formatDate(r.createdAt)}</div>
                    </td>
                    <td>
                      <div className="cell-main">{r.customerName || "—"}</div>
                      <div className="cell-sub">{r.customerPhone}</div>
                    </td>
                    <td>{r.city || r.address}</td>
                    <td>
                      {r.scheduledFor ? (
                        <span className="cell-main">{formatDate(r.scheduledFor)}</span>
                      ) : (
                        <span className="muted">{r.preferredDate ? `Prefers ${formatDate(r.preferredDate)}` : "Any day"}</span>
                      )}
                    </td>
                    <td>{r.vendorName ?? <span className="muted">—</span>}</td>
                    <td>
                      <span className={`status status-${r.status === "new" ? "new" : r.status === "scheduled" ? "confirmed" : r.status === "completed" ? "delivered" : "cancelled"}`}>
                        {SERVICE_STATUS_LABEL[r.status]}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {open && (
          <ServiceDrawer
            key={open.id}
            request={open}
            vendors={vendors}
            onClose={() => setOpenId(null)}
            onSaved={async () => {
              await load();
              setOpenId(null);
            }}
          />
        )}
      </div>
    </AuthedPage>
  );
}
