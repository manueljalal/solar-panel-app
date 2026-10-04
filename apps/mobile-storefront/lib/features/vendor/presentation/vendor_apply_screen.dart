import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/location/location_picker_screen.dart';
import '../../../shared/location/picked_location.dart';
import '../data/vendor_application_repository.dart';

/// Real vendor onboarding form — writes to Firestore via
/// VendorApplicationRepository. Reached from the home screen's "Own a
/// solar business? Apply" card, which previously did nothing.
class VendorApplyScreen extends StatefulWidget {
  const VendorApplyScreen({super.key});

  @override
  State<VendorApplyScreen> createState() => _VendorApplyScreenState();
}

// Mirrors the backend's EMAIL_PATTERN in
// backend/functions/src/vendor/submit_application.ts — kept in sync so the
// client rejects the same inputs the callable would.
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class _VendorApplyScreenState extends State<VendorApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _note = TextEditingController();
  final _repository = VendorApplicationRepository();

  PickedLocation? _location;
  bool _submitting = false;
  bool _submitted = false;
  String? _locationError;

  @override
  void dispose() {
    _businessName.dispose();
    _city.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _note.dispose();
    super.dispose();
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
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        note: _note.text.trim(),
        location: location,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
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
      body: _submitted ? const _SubmittedState() : _buildForm(l10n),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
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
            _Field(controller: _phone, label: l10n.phoneNumberLabel, validatorMessage: l10n.phoneNumberValidator, keyboardType: TextInputType.phone),
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

class _SubmittedState extends StatelessWidget {
  const _SubmittedState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 44, color: AppColors.success),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.applicationSubmittedTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
            const SizedBox(height: 6),
            Text(
              l10n.applicationSubmittedBody,
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
