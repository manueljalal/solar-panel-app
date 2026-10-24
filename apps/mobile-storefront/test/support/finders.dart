import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Home tab's main vertical scroll view (not the horizontal rows
/// inside it).
Finder homeScrollable() =>
    find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;

/// A bottom-nav tab by its label — the same words also appear on Home
/// (e.g. the "Learn" teaser), so plain find.text would be ambiguous.
Finder navTab(String label) =>
    find.descendant(of: find.byType(BottomNavigationBar), matching: find.text(label));

/// Scrolls [finder] fully into view on Home (not just touching the edge,
/// where a tap could miss) and settles.
Future<void> scrollHomeTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: homeScrollable());
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
