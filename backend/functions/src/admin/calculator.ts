import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { cleanDocId, cleanEnum, cleanLocalized, type LocalizedText } from "../shared/validation/sanitize";

/// The storefront's solar calculator is driven from here:
///  - config/calculator: the sizing assumptions (public read).
///  - packages/{id}: ready-made systems built from real products, which the
///    calculator recommends for the size it works out. Public read for
///    active ones (firestore.rules); written only through these callables.

const SYSTEM_TYPES = ["onGrid", "hybrid", "offGrid"] as const;
const MAX_ITEMS = 20;
const MAX_PACKAGES = 100;

function num(value: unknown, field: string, min: number, max: number, { integer = false } = {}): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value < min || value > max || (integer && !Number.isInteger(value))) {
    throw new HttpsError("invalid-argument", `${field} must be ${integer ? "a whole number " : ""}between ${min} and ${max}.`);
  }
  return value;
}

export interface CalculatorSettings {
  panelWattage: number;
  batteryModuleKwh: number;
  peakSunHours: number;
  lossMarginPercent: number;
  batteryUsablePercent: number;
  performancePercent: number;
}

export const updateCalculatorSettings = onCall<CalculatorSettings>({ region: "us-central1" }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  const d = request.data ?? ({} as CalculatorSettings);
  const settings: CalculatorSettings = {
    panelWattage: num(d.panelWattage, "Panel wattage", 100, 1000, { integer: true }),
    batteryModuleKwh: num(d.batteryModuleKwh, "Battery size", 0.5, 50),
    peakSunHours: num(d.peakSunHours, "Peak sun hours", 1, 10),
    lossMarginPercent: num(d.lossMarginPercent, "Loss margin", 0, 100),
    batteryUsablePercent: num(d.batteryUsablePercent, "Usable battery", 30, 100),
    performancePercent: num(d.performancePercent, "Performance ratio", 30, 100),
  };
  await db.collection("config").doc("calculator").set({ ...settings, updatedAt: FieldValue.serverTimestamp(), updatedBy: uid });
  return { ok: true };
});

interface PackageInput {
  packageId?: string;
  name: LocalizedText;
  systemType: (typeof SYSTEM_TYPES)[number];
  sizeKw: number;
  batteryKwh?: number | null;
  items: { productId: string; qty: number }[];
  active: boolean;
}

export const savePackage = onCall<PackageInput>({ region: "us-central1" }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  const d = request.data ?? ({} as PackageInput);
  const name = cleanLocalized(d.name, "Package name");
  const systemType = cleanEnum(d.systemType, SYSTEM_TYPES, "System type");
  const sizeKw = num(d.sizeKw, "System size (kW)", 0.5, 1000);
  const batteryKwh = d.batteryKwh === undefined || d.batteryKwh === null ? null : num(d.batteryKwh, "Battery storage (kWh)", 0, 5000);
  if (typeof d.active !== "boolean") throw new HttpsError("invalid-argument", "active must be true or false.");

  if (!Array.isArray(d.items) || d.items.length === 0 || d.items.length > MAX_ITEMS) {
    throw new HttpsError("invalid-argument", `Add between 1 and ${MAX_ITEMS} products.`);
  }
  const items = d.items.map((it, i) => ({
    productId: cleanDocId(it?.productId, `Product ${i + 1}`),
    qty: num(it?.qty, `Quantity ${i + 1}`, 1, 500, { integer: true }),
  }));
  if (new Set(items.map((i) => i.productId)).size !== items.length) {
    throw new HttpsError("invalid-argument", "Each product can be listed once — change its quantity instead.");
  }
  const snaps = await db.getAll(...items.map((i) => db.collection("products").doc(i.productId)));
  const missing = snaps.findIndex((s) => !s.exists);
  if (missing >= 0) throw new HttpsError("not-found", `Product ${missing + 1} no longer exists.`);

  const data = { name, systemType, sizeKw, batteryKwh, items, active: d.active, updatedAt: FieldValue.serverTimestamp() };
  if (d.packageId) {
    const ref = db.collection("packages").doc(cleanDocId(d.packageId, "packageId"));
    if (!(await ref.get()).exists) throw new HttpsError("not-found", "Package not found.");
    await ref.update(data);
    return { packageId: ref.id };
  }
  const count = await db.collection("packages").count().get();
  if (count.data().count >= MAX_PACKAGES) throw new HttpsError("resource-exhausted", `At most ${MAX_PACKAGES} packages.`);
  const ref = await db.collection("packages").add({ ...data, createdAt: FieldValue.serverTimestamp(), createdBy: uid });
  return { packageId: ref.id };
});

export const deletePackage = onCall<{ packageId: string }>({ region: "us-central1" }, async (request) => {
  requireRole(request, ["super_admin"]);
  await db.collection("packages").doc(cleanDocId(request.data?.packageId, "packageId")).delete();
  return { ok: true };
});
