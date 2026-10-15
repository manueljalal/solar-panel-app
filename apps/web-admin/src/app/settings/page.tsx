"use client";

import { useEffect, useState } from "react";
import { AuthedPage } from "@/components/authed_page";
import { errorMessage, getSettings, updateSettings, type PlatformSettings } from "@/lib/api";

export default function SettingsPage() {
  const [settings, setSettings] = useState<PlatformSettings | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    getSettings()
      .then((r) => setSettings(r.data))
      .catch((e) => setError(errorMessage(e, "Couldn't load settings — try again.")));
  }, []);

  async function save(e: React.FormEvent) {
    e.preventDefault();
    if (!settings) return;
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      const result = await updateSettings(settings);
      setSettings(result.data);
      setNotice("Settings saved.");
    } catch (err) {
      setError(errorMessage(err, "Couldn't save settings."));
    } finally {
      setSaving(false);
    }
  }

  const set = <K extends keyof PlatformSettings>(key: K, value: PlatformSettings[K]) =>
    setSettings((s) => (s ? { ...s, [key]: value } : s));

  return (
    <AuthedPage>
      <div className="content" style={{ maxWidth: 560 }}>
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Settings</h1>
        <p className="muted" style={{ marginBottom: 20 }}>Platform-wide checkout settings. Changes apply to new orders immediately.</p>
        {!settings && !error && <p className="muted">Loading…</p>}
        {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}
        {settings && (
          <form className="card stack" onSubmit={save}>
            <label className="checkbox-row">
              <input type="checkbox" checked={settings.ordersEnabled} onChange={(e) => set("ordersEnabled", e.target.checked)} />
              Accept new orders
            </label>
            {!settings.ordersEnabled && (
              <p className="error-text" style={{ margin: 0 }}>Checkout is paused — customers see “Ordering is paused right now”.</p>
            )}
            <div className="field">
              <label htmlFor="fee-usd">Delivery fee per order (USD)</label>
              <input
                id="fee-usd"
                type="number"
                min={0}
                step="0.01"
                value={settings.deliveryFee.USD}
                onChange={(e) => set("deliveryFee", { ...settings.deliveryFee, USD: Number(e.target.value) })}
              />
            </div>
            <div className="field">
              <label htmlFor="fee-iqd">Delivery fee per order (IQD)</label>
              <input
                id="fee-iqd"
                type="number"
                min={0}
                step="250"
                value={settings.deliveryFee.IQD}
                onChange={(e) => set("deliveryFee", { ...settings.deliveryFee, IQD: Number(e.target.value) })}
              />
            </div>
            <div className="field">
              <label htmlFor="support-phone">Support phone</label>
              <input id="support-phone" value={settings.supportPhone} onChange={(e) => set("supportPhone", e.target.value)} placeholder="+9647…" />
            </div>
            <div className="field">
              <label htmlFor="support-email">Support email</label>
              <input id="support-email" type="email" value={settings.supportEmail} onChange={(e) => set("supportEmail", e.target.value)} />
            </div>
            {notice && <p style={{ margin: 0 }}>{notice}</p>}
            <div>
              <button className="btn btn-primary" disabled={saving}>
                {saving ? "Saving…" : "Save settings"}
              </button>
            </div>
          </form>
        )}
      </div>
    </AuthedPage>
  );
}
