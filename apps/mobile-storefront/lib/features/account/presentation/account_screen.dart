import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/auth_claims.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/city/city_controller.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/l10n/locale_scope.dart';
import '../../../core/navigation/root_shell.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/bidi.dart';
import '../../../shared/widgets/city_picker.dart';
import '../../bulk/presentation/bulk_market_screen.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../vendor/presentation/vendor_apply_screen.dart';
import '../../vendor/presentation/vendor_dashboard_screen.dart';
import '../data/profile_repository.dart';
import 'edit_profile_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Account tab, laid out the way big marketplaces do it:
///  - profile header with Edit profile (guests get a Sign in / Create
///    account card instead),
///  - an order tracker with per-status counts that jump straight to those
///    orders,
///  - grouped settings sections (Activity, Business, Preferences, Help),
///  - Sign out at the bottom, with account deletion (App Store
///    requirement) quietly below it.
///
/// Guards against reading FirebaseAuth before Firebase.initializeApp() has
/// run — this tab sits inside RootShell's IndexedStack.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

const _appVersion = '1.0.0';

class _AccountScreenState extends State<AccountScreen> {
  AuthClaims? _claims;
  MyProfile? _profile;
  Map<OrderStatus, int>? _orderCounts;
  final _profiles = ProfileRepository();
  final _orders = OrdersRepository();

  // Lazily constructed, and only ever accessed behind a Firebase.apps
  // check — AuthRepository()'s constructor reaches for FirebaseAuth.instance
  // eagerly, which throws if Firebase hasn't initialized yet.
  AuthRepository? _repository;
  AuthRepository get _repo => _repository ??= AuthRepository();

  User? get _user => Firebase.apps.isEmpty ? null : _repo.currentUser;
  bool get _isRealAccount => _user != null && !_user!.isAnonymous;

