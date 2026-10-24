import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';
import 'support/finders.dart';

void main() {
  testWidgets('Featured masonry and product grid render with no overflow', (tester) async {
    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    await scrollHomeTo(tester, find.text('Featured'));
    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('Wattage calculator'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await scrollHomeTo(tester, find.text('Best sellers'));
    expect(find.text('Best sellers'), findsOneWidget);
    await scrollHomeTo(tester, find.text('Tiger Neo Mono Panel'));
    expect(find.text('Tiger Neo Mono Panel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
