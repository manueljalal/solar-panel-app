export type ProductCategory = "residential" | "commercial" | "battery" | "inverter";

export interface Product {
  id: string;
  vendorId: string;
  category: ProductCategory;
  brand: string;
  name: string;
  wattage?: number;
  price: number;
  currency: "USD" | "IQD";
  inStock: boolean;
  images: string[];
}
