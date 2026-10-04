import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/location/location_picker_screen.dart';
import '../../../shared/location/picked_location.dart';
import 'sign_in_screen.dart';
import 'widgets/auth_text_field.dart';

const _e164Pattern = r'^\+[1-9]\d{6,14}$';
const _resendCooldownSeconds = 30;

/// Mirrors backend/functions/src/shared/auth/password.ts's isValidPassword
/// exactly — this is fast client-side feedback only; the backend is the
/// real enforcement and re-checks this independently, so there's no
/// security reliance on this copy staying in sync (a stale client check
/// would just show a confusing error, not let a weak password through).
bool _isValidPassword(String password) {
  return password.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(password);
}

/// Real registration: name, username, password, phone, location — the
/// phone is proven via a WhatsApp-delivered OTP in the same flow before
/// the account is actually created (see AuthRepository.signUp /
/// backend/functions/src/auth/sign_up.ts). Username + password is the
/// credential used for every sign-in after this; the OTP step only ever
/// runs again if signing in from a brand-new device (see sign_in_screen.dart).
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  late final _repository = AuthRepository();

  PickedLocation? _location;
  bool _codeSent = false;
  bool _submitting = false;
  String? _error;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String get _phone => _phoneController.text.trim();

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds -= 1;
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    });
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)),
    );
    if (picked == null) return;
    setState(() {
      _location = picked;
      _error = null;
    });
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    if (!RegExp(_e164Pattern).hasMatch(_phone)) {
      setState(() => _error = l10n.phoneOtpInvalidFormat);
      return;
    }
    if (_location == null) {
      setState(() => _error = l10n.phoneOtpLocationRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.requestPhoneOtp(_phone);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _submitting = false;
      });
      _startCooldown();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = friendlyFunctionError(e, l10n.phoneOtpSendFailedRetry);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.phoneOtpSendFailedConnection;
      });
    }
  }

  Future<void> _createAccount() async {
    final l10n = AppLocalizations.of(context);
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = l10n.phoneOtpEnterCode);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.signUp(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        phone: _phone,
        otp: otp,
        location: _location,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).maybePop();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.code == 'already-exists' ? l10n.signUpUsernameTaken : friendlyFunctionError(e, l10n.signUpGenericError);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.signUpGenericError;
      });
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
        title: Text(l10n.signUpTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_codeSent) ...[
                AuthTextField(
                  label: l10n.phoneOtpNameLabel,
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.phoneOtpNameValidator : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  label: l10n.usernameLabel,
                  controller: _usernameController,
                  forceLatinKeyboard: true,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    return RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(value) ? null : l10n.usernameValidator;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  label: l10n.passwordLabel,
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => _isValidPassword(v ?? '') ? null : l10n.passwordValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  label: l10n.confirmPasswordLabel,
                  controller: _confirmPasswordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => v == _passwordController.text ? null : l10n.confirmPasswordValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  label: l10n.phoneOtpPhoneLabel,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                _LocationField(
                  label: l10n.phoneOtpLocationLabel,
                  location: _location,
                  onTap: _pickLocation,
                ),
              ] else ...[
                Text(
                  l10n.phoneOtpEnterCodeBody(_phone),
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.lg),
                AuthTextField(
                  label: l10n.phoneOtpCodeLabel,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : () => setState(() => _codeSent = false),
                      child: Text(l10n.phoneOtpUseDifferentNumber),
                    ),
                    const Spacer(),
                    if (_cooldownSeconds > 0)
                      Text(l10n.phoneOtpResendIn(_cooldownSeconds), style: AppTypography.bodyMuted)
                    else
                      TextButton(
                        onPressed: _submitting ? null : _sendCode,
                        child: Text(l10n.phoneOtpResendCode),
                      ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.warning, fontSize: 12.5)),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : (_codeSent ? _createAccount : _sendCode),
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
                          _codeSent ? l10n.signUpSubmit : l10n.phoneOtpSendCode,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
              if (!_codeSent) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                    child: Text(l10n.alreadyHaveAccount),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({required this.label, required this.location, required this.onTap});

  final String label;
  final PickedLocation? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.ink600),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      location?.address ?? l10n.locationNotSet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body,
                    ),
                  ),
                  Text(location != null ? l10n.changeLocation : l10n.setLocationOnMap, style: AppTypography.link),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
