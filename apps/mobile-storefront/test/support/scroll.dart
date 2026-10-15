import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls the home feed until [finder] sits mid-screen. scrollUntilVisible
/// alone stops as soon as any pixel is in the viewport — often right under
/// the bottom navigation bar, where a tap lands on the bar instead.
Future<void> revealInFeed(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
}
