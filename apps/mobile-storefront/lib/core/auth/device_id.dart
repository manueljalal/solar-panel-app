import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'solary_device_id';

/// A random id generated once per app install and persisted locally —
/// sent with OTP requests so the backend can rate-limit/flag by device,
/// not just by phone number (see backend/functions/src/auth/
/// request_phone_otp.ts's otpDeviceSends check). Not a hardware
/// fingerprint — it resets on reinstall, which is the right trade-off
/// here: this is an abuse-rate-limiting signal, not a security boundary.
Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_prefsKey);
  if (existing != null) return existing;

  final id = _generateId();
  await prefs.setString(_prefsKey, id);
  return id;
}

String _generateId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
