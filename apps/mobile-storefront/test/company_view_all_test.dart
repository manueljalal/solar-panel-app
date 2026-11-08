import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/features/home/domain/home_company.dart';
import 'package:solary_marketplace/features/home/presentation/widgets/company_row.dart';
import 'package:solary_marketplace/l10n/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      home: Scaffold(body: child),
    );

List<HomeCompany> _companies(int n) => [
      for (var i = 0; i < n; i++) HomeCompany(id: 'c$i', name: 'Company $i', city: 'Erbil', rating: 0, logoUrl: ''),
    ];

void main() {
  testWidgets('more than six companies: five tiles, then View all opening the full grid', (tester) async {
    await tester.pumpWidget(_app(CompanyRow(companies: _companies(9))));
    await tester.pumpAndSettle();
    expect(find.text('Company 4'), findsOneWidget);
    expect(find.text('Company 5'), findsNothing);
    expect(find.text('View all'), findsOneWidget);

    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    expect(find.text('All companies'), findsOneWidget);
    expect(find.text('Company 8'), findsOneWidget);
  });

  testWidgets('six or fewer companies are all shown, no View all', (tester) async {
    await tester.pumpWidget(_app(CompanyRow(companies: _companies(6))));
    await tester.pumpAndSettle();
    expect(find.text('Company 5'), findsOneWidget);
    expect(find.text('View all'), findsNothing);
  });
}
