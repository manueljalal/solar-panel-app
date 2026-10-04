// Integration test — hits the REAL Firestore project (flutter-firebase-
// connect-ec83e), not a fake. Confirms the seeded `vendors`/`products`
// collections are actually reachable and shaped the way HomeRepository
// expects. Requires network + Firebase.initializeApp(), which plain
// `flutter test` doesn't provide, so this is skipped by default — run it
// explicitly with:
//   flutter test test/home_repository_integration_test.dart --dart-define=RUN_INTEGRATION=true
// after `flutter pub get` on a machine with the Firebase CLI logged in
// and network access.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/home/data/home_repository.dart';
import 'package:solary_marketplace/firebase_options.dart';

void main() {
  const runIntegration = bool.fromEnvironment('RUN_INTEGRATION', defaultValue: false);

  group('HomeRepository against live Firestore', () {
    setUpAll(() async {
      if (!runIntegration) return;
      TestWidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    });

    test('fetchCompanies returns the 3 seeded vendors, not the fallback', () async {
      final repo = HomeRepository();
      final companies = await repo.fetchCompanies();

      expect(companies.length, 3);
      expect(companies.map((c) => c.name), containsAll(['SunBridge Energy', 'Helios Power Co.', 'GreenTech Iraq']));
    }, skip: !runIntegration);

    test('fetchProducts returns the 4 seeded products with resolved vendor names', () async {
      final repo = HomeRepository();
      final products = await repo.fetchProducts();

      expect(products.length, 4);
      final panel = products.firstWhere((p) => p.title == 'Tiger Neo Mono Panel');
      expect(panel.vendor, 'SunBridge Energy'); // resolved from vendorId, not a raw id
      expect(panel.price, '\$189');
      if (kDebugMode) {
        // ignore: avoid_print
        print('Live products: ${products.map((p) => p.title).join(', ')}');
      }
    }, skip: !runIntegration);
  });
}
