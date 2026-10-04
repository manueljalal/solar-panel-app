"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAdminAuth } from "@/lib/use_auth";
import { AppShell } from "./app_shell";

/** Wraps a sidebar page: redirects to /login unless signed in as
 * super_admin, and shows a loading state in the meantime. */
export function AuthedPage({ children }: { children: React.ReactNode }) {
  const authState = useAdminAuth();
  const router = useRouter();

  useEffect(() => {
    if (authState.status === "signed-out" || authState.status === "signed-in-not-admin") {
      router.replace("/login");
    }
  }, [authState.status, router]);

  if (authState.status !== "signed-in-admin") {
    return (
      <div className="content">
        <p className="muted">Loading…</p>
      </div>
    );
  }

  return <AppShell>{children}</AppShell>;
}
