import { LegalPage } from "@/components/legal_page";

export const metadata = { title: "Privacy Policy — Solary" };

export default function PrivacyPage() {
  return (
    <LegalPage title="Privacy Policy" updated="31 October 2026">
      <p>
        Solary (&quot;we&quot;) runs a marketplace that connects people in Iraq with solar companies, plus a business-to-business
        marketplace for those companies. This policy explains what we collect, why, who processes it, and the choices you have.
      </p>

      <h2>What we collect</h2>
      <ul>
        <li><strong>Account details</strong> — your name, username, phone number (verified by a WhatsApp code), optional email, and your password, which we store only as a one-way hash.</li>
        <li><strong>Location</strong> — the delivery or service location you pin on the map, the address details you type, and the city you choose. We only read your device&apos;s GPS when you tap &quot;Use my location&quot;.</li>
        <li><strong>Orders, quotes and service requests</strong> — what you order or request, the delivery address, notes you add, and their status.</li>
        <li><strong>Business information</strong> (vendors) — company name, city, address, logo, contact phone and email, products, prices, and B2B posts.</li>
        <li><strong>Photos you upload</strong> — company logos, product and post photos.</li>
        <li><strong>Technical data</strong> — a random device identifier used to recognise trusted devices at sign-in, and basic logs needed to keep the service secure and working.</li>
      </ul>
      <p>Favourites and your chosen city are stored only on your phone.</p>

      <h2>Why we use it</h2>
      <ul>
        <li>To create and secure your account, including sign-in checks on new devices.</li>
        <li>To place orders, book services and send quote requests, and to let the seller or our team contact you about them.</li>
        <li>To show vendors&apos; public profiles, products and B2B posts.</li>
        <li>To prevent fraud and abuse (for example rate limits and account protection).</li>
        <li>To send service messages such as verification codes and order notifications. We do not sell your data or send advertising.</li>
      </ul>

      <h2>Who can see it</h2>
      <ul>
        <li><strong>Sellers</strong> see your name, phone and delivery address for orders, quote requests and service jobs that involve them.</li>
        <li><strong>Other vendors</strong> (B2B only) see a company&apos;s public name, country, city, phone and its posts.</li>
        <li><strong>Our administrators</strong> can see account and order information to run and support the platform.</li>
        <li><strong>Service providers</strong> that process data for us: Google Firebase / Google Cloud (hosting, database, authentication, storage), Google Maps (map display), Meta WhatsApp Business (verification codes), and our email provider (notifications). They process data only to provide their service.</li>
      </ul>

      <h2>How long we keep it</h2>
      <p>
        We keep your account data while your account exists. Orders, quote requests and service requests are kept as business records
        after an account is deleted. Security records such as rate-limit entries expire automatically.
      </p>

      <h2>Your choices and rights</h2>
      <ul>
        <li>Edit your name, username and email in the app (Account → Edit profile).</li>
        <li>Delete your account in the app (Account → Delete account). Business accounts are closed on request — contact us.</li>
        <li>Ask us for a copy of your data or to correct it by emailing <a className="link" href="mailto:info@quadcores.com">info@quadcores.com</a>.</li>
        <li>Location access can be turned off at any time in your phone&apos;s settings.</li>
      </ul>

      <h2>Security</h2>
      <p>
        Data is encrypted in transit, passwords are hashed, and access to personal data is limited to the parties described above.
        No system is perfectly secure, so please keep your password private.
      </p>

      <h2>Children</h2>
      <p>Solary is not intended for children under 16, and we do not knowingly collect their data.</p>

      <h2>Changes</h2>
      <p>We will post updates here and change the date above. Significant changes will be shown in the app.</p>

      <h2>Contact</h2>
      <p>
        Questions or requests: <a className="link" href="mailto:info@quadcores.com">info@quadcores.com</a>
      </p>
    </LegalPage>
  );
}
