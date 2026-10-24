"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { collection, getDocs, query, where } from "firebase/firestore";
import {
  ORDER_STATUS_LABEL,
  formatDate,
  formatTotals,
  orderNumber,
  sumTotals,
  type PortalOrder,
} from "@solary/ui-web";
import { db } from "@/lib/firebase";
import { errorMessage, listOrders, listQuoteRequests, type QuoteRequest } from "@/lib/api";
import { VendorShell, useVendor } from "@/components/vendor_shell";

interface Overview {
  orders: PortalOrder[];
  quotes: QuoteRequest[];
  products: number;
  inStock: number;
}

function OverviewInner() {
  const { vendorId, profile } = useVendor();
  const [data, setData] = useState<Overview | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([
      listOrders({}),
      listQuoteRequests(),
      getDocs(query(collection(db, "products"), where("vendorId", "==", vendorId))),
    ])
      .then(([o, q, p]) =>
        setData({
          orders: o.data.orders,
          quotes: q.data.requests,
          products: p.size,
          inStock: p.docs.filter((d) => d.data().inStock !== false).length,
        }),
      )
      .catch((e) => setError(errorMessage(e, "Couldn't load your overview — try again.")));
  }, [vendorId]);

  const by = (s: PortalOrder["status"]) => data?.orders.filter((o) => o.status === s) ?? [];
  const newOrders = by("placed").length;
  const inProgress = by("confirmed").length + by("out_for_delivery").length;
  const revenue = sumTotals(by("delivered").map((o) => o.totals));
  const newQuotes = data?.quotes.filter((q) => q.status === "new").length ?? 0;

  return (
    <>
      <div className="page-header">
        <div>
          <h1 className="page-title">{profile?.businessName ? `Welcome, ${profile.businessName}` : "Overview"}</h1>
          <p className="page-sub">What needs your attention today.</p>
        </div>
        <Link href="/products/new" className="btn btn-primary">
          Add product
        </Link>
      </div>

      {error && <p className="error-text">{error}</p>}

      <div className="stat-grid">
        <Link href="/orders" className={`stat-card ${newOrders ? "attention" : ""}`}>
          <span className="stat-label">New orders</span>
          <span className="stat-value">{data ? newOrders : "—"}</span>
          <span className="stat-hint">Waiting for you to confirm</span>
        </Link>
        <Link href="/orders" className="stat-card">
          <span className="stat-label">In progress</span>
          <span className="stat-value">{data ? inProgress : "—"}</span>
          <span className="stat-hint">Confirmed or out for delivery</span>
        </Link>
        <div className="stat-card">
          <span className="stat-label">Delivered sales</span>
          <span className="stat-value" style={{ fontSize: 22 }}>{data ? formatTotals(revenue) : "—"}</span>
          <span className="stat-hint">{data ? `${by("delivered").length} delivered orders` : ""}</span>
        </div>
        <Link href="/quotes" className={`stat-card ${newQuotes ? "attention" : ""}`}>
          <span className="stat-label">New quote requests</span>
          <span className="stat-value">{data ? newQuotes : "—"}</span>
          <span className="stat-hint">Shoppers waiting for a price</span>
        </Link>
        <Link href="/products" className="stat-card">
          <span className="stat-label">Products</span>
          <span className="stat-value">{data ? data.products : "—"}</span>
          <span className="stat-hint">{data ? `${data.inStock} in stock` : ""}</span>
        </Link>
      </div>

      <div className="section-title">
        Recent orders <Link href="/orders">View all</Link>
      </div>
      {data && data.orders.length === 0 ? (
        <div className="empty-state">
          <strong>No orders yet</strong>
          Orders from the Solary app will appear here.
        </div>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Order</th>
                <th>Customer</th>
                <th className="num">Total</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {(data?.orders ?? []).slice(0, 6).map((o) => (
                <tr key={o.id}>
                  <td>
                    <div className="cell-main">{orderNumber(o.id)}</div>
                    <div className="cell-sub">{formatDate(o.createdAt)}</div>
                  </td>
                  <td>{o.customerName || "—"}</td>
                  <td className="num">{formatTotals(o.totals)}</td>
                  <td>
                    <span className={`status status-${o.status}`}>{ORDER_STATUS_LABEL[o.status]}</span>
                  </td>
                </tr>
              ))}
              {!data && (
                <tr>
                  <td colSpan={4} className="muted">Loading…</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}

export default function DashboardPage() {
  return (
    <VendorShell>
      <OverviewInner />
    </VendorShell>
  );
}
