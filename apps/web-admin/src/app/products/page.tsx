"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { formatDate, formatMoney } from "@solary/ui-web";
import { AuthedPage } from "@/components/authed_page";
import { errorMessage, listProducts, removeProduct, type AdminProduct } from "@/lib/api";

export default function ProductsPage() {
  const [products, setProducts] = useState<AdminProduct[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setProducts((await listProducts()).data.products);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load products — try again."));
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const shown = useMemo(() => {
    const q = search.trim().toLowerCase();
    return (products ?? []).filter(
      (p) => !q || `${p.name} ${p.brand} ${p.spec} ${p.vendorName}`.toLowerCase().includes(q),
    );
  }, [products, search]);

  async function onRemove(p: AdminProduct) {
    if (!window.confirm(`Remove "${p.name}" by ${p.vendorName} from the marketplace? This can't be undone.`)) return;
    setBusyId(p.id);
    try {
      await removeProduct({ productId: p.id });
      await load();
    } catch (e) {
      setError(errorMessage(e, "Couldn't remove that product — try again."));
    } finally {
      setBusyId(null);
    }
  }

  return (
    <AuthedPage>
      <div className="content">
        <div className="page-header">
          <div>
            <h1 className="page-title">Products</h1>
            <p className="page-sub">Everything vendors have listed. Remove anything that breaks the rules.</p>
          </div>
        </div>

        {error && <p className="error-text">{error}</p>}

        <div className="toolbar">
          <input className="search" placeholder="Search product, brand, vendor" value={search} onChange={(e) => setSearch(e.target.value)} />
          <span className="spacer" />
          {products && <span className="muted">{products.length} products</span>}
        </div>

        {products === null ? (
          <p className="muted">Loading…</p>
        ) : shown.length === 0 ? (
          <div className="empty-state">
            <strong>No products</strong>
            {products.length ? "Try a different search." : "Vendors haven't listed anything yet."}
          </div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Vendor</th>
                  <th className="num">Price</th>
                  <th>Stock</th>
                  <th className="num">Sold</th>
                  <th>Added</th>
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
                    <td>{p.vendorName}</td>
                    <td className="num">{formatMoney(p.price, p.currency)}</td>
                    <td>
                      <span className={`status ${p.inStock ? "status-in_stock" : "status-out_of_stock"}`}>
                        {p.inStock ? "In stock" : "Out of stock"}
                      </span>
                    </td>
                    <td className="num">{p.sold}</td>
                    <td>{formatDate(p.createdAt)}</td>
                    <td className="actions">
                      <button className="btn btn-danger btn-sm" disabled={busyId === p.id} onClick={() => onRemove(p)}>
                        Remove
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AuthedPage>
  );
}
