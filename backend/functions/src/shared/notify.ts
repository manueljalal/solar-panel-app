import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./firebase";

export type NotificationType = "order_status" | "service_status" | "quote_status" | "announcement";

const KEEP_FOR_MS = 90 * 24 * 60 * 60 * 1000;

/// Adds an in-app notification for [uid]. Stored as a type plus parameters
/// (never pre-written sentences) so the app shows it in the reader's own
/// language. notifications/{id} is readable only by its owner, who may
/// only flip `read` (see firestore.rules); old ones expire via TTL.
export async function notify(uid: string, type: NotificationType, params: Record<string, string | number | null>) {
  if (!uid) return;
  await db.collection("notifications").add({
    uid,
    type,
    params,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
    expireAt: Timestamp.fromMillis(Date.now() + KEEP_FOR_MS),
  });
}
