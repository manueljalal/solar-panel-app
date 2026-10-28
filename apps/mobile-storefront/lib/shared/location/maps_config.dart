import 'package:flutter/services.dart';

/// Whether a Google Maps API key was provided (ios/Flutter/MapsKey.xcconfig,
/// android/local.properties). Without one the location picker uses
/// OpenStreetMap instead — Google Maps would crash on iOS with no key.
class MapsConfig {
  MapsConfig._();

  static const _channel = MethodChannel('solary/maps');
  static Future<bool>? _cached;

  static Future<bool> isGoogleConfigured() => _cached ??= _channel
      .invokeMethod<bool>('isConfigured')
      .then((v) => v ?? false)
      .catchError((_) => false); // tests / platforms without the channel
}
