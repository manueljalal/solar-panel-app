"use client";

import { useEffect, useState, type FormEvent } from "react";
import { httpsCallable } from "firebase/functions";
import { collection, onSnapshot } from "firebase/firestore";
import { db, functions } from "@/lib/firebase";
import { AuthedPage } from "@/components/authed_page";
import { ImageField } from "@/components/image_field";

interface Title {
  ku: string;
  ar: string;
  en: string;
}

interface Banner {
  id: string;
  imageUrl: string;
  title: Title | null;
  overlayColor: string | null;
  createdMs: number;
}

const MAX_BANNERS = 5;
const BANNER_ASPECT = 2; // width / height — matches the mobile carousel
const MAX_TITLE = 80;
const ARABIC_SCRIPT = /\p{Script=Arabic}/u;
const LATIN = /\p{Script=Latin}/u;
const EMPTY: Title = { ku: "", ar: "", en: "" };

const createBanner = httpsCallable<{ imageUrl: string; title: Title | null; overlayColor: string | null }, { bannerId: string }>(
  functions,
  "admin-createBanner",
);
const updateBanner = httpsCallable<{ bannerId: string; imageUrl?: string; title?: Title | null; overlayColor?: string | null }, { ok: true }>(
  functions,
  "admin-updateBanner",
);
const deleteBanner = httpsCallable<{ bannerId: string }, { ok: true }>(functions, "admin-deleteBanner");

