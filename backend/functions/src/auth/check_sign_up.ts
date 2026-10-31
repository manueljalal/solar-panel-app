import { onCall, HttpsError } from "firebase-functions/v2/https";
import { isPhoneRegistered, isUsernameAvailable } from "../shared/auth/signup_checks";
import { isValidUsername, normalizeUsername } from "../shared/auth/password";
import { LIMITS, clientIp, enforceRateLimit } from "../shared/rate_limit";

interface CheckSignUpInput {
  username: string;
  phone: string;
}

const E164_PATTERN = /^\+[1-9]\d{6,14}$/;

/// Pre-flight for the sign-up form, called BEFORE a WhatsApp code is sent:
/// tells the user that the username or phone is already taken while they
/// can still change it, instead of after the one-time code was spent.
/// Needs no sign-in (the user has no account yet). Like any sign-up form it
/// reveals whether a username/phone is registered; the code requirement on
/// signUp itself is what protects accounts.
export const checkSignUp = onCall<CheckSignUpInput>({ region: "us-central1" }, async (request) => {
    await enforceRateLimit(`signup-check:${clientIp(request)}`, 30, LIMITS.HOUR);
  const username = normalizeUsername(request.data?.username ?? "");
  const phone = request.data?.phone?.trim() ?? "";
  if (!isValidUsername(username)) {
    throw new HttpsError("invalid-argument", "username must be 3-20 characters: lowercase letters, numbers, underscores only.");
  }
  if (!E164_PATTERN.test(phone)) {
    throw new HttpsError("invalid-argument", "phone must be in E.164 format, e.g. +9647501234567.");
  }
  const [usernameFree, phoneTaken] = await Promise.all([isUsernameAvailable(username), isPhoneRegistered(phone)]);
  return { usernameTaken: !usernameFree, phoneTaken };
});
