import { sendMail } from "./send_mail";
import { escapeHtml, renderTemplate } from "./vendor_application_emails";
import type { OrderItem } from "../orders";

const VENDOR_PORTAL_URL = "https://solary-vendor-dev.web.app";

function money(amount: number, currency: string): string {
  const n = Number.isInteger(amount) ? amount.toString() : amount.toFixed(2);
  return currency === "USD" ? `$${n}` : `${currency} ${n}`;
}

/// Tells a vendor a new cash-on-delivery order is waiting for them.
export async function sendNewOrderEmail(
  to: string,
  businessName: string,
  order: { id: string; items: OrderItem[]; totals: Record<string, number>; customerName: string; address: string },
): Promise<void> {
  const lines = order.items.map((i) => `${i.qty} × ${i.name} — ${money(i.lineTotal, i.currency)}`);
  const total = Object.entries(order.totals).map(([c, a]) => money(a, c)).join(" + ");
  const url = `${VENDOR_PORTAL_URL}/orders`;
  await sendMail({
    to,
    subject: `New order on Solary (${total})`,
    text:
      `Hello ${businessName},\n\nYou have a new cash-on-delivery order from ${order.customerName}.\n\n` +
      `${lines.join("\n")}\nTotal: ${total}\nDeliver to: ${order.address}\n\n` +
      `Confirm it in the vendor portal: ${url}\n`,
    html: renderTemplate({
      heading: "You have a new order",
      bodyHtml:
        `<p style="margin:0 0 16px;">Hello ${escapeHtml(businessName)},</p>` +
        `<p style="margin:0 0 12px;">New cash-on-delivery order from <strong>${escapeHtml(order.customerName)}</strong>:</p>` +
        `<ul style="margin:0 0 12px;padding-left:18px;">${lines.map((l) => `<li>${escapeHtml(l)}</li>`).join("")}</ul>` +
        `<p style="margin:0 0 4px;"><strong>Total:</strong> ${escapeHtml(total)}</p>` +
        `<p style="margin:0 0 16px;"><strong>Deliver to:</strong> ${escapeHtml(order.address)}</p>`,
      buttonLabel: "Open orders",
      buttonUrl: url,
    }),
  });
}
