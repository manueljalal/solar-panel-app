import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/core/auth/phone_number.dart';

void main() {
  test('formatPhone groups Iraqi numbers and leaves others alone', () {
    expect(formatPhone('+9647501234567'), '+964 750 123 4567');
    expect(formatPhone('+905321234567'), '+905321234567');
  });
}
