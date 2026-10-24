"use client";

import { useEffect, useMemo, useState } from "react";
import { formatDate } from "@solary/ui-web";
import { AuthedPage } from "@/components/authed_page";
import { DeleteAccountDialog } from "@/components/delete_account_dialog";
import { errorMessage, listUsers, type AdminUser } from "@/lib/api";

const ROLE_LABEL: Record<AdminUser["role"], string> = { customer: "Customer", vendor: "Vendor", super_admin: "Admin" };
const FILTERS: ("all" | AdminUser["role"])[] = ["all", "customer", "vendor"];

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUser[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<"all" | AdminUser["role"]>("all");
  const [search, setSearch] = useState("");
  const [phoneLookup, setPhoneLookup] = useState("");
  const [deleting, setDeleting] = useState<{ uid?: string; phone?: string } | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const load = () =>
    listUsers()
      .then((r) => setUsers(r.data.users))
      .catch((e) => setError(errorMessage(e, "Couldn't load users — try again.")));

  useEffect(() => {
    void load();
  }, []);

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: users?.length ?? 0 };
    for (const u of users ?? []) c[u.role] = (c[u.role] ?? 0) + 1;
    return c;
  }, [users]);

  const shown = useMemo(() => {
    const q = search.trim().toLowerCase();
    return (users ?? []).filter(
      (u) =>
        (filter === "all" || u.role === filter) &&
        (!q || `${u.name} ${u.username} ${u.phone} ${u.email} ${u.vendorName ?? ""}`.toLowerCase().includes(q)),
    );
  }, [users, filter, search]);

  return (
    <AuthedPage>
      <div className="content">
        <div className="page-header">
          <div>
            <h1 className="page-title">Users</h1>
            <p className="page-sub">Everyone with a Solary account. Guest browsers aren&apos;t listed.</p>
          </div>
        </div>

        {notice && <div className="notice">{notice}</div>}
        {error && <p className="error-text">{error}</p>}

        <form
          className="panel"
          style={{ marginBottom: 16, display: "flex", gap: 10, alignItems: "flex-end", flexWrap: "wrap" }}
          onSubmit={(e) => {
            e.preventDefault();
            if (phoneLookup.trim()) setDeleting({ phone: phoneLookup.trim() });
          }}
        >
          <div className="field" style={{ flex: 1, minWidth: 240 }}>
            <label htmlFor="phone">Find an account by phone</label>
            <input id="phone" placeholder="+9647501234567" value={phoneLookup} onChange={(e) => setPhoneLookup(e.target.value)} />
          </div>
          <button className="btn btn-ghost" type="submit">
            Find
          </button>
          <span className="muted" style={{ fontSize: 12.5, flexBasis: "100%" }}>
            Also finds leftover accounts from unfinished sign-ups, which aren&apos;t in the list below.
          </span>
        </form>

        <div className="toolbar">
          <div className="tabs">
            {FILTERS.map((f) => (
              <button key={f} className={`tab ${filter === f ? "active" : ""}`} onClick={() => setFilter(f)}>
                {f === "all" ? "All" : `${ROLE_LABEL[f]}s`}
                <span className="tab-count">{counts[f] ?? 0}</span>
              </button>
            ))}
          </div>
          <span className="spacer" />
          <input className="search" placeholder="Search name, username, phone" value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>

        {users === null ? (
          <p className="muted">Loading…</p>
        ) : shown.length === 0 ? (
          <div className="empty-state">
            <strong>No users found</strong>
            Try a different search.
          </div>
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
                {shown.map((u) => (
                  <tr key={u.id}>
                    <td>
                      <div className="cell-main">{u.name || "—"}</div>
                      {u.email && <div className="cell-sub">{u.email}</div>}
                    </td>
                    <td>{u.username ? `@${u.username}` : "—"}</td>
                    <td>{u.phone || "—"}</td>
                    <td>
                      <span className={`status ${u.role === "vendor" ? "status-approved" : "status-closed"}`}>
                        {ROLE_LABEL[u.role]}
                      </span>
                      {u.vendorName && <div className="cell-sub">{u.vendorName}</div>}
                    </td>
                    <td>{formatDate(u.createdAt)}</td>
                    <td>{formatDate(u.lastSignInAt)}</td>
                    <td className="actions">
                      {u.role !== "super_admin" && (
                        <button className="btn btn-danger btn-sm" onClick={() => setDeleting({ uid: u.id })}>
                          Delete
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        {deleting && (
          <DeleteAccountDialog
            target={deleting}
            onClose={() => setDeleting(null)}
            onDeleted={(message) => {
              setDeleting(null);
              setNotice(message);
              setPhoneLookup("");
              void load();
            }}
          />
        )}
      </div>
    </AuthedPage>
  );
}
