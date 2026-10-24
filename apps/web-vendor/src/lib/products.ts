export interface Localized {
  ku: string;
  ar: string;
  en: string;
}

export const EMPTY_LOCALIZED: Localized = { ku: "", ar: "", en: "" };

export interface Category {
  id: string;
  name: { ku: string; ar: string; en: string };
}

export interface VendorProduct {
  id: string;
  /** Slug of a document in the admin-managed `categories` collection. */
  category: string;
  brand: string;
  name: string;
  nameI18n: Localized;
  spec: string;
  price: number;
  currency: "USD" | "IQD";
  imageUrl: string;
  description: string | null;
  descriptionI18n: Localized | null;
  warranty: string | null;
  warrantyI18n: Localized | null;
  inStock: boolean;
  rating: number;
  sold: number;
}

export interface ProductFormInput {
  category: string;
  brand: string;
  name: Localized;
  spec: string;
  price: number;
  currency: "USD" | "IQD";
  imageUrl: string;
  description?: Localized;
  warranty?: Localized;
}

export function categoryLabel(category: Category): string {
  return `${category.name.en} · ${category.name.ku} · ${category.name.ar}`;
}

/** Firestore `products` doc -> VendorProduct (fills defaults for old docs). */
function i18n(v: unknown, fallbackEn = ""): VendorProduct["nameI18n"] {
  const o = (v ?? {}) as Record<string, unknown>;
  return { ku: (o.ku as string) ?? "", ar: (o.ar as string) ?? "", en: (o.en as string) ?? fallbackEn };
}

export function productFromDoc(id: string, data: Record<string, unknown>): VendorProduct {
  return {
    id,
    category: (data.category as VendorProduct["category"]) ?? "",
    brand: (data.brand as string) ?? "",
    name: (data.name as string) ?? "",
    nameI18n: i18n(data.nameI18n, (data.name as string) ?? ""),
    spec: (data.spec as string) ?? "",
    price: (data.price as number) ?? 0,
    currency: (data.currency as VendorProduct["currency"]) ?? "USD",
    imageUrl: (data.imageUrl as string) ?? "",
    description: (data.description as string | null) ?? null,
    descriptionI18n: data.descriptionI18n ? i18n(data.descriptionI18n) : null,
    warranty: (data.warranty as string | null) ?? null,
    warrantyI18n: data.warrantyI18n ? i18n(data.warrantyI18n) : null,
    inStock: (data.inStock as boolean) ?? true,
    rating: (data.rating as number) ?? 0,
    sold: (data.sold as number) ?? 0,
  };
}

