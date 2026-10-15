"use client";

import { useState, type FormEvent } from "react";
import { httpsCallable } from "firebase/functions";
import { signOut } from "firebase/auth";
import { auth, functions } from "@/lib/firebase";
import { useVendorAuth } from "@/lib/use_auth";
import { AuthCard, AuthNotice } from "@/components/auth_card";
import { ImageField } from "@/components/image_field";
import { cleanText, EMAIL_PATTERN } from "@/lib/sanitize";

const submitApplication = httpsCallable<
  { businessName: string; city: string; address: string; email: string; note: string; logoUrl: string; location: null },
  { applicationId: string }
>(functions, "vendor-submitApplication");

/** Vendor onboarding. Applying needs a real account: sign up (username +
 * password, phone verified by WhatsApp OTP) or sign in, then fill in the
 * business form. Approval grants the vendor claim to this same account, so
 * there's no second credential to set up afterwards. */
export default function ApplyPage() {
  const authState = useVendorAuth();
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [businessName, setBusinessName] = useState("");
  const [city, setCity] = useState("");
  const [email, setEmail] = useState("");
  const [note, setNote] = useState("");
  const [logoUrl, setLogoUrl] = useState<string | null>(null);

  async function onSubmitApplication(e: FormEvent) {
    e.preventDefault();
    if (authState.status !== "signed-in-not-vendor") return;
    const cleanName = cleanText(businessName);
    const cleanCity = cleanText(city);
    const cleanEmail = cleanText(email).toLowerCase();
    const cleanNote = cleanText(note, true);
    if (!cleanName || !cleanCity || !cleanEmail) {
      setError("Fill in business name, city, and email.");
      return;
    }
    if (cleanName.length > 120 || cleanCity.length > 80 || cleanNote.length > 1000) {
      setError("One of the fields is too long.");
      return;
    }
    if (!EMAIL_PATTERN.test(cleanEmail) || cleanEmail.length > 254) {
      setError("Enter a valid email address.");
      return;
    }
    if (!logoUrl) {
      setError("Add an image of your company.");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await submitApplication({
        businessName: cleanName,
        city: cleanCity,
        address: "",
        email: cleanEmail,
        note: cleanNote,
        logoUrl,
        location: null,
      });
      setSubmitted(true);
    } catch (err) {
      setError((err as { message?: string }).message ?? "Couldn't submit — check your connection and try again.");
    } finally {
      setSubmitting(false);
    }
  }

  if (submitted) {
    return (
      <AuthNotice>
          <div className="brand">Application submitted</div>
          <p className="muted">
            We&apos;ll review it and follow up on your verified phone number. You can sign in here
            once you&apos;re approved.
          </p>
          <a href="/login" className="btn btn-primary" style={{ alignSelf: "center" }}>
            Back to sign in
          </a>
        </AuthNotice>
    );
  }

  if (authState.status === "signed-in-not-vendor") {
    return (
      <AuthNotice>
          <div>
            <div className="brand">Solary</div>
            <p className="muted">Tell us about your business</p>
          </div>
          <form className="stack" onSubmit={onSubmitApplication}>
            <div className="field">
              <label htmlFor="businessName">Business name</label>
              <input id="businessName" maxLength={120} value={businessName} onChange={(e) => setBusinessName(e.target.value)} required />
            </div>
            <div className="field">
              <label htmlFor="city">City</label>
              <input id="city" maxLength={80} value={city} onChange={(e) => setCity(e.target.value)} required />
            </div>
            <div className="field">
              <label htmlFor="email">Email address</label>
              <input
                id="email"
                type="email"
                autoComplete="email"
                maxLength={254}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <ImageField
              id="logo"
              label="Image of your company (logo or storefront)"
              purpose="company-logo"
              value={logoUrl}
              onChange={setLogoUrl}
              required
            />
            <div className="field">
              <label htmlFor="note">What do you sell? (optional)</label>
              <textarea id="note" rows={3} maxLength={1000} value={note} onChange={(e) => setNote(e.target.value)} />
            </div>
            {error && <p className="error-text">{error}</p>}
            <button className="btn btn-primary" type="submit" disabled={submitting}>
              {submitting ? "Submitting…" : "Submit application"}
            </button>
            <button
              type="button"
              className="btn btn-ghost"
              onClick={() => signOut(auth)}
              style={{ fontSize: 12 }}
            >
              Not you? Sign out
            </button>
          </form>
        </AuthNotice>
    );
  }

  if (authState.status === "signed-in-vendor") {
    return (
      <AuthNotice>
          <p>This account is already an approved vendor.</p>
          <a href="/dashboard" className="btn btn-primary" style={{ alignSelf: "flex-start" }}>
            Go to dashboard
          </a>
        </AuthNotice>
    );
  }

  if (authState.status === "loading") return null;

  return <AuthCard initialView="signup" />;
}
