"use client";

import { useEffect, useState } from "react";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { VendorShell } from "@/components/vendor_shell";
import { ImageField } from "@/components/image_field";
import { errorMessage, updateProfile } from "@/lib/api";

interface Profile {
  businessName: string;
  city: string;
  address: string;
  phone: string;
  description: string;
  logoUrl: string;
  status: string;
  rating: number;
  reviewCount: number;
}

export default function ProfilePage() {
  return <VendorShell>{(vendorId) => <ProfileForm vendorId={vendorId} />}</VendorShell>;
}

function ProfileForm({ vendorId }: { vendorId: string }) {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [original, setOriginal] = useState<Profile | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    getDoc(doc(db, "vendors", vendorId))
      .then((snap) => {
        const d = snap.data() ?? {};
        const p: Profile = {
          businessName: d.businessName ?? "",
          city: d.city ?? "",
          address: d.address ?? "",
          phone: d.phone ?? "",
          description: d.description ?? "",
          logoUrl: d.logoUrl ?? "",
          status: d.status ?? "approved",
          rating: d.rating ?? 0,
          reviewCount: d.reviewCount ?? 0,
        };
        setProfile(p);
        setOriginal(p);
      })
      .catch(() => setError("Couldn't load your profile — try again."));
  }, [vendorId]);

  async function save(e: React.FormEvent) {
    e.preventDefault();
    if (!profile || !original) return;
    // Send only what changed — the callable updates just those fields.
    const keys = ["businessName", "city", "address", "phone", "description", "logoUrl"] as const;
    const changes = Object.fromEntries(keys.filter((k) => profile[k] !== original[k]).map((k) => [k, profile[k]]));
    if (Object.keys(changes).length === 0) {
      setNotice("Nothing to save.");
      return;
    }
    setSaving(true);
    setError(null);
    setNotice(null);
    try {
      await updateProfile(changes);
      setOriginal(profile);
      setNotice("Profile saved — shoppers see the update right away.");
    } catch (err) {
      setError(errorMessage(err, "Couldn't save your profile — try again."));
    } finally {
      setSaving(false);
    }
  }

  const set = (key: keyof Profile) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    setProfile((p) => (p ? { ...p, [key]: e.target.value } : p));

  return (
    <div style={{ maxWidth: 560 }}>
      <h1 style={{ fontSize: 20, marginBottom: 4 }}>Business profile</h1>
      <p className="muted" style={{ marginBottom: 20 }}>What shoppers see on your company page in the Solary app.</p>
      {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}
      {!profile && !error && <p className="muted">Loading…</p>}
      {profile && (
        <form className="card stack" onSubmit={save}>
          <div className="app-row-meta">
            {profile.status === "suspended" ? (
              <span className="pill pill-warning">Suspended — contact Solary support</span>
            ) : (
              <span className="pill pill-success">Active</span>
            )}{" "}
            Rating {profile.rating.toFixed(1)} from {profile.reviewCount} review{profile.reviewCount === 1 ? "" : "s"}
          </div>
          <ImageField
            id="logo"
            label="Logo"
            purpose="company-logo"
            value={profile.logoUrl || null}
            onChange={(url) => setProfile((p) => (p ? { ...p, logoUrl: url ?? p.logoUrl } : p))}
          />
          <div className="field">
            <label htmlFor="businessName">Business name</label>
            <input id="businessName" value={profile.businessName} onChange={set("businessName")} required maxLength={120} />
          </div>
          <div className="field-row">
            <div className="field">
              <label htmlFor="city">City</label>
              <input id="city" value={profile.city} onChange={set("city")} required maxLength={80} />
            </div>
            <div className="field">
              <label htmlFor="phone">Phone</label>
              <input id="phone" value={profile.phone} onChange={set("phone")} placeholder="+9647…" required />
            </div>
          </div>
          <div className="field">
            <label htmlFor="address">Address</label>
            <input id="address" value={profile.address} onChange={set("address")} maxLength={300} />
          </div>
          <div className="field">
            <label htmlFor="description">About your business</label>
            <textarea id="description" value={profile.description} onChange={set("description")} maxLength={2000} />
          </div>
          {notice && <p style={{ margin: 0 }}>{notice}</p>}
          <div>
            <button className="btn btn-primary" disabled={saving}>
              {saving ? "Saving…" : "Save profile"}
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
