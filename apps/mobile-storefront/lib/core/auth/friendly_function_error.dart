import 'package:cloud_functions/cloud_functions.dart';

/// Cloud Functions returns `e.message == "INTERNAL"` (literally that
/// string) whenever the server throws anything that ISN'T a deliberate
/// HttpsError — e.g. a real bug in the function. That's by design (never
/// leak a stack trace to the client), but showing the raw code verbatim
/// in the UI ("INTERNAL") is meaningless to a user. Use this instead of
/// `e.message` directly wherever a FirebaseFunctionsException reaches the
/// UI, so an unexpected server error always falls back to [fallback]
/// rather than a bare error code.
String friendlyFunctionError(FirebaseFunctionsException e, String fallback) {
  const nonUserFacing = {'internal', 'unknown', 'unavailable', 'deadline-exceeded', 'data-loss'};
  if (nonUserFacing.contains(e.code)) return fallback;
  return e.message ?? fallback;
}
