"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { getStats, type PlatformStats } from "@/lib/api";

type BadgeKey = "orders" | "applications" | "quotes" | "services";

const SECTIONS: { title?: string; items: { href: string; label: string; badge?: BadgeKey }[] }[] = [
  { items: [{ href: "/dashboard", label: "Dashboard" }] },
  {
    title: "Commerce",
    items: [
      { href: "/orders", label: "Orders", badge: "orders" },
      { href: "/products", label: "Products" },
      { href: "/quotes", label: "Quote requests", badge: "quotes" },
      { href: "/services", label: "Service requests", badge: "services" },
    ],
  },
  {
    title: "Marketplace",
    items: [
      { href: "/vendors", label: "Vendors", badge: "applications" },
      { href: "/b2b", label: "B2B posts" },
      { href: "/users", label: "Users" },
    ],
  },
  {
    title: "Content",
    items: [
      { href: "/categories", label: "Categories" },
      { href: "/banners", label: "Banners" },
      { href: "/learn", label: "Learn" },
      { href: "/calculator", label: "Calculator" },
      { href: "/settings", label: "Settings" },
    ],
  },
];

function badges(stats: PlatformStats | null): Record<BadgeKey, number> {
  return {
    orders: stats?.orders.placed ?? 0,
    applications: stats?.pendingApplications ?? 0,
    quotes: stats?.newQuotes ?? 0,
    services: stats?.newServiceRequests ?? 0,
  };
}

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [stats, setStats] = useState<PlatformStats | null>(null);

  // Badge counts refresh on every page change (cheap count() queries).
  useEffect(() => {
    getStats()
      .then((r) => setStats(r.data))
      .catch(() => {});
  }, [pathname]);

  const counts = badges(stats);

  return (
    <div className="shell-with-sidebar">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span className="sidebar-brand-mark">S</span>
          Solary
        </div>
        <div className="sidebar-sub">Super admin</div>
        <nav className="sidebar-nav">
          {SECTIONS.map((section, i) => (
            <div key={i}>
              {section.title && <div className="sidebar-section">{section.title}</div>}
              {section.items.map((item) => {
                const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
                const badge = item.badge ? counts[item.badge] : 0;
                return (
                  <Link key={item.href} href={item.href} className={`sidebar-link ${active ? "active" : ""}`}>
                    {item.label}
                    {badge > 0 && <span className="sidebar-count">{badge}</span>}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>
        <button className="btn btn-ghost sidebar-signout" onClick={() => signOut(auth)}>
          Sign out
        </button>
      </aside>
      <main className="shell-main">{children}</main>
    </div>
  );
}