/** Mirrors the server's cleanup (which is the real gatekeeper). */
function clean(value: string): string {
  return value
    .normalize("NFC")
    .replace(/[\u0000-\u001F\u007F-\u009F​‎‏‪-‮⁠⁦-⁩﻿]/g, " ")
    .replace(/<[^>]*>/g, "")
    .replace(/[<>]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function friendlyError(err: unknown): string {
  const { code, message } = err as { code?: string; message?: string };
  if ((code === "functions/invalid-argument" || code === "functions/failed-precondition") && message) return message;
  if (code === "functions/permission-denied") return "You don't have permission to do that.";
  return "Something went wrong — try again.";
}

export default function BannersPage() {
  const [banners, setBanners] = useState<Banner[] | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [title, setTitle] = useState<Title>(EMPTY);
  const [overlay, setOverlay] = useState<string | null>(null); // null = no overlay
  const [formKey, setFormKey] = useState(0);
  const [saving, setSaving] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    return onSnapshot(
      collection(db, "banners"),
      (snap) => {
        const rows = snap.docs.map((d) => {
          const data = d.data();
          const t = data.title;
          return {
            id: d.id,
            imageUrl: (data.imageUrl as string) ?? "",
            overlayColor: typeof data.overlayColor === "string" ? data.overlayColor : null,
            title: t ? { ku: t.ku ?? "", ar: t.ar ?? "", en: t.en ?? "" } : null,
            createdMs: data.createdAt?.toMillis?.() ?? 0,
          };
        });
        rows.sort((a, b) => a.createdMs - b.createdMs);
        setBanners(rows);
      },
      () => setLoadError("Couldn't load banners."),
    );
  }, []);

  const full = (banners?.length ?? 0) >= MAX_BANNERS;

  function openForm(banner?: Banner) {
    setAdding(true);
    setEditingId(banner?.id ?? null);
    setImageUrl(banner?.imageUrl ?? null);
    setTitle(banner?.title ?? EMPTY);
    setOverlay(banner?.overlayColor ?? null);
    setFormKey((k) => k + 1);
    setError(null);
  }

  function closeForm() {
    setAdding(false);
    setEditingId(null);
    setImageUrl(null);
    setTitle(EMPTY);
    setOverlay(null);
    setError(null);
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!imageUrl) {
      setError("Add a banner image.");
      return;
    }
    const t = { ku: clean(title.ku), ar: clean(title.ar), en: clean(title.en) };
    const filled = [t.ku, t.ar, t.en].filter(Boolean).length;
    if (filled !== 0 && filled !== 3) {
      setError("Enter the headline in Kurdish, Arabic and English, or leave all three empty.");
      return;
    }
    if (filled === 3) {
      if (!ARABIC_SCRIPT.test(t.ku)) return setError("The Kurdish headline must be written in Kurdish (Arabic script).");
      if (!ARABIC_SCRIPT.test(t.ar)) return setError("The Arabic headline must be written in Arabic.");
      if (!LATIN.test(t.en) || ARABIC_SCRIPT.test(t.en)) return setError("The English headline must use English letters.");
    }
    setSaving(true);
    setError(null);
    try {
      const titleOrNull = filled === 3 ? t : null;
      if (editingId) await updateBanner({ bannerId: editingId, imageUrl, title: titleOrNull, overlayColor: overlay });
      else await createBanner({ imageUrl, title: titleOrNull, overlayColor: overlay });
      closeForm();
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setSaving(false);
    }
  }

  async function onDelete(b: Banner) {
    if (!window.confirm("Delete this banner?")) return;
    setBusyId(b.id);
    setError(null);
    try {
      await deleteBanner({ bannerId: b.id });
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <AuthedPage>
      <div className="content">
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
          <h1 style={{ fontSize: 20, marginBottom: 4 }}>Banners</h1>
          <button className="btn btn-primary" disabled={full || adding} onClick={() => openForm()}>
            Add banner
          </button>
        </div>
        <p className="muted" style={{ marginBottom: 20 }}>
          These slides appear in the mobile app&apos;s home carousel, in the order they were added.{" "}
          {banners ? `${banners.length} of ${MAX_BANNERS} used.` : ""}
          {full ? " Delete one to add another." : ""}
        </p>

        {adding && (
          <form className="card stack" onSubmit={onSubmit} style={{ marginBottom: 24 }}>
            <div style={{ fontWeight: 600 }}>{editingId ? "Edit banner" : "Add banner"}</div>
            <ImageField
              key={formKey}
              id="banner-image"
              label="Banner image (cropped to 2:1)"
              purpose="banner"
              aspect={BANNER_ASPECT}
              value={imageUrl}
              onChange={setImageUrl}
              required
            />
            <p className="muted" style={{ fontSize: 12 }}>
              Optional headline shown over the image — fill in all three languages or leave all empty.
            </p>
            {(
              [
                ["ku", "Kurdish (کوردی)", "rtl"],
                ["ar", "Arabic (العربية)", "rtl"],
                ["en", "English", "ltr"],
              ] as const
            ).map(([key, label, dir]) => (
              <div className="field" key={key}>
                <label htmlFor={`title-${key}`}>{label}</label>
                <input
                  id={`title-${key}`}
                  dir={dir}
                  maxLength={MAX_TITLE}
                  value={title[key]}
                  onChange={(e) => setTitle({ ...title, [key]: e.target.value })}
                />
              </div>
            ))}
            <div className="field">
              <label htmlFor="overlay-color">Shade behind the headline (optional)</label>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <input
                  id="overlay-color"
                  type="color"
                  value={overlay ?? "#1F5A44"}
                  disabled={overlay === null}
                  onChange={(e) => setOverlay(e.target.value.toUpperCase())}
                  style={{ width: 56, height: 36, padding: 2 }}
                />
                <label style={{ display: "flex", alignItems: "center", gap: 6, fontWeight: 400 }}>
                  <input
                    type="checkbox"
                    checked={overlay !== null}
                    onChange={(e) => setOverlay(e.target.checked ? "#1F5A44" : null)}
                    style={{ width: "auto" }}
                  />
                  Use a shade
                </label>
              </div>
              <span className="muted" style={{ fontSize: 12 }}>
                Off = the image is shown untouched (the headline gets a soft text shadow instead).
              </span>
            </div>
            {error && <p className="error-text">{error}</p>}
            <div style={{ display: "flex", gap: 8 }}>
              <button className="btn btn-primary" type="submit" disabled={saving}>
                {saving ? "Saving…" : editingId ? "Save changes" : "Add banner"}
              </button>
              <button className="btn btn-ghost" type="button" onClick={closeForm}>
                Cancel
              </button>
            </div>
          </form>
        )}

        {!adding && error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}

        {loadError ? (
          <p className="error-text">{loadError}</p>
        ) : banners === null ? (
          <p className="muted">Loading…</p>
        ) : banners.length === 0 ? (
          <div className="empty-state">No banners yet — the mobile home screen shows no carousel until you add one.</div>
        ) : (
          <div>
            {banners.map((b, i) => (
              <div className="app-row" key={b.id}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={b.imageUrl}
                  alt=""
                  style={{ width: 160, height: 80, objectFit: "cover", borderRadius: 8, border: "1px solid var(--line)" }}
                />
                <div style={{ flex: 1 }}>
                  <div className="app-row-title">Slide {i + 1}</div>
                  <div className="app-row-meta">{b.title ? b.title.en : "No headline"}</div>
                  {b.title && (
                    <div className="app-row-meta" dir="rtl" style={{ textAlign: "left" }}>
                      {b.title.ku} · {b.title.ar}
                    </div>
                  )}
                </div>
                <div className="app-row-actions">
                  <button className="btn btn-ghost" onClick={() => openForm(b)}>
                    Edit
                  </button>
                  <button className="btn btn-ghost" disabled={busyId === b.id} onClick={() => onDelete(b)}>
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </AuthedPage>
  );
}
