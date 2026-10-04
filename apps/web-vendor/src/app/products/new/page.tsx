"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useVendorAuth } from "@/lib/use_auth";
import { ProductForm } from "../product_form";

export default function NewProductPage() {
  const authState = useVendorAuth();
  const router = useRouter();

  useEffect(() => {
    if (authState.status === "signed-out" || authState.status === "signed-in-not-vendor") {
      router.replace("/login");
    }
  }, [authState.status, router]);

  if (authState.status !== "signed-in-vendor") {
    return (
      <div className="content">
        <p className="muted">Loading…</p>
      </div>
    );
  }

  return (
    <div className="content" style={{ maxWidth: 480 }}>
      <h1 style={{ fontSize: 20, marginBottom: 20 }}>Add product</h1>
      <div className="card">
        <ProductForm />
      </div>
    </div>
  );
}
