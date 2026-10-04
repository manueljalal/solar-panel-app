import { HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { Role } from "./roles";

/// Throws a permission-denied HttpsError unless the caller's token carries
/// one of the allowed roles. Every admin/vendor-only callable starts with
/// this — never trust a client-supplied role field, only the signed
/// custom claim on request.auth.token.
export function requireRole(request: CallableRequest, allowed: Role[]): { uid: string; role: Role } {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const role = (auth.token.role as Role | undefined) ?? "customer";
  if (!allowed.includes(role)) {
    throw new HttpsError("permission-denied", `Requires one of: ${allowed.join(", ")}.`);
  }

  return { uid: auth.uid, role };
}

/// Vendor-scoped functions also need to know WHICH vendor the caller
/// represents — read from the vendorId claim set alongside role
/// ('vendor') during approveVendorApplication.
export function requireVendor(request: CallableRequest): { uid: string; vendorId: string } {
  const { uid } = requireRole(request, ["vendor"]);
  const vendorId = request.auth?.token.vendorId as string | undefined;
  if (!vendorId) {
    throw new HttpsError("failed-precondition", "Vendor account has no vendorId claim.");
  }
  return { uid, vendorId };
}
