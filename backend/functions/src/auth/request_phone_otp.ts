import { onCall, HttpsError } from "firebase-functions/v2/https";
import { whatsappAccessToken } from "../shared/whatsapp/send_otp";
import { E164_PATTERN, issuePhoneOtp, OTP_TTL_MS } from "../shared/auth/issue_otp";

interface RequestOtpInput {
  phone: string; // E.164, e.g. "+9647501234567"
  deviceId?: string; // client-generated, persisted locally — see device_id.dart
}

/// Starts phone verification for signUp / signInOtpStepUp — see
/// issuePhoneOtp for the hashing and rate limiting.
export const requestPhoneOtp = onCall<RequestOtpInput>(
  { region: "us-central1", secrets: [whatsappAccessToken] },
  async (request) => {
    const phone = request.data?.phone?.trim();
    const deviceId = request.data?.deviceId?.trim() || null;
    if (!phone || !E164_PATTERN.test(phone)) {
      throw new HttpsError("invalid-argument", "phone must be in E.164 format, e.g. +9647501234567.");
    }

    await issuePhoneOtp(phone, deviceId);

    return { ok: true, expiresInSeconds: OTP_TTL_MS / 1000 };
  }
);
