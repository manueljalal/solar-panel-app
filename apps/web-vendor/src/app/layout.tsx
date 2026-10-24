import "./globals.css";
import "@solary/ui-web/dashboard.css";

export const metadata = {
  title: "Solary — Vendor Portal",
  description: "Manage your products, orders and quote requests",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
