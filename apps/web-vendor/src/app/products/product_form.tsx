"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { httpsCallable } from "firebase/functions";
import { functions } from "@/lib/firebase";
import { categoryLabel, EMPTY_LOCALIZED, type Localized, type ProductFormInput, type VendorProduct } from "@/lib/products";
import { useCategories } from "@/lib/categories";
import { LocalizedField } from "@/components/localized_field";
import { ImageField } from "@/components/image_field";
import { cleanText } from "@/lib/sanitize";

const createProduct = httpsCallable<ProductFormInput, { productId: string }>(functions, "vendor-createProduct");
const updateProduct = httpsCallable<{ productId: string; patch: Partial<Omit<ProductFormInput, "description" | "warranty">> & { description?: Localized | null; warranty?: Localized | null } }, { ok: true }>(
  functions,
  "vendor-updateProduct",
);

function friendlyError(e: unknown): string {
  // Callable errors carry a Firebase `code` ("functions/invalid-argument") and
  // a server-written, user-readable `message` — show it for validation errors.
  const { code, message } = e as { code?: string; message?: string };
  if (code === "functions/permission-denied") return "You don't have permission to do that.";
  if (code === "functions/unauthenticated") return "Sign in again and retry.";
  if (code === "functions/invalid-argument" && message) return message;
  if (code === "functions/not-found") return "That product no longer exists.";
  return "Couldn't save — check your connection and try again.";
}

export function ProductForm({ editing }: { editing?: VendorProduct }) {
  const router = useRouter();
  const isEditing = Boolean(editing);
  const { categories, error: categoriesError } = useCategories();
  const [category, setCategory] = useState<string>(editing?.category ?? "");
  const [brand, setBrand] = useState(editing?.brand ?? "");
  const [name, setName] = useState<Localized>(editing?.nameI18n ?? EMPTY_LOCALIZED);
  const [spec, setSpec] = useState(editing?.spec ?? "");
  const [price, setPrice] = useState(editing ? String(editing.price) : "");
  const [currency, setCurrency] = useState<ProductFormInput["currency"]>(editing?.currency ?? "USD");
  const [imageUrl, setImageUrl] = useState<string | null>(editing?.imageUrl || null);
  const [warranty, setWarranty] = useState<Localized>(editing?.warrantyI18n ?? EMPTY_LOCALIZED);
  const [description, setDescription] = useState<Localized>(editing?.descriptionI18n ?? EMPTY_LOCALIZED);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    const priceNumber = Math.round(Number(price) * 100) / 100;
    const cleanL = (v: Localized, multiline = false): Localized => ({
      ku: cleanText(v.ku, multiline),
      ar: cleanText(v.ar, multiline),
      en: cleanText(v.en, multiline),
    });
    const clean = {
      brand: cleanText(brand),
      name: cleanL(name),
      spec: cleanText(spec),
      warranty: cleanL(warranty),
      description: cleanL(description, true),
    };
    const filled = (v: Localized) => [v.ku, v.ar, v.en].filter(Boolean).length;
    // Optional fields: all three languages or none.
    const optionalOrNull = (v: Localized) => (filled(v) === 3 ? v : null);
    if (!category) {
      setError("Choose a category.");
      setSubmitting(false);
      return;
    }
    if (filled(clean.name) !== 3) {
      setError("Enter the product name in Kurdish, Arabic and English.");
      setSubmitting(false);
      return;
    }
    if ((filled(clean.warranty) | 0) % 3 !== 0 || (filled(clean.description) | 0) % 3 !== 0) {
      setError("Warranty and description need all three languages, or leave all three empty.");
      setSubmitting(false);
      return;
    }
    if (!clean.brand || !Number.isFinite(priceNumber) || priceNumber <= 0) {
      setError("Fill in brand, product name, and a valid price.");
      setSubmitting(false);
      return;
    }
    if (!imageUrl) {
      setError("Add a product image.");
      setSubmitting(false);
      return;
    }

    try {
      if (!editing) {
        await createProduct({
          category,
          brand: clean.brand,
          name: clean.name,
          spec: clean.spec,
          price: priceNumber,
          currency,
          imageUrl,
          description: optionalOrNull(clean.description) ?? undefined,
          warranty: optionalOrNull(clean.warranty) ?? undefined,
        });
      } else {
        await updateProduct({
          productId: editing.id,
          patch: {
            category,
            brand: clean.brand,
            name: clean.name,
            spec: clean.spec,
            price: priceNumber,
            currency,
            imageUrl,
            description: optionalOrNull(clean.description),
            warranty: optionalOrNull(clean.warranty),
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
        <select id="category" value={category} onChange={(e) => setCategory(e.target.value)} required>
          <option value="" disabled>
            {categories === null ? "Loading categories…" : "Choose a category"}
          </option>
          {categories?.map((c) => (
            <option key={c.id} value={c.id}>
              {categoryLabel(c)}
            </option>
          ))}
          {/* Keep a legacy/removed category selectable while editing so it isn't silently changed. */}
          {category && categories && !categories.some((c) => c.id === category) && (
            <option value={category}>{category}</option>
          )}
        </select>
        {categoriesError && <p className="error-text">Couldn&apos;t load categories.</p>}
        {categories?.length === 0 && <p className="muted">No categories yet — ask the platform admin to add some.</p>}
      </div>
      <div className="field">
        <label htmlFor="brand">Brand</label>
        <input id="brand" maxLength={80} value={brand} onChange={(e) => setBrand(e.target.value)} required />
      </div>
      <LocalizedField id="name" label="Product name" value={name} onChange={setName} maxLength={120} required />
      <div className="field">
        <label htmlFor="spec">Spec (e.g. 450W, 5kWh)</label>
        <input id="spec" maxLength={120} value={spec} onChange={(e) => setSpec(e.target.value)} />
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
      <ImageField id="image" label="Product image" purpose="product" value={imageUrl} onChange={setImageUrl} required />
      <LocalizedField id="warranty" label="Warranty (optional)" value={warranty} onChange={setWarranty} maxLength={120} />
      <LocalizedField
        id="description"
        label="Description (optional)"
        value={description}
        onChange={setDescription}
        maxLength={2000}
        multiline
      />
      {error && <p className="error-text">{error}</p>}
      <button className="btn btn-primary" type="submit" disabled={submitting}>
        {submitting ? "Saving…" : isEditing ? "Save changes" : "Publish product"}
      </button>
    </form>
  );
}
