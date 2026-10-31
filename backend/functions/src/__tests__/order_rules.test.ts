import { test } from "node:test";
import assert from "node:assert/strict";
import { transitionError } from "../shared/order_rules";

test("happy path: placed -> confirmed -> out_for_delivery -> delivered", () => {
  assert.equal(transitionError("placed", "confirmed", "vendor"), null);
  assert.equal(transitionError("confirmed", "out_for_delivery", "vendor"), null);
  assert.equal(transitionError("out_for_delivery", "delivered", "vendor"), null);
});

test("no skipping steps or reopening finished orders", () => {
  assert.notEqual(transitionError("placed", "delivered", "vendor"), null);
  assert.notEqual(transitionError("delivered", "placed", "super_admin"), null);
  assert.notEqual(transitionError("cancelled", "confirmed", "super_admin"), null);
  assert.notEqual(transitionError("out_for_delivery", "cancelled", "vendor"), null);
});

test("customers may only cancel, and only before the vendor confirms", () => {
  assert.equal(transitionError("placed", "cancelled", "customer"), null);
  assert.notEqual(transitionError("confirmed", "cancelled", "customer"), null);
  assert.notEqual(transitionError("placed", "confirmed", "customer"), null);
});
