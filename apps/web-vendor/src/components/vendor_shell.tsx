"use client";

import { useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useVendorAuth } from "@/lib/use_auth";

const NAV = [
  { href: "/dashboard", label: "Products" },
  { href: "/orders", label: "Orders" },
  { href: "/quotes", label: "Quote requests" },
  { href: "/profile", label: "Business profile" },
];

/** Signed-in vendor page frame: top bar, section nav, and a redirect to
 * /login for anyone who isn't an approved vendor. Children get the
 * caller's vendorId. */
export function VendorShell({ children }: { children: (vendorId: string) => React.ReactNode }) {
  const authState = useVendorAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (authState.status === "signed-out" || authState.status === "signed-in-not-vendor") {
      router.replace("/login");
    }
  }, [authState.status, router]);

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
      <nav className="section-nav" aria-label="Sections">
        {NAV.map((item) => (
          <Link key={item.href} href={item.href} className={`tab ${pathname === item.href ? "active" : ""}`}>
            {item.label}
          </Link>
        ))}
      </nav>
      <div className="content">{children(authState.vendorId)}</div>
    </div>
  );
}
