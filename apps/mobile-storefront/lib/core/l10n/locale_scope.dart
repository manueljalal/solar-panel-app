import 'package:flutter/material.dart';
import 'locale_controller.dart';

/// Makes one shared LocaleController available to the whole widget tree —
/// wrap the app root in this once (see main.dart), then call
/// `LocaleScope.of(context)` anywhere to read the current locale or call
/// `.setLocale(...)` (e.g. from the Account tab's language picker).
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({super.key, required LocaleController controller, required super.child})
      : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope.of() called with no LocaleScope ancestor — wrap the app root in one.');
    return scope!.notifier!;
  }
}
