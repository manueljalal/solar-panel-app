"use client";

import { AuthedPage } from "./authed_page";

export function ComingSoon({ title }: { title: string }) {
  return (
    <AuthedPage>
      <div className="content">
        <h1 style={{ fontSize: 20, marginBottom: 4 }}>{title}</h1>
        <div className="placeholder-card card">
          <p>{title} isn&apos;t built yet.</p>
          <p className="muted" style={{ marginTop: 4 }}>Check back soon.</p>
        </div>
      </div>
    </AuthedPage>
  );
}
