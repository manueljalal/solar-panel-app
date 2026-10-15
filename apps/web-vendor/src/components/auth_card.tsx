"use client";

import { useEffect, useState, type FormEvent } from "react";
import { httpsCallable } from "firebase/functions";
import { signInWithCustomToken } from "firebase/auth";
import { auth, functions } from "@/lib/firebase";

// Same credential model as the mobile app (see backend/functions/src/auth):
// username + password, phone proven with a WhatsApp OTP at signup, and a
// fresh OTP the first time a new device signs in. Role (customer / vendor /
// super_admin) is a claim granted afterwards — it never changes sign-in.

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;
const USERNAME_PATTERN = /^[a-z0-9_]{3,20}$/;
const RESEND_COOLDOWN_SECONDS = 30;
const DEVICE_KEY = "solary_device_id";

// Mirrors isValidPassword in backend/functions/src/shared/auth/password.ts
// — fast feedback only, the server enforces the real rule.
function isValidPassword(p: string): boolean {
  return p.length >= 8 && /[A-Z]/.test(p) && /[a-z]/.test(p) && /[0-9]/.test(p) && /[^A-Za-z0-9]/.test(p);
}

function getDeviceId(): string {
  try {
    const existing = localStorage.getItem(DEVICE_KEY);
    if (existing) return existing;
    const bytes = crypto.getRandomValues(new Uint8Array(16));
    const id = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
    localStorage.setItem(DEVICE_KEY, id);
    return id;
  } catch {
    // Storage blocked: a per-load id just means every load steps up.
    return crypto.randomUUID().replace(/-/g, "");
  }
}

const requestPhoneOtp = httpsCallable<{ phone: string; deviceId: string }, { ok: true }>(
  functions,
  "auth-requestPhoneOtp",
);
const signUpFn = httpsCallable<Record<string, string>, { customToken: string }>(functions, "auth-signUp");
const signInFn = httpsCallable<{ username: string; password: string; deviceId: string }, { customToken: string }>(
  functions,
  "auth-signIn",
);
const requestResetFn = httpsCallable<{ identifier: string; deviceId: string }, { ok: true }>(
  functions,
  "auth-requestPasswordReset",
);
const resetPasswordFn = httpsCallable<
  { identifier: string; otp: string; newPassword: string; deviceId: string },
  { customToken: string }
>(functions, "auth-resetPassword");
const stepUpFn = httpsCallable<{ username: string; otp: string; deviceId: string }, { customToken: string }>(
  functions,
  "auth-signInOtpStepUp",
);

function message(err: unknown, fallback: string): string {
  return (err as { message?: string }).message || fallback;
}

type View = "signin" | "signup" | "signup-otp" | "stepup-otp" | "reset" | "reset-otp";

const COPY = {
  vendor: {
    headline: "Sell solar, grow your business.",
    sub: "List your products, manage orders and installations, and reach customers across the region.",
    points: ["One account for signing up and applying", "Phone verified once over WhatsApp", "Track orders, payouts and installs"],
  },
  admin: {
    headline: "Run the Solary marketplace.",
    sub: "Review vendor applications, manage categories and users, and keep an eye on the platform.",
    points: ["Role-based super admin access", "New devices verified over WhatsApp", "Every action tied to a named account"],
  },
};

