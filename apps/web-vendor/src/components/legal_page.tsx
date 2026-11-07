/** Plain, readable layout for the public legal pages (no sign-in needed). */
export function LegalPage({ title, updated, children }: { title: string; updated: string; children: React.ReactNode }) {
  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "48px 20px 80px", lineHeight: 1.65, fontSize: 15 }}>
      <div style={{ fontWeight: 800, fontSize: 18, marginBottom: 28 }}>Solary</div>
      <h1 style={{ fontSize: 30, letterSpacing: "-0.02em", margin: "0 0 6px" }}>{title}</h1>
      <p className="muted" style={{ marginTop: 0 }}>Last updated: {updated}</p>
      <div className="legal">{children}</div>
      <p className="muted" style={{ marginTop: 40, fontSize: 13 }}>
        Solary · <a className="link" href="mailto:info@quadcores.com">info@quadcores.com</a> ·{" "}
        <a className="link" href="/privacy">Privacy</a> · <a className="link" href="/terms">Terms</a>
      </p>
    </main>
  );
}
