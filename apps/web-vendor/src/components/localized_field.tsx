"use client";

import type { Localized } from "@/lib/products";

/** Three inputs — Kurdish, Arabic, English — for one piece of text.
 * Kurdish and Arabic are laid out right-to-left. */
export function LocalizedField({
  id,
  label,
  value,
  onChange,
  maxLength,
  multiline,
  required,
}: {
  id: string;
  label: string;
  value: Localized;
  onChange: (next: Localized) => void;
  maxLength: number;
  multiline?: boolean;
  required?: boolean;
}) {
  const langs = [
    { key: "ku", name: "Kurdish (کوردی)", dir: "rtl", lang: "ckb" },
    { key: "ar", name: "Arabic (العربية)", dir: "rtl", lang: "ar" },
    { key: "en", name: "English", dir: "ltr", lang: "en" },
  ] as const;

  return (
    <fieldset style={{ border: 0, padding: 0, margin: 0 }} className="stack">
      <legend style={{ fontSize: 13, fontWeight: 600, color: "var(--ink-600)", marginBottom: 6 }}>{label}</legend>
      {langs.map((l) => {
        const common = {
          id: `${id}-${l.key}`,
          dir: l.dir,
          lang: l.lang,
          maxLength,
          required,
          value: value[l.key],
          placeholder: l.name,
          "aria-label": `${label} — ${l.name}`,
        };
        return (
          <div className="field" key={l.key}>
            {multiline ? (
              <textarea rows={3} {...common} onChange={(e) => onChange({ ...value, [l.key]: e.target.value })} />
            ) : (
              <input {...common} onChange={(e) => onChange({ ...value, [l.key]: e.target.value })} />
            )}
          </div>
        );
      })}
    </fieldset>
  );
}
