import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/core/auth/phone_number.dart';

void main() {
  test('formatPhone groups Iraqi numbers and leaves others alone', () {
    expect(formatPhone('+9647501234567'), '+964 750 123 4567');
    expect(formatPhone('+905321234567'), '+905321234567');
  });

  test('normalizePhone accepts common local formats', () {
    expect(normalizePhone('0750 123 4567'), '+9647501234567');
    expect(normalizePhone('00964-750-123-4567'), '+9647501234567');
    expect(normalizePhone(' +964 (750) 123 4567 '), '+9647501234567');
    expect(isValidE164(normalizePhone('0750 123 4567')), isTrue);
    expect(isValidE164(normalizePhone('12345')), isFalse);
  });
}
