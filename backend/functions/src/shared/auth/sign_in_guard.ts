import { HttpsError } from "firebase-functions/v2/https";
import { LIMITS } from "../rate_limit";

/// Wrong passwords per account identifier before signIn and the new-device
/// step-up stop accepting attempts, and the window they are counted over.
export const MAX_FAILED_SIGNINS = 10;
export const FAILED_WINDOW = 15 * LIMITS.MINUTE;

/// The client's persisted device id, or null when none was sent. Bounded
/// because it is stored on the profile (knownDeviceIds).
export function cleanDeviceId(raw: unknown): string | null {
  if (typeof raw !== "string" || !raw.trim()) return null;
  const id = raw.trim();
  if (id.length > 128) throw new HttpsError("invalid-argument", "deviceId is invalid.");
  return id;
}
