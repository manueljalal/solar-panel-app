"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useVendorAuth } from "@/lib/use_auth";
import { AuthCard, AuthNotice } from "@/components/auth_card";

/** Vendor portal sign-in. Same username + password (+ WhatsApp OTP on a
 * new device) as every other role — vendors sign up like normal users,
 * apply at /apply, and the approval just grants the vendor claim to that
 * same account. Signing up here is allowed; it creates the account you
 * then apply with. */
export default function LoginPage() {
  const state = useVendorAuth();
  const router = useRouter();

  useEffect(() => {
    if (state.status === "signed-in-vendor") router.replace("/dashboard");
  }, [state.status, router]);

  if (state.status === "signed-in-not-vendor") {
    return (
      <AuthNotice>
          <div className="brand">Solary</div>
          <p className="muted">
            You&apos;re signed in, but this account isn&apos;t an approved vendor yet. If you haven&apos;t applied,
            do it now; if you have, we&apos;ll notify you once it&apos;s approved.
          </p>
          <a href="/apply" className="btn btn-primary" style={{ alignSelf: "flex-start" }}>
            Apply to become a vendor
          </a>
          <button type="button" className="btn btn-ghost" onClick={() => signOut(auth)}>
            Sign out
          </button>
        </AuthNotice>
    );
  }

  return <AuthCard />;
}
