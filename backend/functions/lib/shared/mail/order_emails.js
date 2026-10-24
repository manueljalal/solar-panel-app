"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendNewOrderEmail = sendNewOrderEmail;
const send_mail_1 = require("./send_mail");
const vendor_application_emails_1 = require("./vendor_application_emails");
const VENDOR_PORTAL_URL = "https://solary-vendor-dev.web.app";
function money(amount, currency) {
    const n = Number.isInteger(amount) ? amount.toString() : amount.toFixed(2);
    return currency === "USD" ? `$${n}` : `${currency} ${n}`;
}
/// Tells a vendor a new cash-on-delivery order is waiting for them.
async function sendNewOrderEmail(to, businessName, order) {
    const lines = order.items.map((i) => `${i.qty} × ${i.name} — ${money(i.lineTotal, i.currency)}`);
    const total = Object.entries(order.totals).map(([c, a]) => money(a, c)).join(" + ");
    const url = `${VENDOR_PORTAL_URL}/orders`;
    await (0, send_mail_1.sendMail)({
        to,
        subject: `New order on Solary (${total})`,
        text: `Hello ${businessName},\n\nYou have a new cash-on-delivery order from ${order.customerName}.\n\n` +
            `${lines.join("\n")}\nTotal: ${total}\nDeliver to: ${order.address}\n\n` +
            `Confirm it in the vendor portal: ${url}\n`,
        html: (0, vendor_application_emails_1.renderTemplate)({
            heading: "You have a new order",
            bodyHtml: `<p style="margin:0 0 16px;">Hello ${(0, vendor_application_emails_1.escapeHtml)(businessName)},</p>` +
                `<p style="margin:0 0 12px;">New cash-on-delivery order from <strong>${(0, vendor_application_emails_1.escapeHtml)(order.customerName)}</strong>:</p>` +
                `<ul style="margin:0 0 12px;padding-left:18px;">${lines.map((l) => `<li>${(0, vendor_application_emails_1.escapeHtml)(l)}</li>`).join("")}</ul>` +
                `<p style="margin:0 0 4px;"><strong>Total:</strong> ${(0, vendor_application_emails_1.escapeHtml)(total)}</p>` +
                `<p style="margin:0 0 16px;"><strong>Deliver to:</strong> ${(0, vendor_application_emails_1.escapeHtml)(order.address)}</p>`,
            buttonLabel: "Open orders",
            buttonUrl: url,
        }),
    });
}
