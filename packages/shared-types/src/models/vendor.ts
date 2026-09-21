export type VendorStatus = "pending" | "approved" | "suspended";

export interface Vendor {
  id: string;
  ownerUserId: string;
  businessName: string;
  city: string;
  status: VendorStatus;
  rating: number;
  reviewCount: number;
  createdAt: string; // ISO
}
