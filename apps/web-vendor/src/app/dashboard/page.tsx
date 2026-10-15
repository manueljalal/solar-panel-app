"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { httpsCallable } from "firebase/functions";
import { collection, onSnapshot, orderBy, query, where } from "firebase/firestore";
import { db, functions } from "@/lib/firebase";
import { useCategories } from "@/lib/categories";
import { VendorShell } from "@/components/vendor_shell";
import type { VendorProduct } from "@/lib/products";

const deleteProduct = httpsCallable<{ productId: string }, { ok: true }>(functions, "vendor-deleteProduct");

function i18n(v: unknown, fallbackEn = ""): VendorProduct["nameI18n"] {
  const o = (v ?? {}) as Record<string, unknown>;
  return { ku: (o.ku as string) ?? "", ar: (o.ar as string) ?? "", en: (o.en as string) ?? fallbackEn };
}

function fromDoc(id: string, data: Record<string, unknown>): VendorProduct {
  return {
    id,
    category: (data.category as VendorProduct["category"]) ?? "",
    brand: (data.brand as string) ?? "",
    name: (data.name as string) ?? "Untitled product",
    nameI18n: i18n(data.nameI18n, (data.name as string) ?? ""),
    spec: (data.spec as string) ?? "",
    price: (data.price as number) ?? 0,
    currency: (data.currency as VendorProduct["currency"]) ?? "USD",
    imageUrl: (data.imageUrl as string) ?? "",
    description: (data.description as string | null) ?? null,
    descriptionI18n: data.descriptionI18n ? i18n(data.descriptionI18n) : null,
    warranty: (data.warranty as string | null) ?? null,
    warrantyI18n: data.warrantyI18n ? i18n(data.warrantyI18n) : null,
    inStock: (data.inStock as boolean) ?? true,
    rating: (data.rating as number) ?? 0,
    sold: (data.sold as number) ?? 0,
  };
}

export default function DashboardPage() {
  return <VendorShell>{(vendorId) => <Products vendorId={vendorId} />}</VendorShell>;
}

function Products({ vendorId }: { vendorId: string }) {
  const { categories } = useCategories();
  const [products, setProducts] = useState<VendorProduct[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, "products"),
      where("vendorId", "==", vendorId),
      orderBy("createdAt", "desc"),
    );
    const unsubscribe = onSnapshot(
      q,
      (snap) => setProducts(snap.docs.map((d) => fromDoc(d.id, d.data()))),
      () => setError("Couldn't load your products."),
    );
    return unsubscribe;
  }, [vendorId]);

  async function onDelete(id: string, name: string) {
    if (!window.confirm(`Remove "${name}"?`)) return;
    setBusyId(id);
    try {
      await deleteProduct({ productId: id });
    } catch {
      setError("Couldn't remove that product — try again.");
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <div className="page-header">
        <div>
          <h1 style={{ fontSize: 20, marginBottom: 4 }}>My products</h1>
          <p className="muted">Manage what shoppers see on Solary.</p>
        </div>
        <Link href="/products/new" className="btn btn-primary">
          Add product
        </Link>
      </div>

      {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}

      {products === null ? (
        <p className="muted">Loading…</p>
      ) : products.length === 0 ? (
        <div className="empty-state">No products yet. Tap &quot;Add product&quot; to list your first item.</div>
      ) : (
        <div>
          {products.map((p) => (
            <div className="app-row" key={p.id}>
              {p.imageUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={p.imageUrl} alt="" className="product-thumb" />
              ) : (
                <div className="product-thumb" />
              )}
              <div style={{ flex: 1 }}>
                <div className="app-row-title">{p.name}</div>
                <div className="app-row-meta">
                  {categories?.find((c) => c.id === p.category)?.name.en ?? p.category} · {p.spec} · {p.brand}
                </div>
                <div className="app-row-meta">
                  {p.currency === "USD" ? "$" : "IQD "}
                  {p.price.toLocaleString()}{" "}
                  <span className={`pill ${p.inStock ? "pill-success" : "pill-warning"}`} style={{ marginLeft: 6 }}>
                    {p.inStock ? "In stock" : "Out of stock"}
                  </span>
                </div>
              </div>
              <div className="app-row-actions">
                <Link href={`/products/edit?id=${p.id}`} className="btn btn-ghost">
                  Edit
                </Link>
                <button className="btn btn-danger" disabled={busyId === p.id} onClick={() => onDelete(p.id, p.name)}>
                  Remove
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
