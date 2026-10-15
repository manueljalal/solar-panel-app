"use client";

import { useEffect, useState, type FormEvent } from "react";
import { httpsCallable } from "firebase/functions";
import { collection, onSnapshot } from "firebase/firestore";
import { db, functions } from "@/lib/firebase";
import { ImageField } from "@/components/image_field";
import { AuthedPage } from "@/components/authed_page";

interface LocalizedName {
  ku: string;
  ar: string;
  en: string;
}

interface Category {
  id: string;
  name: LocalizedName;
  imageUrl: string;
}

const createCategory = httpsCallable<{ name: LocalizedName; imageUrl: string }, { categoryId: string }>(functions, "admin-createCategory");
const updateCategory = httpsCallable<{ categoryId: string; name: LocalizedName; imageUrl?: string }, { ok: true }>(
  functions,
  "admin-updateCategory",
);
const deleteCategory = httpsCallable<{ categoryId: string }, { ok: true }>(functions, "admin-deleteCategory");

const MAX_NAME = 80;
// Mirrors the server (backend/functions/src/shared/validation/sanitize.ts),
// which is the real gatekeeper — this only gives instant feedback.
const ARABIC_SCRIPT = /\p{Script=Arabic}/u;
const LATIN = /\p{Script=Latin}/u;

/** Strips control/bidi-override chars and HTML angle brackets, collapses whitespace. */
function clean(value: string): string {
  return value
    .normalize("NFC")
    .replace(/[\u0000-\u001F\u007F-\u009F​‎‏‪-‮⁠⁦-⁩﻿]/g, " ")
    .replace(/<[^>]*>/g, "")
    .replace(/[<>]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function validate(name: LocalizedName): string | null {
  if (!name.ku || !name.ar || !name.en) return "Fill in the name in Kurdish, Arabic and English.";
  if (!ARABIC_SCRIPT.test(name.ku)) return "The Kurdish name must be written in Kurdish (Arabic script).";
  if (!ARABIC_SCRIPT.test(name.ar)) return "The Arabic name must be written in Arabic.";
  if (!LATIN.test(name.en) || ARABIC_SCRIPT.test(name.en)) return "The English name must use English letters.";
  return null;
}

function friendlyError(err: unknown): string {
  const message = (err as { message?: string }).message;
  // Callable errors already carry a user-readable message from the server.
  return message && !message.includes("internal") ? message : "Something went wrong — try again.";
}

const EMPTY: LocalizedName = { ku: "", ar: "", en: "" };

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[] | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<LocalizedName>(EMPTY);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [imageKey, setImageKey] = useState(0); // remounts the picker to clear it
  const [saving, setSaving] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    return onSnapshot(
      collection(db, "categories"),
      (snap) => {
        const rows = snap.docs.map((d) => {
          const n = d.data().name ?? {};
          return { id: d.id, name: { ku: n.ku ?? "", ar: n.ar ?? "", en: n.en ?? "" }, imageUrl: (d.data().imageUrl as string) ?? "" };
        });
        rows.sort((a, b) => a.name.en.localeCompare(b.name.en));
        setCategories(rows);
      },
      () => setLoadError("Couldn't load categories."),
    );
  }, []);

  function startEdit(category: Category) {
    setEditingId(category.id);
    setForm(category.name);
    setImageUrl(category.imageUrl || null);
    setImageKey((k) => k + 1);
    setError(null);
  }

  function reset() {
    setEditingId(null);
    setForm(EMPTY);
    setImageUrl(null);
    setImageKey((k) => k + 1);
    setError(null);
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const name = { ku: clean(form.ku), ar: clean(form.ar), en: clean(form.en) };
    const problem = validate(name);
    if (problem) {
      setError(problem);
      return;
    }
    if (!imageUrl) {
      setError("Add a category image.");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      if (editingId) await updateCategory({ categoryId: editingId, name, imageUrl });
      else await createCategory({ name, imageUrl });
      reset();
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setSaving(false);
    }
  }

  async function onDelete(category: Category) {
    if (!window.confirm(`Delete "${category.name.en}"?`)) return;
    setBusyId(category.id);
    setError(null);
    try {
      await deleteCategory({ categoryId: category.id });
      if (editingId === category.id) reset();
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Categories</h1>
        <p className="muted" style={{ marginBottom: 20 }}>
          Vendors must pick one of these when adding an item. Each category needs a name in Kurdish, Arabic and English.
        </p>

        <form className="card stack" onSubmit={onSubmit} style={{ marginBottom: 24 }}>
          <div style={{ fontWeight: 600 }}>{editingId ? "Edit category" : "Add category"}</div>
          <div className="field">
            <label htmlFor="name-ku">Kurdish (کوردی)</label>
            <input
              id="name-ku"
              dir="rtl"
              lang="ckb"
              maxLength={MAX_NAME}
              value={form.ku}
              onChange={(e) => setForm({ ...form, ku: e.target.value })}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="name-ar">Arabic (العربية)</label>
            <input
              id="name-ar"
              dir="rtl"
              lang="ar"
              maxLength={MAX_NAME}
              value={form.ar}
              onChange={(e) => setForm({ ...form, ar: e.target.value })}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="name-en">English</label>
            <input
              id="name-en"
              dir="ltr"
              lang="en"
              maxLength={MAX_NAME}
              value={form.en}
              onChange={(e) => setForm({ ...form, en: e.target.value })}
              required
            />
          </div>
          <ImageField
            key={imageKey}
            id="category-image"
            label="Category image"
            purpose="category"
            value={imageUrl}
            onChange={setImageUrl}
            required
          />
          {error && <p className="error-text">{error}</p>}
          <div style={{ display: "flex", gap: 8 }}>
            <button className="btn btn-primary" type="submit" disabled={saving}>
              {saving ? "Saving…" : editingId ? "Save changes" : "Add category"}
            </button>
            {editingId && (
              <button className="btn btn-ghost" type="button" onClick={reset}>
                Cancel
              </button>
            )}
          </div>
        </form>

        {loadError ? (
          <p className="error-text">{loadError}</p>
        ) : categories === null ? (
          <p className="muted">Loading…</p>
        ) : categories.length === 0 ? (
          <div className="empty-state">No categories yet — add the first one above.</div>
        ) : (
          <div>
            {categories.map((c) => (
              <div className="app-row" key={c.id}>
                {c.imageUrl && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={c.imageUrl}
                    alt=""
                    style={{ width: 56, height: 56, objectFit: "cover", borderRadius: 8, border: "1px solid var(--line)" }}
                  />
                )}
                <div style={{ flex: 1 }}>
                  <div className="app-row-title">{c.name.en}</div>
                  <div className="app-row-meta" dir="rtl" style={{ textAlign: "left" }}>
                    {c.name.ku} · {c.name.ar}
                  </div>
                </div>
                <div className="app-row-actions">
                  <button className="btn btn-ghost" onClick={() => startEdit(c)}>
                    Edit
                  </button>
                  <button className="btn btn-ghost" disabled={busyId === c.id} onClick={() => onDelete(c)}>
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
