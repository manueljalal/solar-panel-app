"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.smtpPass = exports.smtpUser = void 0;
exports.sendMail = sendMail;
const params_1 = require("firebase-functions/params");
const nodemailer_1 = __importDefault(require("nodemailer"));
const v2_1 = require("firebase-functions/v2");
// Secret values live in Secret Manager (set via `firebase functions:secrets:set
// SMTP_USER` / `SMTP_PASS`) — never in source, never in an .env file that
// could be committed. Host/port aren't secrets, so they're plain params.
exports.smtpUser = (0, params_1.defineSecret)("SMTP_USER");
exports.smtpPass = (0, params_1.defineSecret)("SMTP_PASS");
const SMTP_HOST = "smtp.zoho.com";
const SMTP_PORT = 587;
const FROM_ADDRESS = "Solary <info@quadcores.com>";
const REPLY_TO = "info@quadcores.com";
// Reused across invocations within the same warm container — nodemailer
// pools connections internally, so re-creating the transporter per call
// would mean a fresh TLS handshake on every email instead of amortizing
// it over a function instance's lifetime.
let cachedTransporter = null;
function getTransporter() {
    if (cachedTransporter)
        return cachedTransporter;
    cachedTransporter = nodemailer_1.default.createTransport({
        host: SMTP_HOST,
        port: SMTP_PORT,
        secure: false, // STARTTLS on 587, not implicit TLS
        auth: { user: exports.smtpUser.value(), pass: exports.smtpPass.value() },
        pool: true,
        maxConnections: 3,
    });
    return cachedTransporter;
}
/// Best-effort send — callers decide whether a failure here should block
/// the caller's own operation (it generally shouldn't: approving/rejecting
/// an application is the important side effect, the email is a courtesy).
async function sendMail(message) {
    try {
        await getTransporter().sendMail({
            from: FROM_ADDRESS,
            replyTo: REPLY_TO,
            to: message.to,
            subject: message.subject,
            text: message.text,
            html: message.html,
        });
    }
    catch (err) {
        // Don't let a flaky SMTP provider fail an admin action or leak
        // recipient addresses into error responses sent back to the client.
        v2_1.logger.error("sendMail failed", { err: err instanceof Error ? err.message : String(err) });
    }
}
