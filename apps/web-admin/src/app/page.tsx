"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAdminAuth } from "@/lib/use_auth";

export default function Home() {
  const auth = useAdminAuth();
  const router = useRouter();

  useEffect(() => {
    if (auth.status === "signed-in-admin") router.replace("/dashboard");
    else if (auth.status === "signed-out" || auth.status === "signed-in-not-admin") router.replace("/login");
  }, [auth.status, router]);

  return (
    <div className="content">
      <p className="muted">Loading…</p>
    </div>
  );
}
