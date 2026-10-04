import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/main.dart';

import 'support/fake_home_repository.dart';

void main() {
  testWidgets('Account tab offers Sign in, which opens username/password sign-in and links to sign-up',
      (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is! NetworkImageLoadException) originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(SolaryMarketplaceApp(homeRepository: FakeHomeRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    // Guest state — no Firebase in tests, so the anonymous sign-in never
    // resolves; the "Sign in" entry point should still be reachable.
    expect(find.text('Sign in'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // Username + password is the sign-in credential now — no phone/OTP
    // fields on this screen (those only appear mid-flow if the backend
    // demands device step-up, which needs a real Firebase backend to
    // trigger and isn't exercised here).
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Reach sign-up from sign-in.
    await tester.tap(find.text('Need an account? Create one'));
    await tester.pumpAndSettle();
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Your location'), findsOneWidget);
  });
}
