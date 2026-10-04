"use client";

import { useEffect, useState } from "react";
import { onAuthStateChanged, type User } from "firebase/auth";
import { auth } from "./firebase";

export type VendorAuthState =
  | { status: "loading" }
  | { status: "signed-out" }
  | { status: "signed-in-not-vendor"; user: User }
  | { status: "signed-in-vendor"; user: User; vendorId: string };

/** Tracks Firebase Auth state and the `role`/`vendorId` custom claims,
 * refreshed on every sign-in so a just-granted vendor claim shows up
 * without a manual reload (claims are cached on the ID token otherwise). */
export function useVendorAuth(): VendorAuthState {
  const [state, setState] = useState<VendorAuthState>({ status: "loading" });

  useEffect(() => {
    return onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setState({ status: "signed-out" });
        return;
      }
      const token = await user.getIdTokenResult(true);
      const role = token.claims.role;
      const vendorId = token.claims.vendorId as string | undefined;
      if (role === "vendor" && vendorId) {
        setState({ status: "signed-in-vendor", user, vendorId });
      } else {
        setState({ status: "signed-in-not-vendor", user });
      }
    });
  }, []);

  return state;
}
