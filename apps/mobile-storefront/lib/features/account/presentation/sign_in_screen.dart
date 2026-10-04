import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import 'sign_up_screen.dart';
import 'widgets/auth_text_field.dart';

const _resendCooldownSeconds = 30;

/// Real sign-in — username + password. If the device isn't one this
/// account has used before, AuthRepository.signIn throws StepUpRequired
/// (see that class's doc) and this screen transparently switches into a
/// one-time WhatsApp-OTP step (_StepUpState.sending/codeSent) before
/// completing the sign-in — the user only sees "new device, confirm via
/// code", not a different sign-in method.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

enum _StepUpState { none, needed, codeSent }

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  late final _repository = AuthRepository();

  _StepUpState _stepUp = _StepUpState.none;
  String? _stepUpPhone;
  bool _submitting = false;
  String? _error;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.signIn(username: _usernameController.text.trim(), password: _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on StepUpRequired catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _stepUp = _StepUpState.needed;
        _stepUpPhone = e.phone;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.code == 'permission-denied' ? l10n.signInIncorrect : friendlyFunctionError(e, l10n.signInGenericError);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.signInGenericError;
      });
    }
  }

  Future<void> _sendStepUpCode() async {
    final l10n = AppLocalizations.of(context);
    if (_stepUpPhone == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.requestPhoneOtp(_stepUpPhone!);
      if (!mounted) return;
      setState(() {
        _stepUp = _StepUpState.codeSent;
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

  Future<void> _verifyStepUpCode() async {
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
      await _repository.signInOtpStepUp(username: _usernameController.text.trim(), otp: otp);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = friendlyFunctionError(e, l10n.phoneOtpIncorrectCode);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.phoneOtpVerifyFailedRetry;
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
        title: Text(
          _stepUp == _StepUpState.none ? l10n.signInTitle : l10n.stepUpTitle,
          style: AppTypography.h1.copyWith(fontSize: 19),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _stepUp == _StepUpState.none ? _buildSignInForm(l10n) : _buildStepUp(l10n),
      ),
    );
  }

  Widget _buildSignInForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            label: l10n.usernameLabel,
            controller: _usernameController,
            forceLatinKeyboard: true,
            autofillHints: const [AutofillHints.username],
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.usernameValidator : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            label: l10n.passwordLabel,
            controller: _passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            validator: (v) => (v == null || v.isEmpty) ? l10n.passwordValidator : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.warning, fontSize: 12.5)),
          ],
          const SizedBox(height: AppSpacing.lg),
          _submitButton(onPressed: _submit, label: l10n.signInSubmit),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
              ),
              child: Text(l10n.needAnAccount),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepUp(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.stepUpBody, style: AppTypography.bodyMuted),
        const SizedBox(height: AppSpacing.lg),
        if (_stepUp == _StepUpState.codeSent) ...[
          AuthTextField(
            label: l10n.phoneOtpCodeLabel,
            controller: _otpController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Spacer(),
              if (_cooldownSeconds > 0)
                Text(l10n.phoneOtpResendIn(_cooldownSeconds), style: AppTypography.bodyMuted)
              else
                TextButton(
                  onPressed: _submitting ? null : _sendStepUpCode,
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
        _submitButton(
          onPressed: _stepUp == _StepUpState.codeSent ? _verifyStepUpCode : _sendStepUpCode,
          label: _stepUp == _StepUpState.codeSent ? l10n.stepUpVerifyCode : l10n.stepUpSendCode,
        ),
      ],
    );
  }

  Widget _submitButton({required VoidCallback onPressed, required String label}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitting ? null : onPressed,
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
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}
