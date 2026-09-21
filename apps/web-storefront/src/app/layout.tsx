export const metadata = {
  title: "Solary — Solar, sourced right",
  description: "Compare vetted vendors, pick your system, get it installed.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
