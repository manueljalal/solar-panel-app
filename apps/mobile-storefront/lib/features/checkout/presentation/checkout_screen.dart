import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/address/address_book.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/location/location_picker_screen.dart';
import '../../../shared/location/picked_location.dart';
import '../../../shared/money.dart';
import '../../account/presentation/sign_in_screen.dart';
import '../../cart/data/cart_scope.dart';
import '../../cart/domain/cart_item.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/presentation/orders_screen.dart';

/// Cash-on-delivery checkout: delivery location + address details, an
/// optional note, the order summary, and one "Place order" button. Needs a
/// real (non-guest) account — the seller calls the verified phone to
/// confirm. Items from several sellers become one order per seller.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, OrdersRepository? repository}) : _repository = repository;

  final OrdersRepository? _repository;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final OrdersRepository _repo = widget._repository ?? OrdersRepository();
  final _address = TextEditingController();
  final _note = TextEditingController();
  PickedLocation? _location;
  // One id per checkout: a retry after a timeout reuses it, so the server
  // never creates the same orders twice.
  final String _requestId = newRequestId();
  bool _submitting = false;
  String? _error;

  User? get _user => Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
  bool get _hasAccount => _user != null && !_user!.isAnonymous;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  /// Start from the saved delivery address (set at sign-up / last order).
  Future<void> _prefill() async {
    final saved = await AddressBook.instance.load();
    if (saved == null || !mounted || _location != null) return;
    setState(() {
      _location = saved.location;
      if (_address.text.trim().isEmpty) _address.text = saved.line.isNotEmpty ? saved.line : saved.location.address;
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _location = picked;
      if (_address.text.trim().isEmpty) _address.text = picked.address;
      _error = null;
    });
  }

  Future<void> _placeOrder() async {
    final l10n = AppLocalizations.of(context);
    final cart = CartScope.of(context);
    final location = _location;
    if (location == null) return setState(() => _error = l10n.checkoutLocationRequired);
    if (_address.text.trim().length < 3) return setState(() => _error = l10n.checkoutAddressRequired);

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repo.placeOrder(
        items: cart.items,
        address: _address.text.trim(),
        location: location,
        note: _note.text.trim(),
        requestId: _requestId,
      );
      cart.clear();
      // Next time this is the default address.
      AddressBook.instance.remember(location, _address.text.trim());
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const _OrderPlacedScreen()));
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.checkoutTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
      ),
      body: _hasAccount ? _form(l10n) : _signInPrompt(l10n),
    );
  }

  Widget _signInPrompt(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 40, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.checkoutSignInTitle, style: AppTypography.cardTitle, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(l10n.checkoutSignInBody, style: AppTypography.bodyMuted, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          _PrimaryButton(
            label: l10n.accountSignIn,
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
              if (!mounted) return;
              setState(() {});
              _prefill();
            },
          ),
        ],
      ),
    );
  }

  Widget _form(AppLocalizations l10n) {
    final cart = CartScope.of(context);
    final items = cart.items;
    final bySeller = <String, List<CartItem>>{};
    for (final i in items) {
      bySeller.putIfAbsent(i.product.vendor, () => []).add(i);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: [
        _SectionTitle(l10n.checkoutDeliverTo),
        _Bordered(
          onTap: _pickLocation,
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _location?.address.isNotEmpty == true ? _location!.address : l10n.checkoutChooseLocation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _location == null ? AppTypography.link : AppTypography.body,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink400),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _address,
          decoration: InputDecoration(labelText: l10n.checkoutAddressLabel, hintText: l10n.checkoutAddressHint),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _note,
          maxLines: 2,
          decoration: InputDecoration(labelText: l10n.checkoutNoteLabel),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(l10n.checkoutPayment),
        _Bordered(
          child: Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.checkoutCod, style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(l10n.checkoutCodHint, style: AppTypography.bodyMuted),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(l10n.checkoutSummary),
        for (final entry in bySeller.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(l10n.orderFrom(entry.key), style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700)),
          ),
          for (final i in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${i.quantity} × ${i.product.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text(formatMoney(i.lineTotal, i.currency), style: AppTypography.body),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (bySeller.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(l10n.checkoutSellersNote, style: AppTypography.bodyMuted.copyWith(fontSize: 12.5)),
          ),
        const Divider(color: AppColors.line),
        Row(
          children: [
            Expanded(child: Text(l10n.checkoutTotal, style: AppTypography.cardTitle)),
            Text(formatTotals(cart.totals), style: AppTypography.price),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(color: AppColors.warning, fontSize: 13)),
        ],
        const SizedBox(height: AppSpacing.lg),
        _PrimaryButton(
          label: l10n.checkoutPlaceOrder,
          loading: _submitting,
          onPressed: items.isEmpty || _submitting ? null : _placeOrder,
        ),
      ],
    );
  }
}

class _OrderPlacedScreen extends StatelessWidget {
  const _OrderPlacedScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.orderPlacedTitle, style: AppTypography.h1.copyWith(fontSize: 22)),
              const SizedBox(height: 6),
              Text(l10n.orderPlacedBody, style: AppTypography.bodyMuted, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              _PrimaryButton(
                label: l10n.orderViewOrders,
                // Orders live under Account now; open the list directly.
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(l10n.done),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text, style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
      );
}

class _Bordered extends StatelessWidget {
  const _Bordered({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
        ),
        child: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}
