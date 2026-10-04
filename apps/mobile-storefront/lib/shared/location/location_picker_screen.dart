import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import 'picked_location.dart';

// Erbil, Iraq — reasonable default center when no GPS fix / no initial
// location is available yet, matching the rest of the app's Erbil-first
// assumption (see HomeAppBar's location label).
const _defaultCenter = LatLng(36.1911, 44.0092);

/// Pick a location on a real OpenStreetMap map — tap/drag to place a pin,
/// or tap "Use my location" to center on a GPS fix. On confirm, reverse-
/// geocodes the pin to a human-readable address via the `geocoding`
/// package (platform-native geocoder, not a paid API) and returns a
/// PickedLocation. Uses OpenStreetMap tiles (via flutter_map), not Google
/// Maps — no API key or billing account required, which matters for a
/// marketplace targeting Iraq where Google's own data is already patchy.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  final PickedLocation? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final _mapController = MapController();
  late LatLng _center = widget.initial != null
      ? LatLng(widget.initial!.latitude, widget.initial!.longitude)
      : _defaultCenter;

  bool _locating = false;
  bool _confirming = false;
  String? _error;

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _error = l10n.locationPermissionDenied;
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _error = l10n.locationServiceDisabled;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final target = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = target;
        _locating = false;
      });
      _mapController.move(target, 16);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _error = l10n.locationFetchFailed;
      });
    }
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      String address = '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(_center.latitude, _center.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.street, p.subLocality, p.locality, p.administrativeArea, p.country]
              .where((s) => s != null && s.trim().isNotEmpty)
              .toSet() // drop accidental duplicates (e.g. street == locality)
              .toList();
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {
        // Reverse geocoding is best-effort — coordinates alone are still a
        // valid, usable result, so a geocoder failure isn't fatal here.
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        PickedLocation(latitude: _center.latitude, longitude: _center.longitude, address: address),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _error = l10n.locationFetchFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pickLocationTitle, style: AppTypography.h1.copyWith(fontSize: 18)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onTap: (_, point) => setState(() => _center = point),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) setState(() => _center = position.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.solary.solary_marketplace',
              ),
            ],
          ),
          // Fixed center-screen pin — the map pans under it (onPositionChanged
          // tracks the center), which is the standard "drag the map, not the
          // pin" pattern for a single-point picker.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on, size: 44, color: AppColors.accent),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: 160,
            child: FloatingActionButton.small(
              heroTag: 'use-current-location',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.ink900,
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.pickLocationHint, style: AppTypography.bodyMuted),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(_error!, style: const TextStyle(color: AppColors.warning, fontSize: 12.5)),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirming ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                      ),
                      child: _confirming
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.confirmLocation, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
