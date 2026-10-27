import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/bidi.dart';
import '../data/profile_repository.dart';
import 'change_password_screen.dart';

final _usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Edit name, username and email; phone is shown verified and read-only.
/// Only changed fields are sent, and the server re-validates everything
/// (username uniqueness is enforced there in a transaction). Pops `true`
/// after a successful save.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile, ProfileRepository? repository}) : _repository = repository;

  final MyProfile profile;
  final ProfileRepository? _repository;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final ProfileRepository _repo = widget._repository ?? ProfileRepository();
  final _formKey = GlobalKey<FormState>();
  // Owned by this State and disposed in dispose() — never while a widget
  // that uses them is still on screen.
  late final _name = TextEditingController(text: widget.profile.name);
  late final _username = TextEditingController(text: widget.profile.username);
  late final _email = TextEditingController(text: widget.profile.email);
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _username, _email]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _changed(TextEditingController c, String original) {
    final v = c.text.trim();
    return v == original ? null : v;
  }

  bool get _dirty =>
      _changed(_name, widget.profile.name) != null ||
      _changed(_username, widget.profile.username) != null ||
      _changed(_email, widget.profile.email) != null;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.update(
        name: _changed(_name, widget.profile.name),
        username: _changed(_username, widget.profile.username)?.toLowerCase(),
        email: _changed(_email, widget.profile.email),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      Navigator.of(context).pop(true);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyFunctionError(e, l10n.profileSaveFailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.profileSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initial = _name.text.trim().isEmpty ? '?' : _name.text.trim().characters.first.toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceSunken,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.profileTitle, style: AppTypography.h1.copyWith(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _saving || !_dirty ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.accountSave, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _Card(
              title: l10n.profileDetails,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 80,
                  decoration: InputDecoration(labelText: l10n.phoneOtpNameLabel, counterText: ''),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.phoneOtpNameValidator : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _username,
                  autocorrect: false,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: l10n.usernameLabel, prefixText: '@'),
                  validator: (v) => _usernamePattern.hasMatch((v ?? '').trim().toLowerCase()) ? null : l10n.usernameValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: l10n.profileEmailOptional, helperText: l10n.profileEmailHint),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    return t.isEmpty || (_emailPattern.hasMatch(t) && t.length <= 254) ? null : l10n.emailInvalidError;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Card(
              title: l10n.profilePhoneVerified,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(ltr(widget.profile.phone), style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(l10n.profilePhoneNote, style: AppTypography.bodyMuted.copyWith(fontSize: 12.5)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Card(
              title: l10n.profileSecurity,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChangePasswordScreen(repository: _repo)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(l10n.profileChangePassword, style: AppTypography.body)),
                      const Icon(Icons.chevron_right, color: AppColors.ink400),
                    ],
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(_error!, style: const TextStyle(color: AppColors.warning, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodyMuted.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
