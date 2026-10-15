export type Role = "super_admin" | "vendor" | "customer";

/** admin-listUsers row — never includes passwordHash or device ids. */
export interface UserSummary {
  uid: string;
  name: string;
  username: string;
  phone: string;
  email: string;
  role: Role;
  disabled: boolean;
  createdAt: number | null;
  lastSignInAt: number | null;
}
