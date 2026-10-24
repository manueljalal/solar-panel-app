"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { doc, getDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { VendorShell, useVendor } from "@/components/vendor_shell";
import { ProductForm } from "../product_form";
import { productFromDoc, type VendorProduct } from "@/lib/products";

function EditProductInner() {
  const { vendorId } = useVendor();
  const id = useSearchParams().get("id");
  const [product, setProduct] = useState<VendorProduct | null | "not-found">(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setProduct("not-found");
      return;
    }
    getDoc(doc(db, "products", id))
      .then((snap) => {
        if (!snap.exists() || snap.data().vendorId !== vendorId) {
          setProduct("not-found");
          return;
        }
        setProduct(productFromDoc(snap.id, snap.data()));
      })
      .catch(() => setError("Couldn't load that product."));
  }, [vendorId, id]);

  return (
    <div style={{ maxWidth: 560 }}>
      <div className="page-header">
        <div>
          <h1 className="page-title">Edit product</h1>
          <p className="page-sub">
            <Link className="link" href="/products">← Back to products</Link>
          </p>
        </div>
      </div>
      {error ? (
        <p className="error-text">{error}</p>
      ) : product === "not-found" ? (
        <p className="error-text">Product not found.</p>
      ) : (
        <div className="panel">{product ? <ProductForm editing={product} /> : <p className="muted">Loading…</p>}</div>
      )}
    </div>
  );
}

export default function EditProductPage() {
  return (
    <VendorShell>
      <Suspense fallback={<p className="muted">Loading…</p>}>
        <EditProductInner />
      </Suspense>
    </VendorShell>
  );
}
