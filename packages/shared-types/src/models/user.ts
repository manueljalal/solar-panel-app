export type Role = "super_admin" | "vendor" | "customer";

export interface User {
  id: string;
  role: Role;
  name: string;
  email: string;
  phone?: string;
  createdAt: string; // ISO
}
