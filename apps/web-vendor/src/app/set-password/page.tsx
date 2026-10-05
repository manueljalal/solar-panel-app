"use client";

import { Suspense, useState, type FormEvent } from "react";
import { useSearchParams } from "next/navigation";
import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";

const setVendorPassword = httpsCallable<{ token: string; password: string }, { ok: true }>(
  functions,
  "auth-setVendorPassword",
);

const PASSWORD_HINT = "At least 8 characters, with an uppercase letter, a lowercase letter, a number, and a symbol.";

function friendlyError(err: unknown): string {
  const message = (err as { message?: string }).message ?? "";
  if (message.includes("invalid or has expired")) {
    return "This link is invalid or has expired. Ask an admin to re-approve your application to get a new one.";
  }
  if (message.includes("password must be")) {
    return PASSWORD_HINT;
  }
  return "Couldn't set your password — try again.";
}

function SetPasswordForm() {
  const token = useSearchParams().get("token") ?? "";
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (password !== confirm) {
      setError("Passwords don't match.");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await setVendorPassword({ token, password });
      setDone(true);
    } catch (err) {
      setError(friendlyError(err));
      setSubmitting(false);
    }
  }

  if (!token) {
    return (
      <div className="card stack">
        <div className="brand">Solary</div>
        <p className="error-text">
          This link is missing its token. Open the link from your approval email directly.
        </p>
      </div>
    );
  }

  if (done) {
    return (
      <div className="card stack" style={{ textAlign: "center" }}>
        <div className="brand">Password set</div>
        <p className="muted">You can now sign in with your email and password, or your phone number.</p>
        <a href="/login" className="btn btn-primary" style={{ alignSelf: "center" }}>
          Sign in
        </a>
      </div>
    );
  }

  return (
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
        <p className="muted" style={{ fontSize: 12 }}>{PASSWORD_HINT}</p>
        {error && <p className="error-text">{error}</p>}
        <button className="btn btn-primary" type="submit" disabled={submitting}>
          {submitting ? "Saving…" : "Set password"}
        </button>
      </form>
    </div>
  );
}

export default function SetPasswordPage() {
  return (
    <div className="content" style={{ maxWidth: 400, paddingTop: 96 }}>
      <Suspense fallback={<p className="muted">Loading…</p>}>
        <SetPasswordForm />
      </Suspense>
    </div>
  );
}
