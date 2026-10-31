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

/// Reads the newest posts and filters in memory (status / country /
/// owner). Indexed queries (status+createdAt, vendorId+createdAt — see
/// firestore.indexes.json): the open feed is the newest 100 open posts, and
/// "mine" is the caller's own newest 200 regardless of everyone else's.
function makeLister(collection: string, openStatus: string, kind: Kind) {
  return onCall<ListInput>({ region: "us-central1" }, async (request) => {
    const me = await requireBulkVendor(request);
    const country =
      request.data?.country === undefined ? undefined : cleanEnum(request.data.country, COUNTRIES, "country");
    const mine = request.data?.mine === true;

    const base = db.collection(collection);
    const snap = mine
      ? await base.where("vendorId", "==", me.vendorId).orderBy("createdAt", "desc").limit(200).get()
      : await base.where("status", "==", openStatus).orderBy("createdAt", "desc").limit(FEED_LIMIT).get();
    const rows = snap.docs
      .map((d) => {
        const data = d.data();
        return {
          ...data,
          id: d.id,
          status: data.status as string,
          country: data.country as string,
          createdAt: data.createdAt?.toMillis?.() ?? null,
          isMine: data.vendorId === me.vendorId,
        };
      })
      .filter((r) => (mine ? r.isMine : r.status === openStatus && (!country || r.country === country)));

    return { [kind]: rows };
  });
}

export const listListings = makeLister("bulkListings", "active", "listings");
export const listRequests = makeLister("bulkRequests", "open", "requests");
