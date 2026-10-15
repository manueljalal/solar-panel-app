import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Every language a post can be written in — the same three the app and
/// products use.
const bulkPostLanguages = <(String code, String label)>[
  ('en', 'English'),
  ('ar', 'العربية'),
  ('ku', 'کوردی'),
];

/// The language tabs the form offers. Picking one switches the whole form
/// (labels, hints, direction) into that language.
List<(String code, String label)> postLanguagesFor(String formLanguage) =>
    bulkPostLanguages;

/// The app locale whose strings the form shows for a post language.
Locale localeForPostLanguage(String code) => switch (code) {
  'ar' => const Locale('ar'),
  'ku' => const Locale('ckb'),
  _ => const Locale('en'),
};

/// The post language matching the app's current language — where the form
/// opens.
String postLanguageForApp(String appLanguageCode) => switch (appLanguageCode) {
  'ar' => 'ar',
  'ckb' => 'ku',
  _ => 'en',
};

bool isRtlPostLanguage(String code) => code == 'ar' || code == 'ku';

/// Title + details in any of the post languages. The poster picks a
/// language tab and writes in it; the form (which owns [language]) also
/// switches its own labels to that language. At least one title is
/// required (checked by the form). Each tab shows a dot once it has text.
class LocalizedPostFields extends StatelessWidget {
  const LocalizedPostFields({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.l10n,
    required this.titles,
    required this.descriptions,
    required this.onChanged,
  });

  final String language;
  final ValueChanged<String> onLanguageChanged;

  /// Strings in the selected post language (see [localeForPostLanguage]).
  final AppLocalizations l10n;

  /// One controller per language code; owned (and disposed) by the form.
  final Map<String, TextEditingController> titles;
  final Map<String, TextEditingController> descriptions;
  final VoidCallback onChanged;

  static Map<String, TextEditingController> controllers() => {
    for (final l in bulkPostLanguages) l.$1: TextEditingController(),
  };

  /// Non-empty entries only, trimmed — what gets sent to the server.
  static Map<String, String> values(Map<String, TextEditingController> c) => {
    for (final e in c.entries)
      if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
  };

  bool _filled(String code) =>
      titles[code]!.text.trim().isNotEmpty ||
      descriptions[code]!.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final rtl = isRtlPostLanguage(language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.bulkLanguagesHint, style: AppTypography.bodyMuted),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final l in postLanguagesFor(language))
              ChoiceChip(
                label: Text(_filled(l.$1) ? '${l.$2} •' : l.$2),
                selected: language == l.$1,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: language == l.$1 ? Colors.white : AppColors.ink900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                onSelected: (_) => onLanguageChanged(l.$1),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.bulkFormTitleLabel,
          style: AppTypography.cardTitle.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          key: ValueKey('title-$language'),
          controller: titles[language],
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(hintText: l10n.bulkFormTitleHint),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.bulkFormDescriptionLabel,
          style: AppTypography.cardTitle.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          key: ValueKey('desc-$language'),
          controller: descriptions[language],
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          maxLines: 3,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

/// Optional post photo. Picked from the gallery, downscaled on pick so the
/// base64 upload stays well inside the callable payload limit.
class PostPhotoField extends StatelessWidget {
  const PostPhotoField({
    super.key,
    required this.bytes,
    required this.onPicked,
    required this.l10n,
  });

  final AppLocalizations l10n;
  final Uint8List? bytes;
  final ValueChanged<Uint8List> onPicked;

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file == null) return;
    onPicked(await file.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bulkFormPhotoLabel,
          style: AppTypography.cardTitle.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: _pick,
          child: Container(
            height: 170,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.line),
            ),
            child: bytes != null
                ? Image.memory(bytes!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.bulkFormPhotoAdd, style: AppTypography.link),
                    ],
                  ),
          ),
        ),
        if (bytes != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: _pick,
              child: Text(l10n.bulkFormPhotoChange),
            ),
          ),
      ],
    );
  }
}
