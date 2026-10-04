/// A location picked on the map — coordinates plus a reverse-geocoded,
/// human-readable address. The address is a best-effort label (OSM's free
/// Nominatim-backed geocoder), never the source of truth for the actual
/// coordinates, which is what gets stored and used for anything precise
/// (e.g. showing the pin again later).
class PickedLocation {
  const PickedLocation({required this.latitude, required this.longitude, required this.address});

  final double latitude;
  final double longitude;
  final String address;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  static PickedLocation? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final lat = json['latitude'];
    final lng = json['longitude'];
    if (lat is! num || lng is! num) return null;
    return PickedLocation(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      address: json['address'] as String? ?? '',
    );
  }
}
