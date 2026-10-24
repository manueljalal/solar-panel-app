"use client";

import Link from "next/link";
import { VendorShell } from "@/components/vendor_shell";
import { ProductForm } from "../product_form";

export default function NewProductPage() {
  return (
    <VendorShell>
      <div style={{ maxWidth: 560 }}>
        <div className="page-header">
          <div>
            <h1 className="page-title">Add product</h1>
            <p className="page-sub">
              <Link className="link" href="/products">← Back to products</Link>
            </p>
          </div>
        </div>
        <div className="panel">
          <ProductForm />
        </div>
      </div>
    </VendorShell>
  );
}
