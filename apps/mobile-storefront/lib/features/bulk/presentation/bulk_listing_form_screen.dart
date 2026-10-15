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
import '../domain/bulk_models.dart';
import 'widgets/bulk_form_fields.dart';

/// Post a wholesale offer: product + quantity-tier pricing. Pops `true`
/// once posted so the marketplace can refresh.
class BulkListingFormScreen extends StatefulWidget {
  const BulkListingFormScreen({
    super.key,
    required this.repository,
    this.categories = const [],
  });

  final BulkRepository repository;

  /// Admin-managed categories (same list Home filters by); empty hides the picker.
  final List<HomeCategory> categories;

  @override
  State<BulkListingFormScreen> createState() => _BulkListingFormScreenState();
}

class _TierRow {
  final qty = TextEditingController();
  final price = TextEditingController();
  void dispose() {
    qty.dispose();
    price.dispose();
  }
}

class _BulkListingFormScreenState extends State<BulkListingFormScreen> {
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
  final _tiers = [_TierRow()];
  String? _categoryId;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [..._titles.values, ..._descriptions.values]) {
      c.dispose();
    }
    _unit.dispose();
    for (final t in _tiers) {
      t.dispose();
    }
    super.dispose();
  }

  String? _requiredNumber(
    String? v,
    AppLocalizations l10n, {
    bool integer = false,
  }) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return l10n.bulkFieldRequired;
    final n = integer ? int.tryParse(text) : double.tryParse(text);
    if (n == null || n <= 0) return l10n.bulkInvalidNumber;
    return null;
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
    final tiers = [
      for (final t in _tiers)
        BulkTier(
          minQty: int.parse(t.qty.text.trim()),
          unitPriceUsd: double.parse(t.price.text.trim()),
        ),
    ];
    if (tiers.map((t) => t.minQty).toSet().length != tiers.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.bulkDuplicateTier)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final photo = _photo;
      final imageUrl = photo == null
          ? null
          : await widget.repository.uploadImage(photo);
      await widget.repository.createListing(
        title: titles,
        description: LocalizedPostFields.values(_descriptions),
        imageUrl: imageUrl,
        unit: _unit.text.trim(),
        categoryId: _categoryId,
        tiers: tiers,
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
            l10n.bulkPostListing,
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
                _label(l10n.bulkFormUnitLabel),
                TextFormField(
                  controller: _unit,
                  decoration: InputDecoration(hintText: l10n.bulkFormUnitHint),
                  validator: required,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.bulkPriceTiers,
                  style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < _tiers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tiers[i].qty,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.bulkTierQtyLabel,
                            ),
                            validator: (v) =>
                                _requiredNumber(v, l10n, integer: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _tiers[i].price,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.bulkTierPriceLabel,
                            ),
                            validator: (v) => _requiredNumber(v, l10n),
                          ),
                        ),
                        if (_tiers.length > 1)
                          IconButton(
                            tooltip: l10n.bulkRemoveTier,
                            onPressed: () =>
                                setState(() => _tiers.removeAt(i).dispose()),
                            icon: const Icon(Icons.close, size: 20),
                          ),
                      ],
                    ),
                  ),
                if (_tiers.length < 5)
                  TextButton.icon(
                    onPressed: () => setState(() => _tiers.add(_TierRow())),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.bulkAddTier),
                  ),
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
