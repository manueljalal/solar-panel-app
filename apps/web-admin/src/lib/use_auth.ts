"use client";

import { useEffect, useState } from "react";
import { onAuthStateChanged, type User } from "firebase/auth";
import { auth } from "./firebase";

export type AdminAuthState =
  | { status: "loading" }
  | { status: "signed-out" }
  | { status: "signed-in-not-admin"; user: User }
  | { status: "signed-in-admin"; user: User };

/** Tracks Firebase Auth state and the `role` custom claim, refreshed on
 * every sign-in so a just-granted super_admin claim shows up without a
 * manual reload (claims are cached on the ID token otherwise). */
export function useAdminAuth(): AdminAuthState {
  const [state, setState] = useState<AdminAuthState>({ status: "loading" });

  useEffect(() => {
    return onAuthStateChanged(auth, async (user) => {
      if (!user) {
        setState({ status: "signed-out" });
        return;
      }
      const token = await user.getIdTokenResult(true);
      const role = token.claims.role;
      setState(role === "super_admin" ? { status: "signed-in-admin", user } : { status: "signed-in-not-admin", user });
    });
  }, []);

  return state;
}
