import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "../shared/firebase";
import { requireRole } from "../shared/auth/require_role";
import { cleanLocalized, type LocalizedText } from "../shared/validation/sanitize";

/// Super-admin broadcast: one in-app notification (type "announcement") per
/// user, written to notifications/{id} like every other notification so the
/// app's bell, unread badge and list work unchanged. The wording is stored
/// in all three languages and the app shows the reader's own.
const KEEP_FOR_MS = 90 * 24 * 60 * 60 * 1000;
const BATCH = 400; // Firestore batches allow 500 writes.

interface AnnouncementInput {
  title: LocalizedText;
  body: LocalizedText;
}

export const sendAnnouncement = onCall<AnnouncementInput>({ region: "us-central1", timeoutSeconds: 300 }, async (request) => {
  const { uid } = requireRole(request, ["super_admin"]);
  const title = cleanLocalized(request.data?.title, "Title", { max: 80 });
  const body = cleanLocalized(request.data?.body, "Message", { max: 300, multiline: true });

  const users = await db.collection("users").select().get();
  if (users.empty) throw new HttpsError("failed-precondition", "There are no users to notify.");

  const announcementRef = db.collection("announcements").doc();
  const expireAt = Timestamp.fromMillis(Date.now() + KEEP_FOR_MS);
  const ids = users.docs.map((d) => d.id);

  for (let i = 0; i < ids.length; i += BATCH) {
    const batch = db.batch();
    for (const userId of ids.slice(i, i + BATCH)) {
      batch.set(db.collection("notifications").doc(), {
        uid: userId,
        type: "announcement",
        params: { announcementId: announcementRef.id, title, body },
        read: false,
        createdAt: FieldValue.serverTimestamp(),
        expireAt,
      });
    }
    await batch.commit();
  }

  // Audit trail of what was sent, by whom, to how many.
  await announcementRef.set({ title, body, sentBy: uid, recipients: ids.length, createdAt: FieldValue.serverTimestamp() });
  return { announcementId: announcementRef.id, recipients: ids.length };
});
