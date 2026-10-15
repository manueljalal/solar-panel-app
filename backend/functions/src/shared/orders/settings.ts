import { db } from "../firebase";

/// Platform-wide knobs an admin can change from the web admin's Settings
/// page (admin-updateSettings). Stored on settings/platform, which is
/// publicly readable so the checkout screen can show the delivery fee
/// before the order is placed — but placeOrder always re-reads it
/// server-side and never trusts a client-sent fee.
export interface PlatformSettings {
  ordersEnabled: boolean;
  deliveryFee: { USD: number; IQD: number };
  supportPhone: string;
  supportEmail: string;
}

export const DEFAULT_SETTINGS: PlatformSettings = {
  ordersEnabled: true,
  deliveryFee: { USD: 0, IQD: 0 },
  supportPhone: "",
  supportEmail: "",
};

export const settingsRef = () => db.collection("settings").doc("platform");

export async function readSettings(): Promise<PlatformSettings> {
  const data = (await settingsRef().get()).data() ?? {};
  const fee = (data.deliveryFee ?? {}) as Record<string, unknown>;
  return {
    ordersEnabled: data.ordersEnabled !== false,
    deliveryFee: {
      USD: typeof fee.USD === "number" ? fee.USD : 0,
      IQD: typeof fee.IQD === "number" ? fee.IQD : 0,
    },
    supportPhone: typeof data.supportPhone === "string" ? data.supportPhone : "",
    supportEmail: typeof data.supportEmail === "string" ? data.supportEmail : "",
  };
}
