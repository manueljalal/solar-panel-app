"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.POST_LANGUAGES = void 0;
exports.cleanText = cleanText;
exports.cleanLocalized = cleanLocalized;
exports.cleanEmail = cleanEmail;
exports.cleanPrice = cleanPrice;
exports.cleanEnum = cleanEnum;
exports.cleanDocId = cleanDocId;
exports.cleanMultilingual = cleanMultilingual;
exports.primaryText = primaryText;
const https_1 = require("firebase-functions/v2/https");
// Control chars (keeps \n/\t out here; multiline handling re-adds \n),
// zero-width space / BOM, and bidi override/isolate characters — the latter
// are the usual vehicle for "spoofed" text. ZWNJ/ZWJ (U+200C/D) are kept:
// Kurdish and Arabic text legitimately needs them.
const STRIP_INVISIBLE = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F​‎‏‪-‮⁠⁦-⁩﻿]/g;
const HTML_TAG = /<[^>]*>/g;
/// Normalizes and sanitizes a user-supplied string: must already be a
/// string (no coercion — an object/array is rejected, not stringified),
/// NFC-normalized, invisible/control characters and HTML tags/angle
/// brackets removed, whitespace collapsed, trimmed, then length-checked.
/// Output is stored and rendered as plain text, never as HTML.
function cleanText(value, field, { max, min = 0, multiline = false }) {
    if (value === undefined || value === null) {
        if (min > 0)
            throw new https_1.HttpsError("invalid-argument", `${field} is required.`);
        return "";
    }
    if (typeof value !== "string") {
        throw new https_1.HttpsError("invalid-argument", `${field} must be text.`);
    }
    // Cap before regex work so a huge payload can't burn CPU.
    if (value.length > max * 4) {
        throw new https_1.HttpsError("invalid-argument", `${field} exceeds ${max} characters.`);
    }
    let text = value.normalize("NFC").replace(STRIP_INVISIBLE, "");
    text = text.replace(HTML_TAG, "").replace(/[<>]/g, "");
    text = multiline
        ? text.replace(/\r\n?/g, "\n").replace(/[ \t]+/g, " ").replace(/ ?\n ?/g, "\n").replace(/\n{3,}/g, "\n\n")
        : text.replace(/\s+/g, " ");
    text = text.trim();
    if (text.length > max) {
        throw new https_1.HttpsError("invalid-argument", `${field} exceeds ${max} characters.`);
    }
    if (text.length < min) {
        throw new https_1.HttpsError("invalid-argument", min === 1 ? `${field} is required.` : `${field} must be at least ${min} characters.`);
    }
    return text;
}
const ARABIC_SCRIPT_LETTER = /\p{Script=Arabic}/u;
const LATIN_LETTER = /\p{Script=Latin}/u;
function cleanLocalized(value, field, opts = {}) {
    const { max = 80, multiline = false, optional = false } = opts;
    if (optional && (value === undefined || value === null))
        return null;
    if (typeof value !== "object" || value === null || Array.isArray(value)) {
        throw new https_1.HttpsError("invalid-argument", `${field} needs Kurdish, Arabic and English.`);
    }
    const raw = value;
    const extra = Object.keys(raw).filter((k) => k !== "ku" && k !== "ar" && k !== "en");
    if (extra.length > 0) {
        throw new https_1.HttpsError("invalid-argument", `${field} has unsupported languages: ${extra.join(", ")}.`);
    }
    const min = optional ? 0 : 1;
    const ku = cleanText(raw.ku, `${field} (Kurdish)`, { max, min, multiline });
    const ar = cleanText(raw.ar, `${field} (Arabic)`, { max, min, multiline });
    const en = cleanText(raw.en, `${field} (English)`, { max, min, multiline });
    if (optional) {
        const filled = [ku, ar, en].filter(Boolean).length;
        if (filled === 0)
            return null;
        if (filled !== 3) {
            throw new https_1.HttpsError("invalid-argument", `${field}: fill in all three languages, or leave all empty.`);
        }
    }
    if (!ARABIC_SCRIPT_LETTER.test(ku)) {
        throw new https_1.HttpsError("invalid-argument", `${field} (Kurdish) must be written in Kurdish (Arabic script).`);
    }
    if (!ARABIC_SCRIPT_LETTER.test(ar)) {
        throw new https_1.HttpsError("invalid-argument", `${field} (Arabic) must be written in Arabic.`);
    }
    // English text may legitimately contain Arabic digits/symbols, but no Arabic-script letters.
    if (!LATIN_LETTER.test(en) || ARABIC_SCRIPT_LETTER.test(en)) {
        throw new https_1.HttpsError("invalid-argument", `${field} (English) must be written in English letters.`);
    }
    return { ku, ar, en };
}
function cleanEmail(value, field = "email") {
    const email = cleanText(value, field, { max: 254, min: 1 }).toLowerCase();
    // Intentionally simple — the approval email landing is the real check.
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) {
        throw new https_1.HttpsError("invalid-argument", "Enter a valid email address.");
    }
    return email;
}
function cleanPrice(value, field = "price") {
    if (typeof value !== "number" || !Number.isFinite(value) || value <= 0 || value > 1000000000) {
        throw new https_1.HttpsError("invalid-argument", `${field} must be a positive number.`);
    }
    // Max two decimals — no float dust like 0.1+0.2 reaching the database.
    return Math.round(value * 100) / 100;
}
function cleanEnum(value, allowed, field) {
    if (typeof value !== "string" || !allowed.includes(value)) {
        throw new https_1.HttpsError("invalid-argument", `${field} must be one of: ${allowed.join(", ")}.`);
    }
    return value;
}
/// Firestore document ids we generate are 20 chars [A-Za-z0-9]; reject
/// anything else before it's used as a path segment (no "/" injection).
function cleanDocId(value, field) {
    if (typeof value !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) {
        throw new https_1.HttpsError("invalid-argument", `${field} is invalid.`);
    }
    return value;
}
/// Free-form multilingual text for marketplace posts: any subset of the
/// supported content languages (en/ar/ku), at least one non-empty (unless
/// optional). Unlike cleanLocalized this does NOT demand all three languages
/// or a script match — a vendor posting in just Arabic or just English is
/// fine. Readers fall back from their own language to English to whatever
/// exists.
exports.POST_LANGUAGES = ["en", "ar", "ku"];
function cleanMultilingual(value, field, opts) {
    // Older clients sent a plain string — treat it as English.
    const raw = typeof value === "string" ? { en: value } : typeof value === "object" && value !== null && !Array.isArray(value)
        ? value
        : {};
    const extra = Object.keys(raw).filter((k) => !exports.POST_LANGUAGES.includes(k));
    if (extra.length > 0) {
        throw new https_1.HttpsError("invalid-argument", `${field} has unsupported languages: ${extra.join(", ")}.`);
    }
    const out = {};
    for (const lang of exports.POST_LANGUAGES) {
        const text = cleanText(raw[lang], `${field} (${lang})`, { max: opts.max, multiline: opts.multiline });
        if (text)
            out[lang] = text;
    }
    if (!opts.optional && Object.keys(out).length === 0) {
        throw new https_1.HttpsError("invalid-argument", `${field} is required in at least one language.`);
    }
    return out;
}
/// The single plain-text version stored next to the i18n map for readers
/// that don't know about languages: English if present, else the first.
function primaryText(t) {
    return t.en ?? t.ar ?? t.ku ?? "";
}
