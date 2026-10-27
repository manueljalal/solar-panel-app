import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../data/profile_repository.dart';

// Same rule as backend isValidPassword (the server is the real check).
bool _strong(String p) =>
    p.length >= 8 &&
    RegExp('[A-Z]').hasMatch(p) &&
    RegExp('[a-z]').hasMatch(p) &&
    RegExp('[0-9]').hasMatch(p) &&
    RegExp('[^A-Za-z0-9]').hasMatch(p);

/// Change password: current password required; new one must meet the
/// sign-up strength rules and be typed twice. The server also limits wrong
/// current-password attempts.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.repository});

  final ProfileRepository repository;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.changePassword(current: _current.text, next: _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
      Navigator.of(context).pop();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyFunctionError(e, l10n.passwordChangeFailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.passwordChangeFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _show = !_show),
          ),
        );
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.profileChangePassword, style: AppTypography.h1.copyWith(fontSize: 18)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _current,
              obscureText: !_show,
              autocorrect: false,
              autofillHints: const [AutofillHints.password],
              decoration: deco(l10n.passwordCurrent),
              validator: (v) => (v == null || v.isEmpty) ? l10n.passwordRequired : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _next,
              obscureText: !_show,
              autocorrect: false,
              autofillHints: const [AutofillHints.newPassword],
              decoration: deco(l10n.passwordNew).copyWith(helperText: l10n.passwordValidator, helperMaxLines: 2),
              validator: (v) => _strong(v ?? '') ? null : l10n.passwordValidator,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirm,
              obscureText: !_show,
              autocorrect: false,
              decoration: deco(l10n.passwordConfirm),
              validator: (v) => v == _next.text ? null : l10n.passwordMismatch,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.warning, fontSize: 13)),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.profileChangePassword, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
