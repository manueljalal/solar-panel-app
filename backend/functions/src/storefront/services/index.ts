import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { cleanDocId, cleanEnum, cleanText } from "../../shared/validation/sanitize";
import { SERVICE_TYPES, serializeServiceRequest } from "../../shared/services";
import { LIMITS, clientIp, enforceRateLimit } from "../../shared/rate_limit";

interface RequestServiceInput {
  type: (typeof SERVICE_TYPES)[number];
  address: string;
  city?: string;
  location: { latitude: number; longitude: number; address?: string };
  preferredDate?: number | null; // epoch millis
  panelCount?: number | null; // cleaning
  systemSizeKw?: number | null; // installation
  note?: string;
}

function optionalPositive(v: unknown, field: string, max: number): number | null {
  if (v === undefined || v === null) return null;
  if (typeof v !== "number" || !Number.isFinite(v) || v <= 0 || v > max) {
    throw new HttpsError("invalid-argument", `${field} must be a positive number.`);
  }
  return Math.round(v * 10) / 10;
}

/// Customer books an installation or panel cleaning. Needs a real account
/// (the team calls the verified phone to confirm).
export const requestService = onCall<RequestServiceInput>({ region: "us-central1" }, async (request) => {
    await enforceRateLimit(`service:${request.auth?.uid ?? clientIp(request)}`, 10, LIMITS.HOUR);
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Sign in required.");
  if (auth.token.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("failed-precondition", "Create an account to request a service.");
  }
  const user = (await db.collection("users").doc(auth.uid).get()).data();
  if (!user?.phone) throw new HttpsError("failed-precondition", "Your account needs a verified phone number.");

  const type = cleanEnum(request.data?.type, SERVICE_TYPES, "type");
  const address = cleanText(request.data?.address, "address", { max: 300, min: 3 });
  const city = cleanText(request.data?.city, "city", { max: 80 });
  const note = cleanText(request.data?.note, "note", { max: 1000, multiline: true });
  const loc = request.data?.location;
  if (
    !loc || typeof loc.latitude !== "number" || typeof loc.longitude !== "number" ||
    !(loc.latitude >= -90 && loc.latitude <= 90) || !(loc.longitude >= -180 && loc.longitude <= 180)
  ) {
    throw new HttpsError("invalid-argument", "Choose the location on the map.");
  }
  const location = {
    latitude: loc.latitude,
    longitude: loc.longitude,
    address: cleanText(loc.address, "location address", { max: 300 }),
  };

  let preferredDate: Timestamp | null = null;
  const pd = request.data?.preferredDate;
  if (pd !== undefined && pd !== null) {
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    if (typeof pd !== "number" || pd < startOfToday.getTime() || pd > Date.now() + 365 * 86_400_000) {
      throw new HttpsError("invalid-argument", "Choose a date from today onwards.");
    }
    preferredDate = Timestamp.fromMillis(pd);
  }

  const ref = db.collection("serviceRequests").doc();
  await ref.set({
    uid: auth.uid,
    customerName: user.name ?? "",
    customerPhone: user.phone,
    type,
    status: "new",
    address,
    city,
    location,
    preferredDate,
    panelCount: type === "cleaning" ? optionalPositive(request.data?.panelCount, "panelCount", 10_000) : null,
    systemSizeKw: type === "installation" ? optionalPositive(request.data?.systemSizeKw, "systemSizeKw", 10_000) : null,
    note,
    vendorId: null,
    vendorName: null,
    scheduledFor: null,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { id: ref.id };
});

export const listMyServiceRequests = onCall({ region: "us-central1" }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const snap = await db.collection("serviceRequests").where("uid", "==", request.auth.uid).orderBy("createdAt", "desc").limit(100).get();
  const requests = snap.docs
    .map((d) => serializeServiceRequest(d))
    .sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
  return { requests };
});

/// Customer cancels their own request while it's still 'new'.
export const cancelMyServiceRequest = onCall<{ id: string }>({ region: "us-central1" }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const id = cleanDocId(request.data?.id, "id");
  const ref = db.collection("serviceRequests").doc(id);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || snap.data()?.uid !== request.auth!.uid) throw new HttpsError("not-found", "Request not found.");
    if (snap.data()?.status !== "new") {
      throw new HttpsError("failed-precondition", "This request is already scheduled — call us to change it.");
    }
    tx.update(ref, { status: "cancelled", updatedAt: FieldValue.serverTimestamp() });
  });
  return { ok: true };
});
