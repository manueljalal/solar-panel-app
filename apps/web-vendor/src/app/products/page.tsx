"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { collection, onSnapshot, query, where } from "firebase/firestore";
import { formatMoney } from "@solary/ui-web";
import { db } from "@/lib/firebase";
import { deleteProduct, errorMessage } from "@/lib/api";
import { useCategories } from "@/lib/categories";
import { productFromDoc, type VendorProduct } from "@/lib/products";
import { VendorShell, useVendor } from "@/components/vendor_shell";

function ProductsInner() {
  const { vendorId } = useVendor();
  const { categories } = useCategories();
  const [products, setProducts] = useState<VendorProduct[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [search, setSearch] = useState("");

  useEffect(() => {
    // Live list; sorted in memory so no vendorId+createdAt index is needed.
    return onSnapshot(
      query(collection(db, "products"), where("vendorId", "==", vendorId)),
      (snap) =>
        setProducts(
          snap.docs
            .map((d) => ({ p: productFromDoc(d.id, d.data()), t: d.data().createdAt?.toMillis?.() ?? 0 }))
            .sort((a, b) => b.t - a.t)
            .map((x) => x.p),
        ),
      () => setError("Couldn't load your products."),
    );
  }, [vendorId]);

  const shown = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!products) return null;
    return q ? products.filter((p) => `${p.name} ${p.brand} ${p.spec}`.toLowerCase().includes(q)) : products;
  }, [products, search]);

  async function onDelete(p: VendorProduct) {
    if (!window.confirm(`Remove "${p.name}" from Solary?`)) return;
    setBusyId(p.id);
    try {
      await deleteProduct({ productId: p.id });
    } catch (e) {
      setError(errorMessage(e, "Couldn't remove that product — try again."));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <>
      <div className="page-header">
        <div>
          <h1 className="page-title">Products</h1>
          <p className="page-sub">What shoppers see in the Solary app.</p>
        </div>
        <Link href="/products/new" className="btn btn-primary">
          Add product
        </Link>
      </div>

      {error && <p className="error-text">{error}</p>}

      <div className="toolbar">
        <input className="search" placeholder="Search products" value={search} onChange={(e) => setSearch(e.target.value)} />
        <span className="spacer" />
        {products && <span className="muted">{products.length} products</span>}
      </div>

      {shown === null ? (
        <p className="muted">Loading…</p>
      ) : shown.length === 0 ? (
        <div className="empty-state">
          <strong>{products?.length ? "No matching products" : "No products yet"}</strong>
          {products?.length ? "Try a different search." : "Add your first product to start selling."}
        </div>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Product</th>
                <th>Category</th>
                <th className="num">Price</th>
                <th>Stock</th>
                <th className="num">Sold</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {shown.map((p) => (
                <tr key={p.id}>
                  <td>
                    <div className="cell-media">
                      {p.imageUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={p.imageUrl} alt="" className="thumb" />
                      ) : (
                        <div className="thumb thumb-empty">{p.name.charAt(0)}</div>
                      )}
                      <div>
                        <div className="cell-main">{p.name}</div>
                        <div className="cell-sub">{[p.brand, p.spec].filter(Boolean).join(" · ")}</div>
                      </div>
                    </div>
                  </td>
                  <td>{categories?.find((c) => c.id === p.category)?.name.en ?? p.category}</td>
                  <td className="num">{formatMoney(p.price, p.currency)}</td>
                  <td>
                    <span className={`status ${p.inStock ? "status-in_stock" : "status-out_of_stock"}`}>
                      {p.inStock ? "In stock" : "Out of stock"}
                    </span>
                  </td>
                  <td className="num">{p.sold}</td>
                  <td className="actions">
                    <Link href={`/products/edit?id=${p.id}`} className="btn btn-ghost btn-sm">
                      Edit
                    </Link>{" "}
                    <button className="btn btn-danger btn-sm" disabled={busyId === p.id} onClick={() => onDelete(p)}>
                      Remove
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}

export default function ProductsPage() {
  return (
    <VendorShell>
      <ProductsInner />
    </VendorShell>
  );
}
