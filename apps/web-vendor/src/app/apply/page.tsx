"use client";

import { useEffect, useState, type FormEvent } from "react";
import { httpsCallable, type HttpsCallableResult } from "firebase/functions";
import { signInWithCustomToken, signOut } from "firebase/auth";
import { auth, functions } from "@/lib/firebase";
import { useVendorAuth } from "@/lib/use_auth";

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
const RESEND_COOLDOWN_SECONDS = 30;

const requestPhoneOtp = httpsCallable<{ phone: string }, { ok: true; expiresInSeconds: number }>(
  functions,
  "auth-requestPhoneOtp",
);
const verifyPhoneOtp = httpsCallable<
  { phone: string; otp: string; name?: string },
  { customToken: string; isNewUser: boolean }
>(functions, "auth-verifyPhoneOtp");
const submitApplication = httpsCallable<
  { businessName: string; city: string; address: string; phone: string; email: string; note: string; location: null },
  { applicationId: string }
>(functions, "vendor-submitApplication");

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Vendor onboarding, reachable without an existing account — the web
 * portal's equivalent of the mobile app's "Own a solar business? Apply"
 * card. Phone + WhatsApp OTP verification comes first (the same
 * auth-requestPhoneOtp/verifyPhoneOtp Cloud Functions the mobile app
 * uses — phone verification is the only real identity check in this
 * system, see auth_repository.dart's class doc), then the application
 * form writes to vendorApplications the same way the mobile app does. */
export default function ApplyPage() {
  const authState = useVendorAuth();
  const [step, setStep] = useState<"phone" | "otp" | "form" | "submitted">("phone");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [cooldown, setCooldown] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [businessName, setBusinessName] = useState("");
  const [city, setCity] = useState("");
  const [applyPhone, setApplyPhone] = useState("");
  const [email, setEmail] = useState("");
  const [note, setNote] = useState("");

  useEffect(() => {
    if (authState.status === "signed-in-not-vendor" && step === "phone") {
      setStep("form");
      setApplyPhone(phone);
    }
  }, [authState.status, step, phone]);

  useEffect(() => {
    if (cooldown <= 0) return;
    const id = setInterval(() => setCooldown((s) => s - 1), 1000);
    return () => clearInterval(id);
  }, [cooldown]);

  async function onSendCode(e: FormEvent) {
    e.preventDefault();
    if (!name.trim()) {
      setError("Enter your name.");
      return;
    }
    if (!E164_PATTERN.test(phone.trim())) {
      setError("Enter a full number with country code, e.g. +9647501234567.");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await requestPhoneOtp({ phone: phone.trim() });
      setStep("otp");
      setCooldown(RESEND_COOLDOWN_SECONDS);
    } catch (err) {
      setError((err as { message?: string }).message ?? "Couldn't send a code — try again.");
    } finally {
      setSubmitting(false);
    }
  }

  async function onResend() {
    setSubmitting(true);
    setError(null);
    try {
      await requestPhoneOtp({ phone: phone.trim() });
      setCooldown(RESEND_COOLDOWN_SECONDS);
    } catch (err) {
      setError((err as { message?: string }).message ?? "Couldn't send a code — try again.");
    } finally {
      setSubmitting(false);
    }
  }

  async function onVerify(e: FormEvent) {
    e.preventDefault();
    if (otp.trim().length !== 6) {
      setError("Enter the 6-digit code.");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const result: HttpsCallableResult<{ customToken: string; isNewUser: boolean }> = await verifyPhoneOtp({
        phone: phone.trim(),
        otp: otp.trim(),
        name: name.trim(),
      });
      await signInWithCustomToken(auth, result.data.customToken);
      // useVendorAuth's listener + the effect above moves to "form" once
      // the signed-in, non-vendor state resolves.
    } catch (err) {
      setError((err as { message?: string }).message ?? "Incorrect or expired code.");
    } finally {
      setSubmitting(false);
    }
  }

  async function onSubmitApplication(e: FormEvent) {
    e.preventDefault();
    if (authState.status !== "signed-in-not-vendor") return;
    if (!businessName.trim() || !city.trim() || !applyPhone.trim() || !email.trim()) {
      setError("Fill in business name, city, phone number, and email.");
      return;
    }
    if (!EMAIL_PATTERN.test(email.trim())) {
      setError("Enter a valid email address.");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      await submitApplication({
        businessName: businessName.trim(),
        city: city.trim(),
        address: "",
        phone: applyPhone.trim(),
        email: email.trim(),
        note: note.trim(),
        location: null,
      });
      setStep("submitted");
    } catch {
      setError("Couldn't submit — check your connection and try again.");
    } finally {
      setSubmitting(false);
    }
  }

  if (step === "submitted") {
    return (
      <div className="content" style={{ maxWidth: 440, paddingTop: 96 }}>
        <div className="card stack" style={{ textAlign: "center" }}>
          <div className="brand">Application submitted</div>
          <p className="muted">
            We&apos;ll review it and follow up on the phone number you provided. You can sign in here
            once you&apos;re approved.
          </p>
          <a href="/login" className="btn btn-primary" style={{ alignSelf: "center" }}>
            Back to sign in
          </a>
        </div>
      </div>
    );
  }

  if (step === "form" && authState.status === "signed-in-not-vendor") {
    return (
      <div className="content" style={{ maxWidth: 440, paddingTop: 64 }}>
        <div className="card stack">
          <div>
            <div className="brand">Solary</div>
            <p className="muted">Tell us about your business</p>
          </div>
          <form className="stack" onSubmit={onSubmitApplication}>
            <div className="field">
              <label htmlFor="businessName">Business name</label>
              <input id="businessName" value={businessName} onChange={(e) => setBusinessName(e.target.value)} required />
            </div>
            <div className="field">
              <label htmlFor="city">City</label>
              <input id="city" value={city} onChange={(e) => setCity(e.target.value)} required />
            </div>
            <div className="field">
              <label htmlFor="applyPhone">Phone number</label>
              <input
                id="applyPhone"
                type="tel"
                value={applyPhone}
                onChange={(e) => setApplyPhone(e.target.value)}
                required
              />
            </div>
            <div className="field">
              <label htmlFor="email">Email address</label>
              <input
                id="email"
                type="email"
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="field">
              <label htmlFor="note">What do you sell? (optional)</label>
              <textarea id="note" rows={3} value={note} onChange={(e) => setNote(e.target.value)} />
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
              Not you? Use a different number
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="content" style={{ maxWidth: 400, paddingTop: 96 }}>
      <div className="card stack">
        <div>
          <div className="brand">Solary</div>
          <p className="muted">Own a solar business? Apply here.</p>
        </div>

        {step === "phone" ? (
          <form className="stack" onSubmit={onSendCode}>
            <p className="muted" style={{ fontSize: 12.5 }}>
              First, verify your phone number — we&apos;ll send a 6-digit code to it.
            </p>
            <div className="field">
              <label htmlFor="name">Your name</label>
              <input id="name" value={name} onChange={(e) => setName(e.target.value)} required />
            </div>
            <div className="field">
              <label htmlFor="phone">Phone number</label>
              <input
                id="phone"
                type="tel"
                placeholder="+9647501234567"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                required
              />
            </div>
            {error && <p className="error-text">{error}</p>}
            <button className="btn btn-primary" type="submit" disabled={submitting}>
              {submitting ? "Sending…" : "Send code"}
            </button>
          </form>
        ) : (
          <form className="stack" onSubmit={onVerify}>
            <p className="muted" style={{ fontSize: 12.5 }}>
              Enter the code sent to {phone}.
            </p>
            <div className="field">
              <label htmlFor="otp">6-digit code</label>
              <input
                id="otp"
                inputMode="numeric"
                maxLength={6}
                value={otp}
                onChange={(e) => setOtp(e.target.value)}
                required
              />
            </div>
            {error && <p className="error-text">{error}</p>}
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
              <button
                type="button"
                className="btn btn-ghost"
                disabled={submitting}
                onClick={() => {
                  setStep("phone");
                  setOtp("");
                  setError(null);
                }}
              >
                Use a different number
              </button>
              {cooldown > 0 ? (
                <span className="muted">Resend code in {cooldown}s</span>
              ) : (
                <button type="button" className="btn btn-ghost" disabled={submitting} onClick={onResend}>
                  Resend code
                </button>
              )}
            </div>
            <button className="btn btn-primary" type="submit" disabled={submitting}>
              {submitting ? "Verifying…" : "Verify code"}
            </button>
          </form>
        )}

        <p className="muted" style={{ fontSize: 12 }}>
          Already approved? <a href="/login" style={{ textDecoration: "underline" }}>Sign in</a>
        </p>
      </div>
    </div>
  );
}
