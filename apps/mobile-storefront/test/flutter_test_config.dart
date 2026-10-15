import 'dart:async';

import 'package:solary_marketplace/shared/widgets/placeholder_image.dart';

/// Loaded automatically by `flutter test` before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Network images can never load in the test VM; render their fallback
  // instead of an endless loading spinner.
  NetworkImageWithFallback.networkEnabled = false;
  await testMain();
}
