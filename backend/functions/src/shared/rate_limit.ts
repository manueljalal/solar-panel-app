import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { createHash } from "crypto";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "./firebase";

/// Sliding-window limiter backed by rateLimits/{hash(key)} docs, checked and
/// updated in a transaction so concurrent calls can't slip past it. Each doc
/// carries expireAt for Firestore's TTL cleanup (see firestore.indexes.json).
///
/// Throws resource-exhausted when [key] already made [max] calls within the
/// last [windowMs].
export async function enforceRateLimit(key: string, max: number, windowMs: number, message?: string): Promise<void> {
  const id = createHash("sha256").update(key).digest("hex").slice(0, 40);
  const ref = db.collection("rateLimits").doc(id);
  const now = Date.now();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const recent = ((snap.data()?.hits as number[] | undefined) ?? []).filter((t) => now - t < windowMs);
    if (recent.length >= max) {
      throw new HttpsError("resource-exhausted", message ?? "Too many requests. Please wait a little and try again.");
    }
    recent.push(now);
    tx.set(ref, { hits: recent, expireAt: Timestamp.fromMillis(now + windowMs) });
  });
}

/// The caller's IP as seen by Google's front end (first X-Forwarded-For hop).
export function clientIp(request: CallableRequest): string {
  const fwd = request.rawRequest?.headers?.["x-forwarded-for"];
  const first = (Array.isArray(fwd) ? fwd[0] : fwd)?.split(",")[0]?.trim();
  return first || request.rawRequest?.ip || "unknown";
}

const HOUR = 60 * 60 * 1000;
export const LIMITS = { HOUR, DAY: 24 * HOUR, MINUTE: 60 * 1000 };

function docFor(key: string) {
  return db.collection("rateLimits").doc(createHash("sha256").update(key).digest("hex").slice(0, 40));
}

/// How many hits [key] recorded within [windowMs] (no write).
export async function recentHits(key: string, windowMs: number): Promise<number> {
  const now = Date.now();
  const hits = ((await docFor(key).get()).data()?.hits as number[] | undefined) ?? [];
  return hits.filter((t) => now - t < windowMs).length;
}

/// Record one hit for [key] (e.g. a failed password).
export async function addHit(key: string, windowMs: number): Promise<void> {
  const ref = docFor(key);
  const now = Date.now();
  await db.runTransaction(async (tx) => {
    const hits = (((await tx.get(ref)).data()?.hits as number[] | undefined) ?? []).filter((t) => now - t < windowMs);
    hits.push(now);
    tx.set(ref, { hits, expireAt: Timestamp.fromMillis(now + windowMs) });
  });
}

export async function clearHits(key: string): Promise<void> {
  await docFor(key).delete();
}
