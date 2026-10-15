import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/domain/home_category.dart';
import '../data/bulk_repository.dart';
import 'widgets/bulk_form_fields.dart';

/// Post a buyer request ("I need N units"). Pops `true` once posted.
class BulkRequestFormScreen extends StatefulWidget {
  const BulkRequestFormScreen({
    super.key,
    required this.repository,
    this.categories = const [],
  });

  final BulkRepository repository;

  /// Admin-managed categories (same list Home filters by); empty hides the picker.
  final List<HomeCategory> categories;

  @override
  State<BulkRequestFormScreen> createState() => _BulkRequestFormScreenState();
}

class _BulkRequestFormScreenState extends State<BulkRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titles = LocalizedPostFields.controllers();
  final _descriptions = LocalizedPostFields.controllers();
  Uint8List? _photo;

  /// Language the form is shown (and the active text tab) in. Starts on the
  /// app's language; picking a tab switches the whole form to it.
  String _formLang = 'en';
  bool _langInit = false;

  AppLocalizations get _l10n =>
      lookupAppLocalizations(localeForPostLanguage(_formLang));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_langInit) {
      _langInit = true;
      _formLang = postLanguageForApp(
        Localizations.localeOf(context).languageCode,
      );
    }
  }

  final _unit = TextEditingController(text: 'pcs');
  final _quantity = TextEditingController();
  final _target = TextEditingController();
  final _deliveryCity = TextEditingController();
  String? _categoryId;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [..._titles.values, ..._descriptions.values]) {
      c.dispose();
    }
    _unit.dispose();
    _quantity.dispose();
    _target.dispose();
    _deliveryCity.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = _l10n;
    if (!_formKey.currentState!.validate()) return;
    final titles = LocalizedPostFields.values(_titles);
    if (titles.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.bulkTitleNeeded)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final target = _target.text.trim();
      final photo = _photo;
      final imageUrl = photo == null
          ? null
          : await widget.repository.uploadImage(photo);
      await widget.repository.createRequest(
        title: titles,
        description: LocalizedPostFields.values(_descriptions),
        imageUrl: imageUrl,
        unit: _unit.text.trim(),
        categoryId: _categoryId,
        quantity: int.parse(_quantity.text.trim()),
        targetPriceUsd: target.isEmpty ? null : double.parse(target),
        deliveryCity: _deliveryCity.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyFunctionError(e, l10n.bulkPostFailed))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.bulkPostFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.bulkFieldRequired : null;
    return Directionality(
      textDirection: isRtlPostLanguage(_formLang)
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSunken,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceSunken,
          elevation: 0,
          title: Text(
            l10n.bulkPostRequest,
            style: AppTypography.h1.copyWith(fontSize: 18),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostPhotoField(
                  l10n: l10n,
                  bytes: _photo,
                  onPicked: (b) => setState(() => _photo = b),
                ),
                const SizedBox(height: AppSpacing.lg),
                LocalizedPostFields(
                  language: _formLang,
                  onLanguageChanged: (code) => setState(() => _formLang = code),
                  l10n: l10n,
                  titles: _titles,
                  descriptions: _descriptions,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                if (widget.categories.isNotEmpty) ...[
                  _label(l10n.bulkFormCategoryLabel),
                  DropdownButtonFormField<String?>(
                    initialValue: _categoryId,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.bulkFormCategoryNone),
                      ),
                      for (final c in widget.categories)
                        DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(
                            c.nameFor(
                              Localizations.localeOf(context).languageCode,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(l10n.bulkQuantityLabel),
                          TextFormField(
                            controller: _quantity,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              final text = v?.trim() ?? '';
                              if (text.isEmpty) return l10n.bulkFieldRequired;
                              final n = int.tryParse(text);
                              return (n == null || n < 1)
                                  ? l10n.bulkInvalidNumber
                                  : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(l10n.bulkFormUnitLabel),
                          TextFormField(controller: _unit, validator: required),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _label(l10n.bulkTargetPriceLabel),
                TextFormField(
                  controller: _target,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final n = double.tryParse(text);
                    return (n == null || n <= 0)
                        ? l10n.bulkInvalidNumber
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _label(l10n.bulkDeliveryCityLabel),
                TextFormField(controller: _deliveryCity),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.bulkSubmitPost,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
  );
}
