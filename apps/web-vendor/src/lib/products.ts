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