export function AuthCard({
  variant = "vendor",
  allowSignup = true,
  initialView = "signin",
}: {
  variant?: "vendor" | "admin";
  allowSignup?: boolean;
  initialView?: "signin" | "signup";
}) {
  const copy = COPY[variant];
  const [showPassword, setShowPassword] = useState(false);
  const [view, setView] = useState<View>(initialView);
  const [name, setName] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [phone, setPhone] = useState("");
  const [otp, setOtp] = useState("");
  const [cooldown, setCooldown] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (cooldown <= 0) return;
    const id = setInterval(() => setCooldown((s) => s - 1), 1000);
    return () => clearInterval(id);
  }, [cooldown]);

  function go(next: View) {
    setView(next);
    setError(null);
    setOtp("");
  }

  async function sendCode(to: string): Promise<boolean> {
    try {
      await requestPhoneOtp({ phone: to, deviceId: getDeviceId() });
      setCooldown(RESEND_COOLDOWN_SECONDS);
      return true;
    } catch (err) {
      setError(message(err, "Couldn't send a code — try again."));
      return false;
    }
  }

  async function onSignIn(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const res = await signInFn({
        username: username.trim().toLowerCase(),
        password,
        deviceId: getDeviceId(),
      });
      await signInWithCustomToken(auth, res.data.customToken);
    } catch (err) {
      const msg = message(err, "Sign-in failed.");
      if (msg.startsWith("step-up-required:")) {
        // New device: the server put the phone on file in the message.
        const onFile = msg.slice("step-up-required:".length);
        if (await sendCode(onFile)) {
          setPhone(onFile);
          setView("stepup-otp");
        }
      } else {
        setError(msg);
      }
      setSubmitting(false);
    }
  }

  async function onStepUp(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const res = await stepUpFn({
        username: username.trim().toLowerCase(),
        otp: otp.trim(),
        deviceId: getDeviceId(),
      });
      await signInWithCustomToken(auth, res.data.customToken);
    } catch (err) {
      setError(message(err, "Incorrect or expired code."));
      setSubmitting(false);
    }
  }

  // Forgot password: the server texts a code to the phone on file and
  // answers identically whether or not the account exists.
  async function sendResetCode(): Promise<boolean> {
    try {
      await requestResetFn({ identifier: username.trim().toLowerCase(), deviceId: getDeviceId() });
      setCooldown(RESEND_COOLDOWN_SECONDS);
      return true;
    } catch (err) {
      setError(message(err, "Couldn't send a code — try again."));
      return false;
    }
  }

  async function onResetStart(e: FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    if (await sendResetCode()) {
      setPassword(""); // the field now takes the NEW password
      go("reset-otp");
    }
    setSubmitting(false);
  }

  async function onResetFinish(e: FormEvent) {
    e.preventDefault();
    if (!isValidPassword(password)) {
      setError("Password needs 8+ characters with upper and lower case letters, a number and a symbol.");
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const res = await resetPasswordFn({
        identifier: username.trim().toLowerCase(),
        otp: otp.trim(),
        newPassword: password,
        deviceId: getDeviceId(),
      });
      await signInWithCustomToken(auth, res.data.customToken);
    } catch (err) {
      setError(message(err, "Incorrect or expired code."));
      setSubmitting(false);
    }
  }

  async function onSignUpStart(e: FormEvent) {
    e.preventDefault();
    const u = username.trim().toLowerCase();
    if (!name.trim()) return setError("Enter your name.");
    if (!USERNAME_PATTERN.test(u)) {
      return setError("Username: 3-20 characters, lowercase letters, numbers, underscores.");
    }
    if (!E164_PATTERN.test(phone.trim())) {
      return setError("Enter a full number with country code, e.g. +9647501234567.");
    }
    if (!isValidPassword(password)) {
      return setError(
        "Password must be at least 8 characters with an uppercase letter, a lowercase letter, a number, and a symbol.",
      );
    }
    setSubmitting(true);
    setError(null);
    if (await sendCode(phone.trim())) setView("signup-otp");
    setSubmitting(false);
  }

  async function onSignUpFinish(e: FormEvent) {
    e.preventDefault();
    if (otp.trim().length !== 6) return setError("Enter the 6-digit code.");
    setSubmitting(true);
    setError(null);
    try {
      const res = await signUpFn({
        name: name.trim(),
        username: username.trim().toLowerCase(),
        password,
        phone: phone.trim(),
        otp: otp.trim(),
        deviceId: getDeviceId(),
      });
      await signInWithCustomToken(auth, res.data.customToken);
    } catch (err) {
      setError(message(err, "Couldn't create the account."));
      setSubmitting(false);
    }
  }

  const rules = [
    { ok: password.length >= 8, label: "8+ characters" },
    { ok: /[A-Z]/.test(password), label: "Uppercase letter" },
    { ok: /[a-z]/.test(password), label: "Lowercase letter" },
    { ok: /[0-9]/.test(password), label: "A number" },
    { ok: /[^A-Za-z0-9]/.test(password), label: "A symbol" },
  ];

  const busy = (label: string) => (
    <>
      {submitting && <span className="spinner" />}
      {label}
    </>
  );

  const passwordField = (autoComplete: string, showRules: boolean) => (
    <div className="field">
      <label htmlFor="password">Password</label>
      <div className="pw-wrap">
        <input
          id="password"
          type={showPassword ? "text" : "password"}
          autoComplete={autoComplete}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        <button type="button" className="pw-toggle" onClick={() => setShowPassword((v) => !v)}>
          {showPassword ? "Hide" : "Show"}
        </button>
      </div>
      {showRules && (
        <ul className="pw-rules">
          {rules.map((r) => (
            <li key={r.label} className={r.ok ? "ok" : ""}>
              {r.label}
            </li>
          ))}
        </ul>
      )}
    </div>
  );

  const otpField = (
    <div className="field">
      <label htmlFor="otp">6-digit code</label>
      <input
        id="otp"
        className="otp-input"
        inputMode="numeric"
        autoComplete="one-time-code"
        maxLength={6}
        placeholder="······"
        value={otp}
        onChange={(e) => setOtp(e.target.value.replace(/\D/g, ""))}
        autoFocus
        required
      />
    </div>
  );

  const alert = error && (
    <div className="auth-alert" role="alert">
      {error}
    </div>
  );

  const resend = (to: string) =>
    cooldown > 0 ? (
      <span className="muted">Resend code in {cooldown}s</span>
    ) : (
      <button
        type="button"
        className="auth-link"
        disabled={submitting}
        onClick={() => {
          setError(null);
          void sendCode(to);
        }}
      >
        Resend code
      </button>
    );

  const whatsappNote = (
    <div className="auth-info">
      <span aria-hidden>💬</span>
      <span>We sent a 6-digit code on WhatsApp to {phone}. It expires in 5 minutes.</span>
    </div>
  );

  const titles: Record<View, [string, string]> = {
    signin: ["Welcome back", "Sign in with your username (or email) and password."],
    signup: ["Create your account", "Your phone number is verified once, on WhatsApp."],
    "signup-otp": ["Verify your phone", "One last step to finish creating your account."],
    "stepup-otp": ["Confirm it's you", "This is a new device, so we need to verify your phone."],
    reset: ["Reset your password", "We'll send a code to the WhatsApp number on your account."],
    "reset-otp": ["Choose a new password", "If that account exists, we sent a 6-digit code to its WhatsApp."],
  };

  return (
    <div className="auth-page">
      <aside className="auth-aside">
        <div className="auth-logo">
          <span className="auth-logo-mark">
            <Sun />
          </span>
          Solary
        </div>
        <div>
          <h2 className="auth-headline">{copy.headline}</h2>
          <p className="auth-sub">{copy.sub}</p>
          <ul className="auth-points">
            {copy.points.map((p) => (
              <li key={p}>
                <Check />
                {p}
              </li>
            ))}
          </ul>
        </div>
        <div className="auth-foot">Solary, a Quadcores product</div>
      </aside>

      <main className="auth-main">
        <div className="auth-panel">
          <div className="auth-logo auth-mobile-logo">
            <span className="auth-logo-mark">
              <Sun />
            </span>
            Solary
          </div>

          {allowSignup && (view === "signin" || view === "signup") && (
            <div className="auth-seg" role="tablist">
              <button type="button" className={view === "signin" ? "active" : ""} onClick={() => go("signin")}>
                Sign in
              </button>
              <button type="button" className={view === "signup" ? "active" : ""} onClick={() => go("signup")}>
                Sign up
              </button>
            </div>
          )}

          <h1 className="auth-title">{titles[view][0]}</h1>
          <p className="auth-lede">{titles[view][1]}</p>

          {view === "signin" && (
            <form className="auth-form" onSubmit={onSignIn}>
              <div className="field">
                <label htmlFor="username">Username or email</label>
                <input
                  id="username"
                  autoComplete="username"
                  autoCapitalize="none"
                  spellCheck={false}
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  required
                />
              </div>
              {passwordField("current-password", false)}
              {alert}
              <button className="btn btn-primary" type="submit" disabled={submitting}>
                {busy(submitting ? "Signing in…" : "Sign in")}
              </button>
              <div className="auth-row">
                <button type="button" className="auth-link" onClick={() => go("reset")}>
                  Forgot password?
                </button>
              </div>
            </form>
          )}

          {view === "reset" && (
            <form className="auth-form" onSubmit={onResetStart}>
              <div className="field">
                <label htmlFor="reset-username">Username or email</label>
                <input
                  id="reset-username"
                  autoComplete="username"
                  autoCapitalize="none"
                  spellCheck={false}
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  required
                />
              </div>
              {alert}
              <button className="btn btn-primary" type="submit" disabled={submitting}>
                {busy(submitting ? "Sending code…" : "Send code")}
              </button>
              <div className="auth-row">
                <button type="button" className="auth-link" onClick={() => go("signin")}>
                  Back to sign in
                </button>
              </div>
            </form>
          )}

          {view === "reset-otp" && (
            <form className="auth-form" onSubmit={onResetFinish}>
              {otpField}
              {passwordField("new-password", true)}
              {alert}
              <button className="btn btn-primary" type="submit" disabled={submitting}>
                {busy(submitting ? "Saving…" : "Set password and sign in")}
              </button>
              <div className="auth-row">
                <button type="button" className="auth-link" onClick={() => go("signin")}>
                  Back to sign in
                </button>
                <button
                  type="button"
                  className="auth-link"
                  disabled={cooldown > 0 || submitting}
                  onClick={() => {
                    setError(null);
                    sendResetCode();
                  }}
                >
                  {cooldown > 0 ? `Resend in ${cooldown}s` : "Resend code"}
                </button>
              </div>
            </form>
          )}

          {view === "stepup-otp" && (
            <form className="auth-form" onSubmit={onStepUp}>
              {whatsappNote}
              {otpField}
              {alert}
              <button className="btn btn-primary" type="submit" disabled={submitting}>
                {busy(submitting ? "Verifying…" : "Verify and sign in")}
              </button>
              <div className="auth-row">
                <button type="button" className="auth-link" onClick={() => go("signin")}>
                  Back to sign in
                </button>
                {resend(phone)}
              </div>
            </form>
          )}

          {view === "signup" && (
            <form className="auth-form" onSubmit={onSignUpStart}>
              <div className="field">
                <label htmlFor="name">Full name</label>
                <input id="name" autoComplete="name" value={name} onChange={(e) => setName(e.target.value)} required />
              </div>
              <div className="field">
                <label htmlFor="username">Username</label>
                <input
                  id="username"
                  autoComplete="username"
                  autoCapitalize="none"
                  spellCheck={false}
                  placeholder="lowercase, numbers, _"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  required
                />
              </div>
              <div className="field">
                <label htmlFor="phone">WhatsApp number</label>
                <input
                  id="phone"
                  type="tel"
                  placeholder="+9647501234567"
                  autoComplete="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  required
                />
              </div>
              {passwordField("new-password", true)}
              {alert}
              <button className="btn btn-primary" type="submit" disabled={submitting}>
                {busy(submitting ? "Sending code…" : "Continue")}
              </button>
            </form>
          )}

          {view === "signup-otp" && (
            <form className="auth-form" onSubmit={onSignUpFinish}>
              {whatsappNote}
              {otpField}
              {alert}
              <button className="btn btn-primary" type="submit" disabled={submitting}>
                {busy(submitting ? "Creating account…" : "Create account")}
              </button>
              <div className="auth-row">
                <button type="button" className="auth-link" onClick={() => go("signup")}>
                  Edit details
                </button>
                {resend(phone.trim())}
              </div>
            </form>
          )}
        </div>
      </main>
    </div>
  );
}

function Sun() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
    </svg>
  );
}

function Check() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 6 9 17l-5-5" />
    </svg>
  );
}

/** Centered card for the non-form states that live inside the auth look
 * (e.g. "signed in but not approved yet"). */
export function AuthNotice({ children }: { children: React.ReactNode }) {
  return (
    <div className="auth-page" style={{ gridTemplateColumns: "1fr" }}>
      <main className="auth-main" style={{ background: "var(--surface-sunken)", alignItems: "center" }}>
        <div className="card stack" style={{ maxWidth: 420, width: "100%", padding: 28 }}>
          {children}
        </div>
      </main>
    </div>
  );
}
