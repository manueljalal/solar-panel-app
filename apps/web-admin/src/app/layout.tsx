export const metadata = {
  title: "Solary — Super Admin",
  description: "Platform administration console",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
