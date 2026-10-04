"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";
import { PRODUCT_CATEGORIES, categoryLabel, type ProductFormInput, type VendorProduct } from "@/lib/products";

const createProduct = httpsCallable<ProductFormInput, { productId: string }>(functions, "vendor-createProduct");
const updateProduct = httpsCallable<{ productId: string; patch: Partial<ProductFormInput> }, { ok: true }>(
  functions,
  "vendor-updateProduct",
);

function friendlyError(e: unknown): string {
  const message = e instanceof Error ? e.message : String(e);
  if (message.includes("permission-denied")) return "You don't have permission to do that.";
  if (message.includes("invalid-argument")) return "Check the values and try again.";
  return "Check your connection and try again.";
}

export function ProductForm({ editing }: { editing?: VendorProduct }) {
  const router = useRouter();
  const isEditing = Boolean(editing);
  const [category, setCategory] = useState<ProductFormInput["category"]>(editing?.category ?? "residential");
  const [brand, setBrand] = useState(editing?.brand ?? "");
  const [name, setName] = useState(editing?.name ?? "");
  const [spec, setSpec] = useState(editing?.spec ?? "");
  const [price, setPrice] = useState(editing ? String(editing.price) : "");
  const [currency, setCurrency] = useState<ProductFormInput["currency"]>(editing?.currency ?? "USD");
  const [imageUrl, setImageUrl] = useState(editing?.imageUrl ?? "");
  const [warranty, setWarranty] = useState(editing?.warranty ?? "");
  const [description, setDescription] = useState(editing?.description ?? "");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    const priceNumber = Number(price);
    if (!brand.trim() || !name.trim() || !Number.isFinite(priceNumber) || priceNumber <= 0) {
      setError("Fill in brand, product name, and a valid price.");
      setSubmitting(false);
      return;
    }

    try {
      if (!editing) {
        await createProduct({
          category,
          brand: brand.trim(),
          name: name.trim(),
          spec: spec.trim(),
          price: priceNumber,
          currency,
          imageUrl: imageUrl.trim(),
          description: description.trim() || undefined,
          warranty: warranty.trim() || undefined,
        });
      } else {
        await updateProduct({
          productId: editing.id,
          patch: {
            brand: brand.trim(),
            name: name.trim(),
            spec: spec.trim(),
            price: priceNumber,
            currency,
            imageUrl: imageUrl.trim(),
            description: description.trim() || undefined,
            warranty: warranty.trim() || undefined,
          },
        });
      }
      router.replace("/dashboard");
    } catch (err) {
      setError(friendlyError(err));
      setSubmitting(false);
    }
  }

  return (
    <form className="stack" onSubmit={onSubmit}>
      <div className="field">
        <label htmlFor="category">Category</label>
        <select id="category" value={category} onChange={(e) => setCategory(e.target.value as ProductFormInput["category"])}>
          {PRODUCT_CATEGORIES.map((c) => (
            <option key={c} value={c}>
              {categoryLabel(c)}
            </option>
          ))}
        </select>
      </div>
      <div className="field">
        <label htmlFor="brand">Brand</label>
        <input id="brand" value={brand} onChange={(e) => setBrand(e.target.value)} required />
      </div>
      <div className="field">
        <label htmlFor="name">Product name</label>
        <input id="name" value={name} onChange={(e) => setName(e.target.value)} required />
      </div>
      <div className="field">
        <label htmlFor="spec">Spec (e.g. 450W, 5kWh)</label>
        <input id="spec" value={spec} onChange={(e) => setSpec(e.target.value)} />
      </div>
      <div className="field-row">
        <div className="field">
          <label htmlFor="price">Price</label>
          <input
            id="price"
            type="number"
            min="0"
            step="0.01"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            required
          />
        </div>
        <div className="field">
          <label htmlFor="currency">Currency</label>
          <select id="currency" value={currency} onChange={(e) => setCurrency(e.target.value as ProductFormInput["currency"])}>
            <option value="USD">USD</option>
            <option value="IQD">IQD</option>
          </select>
        </div>
      </div>
      <div className="field">
        <label htmlFor="imageUrl">Image URL</label>
        <input id="imageUrl" value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="warranty">Warranty (optional)</label>
        <input id="warranty" value={warranty} onChange={(e) => setWarranty(e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="description">Description (optional)</label>
        <textarea id="description" rows={3} value={description} onChange={(e) => setDescription(e.target.value)} />
      </div>
      {error && <p className="error-text">{error}</p>}
      <button className="btn btn-primary" type="submit" disabled={submitting}>
        {submitting ? "Saving…" : isEditing ? "Save changes" : "Publish product"}
      </button>
    </form>
  );
}
