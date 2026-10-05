import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/auth/phone_number.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/location/location_picker_screen.dart';
import '../../../shared/location/picked_location.dart';
import '../../account/presentation/sign_in_screen.dart';
import '../data/vendor_application_repository.dart';

/// Vendor onboarding — reached from the home screen's "Own a solar
/// business? Apply" card and the Account tab. A vendor's only login is a
/// WhatsApp-verified phone number, and approval grants the vendor role to
/// the signed-in uid, so a guest (anonymous) session is first walked
/// through phone verification; the phone on the application is then the
/// verified one, never typed. Existing applications show their status
/// instead of a blank form.
class VendorApplyScreen extends StatefulWidget {
  const VendorApplyScreen({super.key});

  @override
  State<VendorApplyScreen> createState() => _VendorApplyScreenState();
}

// Mirrors the backend's EMAIL_PATTERN in
// backend/functions/src/vendor/submit_application.ts — kept in sync so the
// client rejects the same inputs the callable would.
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

enum _Stage { loading, verifyPhone, form, pending, approved }

class _VendorApplyScreenState extends State<VendorApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _note = TextEditingController();
  final _repository = VendorApplicationRepository();
  final _auth = AuthRepository();

  _Stage _stage = _Stage.loading;
  String _pendingBusiness = '';
  bool _previouslyRejected = false;
  PickedLocation? _location;
  bool _submitting = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _resolveStage();
  }

  @override
  void dispose() {
    _businessName.dispose();
    _city.dispose();
    _address.dispose();
    _email.dispose();
    _note.dispose();
    super.dispose();
  }

  String? get _verifiedPhone => _auth.currentUser?.phoneNumber;

  /// Decides what to show: phone verification for guests, otherwise the
  /// caller's existing application status (or the form if they have none).
  Future<void> _resolveStage() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      setState(() => _stage = _Stage.verifyPhone);
      return;
    }
    setState(() => _stage = _Stage.loading);
    MyApplication? mine;
    try {
      mine = await _repository.getMine();
    } catch (_) {
      // Status is a convenience — if it can't be read, fall through to the
      // form; the server still rejects a duplicate pending application.
    }
    if (!mounted) return;
    setState(() {
      _previouslyRejected = mine?.status == ApplicationStatus.rejected;
      _pendingBusiness = mine?.businessName ?? '';
      _stage = switch (mine?.status) {
        ApplicationStatus.pending => _Stage.pending,
        ApplicationStatus.approved => _Stage.approved,
        _ => _Stage.form,
      };
    });
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)),
    );
    if (picked == null) return;
    setState(() {
      _location = picked;
      _locationError = null;
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    final l10n = AppLocalizations.of(context);
    final location = _location;
    setState(() => _locationError = location == null ? l10n.locationRequiredError : null);
    if (!formValid || location == null) return;

    setState(() => _submitting = true);
    try {
      await _repository.submit(
        businessName: _businessName.text.trim(),
        city: _city.text.trim(),
        address: _address.text.trim(),
        email: _email.text.trim(),
        note: _note.text.trim(),
        location: location,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _pendingBusiness = _businessName.text.trim();
        _stage = _Stage.pending;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      if (e.code == 'failed-precondition') {
        // Server says this session has no verified phone — send them back
        // through verification rather than showing a dead-end error.
        setState(() => _stage = _Stage.verifyPhone);
        return;
      }
      if (e.code == 'already-exists') {
        _resolveStage();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyFunctionError(e, l10n.vendorApplyGenericError))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vendorApplyGenericError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        title: Text(l10n.vendorApplyTitle, style: AppTypography.h1.copyWith(fontSize: 18)),
      ),
      body: switch (_stage) {
        _Stage.loading => const Center(child: CircularProgressIndicator()),
        _Stage.verifyPhone => _buildVerify(l10n),
        _Stage.form => _buildForm(l10n),
        _Stage.pending => _StatusState(
            icon: Icons.hourglass_top_rounded,
            color: AppColors.accent,
            title: l10n.vendorApplyPendingTitle,
            body: _pendingBusiness.isEmpty
                ? l10n.applicationSubmittedBody
                : l10n.vendorApplyPendingBody(_pendingBusiness),
          ),
        _Stage.approved => _StatusState(
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            title: l10n.vendorApplyApprovedTitle,
            body: l10n.vendorApplyApprovedBody,
          ),
      },
    );
  }

  /// Guests can't apply: the vendor role is granted to a real account, and
  /// real accounts are created (phone verified by WhatsApp code) and
  /// signed into (password, plus a WhatsApp code on a new device) through
  /// the app's normal sign-in / sign-up screens — reused here, not
  /// duplicated. Sign-in links to sign-up and pops both when done.
  Widget _buildVerify(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.vendorApplySignInIntro, style: AppTypography.bodyMuted),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
                if (mounted) _resolveStage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
              ),
              child: Text(l10n.vendorApplySignInButton, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    final phone = _verifiedPhone;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.vendorApplyIntro,
              style: AppTypography.bodyMuted,
            ),
            if (_previouslyRejected) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.vendorApplyRejectedNotice, style: const TextStyle(color: AppColors.warning, fontSize: 13)),
            ],
            if (phone != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.vendorApplyVerifiedPhoneLabel, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 18, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(formatPhone(phone), style: AppTypography.body),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _Field(controller: _businessName, label: l10n.businessNameLabel, validatorMessage: l10n.businessNameValidator),
            const SizedBox(height: AppSpacing.md),
            _Field(controller: _city, label: l10n.cityLabel, validatorMessage: l10n.cityValidator),
            const SizedBox(height: AppSpacing.md),
            _Field(controller: _address, label: l10n.addressLabel, validatorMessage: l10n.addressValidator),
            const SizedBox(height: AppSpacing.md),
            _LocationField(
              label: l10n.mapLocationLabel,
              location: _location,
              error: _locationError,
              changeLabel: l10n.changeLocation,
              setLabel: l10n.setLocationOnMap,
              notSetLabel: l10n.locationNotSet,
              onTap: _pickLocation,
            ),
            const SizedBox(height: AppSpacing.md),
            _Field(
              controller: _email,
              label: l10n.emailLabel,
              validatorMessage: l10n.emailValidator,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return l10n.emailValidator;
                if (!_emailPattern.hasMatch(trimmed) || trimmed.length > 254) {
                  return l10n.emailInvalidError;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _Field(controller: _note, label: l10n.whatDoYouSellLabel, required: false, maxLines: 3),
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
                    : Text(l10n.submitApplication, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validatorMessage,
    this.required = true,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? validatorMessage;
  final bool required;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator ??
              (required
                  ? (value) => (value == null || value.trim().isEmpty) ? validatorMessage : null
                  : null),
        ),
      ],
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.location,
    required this.error,
    required this.changeLabel,
    required this.setLabel,
    required this.notSetLabel,
    required this.onTap,
  });

  final String label;
  final PickedLocation? location;
  final String? error;
  final String changeLabel;
  final String setLabel;
  final String notSetLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
        const SizedBox(height: 6),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: error != null ? AppColors.warning : AppColors.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: AppColors.ink600),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      location?.address ?? notSetLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body,
                    ),
                  ),
                  Text(location != null ? changeLabel : setLabel, style: AppTypography.link),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: const TextStyle(color: AppColors.warning, fontSize: 12.5)),
        ],
      ],
    );
  }
}

class _StatusState extends StatelessWidget {
  const _StatusState({required this.icon, required this.color, required this.title, required this.body});

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: color),
            const SizedBox(height: AppSpacing.md),
            Text(title, textAlign: TextAlign.center, style: AppTypography.h1.copyWith(fontSize: 19)),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );
  }
}
