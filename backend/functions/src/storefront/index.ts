// Barrel for storefront functions. Reads (products, vendors) still go
// directly from the Flutter/web clients to Firestore via the public
// `allow read: if true` rules — only writes that need a verified uid or
// server-side validation go through a callable.
export * from "./quotes";
