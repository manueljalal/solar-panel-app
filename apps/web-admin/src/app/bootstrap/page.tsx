"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
} from "firebase/auth";
import { httpsCallable } from "firebase/functions";
import { auth, functions } from "@/lib/firebase";

/** One-time super_admin creation — mirrors backend/functions/src/admin/
 * bootstrap_super_admin.ts, which grants super_admin to whoever calls it
 * FIRST and permanently refuses every call after that (enforced by a
 * transaction on system/bootstrap, not by this page). Safe to leave
 * reachable in production: after the first successful call it just always
 * errors with "already bootstrapped". */
export default function BootstrapPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      // Sign in if the account already exists (e.g. a retry), otherwise
      // create it — either way we end up with a signed-in user to grant
      // the claim to.
      try {
        await signInWithEmailAndPassword(auth, email.trim(), password);
      } catch {
        await createUserWithEmailAndPassword(auth, email.trim(), password);
      }
      const bootstrap = httpsCallable(functions, "admin-bootstrapSuperAdmin");
      await bootstrap();
      setDone(true);
      setTimeout(() => router.replace("/login"), 1500);
    } catch (err) {
      const message = (err as { message?: string }).message ?? "Bootstrap failed.";
      setError(message);
      setSubmitting(false);
    }
  }

  if (done) {
    return (
      <div className="content" style={{ maxWidth: 400, paddingTop: 96 }}>
        <div className="card stack">
          <p>Admin account created. Redirecting to sign in…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="content" style={{ maxWidth: 400, paddingTop: 96 }}>
      <div className="card stack">
        <div>
          <div className="brand">Solary</div>
          <p className="muted">Create the first super admin</p>
        </div>
        <p className="muted" style={{ fontSize: 12.5 }}>
          This only works once — the first account to call this becomes
          super_admin, and every call after that is refused.
        </p>
        <form className="stack" onSubmit={onSubmit}>
          <div className="field">
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              autoComplete="new-password"
              minLength={6}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          {error && <p className="error-text">{error}</p>}
          <button className="btn btn-primary" type="submit" disabled={submitting}>
            {submitting ? "Creating…" : "Create admin account"}
          </button>
        </form>
      </div>
    </div>
  );
}
