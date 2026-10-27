import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/auth_claims.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/city/city_controller.dart';
import '../../../core/navigation/root_shell.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/l10n/locale_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/bidi.dart';
import '../../../shared/widgets/city_picker.dart';
import '../../bulk/presentation/bulk_market_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../data/profile_repository.dart';
import '../../vendor/presentation/vendor_apply_screen.dart';
import '../../vendor/presentation/vendor_dashboard_screen.dart';
import 'sign_in_screen.dart';

/// Account tab: who you are (name, @username, phone), your city, order
/// history, the business entry (apply, or B2B + products for an approved
/// vendor), language, help, about, sign out and — for customer accounts —
/// in-app account deletion (an App Store requirement).
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
  final _profiles = ProfileRepository();

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
    _refresh();
  }

  Future<void> _refresh() async {
    if (Firebase.apps.isEmpty) return;
    // forceRefresh: a sign-in that just happened, or a role just granted by
    // an admin, only shows up on a fresh token.
    final claims = await _repo.getClaims(forceRefresh: true);
    MyProfile? profile;
    if (_isRealAccount) {
      try {
        profile = await _profiles.get();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _claims = claims;
      _profile = profile;
    });
  }

  Future<void> _openSignIn() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
    _refresh();
  }

  Future<void> _signOut() async {
    await _repo.signOut();
    await _repo.ensureSignedIn(); // drop back to a fresh anonymous session
    setState(() => _profile = null);
    _refresh();
  }

  Future<void> _pickCity() async {
    final picked = await showIraqCityPicker(context, selectedId: CityController.instance.value);
    if (picked != null && picked.isNotEmpty) await CityController.instance.set(picked);
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
    final user = _user;
    final isRealAccount = _isRealAccount;
    final claims = _claims;
    final isVendor = claims?.role == AppRole.vendor && claims?.vendorId != null;
    final profile = _profile;

    final title = isRealAccount
        ? (profile?.name.isNotEmpty == true ? profile!.name : _roleLabel(l10n, claims, true))
        : (user != null ? l10n.accountRoleGuest : l10n.accountNotSignedIn);
    final subtitle = isRealAccount
        ? [
            if (profile?.username.isNotEmpty == true) '@${profile!.username}',
            if ((profile?.phone ?? user?.phoneNumber ?? '').isNotEmpty) ltr(profile?.phone ?? user!.phoneNumber!),
          ].join(' · ')
        : l10n.accountAnonymousUnavailable;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.accountTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                    child: isRealAccount && title.isNotEmpty
                        ? Text(
                            title.characters.first.toUpperCase(),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20),
                          )
                        : const Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(title, style: AppTypography.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (isVendor) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(AppRadii.chip),
                                ),
                                child: Text(
                                  l10n.accountRoleVendor,
                                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(subtitle, style: AppTypography.bodyMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  if (isRealAccount)
                    TextButton(onPressed: _signOut, child: Text(l10n.accountSignOut))
                  else
                    TextButton(onPressed: _openSignIn, child: Text(l10n.accountSignIn)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ValueListenableBuilder<String?>(
              valueListenable: CityController.instance,
              builder: (context, _, _) => _AccountRow(
                icon: Icons.location_on_outlined,
                label: CityController.instance.city?.nameFor(lang) ?? l10n.cityChoose,
                trailing: l10n.accountChange,
                onTap: _pickCity,
              ),
            ),
            _AccountRow(
              icon: Icons.receipt_long_outlined,
              label: l10n.accountOrderHistory,
              trailing: l10n.accountView,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
            ),
            if (isVendor) ...[
              _AccountRow(
                icon: Icons.handshake_outlined,
                label: l10n.accountB2B,
                trailing: l10n.homeBulkCta,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BulkMarketScreen())),
              ),
              _AccountRow(
                icon: Icons.storefront_outlined,
                label: l10n.accountMyProducts,
                trailing: l10n.accountManage,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VendorDashboardScreen(vendorId: claims!.vendorId!)),
                ),
              ),
            ] else
              _AccountRow(
                icon: Icons.storefront_outlined,
                label: l10n.accountOwnBusiness,
                trailing: l10n.accountApply,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VendorApplyScreen()));
                  _refresh();
                },
              ),
            _AccountRow(
              icon: Icons.language_outlined,
              label: l10n.accountLanguage,
              trailing: _languageName(l10n, LocaleScope.of(context).value),
              onTap: () => _pickLanguage(context, l10n),
            ),
            _AccountRow(
              icon: Icons.support_agent_outlined,
              label: l10n.accountHelp,
              trailing: '',
              onTap: () => RootShell.tabRequests.value = RootShell.servicesTab,
            ),
            _AccountRow(
              icon: Icons.info_outline,
              label: l10n.accountAbout,
              trailing: 'v$_appVersion',
              onTap: () => _showAbout(l10n),
            ),
            if (isRealAccount && !isVendor) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => _deleteAccount(l10n),
                  style: TextButton.styleFrom(foregroundColor: AppColors.warning),
                  child: Text(l10n.accountDelete),
                ),
              ),
            ],
          ],
        ),
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

  String _roleLabel(AppLocalizations l10n, AuthClaims? claims, bool isRealAccount) {
    if (claims?.role == AppRole.vendor) return l10n.accountRoleVendor;
    if (claims?.role == AppRole.superAdmin) return l10n.accountRoleAdmin;
    return isRealAccount ? l10n.accountSignedIn : l10n.accountRoleGuest;
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

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.label, required this.trailing, this.onTap});

  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.ink900),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label, style: AppTypography.body)),
                if (trailing.isNotEmpty) Text(trailing, style: AppTypography.bodyMuted),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.ink400),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
