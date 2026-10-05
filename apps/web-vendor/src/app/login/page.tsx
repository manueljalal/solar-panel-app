"use client";

import { useEffect, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { httpsCallable } from "firebase/functions";
import { signInWithCustomToken } from "firebase/auth";
import { auth, functions } from "@/lib/firebase";
import { useVendorAuth } from "@/lib/use_auth";

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
const RESEND_COOLDOWN_SECONDS = 30;

const requestPhoneOtp = httpsCallable<{ phone: string }, { ok: true }>(functions, "auth-requestPhoneOtp");
const verifyPhoneOtp = httpsCallable<{ phone: string; otp: string }, { customToken: string }>(
  functions,
  "auth-verifyPhoneOtp",
);
const vendorPasswordSignIn = httpsCallable<{ email: string; password: string }, { customToken: string }>(
  functions,
  "auth-vendorPasswordSignIn",
);

/** Sign-in for already-approved vendors. Two paths: phone + WhatsApp OTP
 * (the original flow, shared with /apply and the mobile app), and email +
 * password (set via the /set-password link in the approval email). Both
 * mint the same kind of custom token and land on the same vendor
 * account — password is a convenience, phone stays the fallback/recovery
 * path since it's the one that's already proven at approval time. */
export default function LoginPage() {
  const state = useVendorAuth();
  const router = useRouter();
  const [mode, setMode] = useState<"phone" | "password">("phone");

  const [step, setStep] = useState<"phone" | "otp">("phone");
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [cooldown, setCooldown] = useState(0);

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (state.status === "signed-in-vendor") router.replace("/dashboard");
  }, [state.status, router]);

  useEffect(() => {
    if (cooldown <= 0) return;
    const id = setInterval(() => setCooldown((s) => s - 1), 1000);
    return () => clearInterval(id);
  }, [cooldown]);

  async function onSendCode(e: FormEvent) {
    e.preventDefault();
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
      const result = await verifyPhoneOtp({ phone: phone.trim(), otp: otp.trim() });
      await signInWithCustomToken(auth, result.data.customToken);
      // useVendorAuth's listener + the effect above redirects once the
      // vendor claim resolves.
    } catch (err) {
      setError((err as { message?: string }).message ?? "Incorrect or expired code.");
      setSubmitting(false);
    }
  }

  async function onPasswordSignIn(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const result = await vendorPasswordSignIn({ email: email.trim(), password });
      await signInWithCustomToken(auth, result.data.customToken);
    } catch (err) {
      setError((err as { message?: string }).message ?? "Incorrect email or password.");
      setSubmitting(false);
    }
  }

  function switchMode(next: "phone" | "password") {
    setMode(next);
    setError(null);
    setStep("phone");
    setOtp("");
  }

  return (
    <div className="content" style={{ maxWidth: 400, paddingTop: 96 }}>
      <div className="card stack">
        <div>
          <div className="brand">Solary</div>
          <p className="muted">Vendor portal</p>
        </div>

        <div className="tabs">
          <button className={`tab ${mode === "phone" ? "active" : ""}`} onClick={() => switchMode("phone")}>
            Phone
          </button>
          <button className={`tab ${mode === "password" ? "active" : ""}`} onClick={() => switchMode("password")}>
            Email &amp; password
          </button>
        </div>

        {mode === "phone" &&
          (step === "phone" ? (
            <form className="stack" onSubmit={onSendCode}>
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
              {state.status === "signed-in-not-vendor" && (
                <p className="error-text">Signed in, but this account isn&apos;t an approved vendor yet.</p>
              )}
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
          ))}

        {mode === "password" && (
          <form className="stack" onSubmit={onPasswordSignIn}>
            <div className="field">
              <label htmlFor="email">Email</label>
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
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            {error && <p className="error-text">{error}</p>}
            {state.status === "signed-in-not-vendor" && (
              <p className="error-text">Signed in, but this account isn&apos;t an approved vendor yet.</p>
            )}
            <button className="btn btn-primary" type="submit" disabled={submitting}>
              {submitting ? "Signing in…" : "Sign in"}
            </button>
            <p className="muted" style={{ fontSize: 12 }}>
              No password yet? Use the link from your approval email, or sign in with your phone number instead.
            </p>
          </form>
        )}

        <p className="muted" style={{ fontSize: 12 }}>
          Don&apos;t have a vendor account yet?{" "}
          <a href="/apply" style={{ textDecoration: "underline" }}>
            Apply here
          </a>
          .
        </p>
      </div>
    </div>
  );
}
