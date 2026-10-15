/** Client-side cleanup for instant feedback. The Cloud Functions re-validate
 * everything — this is never the security boundary. */
export function cleanText(value: string, multiline = false): string {
  let text = value
    .normalize("NFC")
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F​‎‏‪-‮⁠⁦-⁩﻿]/g, "")
    .replace(/<[^>]*>/g, "")
    .replace(/[<>]/g, "");
  text = multiline
    ? text.replace(/\r\n?/g, "\n").replace(/[ \t]+/g, " ").replace(/ ?\n ?/g, "\n").replace(/\n{3,}/g, "\n\n")
    : text.replace(/\s+/g, " ");
  return text.trim();
}

export const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
