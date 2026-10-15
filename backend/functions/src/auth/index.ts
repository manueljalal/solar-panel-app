// Single credential model for all three roles (customer / vendor /
// super_admin): username + password, phone proven by a WhatsApp OTP at
// signup, new devices step up with another OTP.
// Role is only a custom claim granted later (approveVendorApplication /
// bootstrapSuperAdmin) — it never changes how someone signs in.
//
// set_vendor_password IS exported: approval ends with a one-time emailed
// "set your password" link. It writes the same users/{uid}.passwordHash
// that signUp/signIn use, so it is the same single credential — the vendor
// can then sign in with their username + that password everywhere.
//
// Deliberately NOT exported anymore (files left on disk, safe to delete):
// verify_phone_otp (passwordless phone login) and vendor_password_sign_in
// (separate email+password vendor credential).
export * from "./request_phone_otp";
export * from "./sign_up";
export * from "./sign_in";
export * from "./sign_in_otp_step_up";
export * from "./set_vendor_password";
