"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import { httpsCallable } from "firebase/functions";
import { collection, onSnapshot } from "firebase/firestore";
import { ref as storageRef, uploadBytesResumable, deleteObject, type UploadTask } from "firebase/storage";
import { db, functions, storage } from "@/lib/firebase";
import { AuthedPage } from "@/components/authed_page";
import { uploadImage } from "@/lib/images";
import { ImageField } from "@/components/image_field";
import { readVideoMeta } from "@/lib/video_meta";

interface Localized {
  ku: string;
  ar: string;
  en: string;
}

interface LearnItem {
  id: string;
  title: Localized;
  description: Localized;
  videoUrl: string;
  thumbnailUrl: string | null;
  createdMs: number;
}

const MAX_VIDEO_BYTES = 50 * 1024 * 1024;
const MAX_TITLE = 120;
const MAX_DESCRIPTION = 2000;
const ARABIC_SCRIPT = /\p{Script=Arabic}/u;
const LATIN = /\p{Script=Latin}/u;
const EMPTY: Localized = { ku: "", ar: "", en: "" };
const LANGS = [
  { key: "ku", label: "Kurdish (کوردی)", dir: "rtl" },
  { key: "ar", label: "Arabic (العربية)", dir: "rtl" },
  { key: "en", label: "English", dir: "ltr" },
] as const;

type Payload = {
  title: Localized;
  description: Localized;
  videoPath: string;
  thumbnailUrl?: string | null;
  durationSec?: number | null;
};
const createLearnItem = httpsCallable<Payload, { learnItemId: string }>(functions, "admin-createLearnItem");
const updateLearnItem = httpsCallable<Partial<Payload> & { learnItemId: string }, { ok: true }>(
  functions,
  "admin-updateLearnItem",
);
const deleteLearnItem = httpsCallable<{ learnItemId: string }, { ok: true }>(functions, "admin-deleteLearnItem");

/** Mirrors the server's cleanup (the server is the real gatekeeper). */
function clean(value: string, multiline = false): string {
  let text = value
    .normalize("NFC")
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F​‎‏‪-‮⁠⁦-⁩﻿]/g, "")
    .replace(/<[^>]*>/g, "")
    .replace(/[<>]/g, "");
  text = multiline
    ? text.replace(/\r\n?/g, "\n").replace(/[ \t]+/g, " ").replace(/ ?\n ?/g, "\n").replace(/\n{3,}/g, "\n\n")
    : text.replace(/\s+/g, " ");
  return text.trim();
}

function validateLocalized(v: Localized, name: string): string | null {
  if (!v.ku || !v.ar || !v.en) return `Enter the ${name} in Kurdish, Arabic and English.`;
  if (!ARABIC_SCRIPT.test(v.ku)) return `The Kurdish ${name} must be written in Kurdish (Arabic script).`;
  if (!ARABIC_SCRIPT.test(v.ar)) return `The Arabic ${name} must be written in Arabic.`;
  if (!LATIN.test(v.en) || ARABIC_SCRIPT.test(v.en)) return `The English ${name} must use English letters.`;
  return null;
}

function friendlyError(err: unknown): string {
  const { code, message } = err as { code?: string; message?: string };
  if (
    (code === "functions/invalid-argument" ||
      code === "functions/failed-precondition" ||
      code === "functions/already-exists") &&
    message
  ) {
    return message;
  }
  if (code === "functions/permission-denied" || code === "storage/unauthorized") return "You don't have permission to do that.";
  if (code === "storage/canceled") return "Upload cancelled.";
  return "Something went wrong — try again.";
}

