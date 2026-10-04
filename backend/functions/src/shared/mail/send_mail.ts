import { defineSecret } from "firebase-functions/params";
import nodemailer, { type Transporter } from "nodemailer";
import { logger } from "firebase-functions/v2";

// Secret values live in Secret Manager (set via `firebase functions:secrets:set
// SMTP_USER` / `SMTP_PASS`) — never in source, never in an .env file that
// could be committed. Host/port aren't secrets, so they're plain params.
export const smtpUser = defineSecret("SMTP_USER");
export const smtpPass = defineSecret("SMTP_PASS");

const SMTP_HOST = "smtp.zoho.com";
const SMTP_PORT = 587;
const FROM_ADDRESS = "Solary <info@quadcores.com>";
const REPLY_TO = "info@quadcores.com";

// Reused across invocations within the same warm container — nodemailer
// pools connections internally, so re-creating the transporter per call
// would mean a fresh TLS handshake on every email instead of amortizing
// it over a function instance's lifetime.
let cachedTransporter: Transporter | null = null;

function getTransporter(): Transporter {
  if (cachedTransporter) return cachedTransporter;
  cachedTransporter = nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: false, // STARTTLS on 587, not implicit TLS
    auth: { user: smtpUser.value(), pass: smtpPass.value() },
    pool: true,
    maxConnections: 3,
  });
  return cachedTransporter;
}

export interface MailMessage {
  to: string;
  subject: string;
  text: string;
  html: string;
}

/// Best-effort send — callers decide whether a failure here should block
/// the caller's own operation (it generally shouldn't: approving/rejecting
/// an application is the important side effect, the email is a courtesy).
export async function sendMail(message: MailMessage): Promise<void> {
  try {
    await getTransporter().sendMail({
      from: FROM_ADDRESS,
      replyTo: REPLY_TO,
      to: message.to,
      subject: message.subject,
      text: message.text,
      html: message.html,
    });
  } catch (err) {
    // Don't let a flaky SMTP provider fail an admin action or leak
    // recipient addresses into error responses sent back to the client.
    logger.error("sendMail failed", { err: err instanceof Error ? err.message : String(err) });
  }
}
