"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";

const NAV_ITEMS = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/vendors", label: "Vendors" },
  { href: "/orders", label: "Orders" },
  { href: "/users", label: "Users" },
  { href: "/categories", label: "Categories" },
  { href: "/disputes", label: "Disputes" },
  { href: "/analytics", label: "Analytics" },
  { href: "/settings", label: "Settings" },
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <div className="shell shell-with-sidebar">
      <aside className="sidebar">
        <div className="sidebar-brand">Solary</div>
        <nav className="sidebar-nav">
          {NAV_ITEMS.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`sidebar-link ${pathname === item.href ? "active" : ""}`}
            >
              {item.label}
            </Link>
          ))}
        </nav>
        <button className="btn btn-ghost sidebar-signout" onClick={() => signOut(auth)}>
          Sign out
        </button>
      </aside>
      <div className="shell-main">{children}</div>
    </div>
  );
}
