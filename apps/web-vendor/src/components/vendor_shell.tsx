"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase";
import { useVendorAuth } from "@/lib/use_auth";
import { listOrders, listQuoteRequests } from "@/lib/api";

export interface VendorProfile {
  businessName: string;
  city: string;
  address: string;
  description: string;
  phone: string;
  logoUrl: string;
  country: "IQ" | "CN";
}

interface VendorContextValue {
  vendorId: string;
  profile: VendorProfile | null;
  reloadProfile: () => Promise<void>;
  /** Badge counts in the sidebar; pages call this after changing data. */
  refreshCounts: () => void;
}

const VendorContext = createContext<VendorContextValue | null>(null);

export function useVendor(): VendorContextValue {
  const v = useContext(VendorContext);
  if (!v) throw new Error("useVendor must be used inside <VendorShell>");
  return v;
}

const NAV = [
  { href: "/dashboard", label: "Overview" },
  { href: "/orders", label: "Orders", badge: "orders" as const },
  { href: "/products", label: "Products" },
  { href: "/quotes", label: "Quote requests", badge: "quotes" as const },
  { href: "/settings", label: "Company" },
];

/** Signed-in vendor layout: sidebar navigation with live badge counts, and
 * the gate that sends anyone who isn't an approved vendor to /login. */
export function VendorShell({ children }: { children: React.ReactNode }) {
  const authState = useVendorAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [profile, setProfile] = useState<VendorProfile | null>(null);
  const [counts, setCounts] = useState<{ orders: number; quotes: number }>({ orders: 0, quotes: 0 });

  const vendorId = authState.status === "signed-in-vendor" ? authState.vendorId : null;

  useEffect(() => {
    if (authState.status === "signed-out" || authState.status === "signed-in-not-vendor") router.replace("/login");
  }, [authState.status, router]);

  const reloadProfile = useCallback(async () => {
    if (!vendorId) return;
    const snap = await getDoc(doc(db, "vendors", vendorId));
    const d = snap.data() ?? {};
    setProfile({
      businessName: d.businessName ?? "",
      city: d.city ?? "",
      address: d.address ?? "",
      description: d.description ?? "",
      phone: d.phone ?? "",
      logoUrl: d.logoUrl ?? "",
      country: d.country === "CN" ? "CN" : "IQ",
    });
  }, [vendorId]);

  const refreshCounts = useCallback(() => {
    if (!vendorId) return;
    Promise.all([listOrders({ status: "placed" }), listQuoteRequests()])
      .then(([o, q]) =>
        setCounts({ orders: o.data.orders.length, quotes: q.data.requests.filter((r) => r.status === "new").length }),
      )
      .catch(() => {});
  }, [vendorId]);

  useEffect(() => {
    void reloadProfile();
    refreshCounts();
  }, [reloadProfile, refreshCounts]);

  if (!vendorId) {
    return (
      <div className="content">
        <p className="muted">Loading…</p>
      </div>
    );
  }

  return (
    <VendorContext.Provider value={{ vendorId, profile, reloadProfile, refreshCounts }}>
      <div className="shell-with-sidebar">
        <aside className="sidebar">
          <div className="sidebar-brand">
            <span className="sidebar-brand-mark">S</span>
            Solary
          </div>
          <div className="sidebar-sub">{profile?.businessName || "Vendor portal"}</div>
          <nav className="sidebar-nav">
            {NAV.map((item) => {
              const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
              const badge = item.badge ? counts[item.badge] : 0;
              return (
                <Link key={item.href} href={item.href} className={`sidebar-link ${active ? "active" : ""}`}>
                  {item.label}
                  {badge > 0 && <span className="sidebar-count">{badge}</span>}
                </Link>
              );
            })}
          </nav>
          <button className="btn btn-ghost sidebar-signout" onClick={() => signOut(auth)}>
            Sign out
          </button>
        </aside>
        <main className="shell-main">
          <div className="content">{children}</div>
        </main>
      </div>
    </VendorContext.Provider>
  );
}
