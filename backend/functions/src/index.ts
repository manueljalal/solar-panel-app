// Entry point — re-export grouped Cloud Functions by domain.
// Each group below is a placeholder namespace to fill in as endpoints
// are implemented. Keeping them split avoids one giant cold-start bundle.

export * as admin from "./admin";
export * as vendor from "./vendor";
export * as storefront from "./storefront";
