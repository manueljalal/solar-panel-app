"use client";

import { useEffect, useMemo, useState, type FormEvent } from "react";
import { httpsCallable } from "firebase/functions";
import { collection, doc, getDoc, onSnapshot } from "firebase/firestore";
import { formatMoney } from "@solary/ui-web";
import { AuthedPage } from "@/components/authed_page";
import { db, functions } from "@/lib/firebase";
import { errorMessage, listProducts, type AdminProduct } from "@/lib/api";

// Super admin only: the backend callables require the super_admin role and
// firestore.rules only show inactive packages to super admins.

interface Settings {
  panelWattage: number;
  batteryModuleKwh: number;
  peakSunHours: number;
  lossMarginPercent: number;
  batteryUsablePercent: number;
  performancePercent: number;
}

// Must match SizingConfig.defaults in the app (solar_sizing.dart).
const DEFAULTS: Settings = {
  panelWattage: 585,
  batteryModuleKwh: 5.12,
  peakSunHours: 5.5,
  lossMarginPercent: 25,
  batteryUsablePercent: 85.5,
  performancePercent: 80,
};

const SETTING_FIELDS: { key: keyof Settings; label: string; hint: string; step: string; min: number; max: number }[] = [
  { key: "panelWattage", label: "Panel wattage (W)", hint: "The panel size the estimate counts in.", step: "1", min: 100, max: 1000 },
  { key: "batteryModuleKwh", label: "Battery size (kWh)", hint: "One battery module.", step: "0.01", min: 0.5, max: 50 },
  { key: "peakSunHours", label: "Peak sun hours", hint: "Full-sun hours per day (Iraq ≈ 5–6).", step: "0.1", min: 1, max: 10 },
  { key: "lossMarginPercent", label: "Loss margin (%)", hint: "Extra on top of the load for heat, dust and wiring.", step: "1", min: 0, max: 100 },
  { key: "batteryUsablePercent", label: "Usable battery (%)", hint: "Share of a battery's capacity actually usable.", step: "0.1", min: 30, max: 100 },
  { key: "performancePercent", label: "Performance ratio (%)", hint: "Used for the daily production estimate.", step: "1", min: 30, max: 100 },
];

type SystemType = "onGrid" | "hybrid" | "offGrid";
const SYSTEM_LABEL: Record<SystemType, string> = { onGrid: "On-grid", hybrid: "Hybrid", offGrid: "Off-grid" };

interface LocalizedName {
  ku: string;
  ar: string;
  en: string;
}

interface Item {
  productId: string;
  qty: number;
}

interface Package {
  id: string;
  name: LocalizedName;
  systemType: SystemType;
  sizeKw: number;
  batteryKwh: number | null;
  items: Item[];
  active: boolean;
}

interface Draft {
  name: LocalizedName;
  systemType: SystemType;
  sizeKw: string;
  batteryKwh: string;
  items: { productId: string; qty: string }[];
  active: boolean;
}

const updateSettings = httpsCallable<Settings, { ok: true }>(functions, "admin-updateCalculatorSettings");
const savePackage = httpsCallable<
  { packageId?: string; name: LocalizedName; systemType: SystemType; sizeKw: number; batteryKwh: number | null; items: Item[]; active: boolean },
  { packageId: string }
>(functions, "admin-savePackage");
const deletePackage = httpsCallable<{ packageId: string }, { ok: true }>(functions, "admin-deletePackage");

const EMPTY_DRAFT: Draft = {
  name: { ku: "", ar: "", en: "" },
  systemType: "hybrid",
  sizeKw: "",
  batteryKwh: "",
  items: [{ productId: "", qty: "1" }],
  active: true,
};

// Mirrors the server's checks (sanitize.ts cleanLocalized) for instant feedback.
const ARABIC_SCRIPT = /\p{Script=Arabic}/u;
const LATIN = /\p{Script=Latin}/u;

function nameProblem(n: LocalizedName): string | null {
  if (!n.ku.trim() || !n.ar.trim() || !n.en.trim()) return "Fill in the package name in Kurdish, Arabic and English.";
  if (!ARABIC_SCRIPT.test(n.ku)) return "The Kurdish name must be written in Kurdish (Arabic script).";
  if (!ARABIC_SCRIPT.test(n.ar)) return "The Arabic name must be written in Arabic.";
  if (!LATIN.test(n.en) || ARABIC_SCRIPT.test(n.en)) return "The English name must use English letters.";
  return null;
}

