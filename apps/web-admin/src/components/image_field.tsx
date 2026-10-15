"use client";

import { useEffect, useRef, useState } from "react";
import { prepareImage, uploadImage, type UploadPurpose } from "@/lib/images";

/** File picker that validates, re-encodes and uploads the chosen image
 * immediately, then reports the stored URL via onChange (null while
 * empty/failed). Existing images (editing) are passed as `value`. */
export function ImageField({
  id,
  label,
  purpose,
  value,
  onChange,
  required,
  aspect,
}: {
  id: string;
  label: string;
  purpose: UploadPurpose;
  value: string | null;
  onChange: (url: string | null) => void;
  required?: boolean;
  /** Centre-crop uploads to this width/height ratio. */
  aspect?: number;
}) {
  const [preview, setPreview] = useState<string | null>(value);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const objectUrl = useRef<string | null>(null);

  useEffect(() => () => {
    if (objectUrl.current) URL.revokeObjectURL(objectUrl.current);
  }, []);

  async function onPick(file: File | undefined) {
    if (!file) return;
    setBusy(true);
    setError(null);
    try {
      const blob = await prepareImage(file, aspect);
      if (objectUrl.current) URL.revokeObjectURL(objectUrl.current);
      objectUrl.current = URL.createObjectURL(blob);
      setPreview(objectUrl.current);
      onChange(await uploadImage(blob, purpose));
    } catch (err) {
      onChange(null);
      setPreview(null);
      const message = (err as { message?: string }).message ?? "";
      setError(
        message.includes("permission-denied") || message.includes("unauthenticated")
          ? "Sign in again to upload."
          : message && !message.toLowerCase().includes("internal") && !message.includes("functions/")
            ? message
            : "Couldn't upload the image — try again.",
      );
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      {preview && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={preview}
          alt=""
          style={{ width: aspect ? 120 * aspect : 120, height: 120, objectFit: "cover", borderRadius: 10, border: "1px solid var(--line)" }}
        />
      )}
      <input
        id={id}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        disabled={busy}
        // Required only until an image has actually been stored.
        required={required && !value}
        onChange={(e) => {
          onPick(e.target.files?.[0]);
          e.target.value = "";
        }}
      />
      {busy && <span className="muted">Uploading…</span>}
      {error && <p className="error-text">{error}</p>}
    </div>
  );
}
