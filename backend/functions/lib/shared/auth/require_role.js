"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireRole = requireRole;
exports.requireVendor = requireVendor;
const https_1 = require("firebase-functions/v2/https");
/// Throws a permission-denied HttpsError unless the caller's token carries
/// one of the allowed roles. Every admin/vendor-only callable starts with
/// this — never trust a client-supplied role field, only the signed
/// custom claim on request.auth.token.
function requireRole(request, allowed) {
    const auth = request.auth;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in required.");
    }
    const role = auth.token.role ?? "customer";
    if (!allowed.includes(role)) {
        throw new https_1.HttpsError("permission-denied", `Requires one of: ${allowed.join(", ")}.`);
    }
    return { uid: auth.uid, role };
}
/// Vendor-scoped functions also need to know WHICH vendor the caller
/// represents — read from the vendorId claim set alongside role
/// ('vendor') during approveVendorApplication.
function requireVendor(request) {
    const { uid } = requireRole(request, ["vendor"]);
    const vendorId = request.auth?.token.vendorId;
    if (!vendorId) {
        throw new https_1.HttpsError("failed-precondition", "Vendor account has no vendorId claim.");
    }
    return { uid, vendorId };
}
