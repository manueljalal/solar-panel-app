import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/auth/phone_number.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../account/presentation/widgets/auth_text_field.dart';
import '../../cart/data/cart_scope.dart';
import '../../cart/domain/cart_item.dart';
import '../../home/domain/home_product.dart';
import '../../orders/data/orders_repository.dart';

/// Checkout: delivery details + order summary, paid cash on delivery.
/// Works for guests (their anonymous account owns the order); a signed-in
/// account gets its name and phone prefilled.
///
/// Online payment isn't offered yet — COD is the only method, stated
/// plainly on the screen.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.repository});

  final OrdersRepository? repository;

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
  late final OrdersRepository _repo = widget.repository ?? OrdersRepository();

  // One id for every attempt made from this screen — a retry after a
  // timeout returns the already-placed orders instead of duplicating them.
  final _checkoutId = OrdersRepository.newCheckoutId();

  Map<String, double> _fees = const {};
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo.fetchDeliveryFees().then((f) {
      if (mounted) setState(() => _fees = f);
    }).catchError((_) {});
    _prefill();
  }

  Future<void> _prefill() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      final profile = await AuthRepository().getMyProfile();
      if (!mounted) return;
      if (_name.text.isEmpty) _name.text = profile.name;
      if (_phone.text.isEmpty) _phone.text = profile.phone;
      final address = profile.location?.address ?? '';
      if (_address.text.isEmpty && address.isNotEmpty) _address.text = address;
    } catch (_) {
      // Prefill is a convenience; the form works without it.
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _city, _address, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _placeOrder(List<CartItem> items) async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final cart = CartScope.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // Guests need their silent anonymous account before the callable.
      if (Firebase.apps.isNotEmpty) await AuthRepository().ensureSignedIn();
      final ids = await _repo.placeOrder(
        checkoutId: _checkoutId,
        items: items,
        delivery: DeliveryDetails(
          name: _name.text.trim(),
          phone: normalizePhone(_phone.text),
          city: _city.text.trim(),
          address: _address.text.trim(),
          note: _note.text.trim(),
        ),
      );
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pop(ids);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = friendlyFunctionError(e, l10n.checkoutFailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.checkoutFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cart = CartScope.of(context);
    final items = cart.items.where((i) => i.product.id.isNotEmpty).toList();
    final lang = Localizations.localeOf(context).languageCode;

    // Same split the server makes: one order per vendor + currency.
    final groups = <String, List<CartItem>>{};
    for (final item in items) {
      groups.putIfAbsent('${item.product.vendorId}_${item.currency}', () => []).add(item);
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.checkoutTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(l10n.checkoutDeliveryDetails, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: l10n.checkoutName,
              controller: _name,
              autofillHints: const [AutofillHints.name],
              validator: (v) => (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: l10n.checkoutPhone,
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: (v) => isValidE164(normalizePhone(v ?? '')) ? null : l10n.checkoutPhoneInvalid,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: l10n.checkoutCity,
              controller: _city,
              validator: (v) => (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: l10n.checkoutAddress,
              controller: _address,
              autofillHints: const [AutofillHints.fullStreetAddress],
              validator: (v) => (v ?? '').trim().length < 3 ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(label: l10n.checkoutNote, controller: _note),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.checkoutSummary, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            for (final group in groups.values) _OrderGroupCard(items: group, fee: _fees[group.first.currency] ?? 0, lang: lang),
            if (groups.length > 1) ...[
              Text(l10n.checkoutSplitNotice(groups.length), style: AppTypography.bodyMuted),
              const SizedBox(height: AppSpacing.md),
            ],
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadii.card)),
              child: Row(
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
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[FormErrorText(_error!), const SizedBox(height: AppSpacing.sm)],
            PrimaryButton(
              label: l10n.checkoutPlaceOrder,
              busy: _submitting,
              onPressed: items.isEmpty ? null : () => _placeOrder(items),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _OrderGroupCard extends StatelessWidget {
  const _OrderGroupCard({required this.items, required this.fee, required this.lang});

  final List<CartItem> items;
  final double fee;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = items.first.currency;
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(items.first.product.vendor, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.quantity} × ${item.product.titleFor(lang)}',
                        style: AppTypography.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text(formatMoney(item.lineTotal, currency), style: AppTypography.body),
                ],
              ),
            ),
          const Divider(color: AppColors.line),
          _MoneyRow(label: l10n.checkoutDeliveryFee, value: fee == 0 ? l10n.checkoutFree : formatMoney(fee, currency)),
          _MoneyRow(label: l10n.checkoutTotal, value: formatMoney(subtotal + fee, currency), bold: true),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTypography.price : AppTypography.bodyMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
