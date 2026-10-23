import 'package:flutter_test/flutter_test.dart';
import 'package:solary_marketplace/core/auth/phone_number.dart';
import 'package:solary_marketplace/shared/formatting/money.dart';

void main() {
  test('formatPhone groups Iraqi numbers and leaves others alone', () {
    expect(formatPhone('+9647501234567'), '+964 750 123 4567');
    expect(formatPhone('+905321234567'), '+905321234567');
  });

  test('normalizePhoneInput accepts what people type and returns E.164', () {
    expect(normalizePhoneInput('0750 123 4567'), '+9647501234567');
    expect(normalizePhoneInput('00964 750 123 4567'), '+9647501234567');
    expect(normalizePhoneInput('+964 (750) 123-4567'), '+9647501234567');
    expect(normalizePhoneInput('٠٧٥٠١٢٣٤٥٦٧'), '+9647501234567');
    expect(normalizePhoneInput('۰۷۵۰۱۲۳۴۵۶۷'), '+9647501234567');
    expect(normalizePhoneInput('12345'), isNull);
    expect(normalizePhoneInput(''), isNull);
  });

  test('formatMoney and formatTotals', () {
    expect(formatMoney(189, 'USD'), '\$189');
    expect(formatMoney(1240.5, 'USD'), '\$1,240.50');
    expect(formatMoney(250000, 'IQD'), 'IQD 250,000');
    expect(formatTotals({'IQD': 250000, 'USD': 378}), '\$378 + IQD 250,000');
    expect(formatTotals({}), '\$0');
  });
}
