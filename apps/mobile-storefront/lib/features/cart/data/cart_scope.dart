import 'package:flutter/material.dart';
import 'cart_controller.dart';

/// Makes one shared CartController available to the whole widget tree
/// without a DI package — wrap the app root in this once (see main.dart),
/// then call `CartScope.of(context)` anywhere to read/mutate the cart.
class CartScope extends InheritedNotifier<CartController> {
  const CartScope({super.key, required CartController controller, required super.child})
      : super(notifier: controller);

  static CartController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'CartScope.of() called with no CartScope ancestor — wrap the app root in one.');
    return scope!.notifier!;
  }
}
