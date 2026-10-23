// Run with `npm test` — builds src/ to lib/ first, then tests the compiled
// output with Node's built-in runner (no extra test dependency).
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { normalizePhone, assertTransition } = require("../lib/shared/orders/order_status");

test("normalizePhone accepts common Iraqi formats and returns E.164", () => {
  assert.equal(normalizePhone("0750 123 4567"), "+9647501234567");
  assert.equal(normalizePhone("00964 750 123 4567"), "+9647501234567");
  assert.equal(normalizePhone("+964 (750) 123-4567"), "+9647501234567");
  assert.equal(normalizePhone("٠٧٥٠١٢٣٤٥٦٧"), "+9647501234567");
  assert.equal(normalizePhone("۰۷۵۰۱۲۳۴۵۶۷"), "+9647501234567");
});

test("normalizePhone rejects anything that isn't a phone number", () => {
  for (const bad of ["", "12345", "hello", null, 7501234567, "0".repeat(41)]) {
    assert.throws(() => normalizePhone(bad), { code: "invalid-argument" });
  }
});

test("assertTransition allows only forward moves and cancellation before delivery", () => {
  assertTransition("placed", "confirmed");
  assertTransition("confirmed", "shipped");
  assertTransition("shipped", "delivered");
  assertTransition("placed", "cancelled");
  assertTransition("shipped", "cancelled");
  for (const [from, to] of [
    ["placed", "shipped"],
    ["placed", "delivered"],
    ["delivered", "cancelled"],
    ["cancelled", "placed"],
    ["confirmed", "placed"],
  ]) {
    assert.throws(() => assertTransition(from, to), { code: "failed-precondition" });
  }
});
