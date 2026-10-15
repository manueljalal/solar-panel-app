import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/auth/password_rules.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/location/location_picker_screen.dart';
import '../../../shared/location/picked_location.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/domain/home_product.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order.dart';
import '../../orders/presentation/order_status_label.dart';
import 'widgets/auth_text_field.dart';

PreferredSizeWidget _appBar(String title) => AppBar(
      backgroundColor: AppColors.surfaceSunken,
      elevation: 0,
      title: Text(title, style: AppTypography.h1.copyWith(fontSize: 20)),
    );

/// Runs [action], turning callable failures into a user-facing message.
Future<String?> _attempt(Future<void> Function() action, String fallback) async {
  try {
    await action();
    return null;
  } on FirebaseFunctionsException catch (e) {
    return friendlyFunctionError(e, fallback);
  } catch (_) {
    return fallback;
  }
}

/// Account → My quotes: each request and the vendor's answer.
class MyQuotesScreen extends StatefulWidget {
  const MyQuotesScreen({super.key});

  @override
  State<MyQuotesScreen> createState() => _MyQuotesScreenState();
}

class _MyQuotesScreenState extends State<MyQuotesScreen> {
  late Future<List<QuoteRequestSummary>> _future = OrdersRepository().listMyQuoteRequests();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: _appBar(l10n.myQuotesTitle),
      body: FutureBuilder<List<QuoteRequestSummary>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _future = OrdersRepository().listMyQuoteRequests()),
                child: Text(l10n.retry),
              ),
            );
          }
          final quotes = snap.data!;
          if (quotes.isEmpty) {
            return Center(child: Text(l10n.myQuotesEmpty, style: AppTypography.bodyMuted));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: quotes.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final q = quotes[i];
              final status = switch (q.status) {
                'responded' => l10n.quoteStatusResponded,
                'declined' => l10n.quoteStatusDeclined,
                _ => l10n.quoteStatusWaiting,
              };
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.productTitle, style: AppTypography.cardTitle),
                    Text(
                      [q.vendor, if (q.createdAt != null) formatOrderDate(q.createdAt!, locale)].join(' · '),
                      style: AppTypography.bodyMuted,
                    ),
                    if (q.note.isNotEmpty) ...[const SizedBox(height: 6), Text(q.note, style: AppTypography.body)],
                    const SizedBox(height: AppSpacing.sm),
                    Text(status, style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.primary)),
                    if (q.price != null)
                      Text(formatMoney(q.price!, q.currency ?? 'USD'), style: AppTypography.price),
                    if ((q.responseMessage ?? '').isNotEmpty) Text(q.responseMessage!, style: AppTypography.body),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Account → Edit profile: display name and saved location.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _repo = AuthRepository();
  PickedLocation? _location;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo.getMyProfile().then((p) {
      if (!mounted) return;
      setState(() {
        _name.text = p.name;
        _location = p.location;
        _loading = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _location)),
    );
    if (picked != null) setState(() => _location = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await _attempt(
      () => _repo.updateMyProfile(name: _name.text.trim(), location: _location),
      l10n.genericConnectionError,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: _appBar(l10n.editProfileTitle),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AuthTextField(
                    label: l10n.phoneOtpNameLabel,
                    controller: _name,
                    validator: (v) => (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.phoneOtpLocationLabel, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.location_on_outlined),
                    label: Text(
                      _location?.address.isNotEmpty == true ? _location!.address : l10n.accountChange,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_error != null) ...[FormErrorText(_error!), const SizedBox(height: AppSpacing.sm)],
                  PrimaryButton(label: l10n.save, busy: _saving, onPressed: _save),
                ],
              ),
            ),
    );
  }
}

/// Account → Change password (needs the current one).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await _attempt(
      () => AuthRepository().changePassword(currentPassword: _current.text, newPassword: _next.text),
      l10n.genericConnectionError,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: _appBar(l10n.changePasswordTitle),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AuthTextField(
              label: l10n.currentPasswordLabel,
              controller: _current,
              obscureText: true,
              validator: (v) => (v ?? '').isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: l10n.newPasswordLabel,
              controller: _next,
              obscureText: true,
              validator: (v) => isValidPassword(v ?? '') ? null : l10n.passwordValidator,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              label: l10n.confirmPasswordLabel,
              controller: _confirm,
              obscureText: true,
              validator: (v) => v == _next.text ? null : l10n.confirmPasswordValidator,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_error != null) ...[FormErrorText(_error!), const SizedBox(height: AppSpacing.sm)],
            PrimaryButton(label: l10n.save, busy: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

/// Asks for the password and permanently deletes the account. Returns true
/// when the account was deleted.
Future<bool> showDeleteAccountDialog(BuildContext context) async {
  final deleted = await showDialog<bool>(context: context, builder: (_) => const _DeleteAccountDialog());
  return deleted ?? false;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _attempt(
      () => AuthRepository().deleteMyAccount(password: _password.text),
      l10n.genericConnectionError,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAccountBody),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _password,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(labelText: l10n.passwordLabel),
          ),
          if (_error != null) ...[const SizedBox(height: AppSpacing.sm), FormErrorText(_error!)],
        ],
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        TextButton(
          onPressed: _busy ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: AppColors.warning),
          child: Text(l10n.deleteAccountConfirm),
        ),
      ],
    );
  }
}

/// "Forgot password?" from the sign-in screen: username → WhatsApp code →
/// new password. Pops with true once signed in.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialIdentifier = ''});

  final String initialIdentifier;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _identifier = TextEditingController(text: widget.initialIdentifier);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _repo = AuthRepository();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_identifier, _code, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context);
    if (_identifier.text.trim().isEmpty) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _attempt(() => _repo.requestPasswordReset(_identifier.text.trim()), l10n.phoneOtpSendFailedConnection);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      if (error == null) _codeSent = true;
    });
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _attempt(
      () => _repo.resetPassword(identifier: _identifier.text.trim(), otp: _code.text.trim(), newPassword: _password.text),
      l10n.signInGenericError,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      appBar: _appBar(l10n.forgotPasswordTitle),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AuthTextField(
              label: l10n.usernameLabel,
              controller: _identifier,
              forceLatinKeyboard: true,
              autofillHints: const [AutofillHints.username],
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_codeSent) ...[
              Text(l10n.forgotPasswordBody, style: AppTypography.bodyMuted),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...[FormErrorText(_error!), const SizedBox(height: AppSpacing.sm)],
              PrimaryButton(label: l10n.forgotPasswordSendCode, busy: _busy, onPressed: _sendCode),
            ] else ...[
              Text(l10n.forgotPasswordCodeSent, style: AppTypography.bodyMuted),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: l10n.phoneOtpCodeLabel,
                controller: _code,
                keyboardType: TextInputType.number,
                validator: (v) => (v ?? '').trim().length == 6 ? null : l10n.phoneOtpEnterCode,
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                label: l10n.newPasswordLabel,
                controller: _password,
                obscureText: true,
                validator: (v) => isValidPassword(v ?? '') ? null : l10n.passwordValidator,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_error != null) ...[FormErrorText(_error!), const SizedBox(height: AppSpacing.sm)],
              PrimaryButton(label: l10n.forgotPasswordReset, busy: _busy, onPressed: _reset),
              TextButton(onPressed: _busy ? null : _sendCode, child: Text(l10n.forgotPasswordResend)),
            ],
          ],
        ),
      ),
    );
  }
}
