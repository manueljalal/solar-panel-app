"use client";

import { useEffect, useState } from "react";
import { deleteAccount, errorMessage, findAccount, type AccountInfo } from "@/lib/api";

/** Looks the account up first and shows exactly what will be removed, then
 * asks the admin to type DELETE before anything happens. */
export function DeleteAccountDialog({
  target,
  onClose,
  onDeleted,
}: {
  target: { uid?: string; phone?: string };
  onClose: () => void;
  onDeleted: (message: string) => void;
}) {
  const [account, setAccount] = useState<AccountInfo | null | undefined>(undefined);
  const [confirm, setConfirm] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    findAccount(target)
      .then((r) => setAccount(r.data.account))
      .catch((e) => {
        setAccount(null);
        setError(errorMessage(e, "Couldn't look that account up."));
      });
  }, [target]);

  async function onDelete() {
    if (!account) return;
    setBusy(true);
    setError(null);
    try {
      const r = await deleteAccount({ uid: account.uid });
      const extra = Object.entries(r.data.removed)
        .filter(([, n]) => n > 0)
        .map(([k, n]) => `${n} ${k}`)
        .join(", ");
      onDeleted(`Deleted ${account.name || account.phone || "the account"}${extra ? ` (also removed ${extra})` : ""}.`);
    } catch (e) {
      setError(errorMessage(e, "Couldn't delete the account — try again."));
      setBusy(false);
    }
  }

  return (
    <>
      <div className="drawer-backdrop" onClick={onClose} />
      <aside className="drawer" role="dialog" aria-label="Delete account">
        <div className="drawer-head">
          <div>
            <h2 className="drawer-title">Delete account</h2>
            <span className="muted">This can&apos;t be undone.</span>
          </div>
          <button className="icon-btn" onClick={onClose} aria-label="Close">×</button>
        </div>
        <div className="drawer-body">
          {error && <p className="error-text" style={{ marginTop: 0 }}>{error}</p>}
          {account === undefined ? (
            <p className="muted">Looking up the account…</p>
          ) : account === null ? (
            !error && <p>No account uses {target.phone ?? "that id"}.</p>
          ) : (
            <>
              <dl className="kv">
                <dt>Name</dt>
                <dd>{account.name || "—"}</dd>
                <dt>Username</dt>
                <dd>{account.username ? `@${account.username}` : "—"}</dd>
                <dt>Phone</dt>
                <dd>{account.phone || "—"}</dd>
                <dt>Role</dt>
                <dd>{account.role}</dd>
                <dt>Profile</dt>
                <dd>{account.hasProfile ? "Yes" : "No — leftover from an unfinished sign-up"}</dd>
                {account.vendorNames.length > 0 && (
                  <>
                    <dt>Vendor company</dt>
                    <dd>{account.vendorNames.join(", ")}</dd>
                  </>
                )}
              </dl>
              <p className="muted">
                Removes the login, profile and username
                {account.vendorNames.length ? ", the vendor company, its products and B2B posts" : ""}. Orders and quote
                requests stay as records. The phone number can be used to sign up again.
              </p>
              <div className="field">
                <label htmlFor="confirm">Type DELETE to confirm</label>
                <input id="confirm" value={confirm} onChange={(e) => setConfirm(e.target.value)} autoComplete="off" />
              </div>
            </>
          )}
        </div>
        <div className="drawer-foot">
          <button className="btn btn-ghost" onClick={onClose}>
            Cancel
          </button>
          {account && (
            <button className="btn btn-danger" disabled={busy || confirm !== "DELETE"} onClick={onDelete}>
              {busy ? "Deleting…" : "Delete permanently"}
            </button>
          )}
        </div>
      </aside>
    </>
  );
}
