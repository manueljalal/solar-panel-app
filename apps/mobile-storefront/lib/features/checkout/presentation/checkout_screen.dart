import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/auth/phone_number.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/formatting/money.dart';
import '../../cart/data/cart_scope.dart';
import '../../cart/domain/cart_item.dart';
import '../../orders/data/order_repository.dart';

/// Contact + delivery details, then "Place order". Payment is cash on
/// delivery — there's no payment gateway, so nothing here collects card
/// details. The totals shown are the cart's; the order itself is priced
/// server-side by storefront-placeOrder from the live `products` docs.
///
/// Pops with the new order's id on success, null if the shopper backs out.
/// [repository] is injectable for widget tests; production code never
/// passes it.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.repository});

  final OrderRepository? repository;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  bool _submitting = false;
  String? _error;

  // Lazy for the same reason as AccountScreen's repository: constructing
  // the real one touches Firebase singletons.
  OrderRepository? _repository;
  OrderRepository get _repo => _repository ??= widget.repository ?? OrderRepository();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit(List<CartItem> items) async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final orderId = await _repo.placeOrder(
        items: items,
        details: CheckoutDetails(
          name: _name.text.trim(),
          phone: normalizePhoneInput(_phone.text)!,
          city: _city.text.trim(),
          address: _address.text.trim(),
          note: _note.text.trim(),
        ),
      );
      if (!mounted) return;
      CartScope.of(context).clear();
      // Back to the Cart tab with the new order id — CartScreen shows the
      // confirmation from there, since only it sits inside RootShell and
      // can switch tabs.
      Navigator.of(context).pop(orderId);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyFunctionError(e, l10n.checkoutFailed);
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = l10n.checkoutFailed;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cart = CartScope.of(context);
    final items = cart.items;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.checkout, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _Section(
              title: l10n.checkoutContactSection,
              children: [
                _Field(
                  label: l10n.checkoutNameLabel,
                  controller: _name,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => (v == null || v.trim().length < 2) ? l10n.checkoutNameValidator : null,
                ),
                _Field(
                  label: l10n.phoneNumberLabel,
                  controller: _phone,
                  hint: l10n.checkoutPhoneHint,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: (v) => normalizePhoneInput(v ?? '') == null ? l10n.checkoutPhoneInvalid : null,
                ),
              ],
            ),
            _Section(
              title: l10n.checkoutDeliverySection,
              children: [
                _Field(
                  label: l10n.cityLabel,
                  controller: _city,
                  autofillHints: const [AutofillHints.addressCity],
                  validator: (v) => (v == null || v.trim().length < 2) ? l10n.required : null,
                ),
                _Field(
                  label: l10n.addressLabel,
                  controller: _address,
                  hint: l10n.checkoutAddressHint,
                  maxLines: 2,
                  autofillHints: const [AutofillHints.streetAddressLine1],
                  validator: (v) => (v == null || v.trim().length < 5) ? l10n.required : null,
                ),
                _Field(label: l10n.checkoutNoteLabel, controller: _note, maxLines: 2),
              ],
            ),
            _Section(
              title: l10n.checkoutPaymentSection,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.checkoutCashOnDelivery, style: AppTypography.cardTitle),
                          const SizedBox(height: 2),
                          Text(l10n.checkoutCashOnDeliveryBody, style: AppTypography.bodyMuted),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _Section(
              title: l10n.checkoutSummarySection,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity} × ${item.product.titleFor(languageCode)}',
                            style: AppTypography.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(formatMoney(item.lineTotal, item.currency), style: AppTypography.body),
                      ],
                    ),
                  ),
                const Divider(color: AppColors.line, height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.checkoutTotal, style: AppTypography.cardTitle),
                    Flexible(child: Text(formatTotals(cart.totals), style: AppTypography.price, textAlign: TextAlign.end)),
                  ],
                ),
              ],
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.warning, fontSize: 13)),
              const SizedBox(height: AppSpacing.md),
            ],
            ElevatedButton(
              onPressed: (_submitting || items.isEmpty) ? null : () => _submit(items),
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
                  : Text(l10n.checkoutPlaceOrder, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
            autofillHints: autofillHints,
            validator: validator,
            maxLines: maxLines,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
