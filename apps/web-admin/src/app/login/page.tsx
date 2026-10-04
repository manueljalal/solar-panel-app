"use client";

import { useEffect, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useAdminAuth } from "@/lib/use_auth";

function friendlyError(code: string): string {
  switch (code) {
    case "auth/invalid-credential":
    case "auth/wrong-password":
    case "auth/user-not-found":
      return "Incorrect email or password.";
    case "auth/invalid-email":
      return "That email address looks invalid.";
    case "auth/too-many-requests":
      return "Too many attempts — try again in a moment.";
    default:
      return "Sign-in failed.";
  }
}

export default function LoginPage() {
  const state = useAdminAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (state.status === "signed-in-admin") router.replace("/dashboard");
  }, [state.status, router]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await signInWithEmailAndPassword(auth, email.trim(), password);
      // useAdminAuth's onAuthStateChanged listener picks this up and the
      // effect above redirects once the role claim resolves.
    } catch (err) {
      const code = (err as { code?: string }).code ?? "";
      setError(friendlyError(code));
      setSubmitting(false);
    }
  }

  return (
    <div className="content" style={{ maxWidth: 400, paddingTop: 96 }}>
      <div className="card stack">
        <div>
          <div className="brand">Solary</div>
          <p className="muted">Super admin console</p>
        </div>
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
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          {error && <p className="error-text">{error}</p>}
          {state.status === "signed-in-not-admin" && (
            <p className="error-text">Signed in, but this account has no admin access.</p>
          )}
          <button className="btn btn-primary" type="submit" disabled={submitting}>
            {submitting ? "Signing in…" : "Sign in"}
          </button>
        </form>
        <p className="muted" style={{ fontSize: 12 }}>
          No admin account yet? Use the one-time{" "}
          <a href="/bootstrap" style={{ textDecoration: "underline" }}>
            bootstrap
          </a>{" "}
          flow to create the first one.
        </p>
      </div>
    </div>
  );
}
