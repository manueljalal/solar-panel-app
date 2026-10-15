"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { httpsCallable } from "firebase/functions";
import { signOut } from "firebase/auth";
import { auth, functions } from "@/lib/firebase";
import { useAdminAuth } from "@/lib/use_auth";
import { AuthCard, AuthNotice } from "@/components/auth_card";

/** One-time super_admin creation — mirrors backend/functions/src/admin/
 * bootstrap_super_admin.ts, which grants super_admin to whoever calls it
 * FIRST and permanently refuses every call after that (enforced by a
 * transaction on system/bootstrap, not by this page). Step 1: sign up like
 * any user (username + password, phone verified over WhatsApp). Step 2:
 * claim the role for that account. */
export default function BootstrapPage() {
  const state = useAdminAuth();
  const router = useRouter();
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onClaim() {
    setSubmitting(true);
    setError(null);
    try {
      await httpsCallable(functions, "admin-bootstrapSuperAdmin")();
      // Claims are cached on the ID token — force a refresh so the
      // role shows up, then the sign-in page routes into the dashboard.
      await auth.currentUser?.getIdToken(true);
      router.replace("/login");
    } catch (err) {
      setError((err as { message?: string }).message ?? "Bootstrap failed.");
      setSubmitting(false);
    }
  }

  if (state.status === "loading") return null;

  if (state.status === "signed-out") {
    return <AuthCard variant="admin" initialView="signup" />;
  }

  if (state.status === "signed-in-admin") {
    return (
      <AuthNotice>
          <p>This account is already a super admin.</p>
          <a href="/dashboard" className="btn btn-primary" style={{ alignSelf: "flex-start" }}>
            Go to dashboard
          </a>
        </AuthNotice>
    );
  }

  return (
    <AuthNotice>
        <div>
          <div className="brand">Solary</div>
          <p className="muted">Claim the super admin role</p>
        </div>
        <p className="muted" style={{ fontSize: 12.5 }}>
          This only works once — the first account to do this becomes super_admin, and every call after that is
          refused.
        </p>
        {error && <p className="error-text">{error}</p>}
        <button className="btn btn-primary" type="button" onClick={onClaim} disabled={submitting}>
          {submitting ? "Claiming…" : "Make this account super admin"}
        </button>
        <button className="btn btn-ghost" type="button" onClick={() => signOut(auth)}>
          Use a different account
        </button>
      </AuthNotice>
  );
}
