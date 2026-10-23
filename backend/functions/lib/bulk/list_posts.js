"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listRequests = exports.listListings = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../shared/firebase");
const sanitize_1 = require("../shared/validation/sanitize");
const shared_1 = require("./shared");
const FEED_LIMIT = 100;
/// Filters in the query (status / country / owner) so the 100-row cap
/// applies to matching posts — filtering in memory after a plain
/// "newest 100" read silently dropped older open posts and a vendor's own
/// older posts. Backed by the bulkListings/bulkRequests composite indexes
/// in firestore.indexes.json.
function makeLister(collection, openStatus, kind) {
    return (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
        const me = await (0, shared_1.requireBulkVendor)(request);
        const country = request.data?.country === undefined ? undefined : (0, sanitize_1.cleanEnum)(request.data.country, shared_1.COUNTRIES, "country");
        const mine = request.data?.mine === true;
        let q = firebase_1.db.collection(collection);
        if (mine) {
            q = q.where("vendorId", "==", me.vendorId);
        }
        else {
            q = q.where("status", "==", openStatus);
            if (country)
                q = q.where("country", "==", country);
        }
        const snap = await q.orderBy("createdAt", "desc").limit(FEED_LIMIT).get();
        const rows = snap.docs.map((d) => {
            // ownerUid is the poster's Firebase account id — internal only, so
            // it isn't sent to every other vendor reading the feed.
            const { ownerUid, ...data } = d.data();
            return {
                ...data,
                id: d.id,
                status: data.status,
                country: data.country,
                createdAt: data.createdAt?.toMillis?.() ?? null,
                isMine: data.vendorId === me.vendorId,
            };
        });
        return { [kind]: rows };
    });
}
exports.listListings = makeLister("bulkListings", "active", "listings");
exports.listRequests = makeLister("bulkRequests", "open", "requests");
