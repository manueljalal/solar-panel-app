"use client";

import { Suspense, useState, type FormEvent } from "react";
import { useSearchParams } from "next/navigation";
import { signInWithCustomToken } from "firebase/auth";
import { auth } from "@/lib/firebase";

// Mirrors isValidPassword in backend/functions/src/shared/auth/password.ts
// — this is just fast feedback, the server enforces the real boundary.
const HAS_UPPER = /[A-Z]/;
const HAS_LOWER = /[a-z]/;
const HAS_DIGIT = /[0-9]/;
const HAS_SYMBOL = /[^A-Za-z0-9]/;

function isValidPassword(password: string): boolean {
  return (
    password.length >= 8 &&
    HAS_UPPER.test(password) &&
    HAS_LOWER.test(password) &&
    HAS_DIGIT.test(password) &&
    HAS_SYMBOL.test(password)
  );
}

const PROJECT_ID = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID;
const SET_PASSWORD_URL = `https://us-central1-${PROJECT_ID}.cloudfunctions.net/auth-setVendorPassword`;

/** Calls the callable over plain HTTPS (the callable wire format is just a
 * JSON POST of {data} answered with {result} or {error}) instead of the
 * Firebase SDK. This endpoint is unauthenticated — the emailed token is the
 * credential — so the SDK's sign-in-state handling adds nothing, and a
 * stalled SDK call was leaving this page spinning with no error. A hard
 * timeout guarantees the user always gets a result or a message. */
async function setVendorPassword(token: string, password: string): Promise<string> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 30_000);
  try {
    const res = await fetch(SET_PASSWORD_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ data: { token, password } }),
      signal: controller.signal,
    });
    const body = (await res.json().catch(() => null)) as
      | { result?: { customToken?: string }; error?: { message?: string } }
      | null;
    if (!res.ok || !body?.result?.customToken) {
      throw new Error(body?.error?.message ?? `Server returned ${res.status}.`);
    }
    return body.result.customToken;
  } catch (err) {
    if ((err as { name?: string }).name === "AbortError") {
      throw new Error("The server took too long to respond. Check your connection and try again.");
    }
    throw err;
  } finally {
    clearTimeout(timer);
  }
}

/** Landing page for the /set-password?token=... link sent by the vendor
 * approval email (see backend's sendVendorApprovedEmail). The token is
 * single-use and expires in 24h — consumed server-side by
 * auth-setVendorPassword, which also returns a session token so the
 * vendor lands straight in the dashboard instead of having to sign in
 * again right after. */
function SetPasswordInner() {
  const params = useSearchParams();
  const token = params.get("token") ?? "";

  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!token) {
      setError("This link is missing its token — open it directly from the approval email.");
      return;
    }
    if (!isValidPassword(password)) {
      setError(
        "Password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.",
      );
      return;
    }
    if (password !== confirm) {
      setError("Passwords don't match.");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const customToken = await setVendorPassword(token, password);
      setDone(true);
      try {
        await signInWithCustomToken(auth, customToken);
      } catch {
        // The password IS set at this point — if auto sign-in fails, send
        // them to the normal sign-in page instead of leaving a spinner.
        window.location.assign("/login");
        return;
      }
      // Hard navigation, not router.replace: a client-side transition on
      // the static export can stall and leave the button spinning forever.
      window.location.assign("/dashboard");
    } catch (err) {
      setError((err as { message?: string }).message ?? "Couldn't set your password — try again.");
      setSubmitting(false);
    }
  }

  return (
    <div className="content" style={{ maxWidth: 400, paddingTop: 96 }}>
      <div className="card stack">
        <div>
          <div className="brand">Solary</div>
          <p className="muted">Set a password for your vendor account</p>
        </div>
        <form className="stack" onSubmit={onSubmit}>
          <div className="field">
            <label htmlFor="password">New password</label>
            <input
              id="password"
              type="password"
              autoComplete="new-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="confirm">Confirm password</label>
            <input
              id="confirm"
              type="password"
              autoComplete="new-password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              required
            />
          </div>
          {error && <p className="error-text">{error}</p>}
          <button className="btn btn-primary" type="submit" disabled={submitting}>
            {done ? "Password set — signing you in…" : submitting ? "Setting password…" : "Set password"}
          </button>
        </form>
        <p className="muted" style={{ fontSize: 12 }}>
          Already set one? <a href="/login" style={{ textDecoration: "underline" }}>Sign in</a>.
        </p>
      </div>
    </div>
  );
}

export default function SetPasswordPage() {
  return (
    <Suspense fallback={<div className="content"><p className="muted">Loading…</p></div>}>
      <SetPasswordInner />
    </Suspense>
  );
}