  @override
  void initState() {
    super.initState();
    OrdersRepository.changes.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    OrdersRepository.changes.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (Firebase.apps.isEmpty) return;
    // forceRefresh: a sign-in that just happened, or a role just granted by
    // an admin, only shows up on a fresh token.
    final claims = await _repo.getClaims(forceRefresh: true);
    MyProfile? profile;
    Map<OrderStatus, int>? counts;
    if (_isRealAccount) {
      final results = await Future.wait<Object?>([
        _profiles.get().then<Object?>((p) => p).catchError((_) => null),
        _orders.listMine().then<Object?>((o) => o).catchError((_) => null),
      ]);
      profile = results[0] as MyProfile?;
      final orders = results[1] as List<CustomerOrder>?;
      if (orders != null) {
        counts = {for (final s in OrderStatus.values) s: 0};
        for (final o in orders) {
          counts[o.status] = counts[o.status]! + 1;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _claims = claims;
      _profile = profile;
      _orderCounts = counts;
    });
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _refresh();
  }

  Future<void> _signOut() async {
    await _repo.signOut();
    await _repo.ensureSignedIn(); // drop back to a fresh anonymous session
    setState(() {
      _profile = null;
      _orderCounts = null;
    });
    _refresh();
  }

  Future<void> _pickCity() async {
    final picked = await showIraqCityPicker(context, selectedId: CityController.instance.value);
    if (picked != null && picked.isNotEmpty) await CityController.instance.set(picked);
  }

  Future<void> _editProfile() async {
    final profile = _profile;
    if (profile == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile, repository: _profiles)),
    );
    if (saved == true) _refresh();
  }

  void _showAbout(AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 30),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Solary', style: AppTypography.h1.copyWith(fontSize: 22)),
              const SizedBox(height: 4),
              Text(l10n.aboutVersion(_appVersion), style: AppTypography.bodyMuted),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.aboutBody, textAlign: TextAlign.center, style: AppTypography.body),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.aboutCompany, style: AppTypography.bodyMuted),
              const SizedBox(height: 2),
              Text('info@quadcores.com', style: AppTypography.bodyMuted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountDeleteTitle),
        content: Text(l10n.accountDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.orderKeep)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: Text(l10n.accountDeleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _profiles.deleteMyAccount();
      await _signOut();
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyFunctionError(e, l10n.accountDeleteFailed))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleteFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final claims = _claims;
    final isVendor = claims?.role == AppRole.vendor && claims?.vendorId != null;
    final isRealAccount = _isRealAccount;

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.accountTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          children: [
            if (isRealAccount) _profileHeader(l10n, isVendor) else _guestCard(l10n),
            if (isRealAccount) ...[
              const SizedBox(height: AppSpacing.md),
              _orderTracker(l10n),
            ],
            _SectionTitle(l10n.accountSectionActivity),
            _Section(children: [
              _Row(
                icon: Icons.receipt_long_outlined,
                label: l10n.accountOrderHistory,
                onTap: () => _push(const OrdersScreen()),
              ),
              _Row(
                icon: Icons.handyman_outlined,
                label: l10n.accountMyServices,
                onTap: () => RootShell.tabRequests.value = RootShell.servicesTab,
              ),
            ]),
            _SectionTitle(l10n.accountSectionBusiness),
            _Section(children: [
              if (isVendor) ...[
                _Row(
                  icon: Icons.handshake_outlined,
                  label: l10n.accountB2B,
                  onTap: () => _push(const BulkMarketScreen()),
                ),
                _Row(
                  icon: Icons.storefront_outlined,
                  label: l10n.accountMyProducts,
                  onTap: () => _push(VendorDashboardScreen(vendorId: claims!.vendorId!)),
                ),
              ] else
                _Row(
                  icon: Icons.storefront_outlined,
                  label: l10n.accountOwnBusiness,
                  value: l10n.accountApply,
                  onTap: () => _push(const VendorApplyScreen()),
                ),
            ]),
            _SectionTitle(l10n.accountSectionPreferences),
            _Section(children: [
              ValueListenableBuilder<String?>(
                valueListenable: CityController.instance,
                builder: (context, _, _) => _Row(
                  icon: Icons.location_on_outlined,
                  label: l10n.accountCity,
                  value: CityController.instance.city?.nameFor(lang) ?? l10n.accountNotSet,
                  onTap: _pickCity,
                ),
              ),
              _Row(
                icon: Icons.language_outlined,
                label: l10n.accountLanguage,
                value: _languageName(l10n, LocaleScope.of(context).value),
                onTap: () => _pickLanguage(context, l10n),
              ),
            ]),
            _SectionTitle(l10n.accountSectionSupport),
            _Section(children: [
              _Row(
                icon: Icons.support_agent_outlined,
                label: l10n.accountHelp,
                onTap: () => RootShell.tabRequests.value = RootShell.servicesTab,
              ),
              _Row(
                icon: Icons.info_outline,
                label: l10n.accountAbout,
                value: 'v$_appVersion',
                onTap: () => _showAbout(l10n),
              ),
            ]),
            if (isRealAccount) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink900,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.line),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(l10n.accountSignOut, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (!isVendor)
                Center(
                  child: TextButton(
                    onPressed: () => _deleteAccount(l10n),
                    style: TextButton.styleFrom(foregroundColor: AppColors.ink400),
                    child: Text(l10n.accountDelete, style: const TextStyle(fontSize: 13)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(AppLocalizations l10n, bool isVendor) {
    final p = _profile;
    final name = p?.name.isNotEmpty == true ? p!.name : l10n.accountSignedIn;
    final phone = p?.phone.isNotEmpty == true ? p!.phone : (_user?.phoneNumber ?? '');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Text(
              name.characters.first.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h1.copyWith(fontSize: 19),
                      ),
                    ),
                    if (isVendor) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 18, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (p?.username.isNotEmpty == true) Text('@${p!.username}', style: AppTypography.bodyMuted),
                if (phone.isNotEmpty) Text(ltr(phone), style: AppTypography.bodyMuted),
              ],
            ),
          ),
          TextButton(onPressed: _profile == null ? null : _editProfile, child: Text(l10n.accountEditProfile)),
        ],
      ),
    );
  }

  Widget _guestCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.accountGuestTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
          const SizedBox(height: 4),
          Text(l10n.accountGuestBody, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _push(const SignInScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                  ),
                  child: Text(l10n.accountSignIn, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _push(const SignUpScreen()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                  ),
                  child: Text(l10n.accountCreateAccount, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Alibaba/Amazon-style order tracker: one tap from a status to its orders.
  Widget _orderTracker(AppLocalizations l10n) {
    final counts = _orderCounts;
    Widget item(IconData icon, String label, OrderStatus status) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _push(OrdersScreen(status: status)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, color: AppColors.ink900, size: 26),
                      if ((counts?[status] ?? 0) > 0)
                        PositionedDirectional(
                          end: -10,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            constraints: const BoxConstraints(minWidth: 18),
                            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(9)),
                            child: Text(
                              '${counts![status]}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMuted.copyWith(fontSize: 11.5, color: AppColors.ink900),
                  ),
                ],
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.accountMyOrders, style: AppTypography.cardTitle.copyWith(fontSize: 15.5))),
              InkWell(
                onTap: () => _push(const OrdersScreen()),
                child: Row(
                  children: [
                    Text(l10n.seeAll, style: AppTypography.bodyMuted),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.ink400),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              item(Icons.hourglass_top_rounded, l10n.orderStatusPlaced, OrderStatus.placed),
              item(Icons.task_alt, l10n.orderStatusConfirmed, OrderStatus.confirmed),
              item(Icons.local_shipping_outlined, l10n.orderStatusOutForDelivery, OrderStatus.outForDelivery),
              item(Icons.inventory_2_outlined, l10n.orderStatusDelivered, OrderStatus.delivered),
            ],
          ),
        ],
      ),
    );
  }

  String _languageName(AppLocalizations l10n, Locale locale) => switch (locale.languageCode) {
        'ar' => l10n.languageNameArabic,
        'ckb' => l10n.languageNameSorani,
        _ => l10n.languageNameEnglish,
      };

  Future<void> _pickLanguage(BuildContext context, AppLocalizations l10n) async {
    final localeController = LocaleScope.of(context);
    final chosen = await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageSheet(l10n: l10n, current: localeController.value),
    );
    if (chosen != null) await localeController.setLocale(chosen);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, AppSpacing.xl, 4, AppSpacing.sm),
        child: Text(
          text,
          style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
}

/// One rounded white card holding several rows, separated by hairlines.
class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, indent: 56, color: AppColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.value});

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.body)),
            if (value != null) Text(value!, style: AppTypography.bodyMuted),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.l10n, required this.current});

  final AppLocalizations l10n;
  final Locale current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.chooseLanguage, style: AppTypography.h1.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.sm),
            for (final locale in LocaleController.supportedLocales)
              _LanguageOption(
                label: switch (locale.languageCode) {
                  'ar' => l10n.languageNameArabic,
                  'ckb' => l10n.languageNameSorani,
                  _ => l10n.languageNameEnglish,
                },
                selected: locale.languageCode == current.languageCode,
                onTap: () => Navigator.of(context).pop(locale),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTypography.body)),
            if (selected) const Icon(Icons.check, size: 18, color: AppColors.ink900),
          ],
        ),
      ),
    );
  }
}

