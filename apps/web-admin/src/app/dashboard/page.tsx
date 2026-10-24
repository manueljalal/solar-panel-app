"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ORDER_STATUS_LABEL, formatDate, formatTotals, orderNumber, type PortalOrder } from "@solary/ui-web";
import { AuthedPage } from "@/components/authed_page";
import { errorMessage, getStats, listOrders, type PlatformStats } from "@/lib/api";

export default function DashboardPage() {
  const [stats, setStats] = useState<PlatformStats | null>(null);
  const [orders, setOrders] = useState<PortalOrder[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([getStats(), listOrders({})])
      .then(([s, o]) => {
        setStats(s.data);
        setOrders(o.data.orders);
      })
      .catch((e) => setError(errorMessage(e, "Couldn't load the dashboard — try again.")));
  }, []);

  const v = (n: number | undefined) => (stats ? n : "—");
  const open = stats ? stats.orders.placed + stats.orders.confirmed + stats.orders.outForDelivery : 0;

  return (
    <AuthedPage>
      <div className="content">
        <div className="page-header">
          <div>
            <h1 className="page-title">Dashboard</h1>
            <p className="page-sub">Platform overview — what needs attention first.</p>
          </div>
        </div>

        {error && <p className="error-text">{error}</p>}

        <div className="stat-grid">
          <Link href="/vendors" className={`stat-card ${stats?.pendingApplications ? "attention" : ""}`}>
            <span className="stat-label">Vendor applications</span>
            <span className="stat-value">{v(stats?.pendingApplications)}</span>
            <span className="stat-hint">Waiting for review</span>
          </Link>
          <Link href="/orders" className={`stat-card ${stats?.orders.placed ? "attention" : ""}`}>
            <span className="stat-label">New orders</span>
            <span className="stat-value">{v(stats?.orders.placed)}</span>
            <span className="stat-hint">Not yet confirmed by the vendor</span>
          </Link>
          <Link href="/orders" className="stat-card">
            <span className="stat-label">Open orders</span>
            <span className="stat-value">{stats ? open : "—"}</span>
            <span className="stat-hint">{stats ? `${stats.orders.delivered} delivered · ${stats.orders.cancelled} cancelled` : ""}</span>
          </Link>
          <Link href="/quotes" className="stat-card">
            <span className="stat-label">New quote requests</span>
            <span className="stat-value">{v(stats?.newQuotes)}</span>
            <span className="stat-hint">Across all vendors</span>
          </Link>
          <Link href="/vendors" className="stat-card">
            <span className="stat-label">Approved vendors</span>
            <span className="stat-value">{v(stats?.vendors)}</span>
            <span className="stat-hint">Selling on Solary</span>
          </Link>
          <Link href="/products" className="stat-card">
            <span className="stat-label">Products</span>
            <span className="stat-value">{v(stats?.products)}</span>
            <span className="stat-hint">Listed by vendors</span>
          </Link>
          <Link href="/users" className="stat-card">
            <span className="stat-label">Accounts</span>
            <span className="stat-value">{v(stats?.users)}</span>
            <span className="stat-hint">Customers and vendors</span>
          </Link>
          <Link href="/b2b" className="stat-card">
            <span className="stat-label">B2B posts</span>
            <span className="stat-value">{stats ? stats.bulkListings + stats.bulkRequests : "—"}</span>
            <span className="stat-hint">{stats ? `${stats.bulkListings} offers · ${stats.bulkRequests} requests` : ""}</span>
          </Link>
        </div>

        <div className="section-title">
          Latest orders <Link href="/orders">View all</Link>
        </div>
        {orders && orders.length === 0 ? (
          <div className="empty-state">
            <strong>No orders yet</strong>
            Orders placed in the app will show up here.
          </div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Order</th>
                  <th>Vendor</th>
                  <th>Customer</th>
                  <th className="num">Total</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {(orders ?? []).slice(0, 8).map((o) => (
                  <tr key={o.id}>
                    <td>
                      <div className="cell-main">{orderNumber(o.id)}</div>
                      <div className="cell-sub">{formatDate(o.createdAt)}</div>
                    </td>
                    <td>{o.vendorName}</td>
                    <td>{o.customerName || "—"}</td>
                    <td className="num">{formatTotals(o.totals)}</td>
                    <td>
                      <span className={`status status-${o.status}`}>{ORDER_STATUS_LABEL[o.status]}</span>
                    </td>
                  </tr>
                ))}
                {!orders && (
                  <tr>
                    <td colSpan={5} className="muted">Loading…</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AuthedPage>
  );
}
