"use client";

import { useEffect, useState, type FormEvent } from "react";
import { doc, getDoc } from "firebase/firestore";
import { AuthedPage } from "@/components/authed_page";
import { db } from "@/lib/firebase";
import { errorMessage, updateSupportConfig } from "@/lib/api";

export default function SettingsPage() {
  const [phone, setPhone] = useState("");
  const [whatsapp, setWhatsapp] = useState("");
  const [hours, setHours] = useState("");
  const [email, setEmail] = useState("");
  const [loaded, setLoaded] = useState(false);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getDoc(doc(db, "config", "support"))
      .then((snap) => {
        const d = snap.data() ?? {};
        setPhone(d.phone ?? "");
        setWhatsapp(d.whatsapp ?? "");
        setHours(d.hours ?? "");
        setEmail(d.email ?? "");
      })
      .finally(() => setLoaded(true));
  }, []);

  async function onSave(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await updateSupportConfig({ phone: phone.trim(), whatsapp: whatsapp.trim(), hours: hours.trim(), email: email.trim() });
      setNotice("Saved — the app shows the new details right away.");
    } catch (err) {
      setError(errorMessage(err, "Couldn't save — try again."));
    } finally {
      setSaving(false);
    }
  }

  return (
    <AuthedPage>
      <div className="content" style={{ maxWidth: 760 }}>
        <div className="page-header">
          <div>
            <h1 className="page-title">Settings</h1>
            <p className="page-sub">Call center details shown in the app&apos;s Services tab.</p>
          </div>
        </div>

        {notice && <div className="notice">{notice}</div>}
        {error && <p className="error-text">{error}</p>}

        {!loaded ? (
          <p className="muted">Loading…</p>
        ) : (
          <form className="panel stack" onSubmit={onSave}>
            <div className="form-grid">
              <div className="field">
                <label htmlFor="phone">Call center phone</label>
                <input id="phone" required placeholder="+9647501234567" value={phone} onChange={(e) => setPhone(e.target.value)} />
              </div>
              <div className="field">
                <label htmlFor="wa">WhatsApp number</label>
                <input id="wa" placeholder="Same as phone if empty" value={whatsapp} onChange={(e) => setWhatsapp(e.target.value)} />
              </div>
              <div className="field">
                <label htmlFor="hours">Opening hours</label>
                <input id="hours" maxLength={120} placeholder="Sat–Thu, 9:00–18:00" value={hours} onChange={(e) => setHours(e.target.value)} />
              </div>
              <div className="field">
                <label htmlFor="email">Support email</label>
                <input id="email" type="email" placeholder="support@…" value={email} onChange={(e) => setEmail(e.target.value)} />
              </div>
            </div>
            <div>
              <button className="btn btn-primary" type="submit" disabled={saving}>
                {saving ? "Saving…" : "Save"}
              </button>
            </div>
          </form>
        )}
      </div>
    </AuthedPage>
  );
}
