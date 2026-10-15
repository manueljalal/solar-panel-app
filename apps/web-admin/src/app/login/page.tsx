"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useAdminAuth } from "@/lib/use_auth";
import { AuthCard, AuthNotice } from "@/components/auth_card";

/** Super admin sign-in: the same username + password (+ WhatsApp OTP on a
 * new device) as every other role. No signup here — admin access is a
 * claim granted via /bootstrap (first admin) or by an existing admin. */
export default function LoginPage() {
  const state = useAdminAuth();
  const router = useRouter();

  useEffect(() => {
    if (state.status === "signed-in-admin") router.replace("/dashboard");
  }, [state.status, router]);

  if (state.status === "signed-in-not-admin") {
    return (
      <AuthNotice>
          <div className="brand">Solary</div>
          <p className="error-text">Signed in, but this account has no admin access.</p>
          <button type="button" className="btn btn-ghost" onClick={() => signOut(auth)}>
            Sign out
          </button>
        </AuthNotice>
    );
  }

  return (
    <AuthCard variant="admin" allowSignup={false} />
  );
}
