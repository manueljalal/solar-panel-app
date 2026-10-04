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

// Fallback content only — used by widget tests (no Firestore in the test
// environment) and as an offline/error fallback in CompanyRow. The backend
// exists now: real reads go through HomeRepository against the `vendors`
// collection, seeded via scripts/seed-firestore.mjs with this exact data.
const homeCompanies = [
  HomeCompany(
    name: 'SunBridge Energy',
    city: 'Erbil',
    rating: 4.9,
    logoUrl: 'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=400&q=80',
  ),
  HomeCompany(
    name: 'Helios Power Co.',
    city: 'Sulaymaniyah',
    rating: 4.8,
    logoUrl: 'https://images.unsplash.com/photo-1497440001374-f26997328c1b?w=400&q=80',
  ),
  HomeCompany(
    name: 'GreenTech Iraq',
    city: 'Basra',
    rating: 4.7,
    logoUrl: 'https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=400&q=80',
  ),
];
