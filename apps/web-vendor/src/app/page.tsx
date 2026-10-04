"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useVendorAuth } from "@/lib/use_auth";

export default function Home() {
  const auth = useVendorAuth();
  const router = useRouter();

  useEffect(() => {
    if (auth.status === "signed-in-vendor") router.replace("/dashboard");
    else if (auth.status === "signed-out" || auth.status === "signed-in-not-vendor") router.replace("/login");
  }, [auth.status, router]);

  return (
    <div className="content">
      <p className="muted">Loading…</p>
    </div>
  );
}
