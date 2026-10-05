import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/auth_claims.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/l10n/locale_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../vendor/presentation/vendor_apply_screen.dart';
import '../../vendor/presentation/vendor_dashboard_screen.dart';
import 'sign_in_screen.dart';

/// Account tab. Shows the real signed-in state from AuthRepository, and —
/// once role claims load — either "Own a solar business? Apply" (for a
/// customer) or "My products" (for an approved vendor). This is the
/// actual entry point into the vendor dashboard; there's no other way to
/// reach it from the UI, matching how role-gating should work (the link
/// simply doesn't appear if you're not a vendor, rather than appearing
/// and then refusing you).
///
/// Guards against reading FirebaseAuth before Firebase.initializeApp() has
/// run — this tab sits inside RootShell's IndexedStack, which builds every
/// tab eagerly (not just the visible one).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AuthClaims? _claims;

  // Lazily constructed, and only ever accessed behind a Firebase.apps
  // check — AuthRepository()'s constructor reaches for
  // FirebaseAuth.instance eagerly, which throws if Firebase hasn't
  // initialized yet. This tab sits inside RootShell's IndexedStack (built
  // eagerly, not just when visible), so that guard is load-bearing, not
  // defensive boilerplate — a plain field initializer here crashes the
  // whole app on cold start in any environment where Firebase init is
  // slow (or, as caught by the test suite, absent entirely).
  AuthRepository? _repository;
  AuthRepository get _repo => _repository ??= AuthRepository();

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    if (Firebase.apps.isEmpty) return;
    // forceRefresh: true — a sign-in that just happened, or a role just
    // granted by an admin, only shows up on a fresh token. Cheap enough
    // to always force here since this only runs on tab load/return.
    final claims = await _repo.getClaims(forceRefresh: true);
    if (!mounted) return;
    setState(() => _claims = claims);
  }

  Future<void> _openSignIn() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
    _loadClaims();
  }

  Future<void> _signOut() async {
    await _repo.signOut();
    await _repo.ensureSignedIn(); // drop back to a fresh anonymous session
    _loadClaims();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = Firebase.apps.isEmpty ? null : _repo.currentUser;
    final isRealAccount = user != null && !user.isAnonymous;
    final claims = _claims;

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.accountTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.surfaceMuted, shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline, color: AppColors.ink900),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null ? _roleLabel(l10n, claims, isRealAccount) : l10n.accountNotSignedIn,
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(l10n, user, isRealAccount),
                        style: AppTypography.bodyMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
          _AccountRow(icon: Icons.location_on_outlined, label: l10n.accountLocation, trailing: l10n.accountChange),
          _AccountRow(icon: Icons.receipt_long_outlined, label: l10n.accountOrderHistory, trailing: l10n.accountView),
          if (claims?.role == AppRole.vendor && claims?.vendorId != null)
            _AccountRow(
              icon: Icons.storefront_outlined,
              label: l10n.accountMyProducts,
              trailing: l10n.accountManage,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => VendorDashboardScreen(vendorId: claims!.vendorId!)),
              ),
            )
          else
            _AccountRow(
              icon: Icons.storefront_outlined,
              label: l10n.accountOwnBusiness,
              trailing: l10n.accountApply,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VendorApplyScreen()),
                );
                // Verifying a phone inside the apply flow swaps the guest
                // session for a real account — refresh role/claims.
                _loadClaims();
              },
            ),
          _AccountRow(
            icon: Icons.language_outlined,
            label: l10n.accountLanguage,
            trailing: _languageName(l10n, LocaleScope.of(context).value),
            onTap: () => _pickLanguage(context, l10n),
          ),
          _AccountRow(icon: Icons.info_outline, label: l10n.accountAbout, trailing: 'v1.0.0'),
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

  String _subtitle(AppLocalizations l10n, User? user, bool isRealAccount) {
    if (user == null) return l10n.accountAnonymousUnavailable;
    if (isRealAccount) return user.email ?? user.phoneNumber ?? l10n.accountSignedIn;
    return l10n.accountBrowsingAnonymously(user.uid.substring(0, 8));
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
                Text(trailing, style: AppTypography.bodyMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
