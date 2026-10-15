"use client";

import { useCallback, useEffect, useState } from "react";
import { formatDateTime, type UserSummary } from "@solary/shared-types";
import { AuthedPage } from "@/components/authed_page";
import { useAdminAuth } from "@/lib/use_auth";
import { errorMessage, listUsers, setAdminRole, setUserDisabled } from "@/lib/api";

const ROLE_LABEL: Record<UserSummary["role"], string> = {
  customer: "Customer",
  vendor: "Vendor",
  super_admin: "Admin",
};

export default function UsersPage() {
  const authState = useAdminAuth();
  const myUid = authState.status === "signed-in-admin" ? authState.user.uid : null;
  const [query, setQuery] = useState("");
  const [users, setUsers] = useState<UserSummary[] | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busyUid, setBusyUid] = useState<string | null>(null);

  const load = useCallback(async (q: string, before?: number) => {
    setError(null);
    try {
      const result = await listUsers(q ? { query: q } : { before });
      setUsers((prev) => (before && prev ? [...prev, ...result.data.users] : result.data.users));
      setHasMore(result.data.hasMore);
    } catch (e) {
      setError(errorMessage(e, "Couldn't load users — try again."));
    }
  }, []);

  useEffect(() => {
    load("");
  }, [load]);

  async function act(user: UserSummary, action: () => Promise<unknown>) {
    setBusyUid(user.uid);
    setError(null);
    try {
      await action();
      await load(query.trim());
    } catch (e) {
      setError(errorMessage(e, "That didn't work — try again."));
    } finally {
      setBusyUid(null);
    }
  }

  function onToggleDisabled(user: UserSummary) {
    const verb = user.disabled ? "Restore" : "Suspend";
    if (!window.confirm(`${verb} ${user.name || user.username}?${user.disabled ? "" : " They'll be signed out everywhere."}`)) return;
    act(user, () => setUserDisabled({ uid: user.uid, disabled: !user.disabled }));
  }

  function onToggleAdmin(user: UserSummary) {
    const makeAdmin = user.role !== "super_admin";
    const msg = makeAdmin
      ? `Make ${user.name || user.username} a super admin? They'll get full access to this console.`
      : `Remove admin access from ${user.name || user.username}?`;
    if (!window.confirm(msg)) return;
    act(user, () => setAdminRole({ uid: user.uid, admin: makeAdmin }));
  }

  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>Users</h1>
        <p className="muted" style={{ marginBottom: 20 }}>
          Registered accounts (guests who never signed up aren&apos;t listed). Search by exact username, phone
          (+964…) or email.
        </p>

        <form
          className="toolbar"
          onSubmit={(e) => {
            e.preventDefault();
            setUsers(null);
            load(query.trim());
          }}
        >
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="username, +9647…, or email"
            aria-label="Search users"
            style={{ minWidth: 260 }}
          />
          <button className="btn btn-primary" type="submit">
            Search
          </button>
          {query && (
            <button
              className="btn btn-ghost"
              type="button"
              onClick={() => {
                setQuery("");
                setUsers(null);
                load("");
              }}
            >
              Clear
            </button>
          )}
        </form>

        {error && <p className="error-text" style={{ marginBottom: 12 }}>{error}</p>}
        {users === null ? (
          <p className="muted">Loading…</p>
        ) : users.length === 0 ? (
          <div className="empty-state">No matching users.</div>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Username</th>
                  <th>Phone</th>
                  <th>Role</th>
                  <th>Joined</th>
                  <th>Last sign-in</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {users.map((u) => (
                  <tr key={u.uid}>
                    <td>
                      {u.name || "—"} {u.disabled && <span className="pill pill-warning">Suspended</span>}
                    </td>
                    <td>{u.username || u.email || "—"}</td>
                    <td>{u.phone || "—"}</td>
                    <td>
                      <span className={u.role === "super_admin" ? "pill pill-accent" : "pill"}>{ROLE_LABEL[u.role]}</span>
                    </td>
                    <td>{formatDateTime(u.createdAt)}</td>
                    <td>{formatDateTime(u.lastSignInAt)}</td>
                    <td style={{ whiteSpace: "nowrap", textAlign: "right" }}>
                      {u.uid !== myUid && (
                        <>
                          <button className="btn btn-ghost" disabled={busyUid === u.uid} onClick={() => onToggleAdmin(u)}>
                            {u.role === "super_admin" ? "Remove admin" : "Make admin"}
                          </button>{" "}
                          <button
                            className={u.disabled ? "btn btn-ghost" : "btn btn-danger"}
                            disabled={busyUid === u.uid}
                            onClick={() => onToggleDisabled(u)}
                          >
                            {u.disabled ? "Restore" : "Suspend"}
                          </button>
                        </>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        {hasMore && users && !query && (
          <button
            className="btn btn-ghost"
            style={{ marginTop: 12 }}
            onClick={() => load("", users[users.length - 1]?.createdAt ?? undefined)}
          >
            Load more
          </button>
        )}
      </div>
    </AuthedPage>
  );
}
