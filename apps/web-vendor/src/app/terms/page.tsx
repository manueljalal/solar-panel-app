import { LegalPage } from "@/components/legal_page";

export const metadata = { title: "Terms of Use — Solary" };

export default function TermsPage() {
  return (
    <LegalPage title="Terms of Use" updated="31 October 2026">
      <p>By creating an account or using Solary you agree to these terms. If you do not agree, please do not use the service.</p>

      <h2>The service</h2>
      <p>
        Solary is a marketplace. Products, installation and cleaning are sold and performed by independent vendors, not by Solary,
        unless stated otherwise. Each vendor is responsible for its listings, prices, stock, warranties, delivery and work.
      </p>

      <h2>Your account</h2>
      <ul>
        <li>Give accurate information and keep your password private. You are responsible for activity on your account.</li>
        <li>One account per person. Your phone number is verified and used to secure the account.</li>
        <li>We may suspend accounts that break these terms, abuse the service or put others at risk.</li>
      </ul>

      <h2>Orders and payment</h2>
      <ul>
        <li>Orders are paid in cash on delivery unless another method is offered. Prices are set by vendors.</li>
        <li>An order is a request to the vendor; it is binding once the vendor confirms it. You can cancel in the app until then.</li>
        <li>Delivery times, returns and warranties are agreed with the vendor. Contact the vendor first; contact us if you can&apos;t resolve an issue.</li>
      </ul>

      <h2>Services, quotes and courses</h2>
      <ul>
        <li>Installation and cleaning bookings are requests until a visit is scheduled and confirmed with you.</li>
        <li>Quotes are offers from vendors and are not binding until both sides agree.</li>
        <li>Learning content is for general guidance and is not a substitute for a qualified installer&apos;s assessment of your site.</li>
      </ul>

      <h2>Vendors</h2>
      <ul>
        <li>Vendors must be legitimate businesses, keep listings accurate and lawful, honour confirmed orders, and comply with applicable laws.</li>
        <li>B2B posts must be genuine offers or requests. We may remove listings or posts and suspend vendors that break these rules.</li>
      </ul>

      <h2>Acceptable use</h2>
      <p>
        Don&apos;t misuse the service: no fraud, spam, fake orders or reviews, illegal or unsafe products, attempts to access other
        accounts, or interference with the platform.
      </p>

      <h2>Liability</h2>
      <p>
        Solary provides the marketplace &quot;as is&quot;. To the extent permitted by law, we are not liable for products, services or
        conduct of vendors or users, or for indirect losses. Nothing in these terms limits rights you have under applicable consumer law.
      </p>

      <h2>Changes</h2>
      <p>We may update these terms; the date above shows the latest version. Continuing to use Solary means you accept the update.</p>

      <h2>Contact</h2>
      <p>
        <a className="link" href="mailto:info@quadcores.com">info@quadcores.com</a>
      </p>
    </LegalPage>
  );
}
