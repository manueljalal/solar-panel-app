// One-time seed script — populates `vendors` and `products` in Firestore
// with the same data currently hardcoded in the Flutter app's
// lib/features/home/domain/{home_company,home_product}.dart, so switching
// the app to live reads is a drop-in swap, not a data rewrite.
//
// Run: node scripts/seed-firestore.mjs
// Uses Application Default Credentials (already set up via `gcloud auth
// application-default login` / `firebase login`) — no service account key
// file needed.

import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const PROJECT_ID = "flutter-firebase-connect-ec83e";

initializeApp({
  credential: applicationDefault(),
  projectId: PROJECT_ID,
});

const db = getFirestore();

const vendors = [
  {
    id: "sunbridge-energy",
    businessName: "SunBridge Energy",
    city: "Erbil",
    status: "approved",
    rating: 4.9,
    reviewCount: 312,
    logoUrl: "https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=400&q=80",
  },
  {
    id: "helios-power-co",
    businessName: "Helios Power Co.",
    city: "Sulaymaniyah",
    status: "approved",
    rating: 4.8,
    reviewCount: 87,
    logoUrl: "https://images.unsplash.com/photo-1497440001374-f26997328c1b?w=400&q=80",
  },
  {
    id: "greentech-iraq",
    businessName: "GreenTech Iraq",
    city: "Basra",
    status: "approved",
    rating: 4.7,
    reviewCount: 54,
    logoUrl: "https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=400&q=80",
  },
];

const products = [
  {
    id: "tiger-neo-450w",
    vendorId: "sunbridge-energy",
    category: "residential",
    brand: "JinkoSolar",
    name: "Tiger Neo Mono Panel",
    spec: "450W",
    wattage: 450,
    price: 189,
    currency: "USD",
    inStock: true,
    rating: 4.9,
    sold: 312,
    warranty: "25-year power output",
    description:
      "High-efficiency N-type monocrystalline panel with a low temperature " +
      "coefficient, built for rooftop residential arrays. Ships with " +
      "mounting hardware compatible with most rail systems.",
    imageUrl: "https://images.unsplash.com/photo-1509391366360-2e959784a276?w=400&q=80",
  },
  {
    id: "luna2000-battery",
    vendorId: "helios-power-co",
    category: "battery",
    brand: "Huawei",
    name: "LUNA2000 Battery Unit",
    spec: "5kWh",
    wattage: null,
    price: 1240,
    currency: "USD",
    inStock: true,
    rating: 4.8,
    sold: 87,
    warranty: "10-year manufacturer",
    description:
      "Modular lithium home battery designed to pair with a residential " +
      "inverter for backup power and time-of-use savings. Wall-mounted, " +
      "stackable up to 3 units for extra capacity.",
    imageUrl: "https://images.unsplash.com/photo-1624397640148-949b1732bb0a?w=400&q=80",
  },
  {
    id: "growatt-hybrid-inverter",
    vendorId: "greentech-iraq",
    category: "inverter",
    brand: "Growatt",
    name: "Hybrid Grid Inverter",
    spec: "6kW",
    wattage: null,
    price: 860,
    currency: "USD",
    inStock: true,
    rating: 4.7,
    sold: 54,
    warranty: "5-year manufacturer",
    description:
      "Hybrid inverter supporting both grid-tied and battery-backed " +
      "operation, with built-in Wi-Fi monitoring and support for two MPPT " +
      "trackers.",
    imageUrl: "https://images.unsplash.com/photo-1592833159155-c62df1b65634?w=400&q=80",
  },
  {
    id: "hiku6-400w",
    vendorId: "sunbridge-energy",
    category: "residential",
    brand: "Canadian Solar",
    name: "HiKu6 Mono Panel",
    spec: "400W",
    wattage: 400,
    price: 164,
    currency: "USD",
    inStock: true,
    rating: 4.6,
    sold: 203,
    warranty: "25-year power output",
    description:
      "Balanced-cost mono panel for larger residential and light-commercial " +
      "arrays, with a reinforced frame rated for higher wind and snow loads.",
    imageUrl: "https://images.unsplash.com/photo-1613665813446-82a78c468a1d?w=400&q=80",
  },
];

async function seed() {
  const batch = db.batch();

  for (const vendor of vendors) {
    const { id, ...data } = vendor;
    batch.set(db.collection("vendors").doc(id), {
      ...data,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  for (const product of products) {
    const { id, ...data } = product;
    batch.set(db.collection("products").doc(id), {
      ...data,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  console.log(`Seeded ${vendors.length} vendors and ${products.length} products.`);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Seed failed:", err);
    process.exit(1);
  });
