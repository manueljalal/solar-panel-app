"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useVendorAuth } from "@/lib/use_auth";
import { ProductForm } from "../product_form";
import type { VendorProduct } from "@/lib/products";

function fromDoc(id: string, data: Record<string, unknown>): VendorProduct {
  return {
    id,
    category: (data.category as VendorProduct["category"]) ?? "residential",
    brand: (data.brand as string) ?? "",
    name: (data.name as string) ?? "",
    spec: (data.spec as string) ?? "",
    price: (data.price as number) ?? 0,
    currency: (data.currency as VendorProduct["currency"]) ?? "USD",
    imageUrl: (data.imageUrl as string) ?? "",
    description: (data.description as string | null) ?? null,
    warranty: (data.warranty as string | null) ?? null,
    inStock: (data.inStock as boolean) ?? true,
    rating: (data.rating as number) ?? 0,
    sold: (data.sold as number) ?? 0,
  };
}

function EditProductInner() {
  const authState = useVendorAuth();
  const router = useRouter();
  const params = useSearchParams();
  const id = params.get("id");
  const [product, setProduct] = useState<VendorProduct | null | "not-found">(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (authState.status === "signed-out" || authState.status === "signed-in-not-vendor") {
      router.replace("/login");
    }
  }, [authState.status, router]);

  useEffect(() => {
    if (authState.status !== "signed-in-vendor" || !id) return;
    getDoc(doc(db, "products", id))
      .then((snap) => {
        if (!snap.exists() || snap.data().vendorId !== authState.vendorId) {
          setProduct("not-found");
          return;
        }
        setProduct(fromDoc(snap.id, snap.data()));
      })
      .catch(() => setError("Couldn't load that product."));
  }, [authState, id]);

  if (authState.status !== "signed-in-vendor" || !id) {
    return (
      <div className="content">
        <p className="muted">Loading…</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="content">
        <p className="error-text">{error}</p>
      </div>
    );
  }

  if (product === "not-found") {
    return (
      <div className="content">
        <p className="error-text">Product not found.</p>
      </div>
    );
  }

  return (
    <div className="content" style={{ maxWidth: 480 }}>
      <h1 style={{ fontSize: 20, marginBottom: 20 }}>Edit product</h1>
      <div className="card">
        {product ? <ProductForm editing={product} /> : <p className="muted">Loading…</p>}
      </div>
    </div>
  );
}

export default function EditProductPage() {
  return (
    <Suspense fallback={<div className="content"><p className="muted">Loading…</p></div>}>
      <EditProductInner />
    </Suspense>
  );
}
