import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../features/account/data/profile_repository.dart';
import '../../shared/iraq_cities.dart';
import '../../shared/location/picked_location.dart';
import '../city/city_controller.dart';

class SavedAddress {
  const SavedAddress({required this.location, required this.line});

  final PickedLocation location;

  /// Street, building, nearest landmark.
  final String line;
}

/// The signed-in customer's delivery address, kept on their profile so
/// checkout and service booking are filled in automatically instead of
/// asking for the map pin every time. Set at sign-up (location), updated
/// whenever a different address is used, and editable from Account.
class AddressBook extends ValueNotifier<SavedAddress?> {
  AddressBook._() : super(null);

  static final instance = AddressBook._();

  final _profiles = ProfileRepository();
  String? _loadedFor; // uid whose address `value` holds

  bool get _signedIn {
    final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous;
  }

  /// The saved address (loaded once per signed-in user).
  Future<SavedAddress?> load({bool refresh = false}) async {
    if (!_signedIn) return value = null;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (!refresh && _loadedFor == uid) return value;
    try {
      final p = await _profiles.get();
      _loadedFor = uid;
      value = p.location == null ? null : SavedAddress(location: p.location!, line: p.addressLine);
      _syncCity();
    } catch (_) {
      // Prefill is a convenience; the forms still work empty.
    }
    return value;
  }

  /// Remember [location]/[line] if they differ from what's saved.
  Future<void> remember(PickedLocation location, String line) async {
    if (!_signedIn) return;
    final current = value;
    final same = current != null &&
        (current.location.latitude - location.latitude).abs() < 1e-6 &&
        (current.location.longitude - location.longitude).abs() < 1e-6 &&
        current.line == line;
    if (same) return;
    try {
      await _profiles.update(location: location, addressLine: line);
      value = SavedAddress(location: location, line: line);
      _syncCity();
    } catch (_) {}
  }

  /// If the shopper hasn't picked a city yet, take it from the address.
  void _syncCity() {
    if (CityController.instance.value != null || value == null) return;
    for (final part in value!.location.address.split(',')) {
      final city = matchIraqCity(part);
      if (city != null) {
        CityController.instance.set(city.id);
        return;
      }
    }
  }

  /// Forget the cached address (e.g. on sign-out).
  void clear() {
    _loadedFor = null;
    value = null;
  }
}
