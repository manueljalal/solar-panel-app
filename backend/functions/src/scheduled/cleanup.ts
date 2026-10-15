import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import { db } from "../shared/firebase";

const DAY_MS = 24 * 60 * 60 * 1000;

async function deleteWhere(query: FirebaseFirestore.Query): Promise<number> {
  let deleted = 0;
  // Pages of 400 keep each batch under Firestore's 500-write limit.
  for (;;) {
    const snap = await query.limit(400).get();
    if (snap.empty) return deleted;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    deleted += snap.size;
    if (snap.size < 400) return deleted;
  }
}

/// Daily housekeeping for short-lived auth records that nothing else
/// deletes when they simply expire unused: OTP codes nobody entered,
/// password-setup links nobody clicked, and per-device OTP rate-limit
/// counters older than a day (the limit window is one hour).
export const cleanupExpiredAuthRecords = onSchedule(
  { schedule: "every day 03:00", timeZone: "Asia/Baghdad", region: "us-central1" },
  async () => {
    const now = new Date();
    const [otps, tokens, devices] = await Promise.all([
      deleteWhere(db.collection("phoneOtps").where("expiresAt", "<", now)),
      deleteWhere(db.collection("passwordSetupTokens").where("expiresAt", "<", now)),
      deleteWhere(db.collection("otpDeviceSends").where("lastSentAt", "<", new Date(now.getTime() - DAY_MS))),
    ]);
    logger.info("cleanupExpiredAuthRecords", { otps, tokens, devices });
  },
);
