import { defineSecret, defineString } from "firebase-functions/params";

// Secret value lives in Secret Manager (set via `firebase functions:secrets:set
// WHATSAPP_ACCESS_TOKEN`) — never in source, never in an .env file that
// could be committed.
export const whatsappAccessToken = defineSecret("WHATSAPP_ACCESS_TOKEN");

// Which WhatsApp Business account sends the codes. Non-secret identifiers,
// set per project in backend/functions/.env.<projectId>, so moving to a
// different business account (e.g. Solary's own) is a config change and a
// redeploy, not a code change.
const phoneNumberId = defineString("WHATSAPP_PHONE_NUMBER_ID", {
  description: "Meta WhatsApp Cloud API phone number id of the sending number",
});
const otpTemplate = defineString("WHATSAPP_OTP_TEMPLATE", {
  description: "Approved Authentication template name (body {{1}} = code, copy-code button)",
});
const otpLanguage = defineString("WHATSAPP_OTP_LANGUAGE", {
  description: "Language code the template is approved in, e.g. en or ar",
});

/// Sends a 6-digit OTP via WhatsApp using a pre-approved Authentication
/// template (Meta requires approved templates for business-initiated
/// conversations outside a 24h customer-service window).
export async function sendWhatsAppOtp(phone: string, otp: string): Promise<void> {
  const token = whatsappAccessToken.value();
  if (!token) {
    throw new Error("WhatsApp access token not configured.");
  }

  const url = `https://graph.facebook.com/v20.0/${phoneNumberId.value()}/messages`;

  const payload = {
    messaging_product: "whatsapp",
    to: phone,
    type: "template",
    template: {
      name: otpTemplate.value(),
      language: { code: otpLanguage.value() },
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
