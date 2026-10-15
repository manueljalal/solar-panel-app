"use client";

import { useEffect, useState } from "react";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { Category } from "@/lib/products";

/** Live list of admin-managed categories, sorted by English name.
 * null while loading; `error` is set if the read fails. */
export function useCategories(): { categories: Category[] | null; error: boolean } {
  const [categories, setCategories] = useState<Category[] | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    return onSnapshot(
      collection(db, "categories"),
      (snap) => {
        const rows = snap.docs.map((d) => {
          const n = d.data().name ?? {};
          return { id: d.id, name: { ku: n.ku ?? "", ar: n.ar ?? "", en: n.en ?? "" } };
        });
        rows.sort((a, b) => a.name.en.localeCompare(b.name.en));
        setCategories(rows);
      },
      () => setError(true),
    );
  }, []);

  return { categories, error };
}
