"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendVendorApprovedEmail = sendVendorApprovedEmail;
exports.sendVendorRejectedEmail = sendVendorRejectedEmail;
const send_mail_1 = require("./send_mail");
const VENDOR_PORTAL_URL = "https://solary-vendor-dev.web.app";
const COMPANY_FOOTER_NAME = "Solary, a Quadcores product";
const COMPANY_FOOTER_CONTACT = "info@quadcores.com";
async function sendVendorApprovedEmail(to, businessName) {
    const loginUrl = `${VENDOR_PORTAL_URL}/login`;
    await (0, send_mail_1.sendMail)({
        to,
        subject: "Your Solary vendor application has been approved",
        text: `Hello ${businessName},\n\n` +
            `Your vendor application for Solary has been reviewed and approved. ` +
            `You can now sign in to the vendor portal using the phone number on your application.\n\n` +
            `Vendor portal: ${loginUrl}\n\n` +
            `If you have any questions, reply to this email and we'll help.\n\n` +
            `Thank you,\nThe Solary Team\n\n` +
            `--\n${COMPANY_FOOTER_NAME}\n${COMPANY_FOOTER_CONTACT}`,
        html: renderTemplate({
            heading: "Your application has been approved",
            bodyHtml: `<p style="margin:0 0 16px;">Hello ${escapeHtml(businessName)},</p>` +
                `<p style="margin:0 0 16px;">Your vendor application for Solary has been reviewed and approved. ` +
                `You can now sign in to the vendor portal using the phone number on your application.</p>`,
            buttonLabel: "Sign in to vendor portal",
            buttonUrl: loginUrl,
            closingHtml: `<p style="margin:16px 0 0;">If you have any questions, reply to this email and we'll help.</p>`,
        }),
    });
}
async function sendVendorRejectedEmail(to, businessName, reason) {
    const reasonText = reason ? `Reason provided: ${reason}\n\n` : "";
    const reasonHtml = reason
        ? `<p style="margin:0 0 16px;"><strong>Reason provided:</strong> ${escapeHtml(reason)}</p>`
        : "";
    await (0, send_mail_1.sendMail)({
        to,
        subject: "Update on your Solary vendor application",
        text: `Hello ${businessName},\n\n` +
            `Thank you for applying to become a vendor on Solary. After review, we're not able to approve ` +
            `your application at this time.\n\n${reasonText}` +
            `You're welcome to submit a new application with updated details.\n\n` +
            `If you have any questions, reply to this email and we'll help.\n\n` +
            `Thank you,\nThe Solary Team\n\n` +
            `--\n${COMPANY_FOOTER_NAME}\n${COMPANY_FOOTER_CONTACT}`,
        html: renderTemplate({
            heading: "Update on your vendor application",
            bodyHtml: `<p style="margin:0 0 16px;">Hello ${escapeHtml(businessName)},</p>` +
                `<p style="margin:0 0 16px;">Thank you for applying to become a vendor on Solary. After review, ` +
                `we're not able to approve your application at this time.</p>${reasonHtml}` +
                `<p style="margin:0 0 16px;">You're welcome to submit a new application with updated details.</p>`,
            closingHtml: `<p style="margin:16px 0 0;">If you have any questions, reply to this email and we'll help.</p>`,
        }),
    });
}
function renderTemplate(options) {
    const button = options.buttonUrl
        ? `<p style="margin:0 0 16px;">
         <a href="${options.buttonUrl}"
            style="display:inline-block;background:#16201c;color:#ffffff;text-decoration:none;
                   padding:10px 20px;border-radius:6px;font-weight:600;font-size:14px;">
           ${escapeHtml(options.buttonLabel ?? "Open")}
         </a>
       </p>
       <p style="margin:0 0 16px;font-size:13px;color:#5b6863;">
         Or copy this link into your browser: ${escapeHtml(options.buttonUrl)}
       </p>`
        : "";
    return `<!doctype html>
<html lang="en">
  <body style="margin:0;padding:0;background:#f5f4f0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f5f4f0;padding:32px 16px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" style="max-width:480px;background:#ffffff;border:1px solid #e3e1db;border-radius:10px;padding:28px;">
            <tr>
              <td style="font-weight:800;font-size:18px;color:#16201c;padding-bottom:16px;">Solary</td>
            </tr>
            <tr>
              <td style="font-size:16px;font-weight:700;color:#16201c;padding-bottom:12px;">${escapeHtml(options.heading)}</td>
            </tr>
            <tr>
              <td style="font-size:14px;line-height:1.5;color:#16201c;">
                ${options.bodyHtml}
                ${button}
                ${options.closingHtml ?? ""}
              </td>
            </tr>
            <tr>
              <td style="padding-top:24px;border-top:1px solid #e3e1db;margin-top:24px;font-size:12px;color:#8d9691;">
                <p style="margin:16px 0 4px;">${escapeHtml(COMPANY_FOOTER_NAME)}</p>
                <p style="margin:0;">Contact: ${escapeHtml(COMPANY_FOOTER_CONTACT)}</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}
function escapeHtml(value) {
    return value
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}
