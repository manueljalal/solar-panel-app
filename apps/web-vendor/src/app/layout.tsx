import "./globals.css";

export const metadata = {
  title: "Solary — Vendor Portal",
  description: "Manage your listings, orders, and installs",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
