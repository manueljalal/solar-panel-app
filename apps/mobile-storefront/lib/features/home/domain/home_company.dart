/// A vendor/company shown in the home screen's "Companies" directory.
/// Maps 1:1 to a document in the Firestore `vendors` collection.
class HomeCompany {
  const HomeCompany({
    required this.name,
    required this.city,
    required this.rating,
    required this.logoUrl,
  });

  factory HomeCompany.fromFirestore(Map<String, dynamic> data) {
    return HomeCompany(
      name: data['businessName'] as String? ?? 'Unnamed vendor',
      city: data['city'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      logoUrl: data['logoUrl'] as String? ?? '',
    );
  }

  final String name;
  final String city;
  final double rating;
  final String logoUrl;
}

