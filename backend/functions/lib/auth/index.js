"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
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
__exportStar(require("./request_phone_otp"), exports);
__exportStar(require("./sign_up"), exports);
__exportStar(require("./sign_in"), exports);
__exportStar(require("./sign_in_otp_step_up"), exports);
__exportStar(require("./set_vendor_password"), exports);
