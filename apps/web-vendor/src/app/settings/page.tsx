"use client";

import { useEffect, useState, type FormEvent } from "react";
import { IRAQ_CITIES } from "@solary/ui-web";
import { ImageField } from "@/components/image_field";
import { VendorShell, useVendor } from "@/components/vendor_shell";
import { errorMessage, updateProfile } from "@/lib/api";

function SettingsInner() {
  const { profile, reloadProfile } = useVendor();
  const [businessName, setBusinessName] = useState("");
  const [city, setCity] = useState("");
  const [address, setAddress] = useState("");
  const [description, setDescription] = useState("");
  const [logoUrl, setLogoUrl] = useState<string | null>(null);
  const [logoChanged, setLogoChanged] = useState(false);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!profile) return;
    setBusinessName(profile.businessName);
    setCity(profile.city);
    setAddress(profile.address);
    setDescription(profile.description);
    setLogoUrl(profile.logoUrl || null);
  }, [profile]);

  async function onSave(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await updateProfile({
        businessName: businessName.trim(),
        city: city.trim(),
        address: address.trim(),
        description: description.trim(),
        ...(logoChanged && logoUrl ? { logoUrl } : {}),
      });
      await reloadProfile();
      setLogoChanged(false);
      setNotice("Company profile saved.");
    } catch (err) {
      setError(errorMessage(err, "Couldn't save — try again."));
    } finally {
      setSaving(false);
    }
  }

  if (!profile) return <p className="muted">Loading…</p>;

  return (
    <div style={{ maxWidth: 720 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Company</h1>
          <p className="page-sub">Shown on your company page and next to your products in the app.</p>
        </div>
      </div>

      {notice && <div className="notice">{notice}</div>}
      {error && <p className="error-text">{error}</p>}

      <form className="panel stack" onSubmit={onSave}>
        <ImageField
          id="logo"
          label="Logo"
          purpose="company-logo"
          value={logoUrl}
          onChange={(url) => {
            setLogoUrl(url);
            setLogoChanged(true);
          }}
        />
        <div className="form-grid">
          <div className="field">
            <label htmlFor="name">Company name</label>
            <input id="name" maxLength={120} required value={businessName} onChange={(e) => setBusinessName(e.target.value)} />
          </div>
          <div className="field">
            <label htmlFor="city">City</label>
            {profile.country === "IQ" ? (
              // Picked from the list so the app's city filter can find this company.
              <select id="city" required value={city} onChange={(e) => setCity(e.target.value)}>
                <option value="" disabled>
                  Choose a city
                </option>
                {!IRAQ_CITIES.includes(city as (typeof IRAQ_CITIES)[number]) && city && (
                  <option value={city}>{city} (current — please pick from the list)</option>
                )}
                {IRAQ_CITIES.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            ) : (
              <input id="city" maxLength={80} required value={city} onChange={(e) => setCity(e.target.value)} />
            )}
          </div>
          <div className="field full">
            <label htmlFor="address">Address</label>
            <input id="address" maxLength={300} value={address} onChange={(e) => setAddress(e.target.value)} />
          </div>
          <div className="field full">
            <label htmlFor="desc">About the company</label>
            <textarea id="desc" rows={4} maxLength={1000} value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>
          <div className="field">
            <label>Phone</label>
            <input value={profile.phone} disabled />
            <span className="muted" style={{ fontSize: 12 }}>Your verified login number — it can't be changed here.</span>
          </div>
          <div className="field">
            <label>Country</label>
            <input value={profile.country === "CN" ? "China" : "Iraq"} disabled />
          </div>
        </div>
        <div>
          <button className="btn btn-primary" type="submit" disabled={saving}>
            {saving ? "Saving…" : "Save changes"}
          </button>
        </div>
      </form>
    </div>
  );
}

export default function SettingsPage() {
  return (
    <VendorShell>
      <SettingsInner />
    </VendorShell>
  );
}
