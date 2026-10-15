"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listRequests = exports.listListings = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = require("../shared/firebase");
const sanitize_1 = require("../shared/validation/sanitize");
const shared_1 = require("./shared");
const FEED_LIMIT = 100;
/// Reads the newest posts and filters in memory (status / country /
/// owner). A single-field createdAt order needs no composite index, and
/// the feed is capped at 100 — revisit with indexes if volume outgrows it.
function makeLister(collection, openStatus, kind) {
    return (0, https_1.onCall)({ region: "us-central1" }, async (request) => {
        const me = await (0, shared_1.requireBulkVendor)(request);
        const country = request.data?.country === undefined ? undefined : (0, sanitize_1.cleanEnum)(request.data.country, shared_1.COUNTRIES, "country");
        const mine = request.data?.mine === true;
        const snap = await firebase_1.db.collection(collection).orderBy("createdAt", "desc").limit(FEED_LIMIT).get();
        const rows = snap.docs
            .map((d) => {
            const data = d.data();
            return {
                ...data,
                id: d.id,
                status: data.status,
                country: data.country,
                createdAt: data.createdAt?.toMillis?.() ?? null,
                isMine: data.vendorId === me.vendorId,
            };
        })
            .filter((r) => (mine ? r.isMine : r.status === openStatus && (!country || r.country === country)));
        return { [kind]: rows };
    });
}
exports.listListings = makeLister("bulkListings", "active", "listings");
exports.listRequests = makeLister("bulkRequests", "open", "requests");
