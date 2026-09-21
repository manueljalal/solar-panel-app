// Custom-claim role model shared by all three roles/apps.
// Set via Admin SDK: admin.auth().setCustomUserClaims(uid, { role }).

export type Role = "super_admin" | "vendor" | "customer";

export interface AuthClaims {
  role: Role;
  vendorId?: string; // present when role === "vendor"
}
