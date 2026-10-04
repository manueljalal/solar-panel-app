export const PRODUCT_CATEGORIES = ["residential", "commercial", "battery", "inverter"] as const;
export type ProductCategory = (typeof PRODUCT_CATEGORIES)[number];

export interface VendorProduct {
  id: string;
  category: ProductCategory;
  brand: string;
  name: string;
  spec: string;
  price: number;
  currency: "USD" | "IQD";
  imageUrl: string;
  description: string | null;
  warranty: string | null;
  inStock: boolean;
  rating: number;
  sold: number;
}

export interface ProductFormInput {
  category: ProductCategory;
  brand: string;
  name: string;
  spec: string;
  price: number;
  currency: "USD" | "IQD";
  imageUrl: string;
  description?: string;
  warranty?: string;
}

export function categoryLabel(category: string): string {
  switch (category) {
    case "residential":
      return "Residential";
    case "commercial":
      return "Commercial";
    case "battery":
      return "Battery";
    case "inverter":
      return "Inverter";
    default:
      return category;
  }
}
