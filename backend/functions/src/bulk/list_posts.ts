import { onCall } from "firebase-functions/v2/https";
import { db } from "../shared/firebase";
import { cleanEnum } from "../shared/validation/sanitize";
import { COUNTRIES, requireBulkVendor } from "./shared";

interface ListInput {
  /** Restrict to one country; omitted = all. */
  country?: (typeof COUNTRIES)[number];
  /** true = only the caller's own posts (any status). */
  mine?: boolean;
}

const FEED_LIMIT = 100;

type Kind = "listings" | "requests";

/// Filters in the query (status / country / owner) so the 100-row cap
/// applies to matching posts — filtering in memory after a plain
/// "newest 100" read silently dropped older open posts and a vendor's own
/// older posts. Backed by the bulkListings/bulkRequests composite indexes
/// in firestore.indexes.json.
function makeLister(collection: string, openStatus: string, kind: Kind) {
  return onCall<ListInput>({ region: "us-central1" }, async (request) => {
    const me = await requireBulkVendor(request);
    const country =
      request.data?.country === undefined ? undefined : cleanEnum(request.data.country, COUNTRIES, "country");
    const mine = request.data?.mine === true;

    let q: FirebaseFirestore.Query = db.collection(collection);
    if (mine) {
      q = q.where("vendorId", "==", me.vendorId);
    } else {
      q = q.where("status", "==", openStatus);
      if (country) q = q.where("country", "==", country);
    }
    const snap = await q.orderBy("createdAt", "desc").limit(FEED_LIMIT).get();

    const rows = snap.docs.map((d) => {
      // ownerUid is the poster's Firebase account id — internal only, so
      // it isn't sent to every other vendor reading the feed.
      const { ownerUid, ...data } = d.data();
      return {
        ...data,
        id: d.id,
        status: data.status as string,
        country: data.country as string,
        createdAt: data.createdAt?.toMillis?.() ?? null,
        isMine: data.vendorId === me.vendorId,
      };
    });

    return { [kind]: rows };
  });
}

export const listListings = makeLister("bulkListings", "active", "listings");
export const listRequests = makeLister("bulkRequests", "open", "requests");
