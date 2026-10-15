// Entry point — re-export grouped Cloud Functions by domain. Callables are
// addressed as "<group>-<name>" (e.g. storefront-placeOrder). Keeping them
// split avoids one giant cold-start bundle.

export * as admin from "./admin";
export * as vendor from "./vendor";
export * as bulk from "./bulk";
export * as storefront from "./storefront";
export * as auth from "./auth";
export * as scheduled from "./scheduled";
