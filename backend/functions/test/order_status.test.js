// Unit tests for the pure order logic. Runs against the compiled output:
//   npm test   (= tsc && node --test test/*.test.js)
const { test } = require("node:test");
const assert = require("node:assert/strict");
const { canTransition, nextStatusesFor, groupLines, sumMoney, addRating } = require("../lib/shared/orders/status");

test("vendor moves forward one step at a time", () => {
  assert.ok(canTransition("vendor", "placed", "confirmed"));
  assert.ok(canTransition("vendor", "confirmed", "installation_scheduled"));
  assert.ok(canTransition("vendor", "installation_scheduled", "installer_en_route"));
  assert.ok(!canTransition("vendor", "placed", "installation_scheduled"), "no skipping");
  assert.ok(!canTransition("vendor", "confirmed", "placed"), "no going back");
});

test("vendor can never verify its own installation", () => {
  assert.ok(!canTransition("vendor", "installer_en_route", "installed_verified"));
  assert.deepEqual(nextStatusesFor("vendor", "installer_en_route"), []);
});

test("vendor cancels only before dispatch", () => {
  assert.ok(canTransition("vendor", "placed", "cancelled"));
  assert.ok(canTransition("vendor", "confirmed", "cancelled"));
  assert.ok(!canTransition("vendor", "installation_scheduled", "cancelled"));
});

test("customer cancels while placed and confirms installation", () => {
  assert.ok(canTransition("customer", "placed", "cancelled"));
  assert.ok(!canTransition("customer", "confirmed", "cancelled"));
  assert.ok(canTransition("customer", "installer_en_route", "installed_verified"));
  assert.ok(!canTransition("customer", "placed", "confirmed"));
});

test("final states are final for everyone, admin included", () => {
  for (const actor of ["customer", "vendor", "super_admin"]) {
    assert.ok(!canTransition(actor, "cancelled", "placed"));
    assert.ok(!canTransition(actor, "installed_verified", "cancelled"));
  }
  assert.ok(canTransition("super_admin", "placed", "installed_verified"));
});

test("groupLines splits by vendor and currency, stable order", () => {
  const groups = groupLines([
    { vendorId: "a", currency: "USD", id: 1 },
    { vendorId: "b", currency: "USD", id: 2 },
    { vendorId: "a", currency: "IQD", id: 3 },
    { vendorId: "a", currency: "USD", id: 4 },
  ]);
  assert.deepEqual([...groups.keys()], ["a_USD", "b_USD", "a_IQD"]);
  assert.deepEqual(groups.get("a_USD").map((l) => l.id), [1, 4]);
});

test("sumMoney avoids float dust", () => {
  assert.equal(sumMoney([0.1, 0.2]), 0.3);
  assert.equal(sumMoney([19.99, 0.01, 100]), 120);
});

test("addRating keeps a running average", () => {
  assert.deepEqual(addRating(0, 0, 4), { average: 4, count: 1 });
  assert.deepEqual(addRating(4, 1, 5), { average: 4.5, count: 2 });
  assert.deepEqual(addRating(4.5, 2, 1), { average: 3.33, count: 3 });
});
