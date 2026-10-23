import 'dart:async';

import 'package:solary_marketplace/shared/widgets/placeholder_image.dart';

/// Runs before every test file (flutter_test picks this file up by name).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  NetworkImageWithFallback.useDiskCache = false;
  await testMain();
}
