import { defineSecret } from "firebase-functions/params";

// Secret value lives in Secret Manager (set via `firebase functions:secrets:set
// WHATSAPP_ACCESS_TOKEN`) — never in source, never in an .env file that
// could be committed. Non-secret config (phone number id) is a plain
// param, fine to keep alongside code.
export const whatsappAccessToken = defineSecret("WHATSAPP_ACCESS_TOKEN");

// Meta Business Cloud API phone number id for the sending number —
// identifier, not a bearer credential, so it's fine as a literal here
// rather than a second secret. Rotate by editing this constant if the
// sending number ever changes.
const WHATSAPP_PHONE_NUMBER_ID = "981766051693209";

/// Sends a 6-digit OTP via WhatsApp using a pre-approved message template
/// (Meta requires approved templates for business-initiated conversations
/// outside a 24h customer-service window — this mirrors the same
/// `auth_otp` template pattern already in production use, not a new
/// template that would need separate Meta approval).
export async function sendWhatsAppOtp(phone: string, otp: string): Promise<void> {
  const token = whatsappAccessToken.value();
  if (!token) {
    throw new Error("WhatsApp access token not configured.");
  }

  const url = `https://graph.facebook.com/v20.0/${WHATSAPP_PHONE_NUMBER_ID}/messages`;

  const payload = {
    messaging_product: "whatsapp",
    to: phone,
    type: "template",
    template: {
      name: "auth_otp",
      language: { code: "en" },
      components: [
        { type: "body", parameters: [{ type: "text", text: otp }] },
        { type: "button", sub_type: "url", index: "0", parameters: [{ type: "text", text: otp }] },
      ],
    },
  };

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    // Deliberately don't log the response body — it can echo back the
    // phone number and template params; log only what's needed to debug
    // delivery failures without creating a PII trail in Cloud Logging.
    throw new Error(`WhatsApp API error: HTTP ${response.status}`);
  }
}
