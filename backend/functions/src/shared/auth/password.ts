import * as bcrypt from "bcryptjs";

// 12 rounds — the standard, well-reviewed balance for bcrypt (NIST/OWASP
// guidance): expensive enough to resist offline brute force at realistic
// hardware cost, cheap enough not to bottleneck a Cloud Function
// invocation (well under a second).
const SALT_ROUNDS = 12;

export function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

export function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

const USERNAME_PATTERN = /^[a-z0-9_]{3,20}$/;

export function isValidUsername(username: string): boolean {
  return USERNAME_PATTERN.test(username);
}

// Strict complexity: 8+ chars, at least one uppercase, one lowercase, one
// digit, one symbol. Enforced server-side — this is the real boundary;
// any client-side check is just fast feedback, never trusted alone.
const HAS_UPPER = /[A-Z]/;
const HAS_LOWER = /[a-z]/;
const HAS_DIGIT = /[0-9]/;
const HAS_SYMBOL = /[^A-Za-z0-9]/;

export function isValidPassword(password: string): boolean {
  return (
    password.length >= 8 &&
    HAS_UPPER.test(password) &&
    HAS_LOWER.test(password) &&
    HAS_DIGIT.test(password) &&
    HAS_SYMBOL.test(password)
  );
}

export function normalizeUsername(username: string): string {
  return username.trim().toLowerCase();
}
