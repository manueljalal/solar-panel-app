export type OrderStatus =
  | "placed"
  | "confirmed"
  | "installation_scheduled"
  | "installer_en_route"
  | "installed_verified"
  | "cancelled";

export interface OrderLineItem {
  productId: string;
  vendorId: string;
  quantity: number;
  unitPrice: number;
}

export interface Order {
  id: string;
  customerId: string;
  items: OrderLineItem[];
  status: OrderStatus;
  paymentMethod: "cod" | "zain_cash" | "fastpay" | "qi_card";
  subtotal: number;
  deliveryFee: number;
  total: number;
  createdAt: string; // ISO
}
