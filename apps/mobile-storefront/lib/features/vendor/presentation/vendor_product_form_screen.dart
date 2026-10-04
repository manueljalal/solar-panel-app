import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/vendor_product_repository.dart';
import '../domain/vendor_product_input.dart';

/// Real add/edit form — calls VendorProductRepository.create or .update,
/// which go through the deployed vendor-createProduct/updateProduct
/// Cloud Functions (server-side validated, ownership-checked). When
/// [editing] is provided, fields are pre-filled and submit calls update
/// instead of create.
class VendorProductFormScreen extends StatefulWidget {
  const VendorProductFormScreen({
    super.key,
    required this.vendorId,
    required this.repository,
    this.editing,
  });

  final String vendorId;
  final VendorProductRepository repository;
  final VendorOwnedProduct? editing;

  @override
  State<VendorProductFormScreen> createState() => _VendorProductFormScreenState();
}

class _VendorProductFormScreenState extends State<VendorProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _brand = TextEditingController(text: widget.editing?.product.brand ?? '');
  late final _name = TextEditingController(text: widget.editing?.product.title ?? '');
  late final _spec = TextEditingController(text: widget.editing?.product.spec ?? '');
  late final _price = TextEditingController(
    text: widget.editing != null ? _stripCurrency(widget.editing!.product.price) : '',
  );
  late final _imageUrl = TextEditingController(text: widget.editing?.product.imageUrl ?? '');
  late final _description = TextEditingController(text: widget.editing?.product.description ?? '');
  late final _warranty = TextEditingController(text: widget.editing?.product.warranty ?? '');
  late String _category = vendorProductCategories.first;

  bool _submitting = false;

  static String _stripCurrency(String price) => price.replaceAll(RegExp(r'[^0-9.]'), '');

  @override
  void dispose() {
    _brand.dispose();
    _name.dispose();
    _spec.dispose();
    _price.dispose();
    _imageUrl.dispose();
    _description.dispose();
    _warranty.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);

    final price = double.tryParse(_price.text.trim()) ?? 0;

    try {
      if (widget.editing == null) {
        await widget.repository.create(VendorProductInput(
          category: _category,
          brand: _brand.text.trim(),
          name: _name.text.trim(),
          spec: _spec.text.trim(),
          price: price,
          imageUrl: _imageUrl.text.trim(),
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          warranty: _warranty.text.trim().isEmpty ? null : _warranty.text.trim(),
        ));
      } else {
        await widget.repository.update(widget.editing!.id, {
          'brand': _brand.text.trim(),
          'name': _name.text.trim(),
          'spec': _spec.text.trim(),
          'price': price,
          'imageUrl': _imageUrl.text.trim(),
          'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
          'warranty': _warranty.text.trim().isEmpty ? null : _warranty.text.trim(),
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldntSaveWithReason(_friendlyError(l10n, e)))),
      );
    }
  }

  String _friendlyError(AppLocalizations l10n, Object e) {
    final message = e.toString();
    if (message.contains('permission-denied')) return l10n.errorPermissionDenied;
    if (message.contains('invalid-argument')) return l10n.errorCheckValues;
    return l10n.errorCheckConnection;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.editing != null;

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(isEditing ? l10n.editProductTitle : l10n.addProductTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(l10n.categoryLabel),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: vendorProductCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(l10n, c))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: AppSpacing.md),
              _Field(label: l10n.brandLabel, controller: _brand, requiredMessage: l10n.required),
              const SizedBox(height: AppSpacing.md),
              _Field(label: l10n.productNameLabel, controller: _name, requiredMessage: l10n.required),
              const SizedBox(height: AppSpacing.md),
              _Field(label: l10n.specLabel, controller: _spec, requiredMessage: l10n.required),
              const SizedBox(height: AppSpacing.md),
              _Field(
                label: l10n.priceLabel,
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final n = double.tryParse(value ?? '');
                  if (n == null || n <= 0) return l10n.priceValidator;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _Field(label: l10n.imageUrlLabel, controller: _imageUrl, required: false),
              const SizedBox(height: AppSpacing.md),
              _Field(label: l10n.warrantyOptionalLabel, controller: _warranty, required: false),
              const SizedBox(height: AppSpacing.md),
              _Field(label: l10n.descriptionOptionalLabel, controller: _description, required: false, maxLines: 3),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEditing ? l10n.saveChanges : l10n.publishProduct,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, String category) => switch (category) {
        'residential' => l10n.categoryResidential,
        'commercial' => l10n.categoryCommercial,
        'battery' => l10n.categoryBattery,
        'inverter' => l10n.categoryInverter,
        _ => category,
      };
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: AppTypography.cardTitle.copyWith(fontSize: 13));
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.required = true,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.requiredMessage,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final String? requiredMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator ??
              (required
                  ? (value) => (value == null || value.trim().isEmpty)
                      ? (requiredMessage ?? AppLocalizations.of(context).required)
                      : null
                  : null),
        ),
      ],
    );
  }
}
