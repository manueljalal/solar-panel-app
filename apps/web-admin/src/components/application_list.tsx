"use client";

export type ApplicationStatus = "pending" | "approved" | "rejected";

export interface VendorApplication {
  id: string;
  businessName: string;
  city: string;
  phone: string;
  email?: string;
  note?: string;
  status: ApplicationStatus;
  uid: string;
  rejectionReason?: string | null;
}

export function ApplicationList({
  applications,
  loading,
  error,
  emptyLabel,
  renderActions,
}: {
  applications: VendorApplication[];
  loading: boolean;
  error: string | null;
  emptyLabel: string;
  renderActions?: (app: VendorApplication) => React.ReactNode;
}) {
  if (error) return <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>;
  if (loading) return <p className="muted">Loading…</p>;
  if (applications.length === 0) return <div className="empty-state">{emptyLabel}</div>;

  return (
    <div>
      {applications.map((app) => (
        <div className="app-row" key={app.id}>
          <div>
            <div className="app-row-title">{app.businessName}</div>
            <div className="app-row-meta">
              {app.city} · {app.phone}
              {app.email ? ` · ${app.email}` : ""}
            </div>
            {app.note && <div className="app-row-meta">{app.note}</div>}
            {app.status === "rejected" && app.rejectionReason && (
              <div className="app-row-meta">Reason: {app.rejectionReason}</div>
            )}
          </div>
          {renderActions && <div className="app-row-actions">{renderActions(app)}</div>}
        </div>
      ))}
    </div>
  );
}
