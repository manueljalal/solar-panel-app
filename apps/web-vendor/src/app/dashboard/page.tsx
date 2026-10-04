"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { signOut } from "firebase/auth";
import { httpsCallable } from "firebase/functions";
import { collection, onSnapshot, orderBy, query, where } from "firebase/firestore";
import { auth, db, functions } from "@/lib/firebase";
import { useVendorAuth } from "@/lib/use_auth";
import { categoryLabel, type VendorProduct } from "@/lib/products";

const deleteProduct = httpsCallable<{ productId: string }, { ok: true }>(functions, "vendor-deleteProduct");

function fromDoc(id: string, data: Record<string, unknown>): VendorProduct {
  return {
    id,
    category: (data.category as VendorProduct["category"]) ?? "residential",
    brand: (data.brand as string) ?? "",
    name: (data.name as string) ?? "Untitled product",
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

export default function DashboardPage() {
  const authState = useVendorAuth();
  const router = useRouter();
  const [products, setProducts] = useState<VendorProduct[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    if (authState.status === "signed-out" || authState.status === "signed-in-not-vendor") {
      router.replace("/login");
    }
  }, [authState.status, router]);

  useEffect(() => {
    if (authState.status !== "signed-in-vendor") return;
    const q = query(
      collection(db, "products"),
      where("vendorId", "==", authState.vendorId),
      orderBy("createdAt", "desc"),
    );
    const unsubscribe = onSnapshot(
      q,
      (snap) => setProducts(snap.docs.map((d) => fromDoc(d.id, d.data()))),
      () => setError("Couldn't load your products."),
    );
    return unsubscribe;
  }, [authState]);

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

  if (authState.status !== "signed-in-vendor") {
    return (
      <div className="content">
        <p className="muted">Loading…</p>
      </div>
    );
  }

  return (
    <div className="shell">
      <div className="topbar">
        <div className="brand">Solary — Vendor Portal</div>
        <button className="btn btn-ghost" onClick={() => signOut(auth)}>
          Sign out
        </button>
      </div>
      <div className="content">
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
                    {categoryLabel(p.category)} · {p.spec} · {p.brand}
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
      </div>
    </div>
  );
}
