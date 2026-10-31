import { test } from "node:test";
import assert from "node:assert/strict";
import { cleanEmail, cleanEnum, cleanMultilingual, cleanPrice, cleanText } from "../shared/validation/sanitize";
import { isValidPassword, isValidUsername, normalizeUsername } from "../shared/auth/password";

test("cleanText strips HTML, control characters and bidi overrides, and trims", () => {
  assert.equal(cleanText("  <b>Hello</b>  world ", "f", { max: 50 }), "Hello world");
  assert.equal(cleanText("a‮b\u0000c", "f", { max: 50 }), "abc");
});

test("cleanText enforces type and length", () => {
  assert.throws(() => cleanText({ evil: 1 }, "f", { max: 10 }));
  assert.throws(() => cleanText("x".repeat(11), "f", { max: 10 }));
  assert.throws(() => cleanText("", "f", { max: 10, min: 1 }));
  assert.equal(cleanText(undefined, "f", { max: 10 }), "");
});

test("cleanPrice rejects non-positive and rounds to cents", () => {
  assert.equal(cleanPrice(10.005), 10.01);
  assert.throws(() => cleanPrice(0));
  assert.throws(() => cleanPrice(-5));
  assert.throws(() => cleanPrice("10" as unknown as number));
});

test("cleanEmail and cleanEnum", () => {
  assert.equal(cleanEmail(" Me@Example.COM "), "me@example.com");
  assert.throws(() => cleanEmail("not-an-email"));
  assert.equal(cleanEnum("IQ", ["IQ", "CN"] as const, "c"), "IQ");
  assert.throws(() => cleanEnum("US", ["IQ", "CN"] as const, "c"));
});

test("cleanMultilingual keeps given languages and rejects unknown ones", () => {
  assert.deepEqual(cleanMultilingual({ en: "Panel", ar: "لوح" }, "t", { max: 50 }), { en: "Panel", ar: "لوح" });
  assert.deepEqual(cleanMultilingual("Plain", "t", { max: 50 }), { en: "Plain" });
  assert.throws(() => cleanMultilingual({ fr: "x" }, "t", { max: 50 }));
  assert.throws(() => cleanMultilingual({}, "t", { max: 50 }));
});

test("password and username rules", () => {
  assert.equal(isValidPassword("Abcdef1!"), true);
  assert.equal(isValidPassword("abcdef1!"), false); // no uppercase
  assert.equal(isValidPassword("Abc1!"), false); // too short
  assert.equal(isValidUsername(normalizeUsername("  Dano_95 ")), true);
  assert.equal(isValidUsername("a@b"), false);
  assert.equal(isValidUsername("ab"), false);
});
