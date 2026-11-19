"use client";

import { useState, type FormEvent } from "react";
import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";
import { AuthedPage } from "@/components/authed_page";

interface Text3 {
  ku: string;
  ar: string;
  en: string;
}

const sendAnnouncement = httpsCallable<{ title: Text3; body: Text3 }, { announcementId: string; recipients: number }>(
  functions,
  "admin-sendAnnouncement",
);

const ARABIC_SCRIPT = /\p{Script=Arabic}/u;
const LATIN = /\p{Script=Latin}/u;
const EMPTY: Text3 = { ku: "", ar: "", en: "" };
const MAX_TITLE = 80;
const MAX_BODY = 300;

const LANGS = [
  ["ku", "Kurdish (کوردی)", "rtl"],
  ["ar", "Arabic (العربية)", "rtl"],
  ["en", "English", "ltr"],
] as const;

function friendlyError(err: unknown): string {
  const { code, message } = err as { code?: string; message?: string };
  if ((code === "functions/invalid-argument" || code === "functions/failed-precondition") && message) return message;
  if (code === "functions/permission-denied") return "You don't have permission to do that.";
  return "Something went wrong — try again.";
}

/** Light client-side check; the server is the real gatekeeper. */
function check(label: string, t: Text3): string | null {
  if (!t.ku.trim() || !t.ar.trim() || !t.en.trim()) return `${label}: fill in Kurdish, Arabic and English.`;
  if (!ARABIC_SCRIPT.test(t.ku)) return `${label} (Kurdish) must be written in Kurdish (Arabic script).`;
  if (!ARABIC_SCRIPT.test(t.ar)) return `${label} (Arabic) must be written in Arabic.`;
  if (!LATIN.test(t.en) || ARABIC_SCRIPT.test(t.en)) return `${label} (English) must use English letters.`;
  return null;
}

export default function AnnouncementsPage() {
  const [title, setTitle] = useState<Text3>(EMPTY);
  const [body, setBody] = useState<Text3>(EMPTY);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState<string | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setDone(null);
    const problem = check("Title", title) ?? check("Message", body);
    if (problem) return setError(problem);
    if (!window.confirm("Send this notification to ALL users? This can't be undone.")) return;
    setSending(true);
    setError(null);
    try {
      const res = await sendAnnouncement({ title, body });
      setDone(`Sent to ${res.data.recipients} users. It will appear in their in-app notifications.`);
      setTitle(EMPTY);
      setBody(EMPTY);
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setSending(false);
    }
  }

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Announcements</h1>
        <p className="muted" style={{ marginBottom: 16 }}>
          Send an in-app notification to every user. Each person sees it in their own language, in the app&apos;s
          notifications list.
        </p>
        <form className="card stack" onSubmit={onSubmit}>
          <div style={{ fontWeight: 600 }}>Title</div>
          {LANGS.map(([key, label, dir]) => (
            <div className="field" key={`t-${key}`}>
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
          <div style={{ fontWeight: 600 }}>Message</div>
          {LANGS.map(([key, label, dir]) => (
            <div className="field" key={`b-${key}`}>
              <label htmlFor={`body-${key}`}>{label}</label>
              <textarea
                id={`body-${key}`}
                dir={dir}
                rows={3}
                maxLength={MAX_BODY}
                value={body[key]}
                onChange={(e) => setBody({ ...body, [key]: e.target.value })}
              />
            </div>
          ))}
          {error && <p className="error-text">{error}</p>}
          {done && <p style={{ color: "var(--primary, #1F5A44)" }}>{done}</p>}
          <div>
            <button className="btn btn-primary" type="submit" disabled={sending}>
              {sending ? "Sending…" : "Send to all users"}
            </button>
          </div>
        </form>
      </div>
    </AuthedPage>
  );
}
