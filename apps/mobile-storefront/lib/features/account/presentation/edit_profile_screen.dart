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

/// Profile settings laid out like Amazon's "Login & security" / Facebook's
/// "Personal details": a list of rows showing each current value; tapping
/// one opens a focused page for just that field. Pops `true` if anything
/// was saved, so the Account tab refreshes.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile, ProfileRepository? repository}) : _repository = repository;

  final MyProfile profile;
  final ProfileRepository? _repository;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final ProfileRepository _repo = widget._repository ?? ProfileRepository();
  late MyProfile _profile = widget.profile;
  bool _changed = false;

  Future<void> _edit({
    required String title,
    required String help,
    required String initial,
    required String? Function(String) validate,
    required Future<void> Function(String) save,
    required MyProfile Function(String) apply,
    TextInputType keyboard = TextInputType.text,
    String? prefix,
    bool ltrField = false,
    String? clearLabel,
  }) async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _EditFieldScreen(
          title: title,
          help: help,
          initial: initial,
          validate: validate,
          save: save,
          keyboard: keyboard,
          prefix: prefix,
          ltrField: ltrField,
          clearLabel: clearLabel,
        ),
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      _profile = apply(value);
      _changed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = _profile;
    final initial = p.name.trim().isEmpty ? '?' : p.name.trim().characters.first.toUpperCase();
    MyProfile copy({String? name, String? username, String? email}) => MyProfile(
          name: name ?? p.name,
          username: username ?? p.username,
          phone: p.phone,
          email: email ?? p.email,
          location: p.location,
          addressLine: p.addressLine,
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(l10n.profileTitle, style: AppTypography.h1.copyWith(fontSize: 18)),
        ),
        body: ListView(
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(child: Text(p.name, style: AppTypography.h1.copyWith(fontSize: 20))),
            if (p.username.isNotEmpty) Center(child: Text('@${p.username}', style: AppTypography.bodyMuted)),
            const SizedBox(height: AppSpacing.xl),
            _Header(l10n.profilePersonalInfo),
            _Row(
              label: l10n.phoneOtpNameLabel,
              value: p.name,
              onTap: () => _edit(
                title: l10n.phoneOtpNameLabel,
                help: l10n.profileNameHelp,
                initial: p.name,
                validate: (v) => v.trim().isEmpty ? l10n.phoneOtpNameValidator : null,
                save: (v) => _repo.update(name: v),
                apply: (v) => copy(name: v),
              ),
            ),
            _Row(
              label: l10n.usernameLabel,
              value: p.username.isEmpty ? l10n.profileAdd : '@${p.username}',
              onTap: () => _edit(
                title: l10n.usernameLabel,
                help: l10n.profileUsernameHelp,
                initial: p.username,
                prefix: '@',
                ltrField: true,
                validate: (v) => _usernamePattern.hasMatch(v.trim().toLowerCase()) ? null : l10n.usernameValidator,
                save: (v) => _repo.update(username: v.trim().toLowerCase()),
                apply: (v) => copy(username: v.trim().toLowerCase()),
              ),
            ),
            _Row(
              label: l10n.emailLabel,
              value: p.email.isEmpty ? l10n.profileAdd : p.email,
              muted: p.email.isEmpty,
              onTap: () => _edit(
                title: l10n.emailLabel,
                help: l10n.profileEmailHelp,
                initial: p.email,
                keyboard: TextInputType.emailAddress,
                ltrField: true,
                clearLabel: p.email.isEmpty ? null : l10n.profileRemoveEmail,
                validate: (v) {
                  final t = v.trim();
                  return t.isEmpty || (_emailPattern.hasMatch(t) && t.length <= 254) ? null : l10n.emailInvalidError;
                },
                save: (v) => _repo.update(email: v.trim()),
                apply: (v) => copy(email: v.trim()),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Header(l10n.profileLoginSecurity),
            _Row(
              label: l10n.profilePhoneVerified,
              value: ltr(p.phone),
              trailing: const Icon(Icons.verified, size: 18, color: AppColors.success),
              footnote: l10n.profilePhoneNote,
            ),
            _Row(
              label: l10n.passwordLabel,
              value: '••••••••',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChangePasswordScreen(repository: _repo)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xs),
        child: Text(text, style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
      );
}

/// One setting: label on top, current value below, chevron if editable.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.onTap, this.trailing, this.footnote, this.muted = false});

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? footnote;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: muted ? AppColors.primary : AppColors.ink900,
                          ),
                        ),
                      ),
                      if (trailing != null) ...[const SizedBox(width: 6), trailing!],
                    ],
                  ),
                  if (footnote != null) ...[
                    const SizedBox(height: 4),
                    Text(footnote!, style: AppTypography.bodyMuted.copyWith(fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}

/// Focused single-field editor: one input, a short explanation, and a Save
/// button pinned to the bottom. Pops with the saved value.
class _EditFieldScreen extends StatefulWidget {
  const _EditFieldScreen({
    required this.title,
    required this.help,
    required this.initial,
    required this.validate,
    required this.save,
    required this.keyboard,
    this.prefix,
    this.ltrField = false,
    this.clearLabel,
  });

  final String title;
  final String help;
  final String initial;
  final String? Function(String) validate;
  final Future<void> Function(String) save;
  final TextInputType keyboard;
  final String? prefix;
  final bool ltrField;
  final String? clearLabel;

  @override
  State<_EditFieldScreen> createState() => _EditFieldScreenState();
}

class _EditFieldScreenState extends State<_EditFieldScreen> {
  late final _controller = TextEditingController(text: widget.initial);
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _dirty => _controller.text.trim() != widget.initial.trim();

  Future<void> _submit(String value) async {
    final l10n = AppLocalizations.of(context);
    final problem = widget.validate(value);
    if (problem != null) return setState(() => _error = problem);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.save(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      Navigator.of(context).pop(value);
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.title, style: AppTypography.h1.copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.help, style: AppTypography.bodyMuted),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                autofocus: true,
                autocorrect: false,
                keyboardType: widget.keyboard,
                textDirection: widget.ltrField ? TextDirection.ltr : null,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) {
                  if (_dirty && !_saving) _submit(v);
                },
                decoration: InputDecoration(
                  prefixText: widget.prefix,
                  errorText: _error,
                  errorMaxLines: 3,
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: _controller.clear),
                ),
              ),
              if (widget.clearLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _saving ? null : () => _submit(''),
                  style: TextButton.styleFrom(foregroundColor: AppColors.warning, padding: EdgeInsets.zero),
                  child: Text(widget.clearLabel!),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving || !_dirty ? null : () => _submit(_controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.chip)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.accountSave, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