function totals(items: { productId: string; qty: number }[], products: Map<string, AdminProduct>): string {
  const sum: Record<string, number> = {};
  for (const it of items) {
    const p = products.get(it.productId);
    if (!p || !(it.qty > 0)) continue;
    sum[p.currency] = (sum[p.currency] ?? 0) + p.price * it.qty;
  }
  const parts = Object.entries(sum).map(([c, v]) => formatMoney(v, c));
  return parts.length ? parts.join(" + ") : "—";
}

export default function CalculatorPage() {
  const [settings, setSettings] = useState<Settings | null>(null);
  const [savingSettings, setSavingSettings] = useState(false);
  const [packages, setPackages] = useState<Package[] | null>(null);
  const [products, setProducts] = useState<AdminProduct[]>([]);
  const [draft, setDraft] = useState<Draft>(EMPTY_DRAFT);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [savingPackage, setSavingPackage] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getDoc(doc(db, "config", "calculator"))
      .then((snap) => setSettings({ ...DEFAULTS, ...(snap.data() as Partial<Settings> | undefined) }))
      .catch(() => setSettings(DEFAULTS));
    listProducts()
      .then((r) => setProducts([...r.data.products].sort((a, b) => a.name.localeCompare(b.name))))
      .catch((err) => setError(errorMessage(err, "Couldn't load products.")));
    return onSnapshot(
      collection(db, "packages"),
      (snap) => {
        const rows = snap.docs.map((d) => {
          const x = d.data();
          return {
            id: d.id,
            name: { ku: x.name?.ku ?? "", ar: x.name?.ar ?? "", en: x.name?.en ?? "" },
            systemType: (x.systemType ?? "onGrid") as SystemType,
            sizeKw: x.sizeKw ?? 0,
            batteryKwh: x.batteryKwh ?? null,
            items: (x.items ?? []) as Item[],
            active: x.active === true,
          };
        });
        rows.sort((a, b) => a.systemType.localeCompare(b.systemType) || a.sizeKw - b.sizeKw);
        setPackages(rows);
      },
      () => setError("Couldn't load packages."),
    );
  }, []);

  const productById = useMemo(() => new Map(products.map((p) => [p.id, p])), [products]);

  async function onSaveSettings(e: FormEvent) {
    e.preventDefault();
    if (!settings) return;
    setSavingSettings(true);
    setError(null);
    setNotice(null);
    try {
      await updateSettings(settings);
      setNotice("Calculator settings saved — the app uses them the next time the calculator opens.");
    } catch (err) {
      setError(errorMessage(err, "Couldn't save settings."));
    } finally {
      setSavingSettings(false);
    }
  }

  function edit(p: Package) {
    setEditingId(p.id);
    setDraft({
      name: p.name,
      systemType: p.systemType,
      sizeKw: String(p.sizeKw),
      batteryKwh: p.batteryKwh == null ? "" : String(p.batteryKwh),
      items: p.items.map((i) => ({ productId: i.productId, qty: String(i.qty) })),
      active: p.active,
    });
    setError(null);
    setNotice(null);
    window.scrollTo({ top: document.getElementById("package-form")?.offsetTop ?? 0, behavior: "smooth" });
  }

  function resetDraft() {
    setEditingId(null);
    setDraft(EMPTY_DRAFT);
  }

  async function onSavePackage(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setNotice(null);
    const problem = nameProblem(draft.name);
    if (problem) return setError(problem);
    const sizeKw = Number(draft.sizeKw);
    if (!(sizeKw > 0)) return setError("Enter the system size in kW.");
    const batteryKwh = draft.batteryKwh.trim() === "" ? null : Number(draft.batteryKwh);
    if (batteryKwh !== null && !(batteryKwh >= 0)) return setError("Battery storage must be a number of kWh.");
    const items = draft.items.map((i) => ({ productId: i.productId, qty: Number(i.qty) }));
    if (items.some((i) => !i.productId)) return setError("Choose a product on every line (or remove the empty line).");
    if (items.some((i) => !Number.isInteger(i.qty) || i.qty < 1)) return setError("Quantities must be whole numbers of 1 or more.");
    if (new Set(items.map((i) => i.productId)).size !== items.length) return setError("Each product can be listed once — change its quantity instead.");

    setSavingPackage(true);
    try {
      await savePackage({
        ...(editingId ? { packageId: editingId } : {}),
        name: { ku: draft.name.ku.trim(), ar: draft.name.ar.trim(), en: draft.name.en.trim() },
        systemType: draft.systemType,
        sizeKw,
        batteryKwh,
        items,
        active: draft.active,
      });
      setNotice(editingId ? "Package updated." : "Package added.");
      resetDraft();
    } catch (err) {
      setError(errorMessage(err, "Couldn't save the package."));
    } finally {
      setSavingPackage(false);
    }
  }

  async function onDelete(p: Package) {
    if (!window.confirm(`Delete the package "${p.name.en}"? This can't be undone.`)) return;
    setBusyId(p.id);
    setError(null);
    try {
      await deletePackage({ packageId: p.id });
      if (editingId === p.id) resetDraft();
    } catch (err) {
      setError(errorMessage(err, "Couldn't delete the package."));
    } finally {
      setBusyId(null);
    }
  }

  const setItem = (i: number, patch: Partial<Draft["items"][number]>) =>
    setDraft({ ...draft, items: draft.items.map((it, j) => (j === i ? { ...it, ...patch } : it)) });

  return (
    <AuthedPage>
      <div className="content" style={{ maxWidth: 900 }}>
        <div className="page-header">
          <div>
            <h1 className="page-title">Calculator</h1>
            <p className="page-sub">
              The sizing assumptions behind the app&apos;s solar calculator, and the packages it recommends to customers.
            </p>
          </div>
        </div>

        {notice && <div className="notice">{notice}</div>}
        {error && <p className="error-text">{error}</p>}

        <h2 style={{ fontSize: 16, margin: "8px 0 10px" }}>Sizing settings</h2>
        {!settings ? (
          <p className="muted">Loading…</p>
        ) : (
          <form className="panel stack" onSubmit={onSaveSettings} style={{ marginBottom: 28 }}>
            <div className="form-grid">
              {SETTING_FIELDS.map((f) => (
                <div className="field" key={f.key}>
                  <label htmlFor={f.key}>{f.label}</label>
                  <input
                    id={f.key}
                    type="number"
                    required
                    step={f.step}
                    min={f.min}
                    max={f.max}
                    value={settings[f.key]}
                    onChange={(e) => setSettings({ ...settings, [f.key]: Number(e.target.value) })}
                  />
                  <span className="muted" style={{ fontSize: 12 }}>{f.hint}</span>
                </div>
              ))}
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <button className="btn btn-primary" type="submit" disabled={savingSettings}>
                {savingSettings ? "Saving…" : "Save settings"}
              </button>
              <button className="btn btn-ghost" type="button" onClick={() => setSettings(DEFAULTS)}>
                Reset to defaults
              </button>
            </div>
          </form>
        )}

        <h2 style={{ fontSize: 16, margin: "8px 0 4px" }}>Packages</h2>
        <p className="muted" style={{ marginBottom: 10, fontSize: 13 }}>
          After a customer calculates, the app shows up to three active packages of the same system type, closest in size to
          the inverter it recommends, with an &quot;Add package to cart&quot; button. A package whose products were removed is
          hidden automatically.
        </p>

        <form id="package-form" className="panel stack" onSubmit={onSavePackage} style={{ marginBottom: 20 }}>
          <div style={{ fontWeight: 600 }}>{editingId ? "Edit package" : "New package"}</div>
          <div className="form-grid">
            <div className="field">
              <label htmlFor="pk-en">Name — English</label>
              <input id="pk-en" dir="ltr" maxLength={80} placeholder="5 kW hybrid home system" value={draft.name.en} onChange={(e) => setDraft({ ...draft, name: { ...draft.name, en: e.target.value } })} />
            </div>
            <div className="field">
              <label htmlFor="pk-ar">Name — Arabic (العربية)</label>
              <input id="pk-ar" dir="rtl" lang="ar" maxLength={80} value={draft.name.ar} onChange={(e) => setDraft({ ...draft, name: { ...draft.name, ar: e.target.value } })} />
            </div>
            <div className="field">
              <label htmlFor="pk-ku">Name — Kurdish (کوردی)</label>
              <input id="pk-ku" dir="rtl" lang="ckb" maxLength={80} value={draft.name.ku} onChange={(e) => setDraft({ ...draft, name: { ...draft.name, ku: e.target.value } })} />
            </div>
            <div className="field">
              <label htmlFor="pk-type">System type</label>
              <select id="pk-type" value={draft.systemType} onChange={(e) => setDraft({ ...draft, systemType: e.target.value as SystemType })}>
                {(Object.keys(SYSTEM_LABEL) as SystemType[]).map((t) => (
                  <option key={t} value={t}>{SYSTEM_LABEL[t]}</option>
                ))}
              </select>
            </div>
            <div className="field">
              <label htmlFor="pk-size">System size (kW)</label>
              <input id="pk-size" type="number" step="0.1" min="0.5" max="1000" placeholder="5" value={draft.sizeKw} onChange={(e) => setDraft({ ...draft, sizeKw: e.target.value })} />
            </div>
            <div className="field">
              <label htmlFor="pk-bat">Battery storage (kWh, optional)</label>
              <input id="pk-bat" type="number" step="0.01" min="0" placeholder="10.24" value={draft.batteryKwh} onChange={(e) => setDraft({ ...draft, batteryKwh: e.target.value })} />
            </div>
          </div>

          <div className="field">
            <label>Products in this package</label>
            {products.length === 0 && <span className="muted">No products in the catalogue yet.</span>}
            {draft.items.map((it, i) => (
              <div key={i} style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 6 }}>
                <select style={{ flex: 1 }} value={it.productId} onChange={(e) => setItem(i, { productId: e.target.value })} aria-label={`Product ${i + 1}`}>
                  <option value="">Choose a product…</option>
                  {products.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name}{p.spec ? ` · ${p.spec}` : ""} — {p.vendorName || "no vendor"} — {formatMoney(p.price, p.currency)}
                    </option>
                  ))}
                </select>
                <input type="number" min="1" step="1" style={{ width: 80 }} value={it.qty} onChange={(e) => setItem(i, { qty: e.target.value })} aria-label={`Quantity ${i + 1}`} />
                <button className="btn btn-ghost" type="button" disabled={draft.items.length === 1} onClick={() => setDraft({ ...draft, items: draft.items.filter((_, j) => j !== i) })}>
                  Remove
                </button>
              </div>
            ))}
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <button className="btn btn-ghost" type="button" disabled={draft.items.length >= 20} onClick={() => setDraft({ ...draft, items: [...draft.items, { productId: "", qty: "1" }] })}>
                + Add product
              </button>
              <span>
                Total: <strong>{totals(draft.items.map((i) => ({ productId: i.productId, qty: Number(i.qty) })), productById)}</strong>
              </span>
            </div>
          </div>

          <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <input type="checkbox" checked={draft.active} onChange={(e) => setDraft({ ...draft, active: e.target.checked })} />
            Show this package to customers
          </label>

          <div style={{ display: "flex", gap: 8 }}>
            <button className="btn btn-primary" type="submit" disabled={savingPackage}>
              {savingPackage ? "Saving…" : editingId ? "Save package" : "Add package"}
            </button>
            {editingId && (
              <button className="btn btn-ghost" type="button" onClick={resetDraft}>
                Cancel
              </button>
            )}
          </div>
        </form>

        {packages === null ? (
          <p className="muted">Loading…</p>
        ) : packages.length === 0 ? (
          <div className="empty-state">No packages yet — build the first one above.</div>
        ) : (
          <div>
            {packages.map((p) => {
              const missing = p.items.filter((i) => !productById.has(i.productId)).length;
              return (
                <div className="app-row" key={p.id}>
                  <div style={{ flex: 1 }}>
                    <div className="app-row-title">
                      {p.name.en}{" "}
                      <span className={`pill ${p.active ? "pill-success" : ""}`}>{p.active ? "Shown" : "Hidden"}</span>
                    </div>
                    <div className="app-row-meta">
                      {SYSTEM_LABEL[p.systemType]} · {p.sizeKw} kW{p.batteryKwh ? ` · ${p.batteryKwh} kWh` : ""} · {p.items.length} products ·{" "}
                      {totals(p.items, productById)}
                      {products.length > 0 && missing > 0 && (
                        <span className="error-text"> · {missing} product(s) no longer exist — customers won&apos;t see it</span>
                      )}
                    </div>
                  </div>
                  <div className="app-row-actions">
                    <button className="btn btn-ghost" onClick={() => edit(p)}>Edit</button>
                    <button className="btn btn-ghost" disabled={busyId === p.id} onClick={() => onDelete(p)}>Delete</button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </AuthedPage>
  );
}
