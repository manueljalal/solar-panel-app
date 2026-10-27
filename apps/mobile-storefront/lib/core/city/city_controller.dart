import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/iraq_cities.dart';

const _prefsKey = 'solary_city';

/// The shopper's city (an IraqCity id), shown in the Home header and
/// Account → Location. Saved on the device so it works for guests too.
class CityController extends ValueNotifier<String?> {
  CityController._() : super(null) {
    _restore();
  }

  static final instance = CityController._();

  IraqCity? get city => iraqCityById(value);

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_prefsKey);
      if (iraqCityById(id) != null) value = id;
    } catch (_) {
      // No storage (e.g. widget tests): start without a city.
    }
  }

  Future<void> set(String id) async {
    if (iraqCityById(id) == null) return;
    value = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, id);
    } catch (_) {}
  }
}
