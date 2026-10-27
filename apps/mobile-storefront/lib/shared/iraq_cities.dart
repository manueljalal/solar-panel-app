/// Iraq's governorate capitals, with names in English, Arabic and Sorani
/// Kurdish plus common alternative spellings, so a vendor city typed as
/// "ERBIL", "Hawler", "أربيل" or "هەولێر" all resolve to the same city.
class IraqCity {
  const IraqCity(this.id, this.en, this.ar, this.ku, [this.aliases = const []]);

  /// Stable id; also the value stored for a vendor's city (English name).
  final String id;
  final String en;
  final String ar;
  final String ku;
  final List<String> aliases;

  String nameFor(String languageCode) => switch (languageCode) {
        'ar' => ar,
        'ckb' || 'ku' => ku,
        _ => en,
      };

  Iterable<String> get _names => [en, ar, ku, ...aliases];
}

const iraqCities = <IraqCity>[
  IraqCity('Baghdad', 'Baghdad', 'بغداد', 'بەغدا', ['bagdad', 'بەغداد']),
  IraqCity('Basra', 'Basra', 'البصرة', 'بەسرە', ['basrah', 'بصرة', 'البصره']),
  IraqCity('Erbil', 'Erbil', 'أربيل', 'هەولێر', ['arbil', 'irbil', 'hawler', 'hewler', 'hawlir', 'اربيل', 'هولير', 'ئەربیل']),
  IraqCity('Sulaymaniyah', 'Sulaymaniyah', 'السليمانية', 'سلێمانی', ['sulaimani', 'sulaimaniya', 'sulaymaniya', 'slemani', 'suli', 'السليمانيه', 'سليمانية']),
  IraqCity('Duhok', 'Duhok', 'دهوك', 'دهۆک', ['dohuk', 'dahuk', 'duhuk', 'دهۆک']),
  IraqCity('Halabja', 'Halabja', 'حلبجة', 'هەڵەبجە', ['حلبجه']),
  IraqCity('Kirkuk', 'Kirkuk', 'كركوك', 'کەرکووک', ['kerkuk', 'كركوك']),
  IraqCity('Mosul', 'Mosul', 'الموصل', 'مووسڵ', ['mosel', 'nineveh', 'ninawa', 'موصل', 'نينوى']),
  IraqCity('Najaf', 'Najaf', 'النجف', 'نەجەف', ['نجف']),
  IraqCity('Karbala', 'Karbala', 'كربلاء', 'کەربەلا', ['kerbala', 'كربلا']),
  IraqCity('Hillah', 'Hillah', 'الحلة', 'حیللە', ['hilla', 'babil', 'babylon', 'حلة', 'بابل']),
  IraqCity('Ramadi', 'Ramadi', 'الرمادي', 'ڕەمادی', ['anbar', 'رمادي', 'الانبار', 'الأنبار']),
  IraqCity('Baqubah', 'Baqubah', 'بعقوبة', 'بەعقووبە', ['baquba', 'diyala', 'بعقوبه', 'ديالى']),
  IraqCity('Tikrit', 'Tikrit', 'تكريت', 'تکریت', ['salahaddin', 'salah al-din', 'صلاح الدين']),
  IraqCity('Kut', 'Kut', 'الكوت', 'کووت', ['wasit', 'كوت', 'واسط']),
  IraqCity('Amarah', 'Amarah', 'العمارة', 'عەمارە', ['amara', 'maysan', 'عمارة', 'ميسان']),
  IraqCity('Nasiriyah', 'Nasiriyah', 'الناصرية', 'ناسرییە', ['nasiriya', 'dhi qar', 'ناصرية', 'ذي قار']),
  IraqCity('Diwaniyah', 'Diwaniyah', 'الديوانية', 'دیوانییە', ['diwaniya', 'qadisiyah', 'ديوانية', 'القادسية']),
  IraqCity('Samawah', 'Samawah', 'السماوة', 'سەماوە', ['samawa', 'muthanna', 'سماوة', 'المثنى']),
];

// Lowercase, no spaces/punctuation/tatweel, Arabic letter variants unified
// (أإآ→ا, ة→ه, ى→ي), so spelling differences don't break matching.
String _normalize(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r"[\s\-_.'’ـ]"), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي');

final Map<String, IraqCity> _index = {
  for (final c in iraqCities)
    for (final n in c._names) _normalize(n): c,
};

/// The Iraqi city a free-text city refers to, or null if unrecognised.
IraqCity? matchIraqCity(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return _index[_normalize(raw)];
}

IraqCity? iraqCityById(String? id) {
  for (final c in iraqCities) {
    if (c.id == id) return c;
  }
  return null;
}
