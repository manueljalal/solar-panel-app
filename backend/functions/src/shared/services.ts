import { Timestamp, type DocumentSnapshot } from "firebase-admin/firestore";

/// Service requests (installation, panel cleaning). The platform receives
/// them; an admin schedules and can assign a vendor, who then sees the job.
///   new -> scheduled -> completed, or cancelled (customer while 'new').
export const SERVICE_TYPES = ["installation", "cleaning"] as const;
export const SERVICE_STATUSES = ["new", "scheduled", "completed", "cancelled"] as const;
export type ServiceStatus = (typeof SERVICE_STATUSES)[number];

const millis = (t: unknown) => (t instanceof Timestamp ? t.toMillis() : null);

export function serializeServiceRequest(snap: DocumentSnapshot, opts: { forStaff?: boolean } = {}) {
  const d = snap.data() ?? {};
  return {
    id: snap.id,
    type: d.type,
    status: d.status as ServiceStatus,
    address: d.address ?? "",
    location: d.location ?? null,
    city: d.city ?? "",
    preferredDate: millis(d.preferredDate),
    scheduledFor: millis(d.scheduledFor),
    panelCount: d.panelCount ?? null,
    systemSizeKw: d.systemSizeKw ?? null,
    note: d.note ?? "",
    vendorId: d.vendorId ?? null,
    vendorName: d.vendorName ?? null,
    createdAt: millis(d.createdAt),
    ...(opts.forStaff
      ? { customerName: d.customerName ?? "", customerPhone: d.customerPhone ?? "", adminNote: d.adminNote ?? "" }
      : {}),
  };
}