export default function LearnPage() {
  const [items, setItems] = useState<LearnItem[] | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<LearnItem | null>(null);
  const [title, setTitle] = useState<Localized>(EMPTY);
  const [description, setDescription] = useState<Localized>(EMPTY);
  const [video, setVideo] = useState<File | null>(null);
  const [cover, setCover] = useState<string | null>(null);
  const [coverTouched, setCoverTouched] = useState(false); // admin picked a cover this session
  const [progress, setProgress] = useState<number | null>(null);
  const [saving, setSaving] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [fileKey, setFileKey] = useState(0);
  const task = useRef<UploadTask | null>(null);

  useEffect(() => {
    return onSnapshot(
      collection(db, "learnItems"),
      (snap) => {
        const rows = snap.docs.map((d) => {
          const data = d.data();
          const l = (v: Localized | undefined): Localized => ({ ku: v?.ku ?? "", ar: v?.ar ?? "", en: v?.en ?? "" });
          return {
            id: d.id,
            title: l(data.title),
            description: l(data.description),
            videoUrl: (data.videoUrl as string) ?? "",
            thumbnailUrl: (data.thumbnailUrl as string | null) ?? null,
            createdMs: data.createdAt?.toMillis?.() ?? 0,
          };
        });
        rows.sort((a, b) => b.createdMs - a.createdMs);
        setItems(rows);
      },
      () => setLoadError("Couldn't load learn items."),
    );
  }, []);

  function openForm(item?: LearnItem) {
    setFormOpen(true);
    setEditing(item ?? null);
    setTitle(item?.title ?? EMPTY);
    setDescription(item?.description ?? EMPTY);
    setVideo(null);
    setCover(item?.thumbnailUrl ?? null);
    setCoverTouched(false);
    setFileKey((k) => k + 1);
    setError(null);
  }

  function closeForm() {
    task.current?.cancel();
    setFormOpen(false);
    setEditing(null);
    setVideo(null);
    setProgress(null);
    setSaving(false);
    setError(null);
  }

  function onPickVideo(file: File | undefined) {
    setError(null);
    if (!file) return setVideo(null);
    if (file.type !== "video/mp4") {
      setVideo(null);
      setFileKey((k) => k + 1);
      return setError("Only MP4 videos are allowed.");
    }
    if (file.size > MAX_VIDEO_BYTES) {
      setVideo(null);
      setFileKey((k) => k + 1);
      return setError("Video must be 50 MB or smaller.");
    }
    setVideo(file);
  }

  /** Streams the file straight to Storage (resumable) and returns its path. */
  function uploadVideo(file: File): Promise<string> {
    const path = `learnVideos/${crypto.randomUUID()}.mp4`;
    return new Promise((resolve, reject) => {
      const t = uploadBytesResumable(storageRef(storage, path), file, { contentType: "video/mp4" });
      task.current = t;
      t.on(
        "state_changed",
        (s) => setProgress(Math.round((s.bytesTransferred / s.totalBytes) * 100)),
        reject,
        () => resolve(path),
      );
    });
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    const t = { ku: clean(title.ku), ar: clean(title.ar), en: clean(title.en) };
    const d = { ku: clean(description.ku, true), ar: clean(description.ar, true), en: clean(description.en, true) };
    const problem = validateLocalized(t, "title") ?? validateLocalized(d, "description");
    if (problem) return setError(problem);
    if (!editing && !video) return setError("Add a video (MP4, up to 50 MB).");

    setSaving(true);
    setError(null);
    let uploadedPath: string | null = null;
    try {
      let thumbnailUrl: string | null = coverTouched ? cover : null;
      let durationSec: number | null = null;
      if (video) {
        // Length always comes from the video; the cover is the admin's own
        // image if they chose one, otherwise a frame captured from the video.
        const meta = await readVideoMeta(video);
        durationSec = meta.durationSec;
        if (!coverTouched && meta.thumbnail) {
          try {
            thumbnailUrl = await uploadImage(meta.thumbnail, "learn");
          } catch {
            thumbnailUrl = null; // not fatal — the app shows a plain card
          }
        }
        uploadedPath = await uploadVideo(video);
      }
      if (editing) {
        await updateLearnItem({
          learnItemId: editing.id,
          title: t,
          description: d,
          // Cover is sent when it changed, or when a new video replaces the old one.
          ...(uploadedPath ? { videoPath: uploadedPath, thumbnailUrl, durationSec } : coverTouched ? { thumbnailUrl } : {}),
        });
      } else {
        await createLearnItem({ title: t, description: d, videoPath: uploadedPath!, thumbnailUrl, durationSec });
      }
      closeForm();
    } catch (err) {
      // The server deletes files it rejects; clean up ours if it never got that far.
      if (uploadedPath) deleteObject(storageRef(storage, uploadedPath)).catch(() => {});
      setError(friendlyError(err));
      setSaving(false);
      setProgress(null);
    }
  }

  async function onDelete(item: LearnItem) {
    if (!window.confirm(`Delete "${item.title.en}"?`)) return;
    setBusyId(item.id);
    setError(null);
    try {
      await deleteLearnItem({ learnItemId: item.id });
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
          <h1 style={{ fontSize: 20, marginBottom: 4 }}>Learn</h1>
          <button className="btn btn-primary" disabled={formOpen} onClick={() => openForm()}>
            Add learn item
          </button>
        </div>
        <p className="muted" style={{ marginBottom: 20 }}>
          Videos shown in the mobile app&apos;s Learn tab, newest first. Each has a title and description in Kurdish, Arabic and English.
        </p>

        {formOpen && (
          <form className="card stack" onSubmit={onSubmit} style={{ marginBottom: 24 }}>
            <div style={{ fontWeight: 600 }}>{editing ? "Edit learn item" : "Add learn item"}</div>

            <div style={{ fontSize: 13, fontWeight: 600, color: "var(--ink-600)" }}>Title</div>
            {LANGS.map((l) => (
              <div className="field" key={l.key}>
                <label htmlFor={`title-${l.key}`}>{l.label}</label>
                <input
                  id={`title-${l.key}`}
                  dir={l.dir}
                  maxLength={MAX_TITLE}
                  value={title[l.key]}
                  onChange={(e) => setTitle({ ...title, [l.key]: e.target.value })}
                  required
                />
              </div>
            ))}

            <div style={{ fontSize: 13, fontWeight: 600, color: "var(--ink-600)" }}>Description</div>
            {LANGS.map((l) => (
              <div className="field" key={l.key}>
                <label htmlFor={`desc-${l.key}`}>{l.label}</label>
                <textarea
                  id={`desc-${l.key}`}
                  dir={l.dir}
                  rows={4}
                  maxLength={MAX_DESCRIPTION}
                  value={description[l.key]}
                  onChange={(e) => setDescription({ ...description, [l.key]: e.target.value })}
                  required
                />
              </div>
            ))}

            <ImageField
              key={`cover-${fileKey}`}
              id="learn-cover"
              label="Cover image (optional — like a YouTube thumbnail; if empty, one is taken from the video)"
              purpose="learn"
              aspect={16 / 9}
              value={cover}
              onChange={(url) => {
                setCover(url);
                setCoverTouched(true);
              }}
            />

            <div className="field">
              <label htmlFor="learn-video">Video (MP4, up to 50 MB){editing ? " — leave empty to keep the current one" : ""}</label>
              <input
                key={fileKey}
                id="learn-video"
                type="file"
                accept="video/mp4"
                disabled={saving}
                onChange={(e) => onPickVideo(e.target.files?.[0])}
              />
              {video && <span className="muted">{video.name} · {(video.size / 1024 / 1024).toFixed(1)} MB</span>}
              {progress !== null && (
                <div style={{ height: 6, borderRadius: 3, background: "var(--line)", overflow: "hidden" }}>
                  <div style={{ width: `${progress}%`, height: "100%", background: "var(--accent)" }} />
                </div>
              )}
            </div>

            {error && <p className="error-text">{error}</p>}
            <div style={{ display: "flex", gap: 8 }}>
              <button className="btn btn-primary" type="submit" disabled={saving}>
                {saving ? (progress !== null && progress < 100 ? `Uploading ${progress}%…` : "Saving…") : editing ? "Save changes" : "Add learn item"}
              </button>
              <button className="btn btn-ghost" type="button" onClick={closeForm}>
                Cancel
              </button>
            </div>
          </form>
        )}

        {!formOpen && error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}

        {loadError ? (
          <p className="error-text">{loadError}</p>
        ) : items === null ? (
          <p className="muted">Loading…</p>
        ) : items.length === 0 ? (
          <div className="empty-state">No learn items yet — the mobile Learn tab stays empty until you add one.</div>
        ) : (
          <div>
            {items.map((item) => (
              <div className="app-row" key={item.id}>
                {item.thumbnailUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={item.thumbnailUrl}
                    alt=""
                    style={{ width: 160, height: 90, objectFit: "cover", borderRadius: 8, background: "#000" }}
                  />
                ) : (
                  <video
                    src={item.videoUrl}
                    preload="metadata"
                    muted
                    playsInline
                    style={{ width: 160, height: 90, objectFit: "cover", borderRadius: 8, background: "#000" }}
                  />
                )}
                <div style={{ flex: 1 }}>
                  <div className="app-row-title">{item.title.en}</div>
                  <div className="app-row-meta" dir="rtl" style={{ textAlign: "left" }}>
                    {item.title.ku} · {item.title.ar}
                  </div>
                </div>
                <div className="app-row-actions">
                  <button className="btn btn-ghost" disabled={formOpen} onClick={() => openForm(item)}>
                    Edit
                  </button>
                  <button className="btn btn-ghost" disabled={busyId === item.id} onClick={() => onDelete(item)}>
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
