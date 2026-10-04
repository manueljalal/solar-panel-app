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
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.hashPassword = hashPassword;
exports.verifyPassword = verifyPassword;
exports.isValidUsername = isValidUsername;
exports.isValidPassword = isValidPassword;
exports.normalizeUsername = normalizeUsername;
const bcrypt = __importStar(require("bcryptjs"));
// 12 rounds — the standard, well-reviewed balance for bcrypt (NIST/OWASP
// guidance): expensive enough to resist offline brute force at realistic
// hardware cost, cheap enough not to bottleneck a Cloud Function
// invocation (well under a second).
const SALT_ROUNDS = 12;
function hashPassword(password) {
    return bcrypt.hash(password, SALT_ROUNDS);
}
function verifyPassword(password, hash) {
    return bcrypt.compare(password, hash);
}
const USERNAME_PATTERN = /^[a-z0-9_]{3,20}$/;
function isValidUsername(username) {
    return USERNAME_PATTERN.test(username);
}
// Strict complexity: 8+ chars, at least one uppercase, one lowercase, one
// digit, one symbol. Enforced server-side — this is the real boundary;
// any client-side check is just fast feedback, never trusted alone.
const HAS_UPPER = /[A-Z]/;
const HAS_LOWER = /[a-z]/;
const HAS_DIGIT = /[0-9]/;
const HAS_SYMBOL = /[^A-Za-z0-9]/;
function isValidPassword(password) {
    return (password.length >= 8 &&
        HAS_UPPER.test(password) &&
        HAS_LOWER.test(password) &&
        HAS_DIGIT.test(password) &&
        HAS_SYMBOL.test(password));
}
function normalizeUsername(username) {
    return username.trim().toLowerCase();
}
