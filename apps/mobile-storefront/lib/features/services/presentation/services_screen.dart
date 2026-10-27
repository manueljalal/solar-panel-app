import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/auth/friendly_function_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/sign_in_screen.dart';
import '../data/services_repository.dart';
import '../domain/service_request.dart';
import 'service_request_screen.dart';

/// Services tab: book an installation or a panel cleaning, reach the call
/// center, and follow your own requests.
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, ServicesRepository? repository}) : _repository = repository;

  final ServicesRepository? _repository;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late final ServicesRepository _repo = widget._repository ?? ServicesRepository();
  Future<SupportInfo>? _support;
  Future<List<ServiceRequest>>? _mine;

  User? get _user => Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
  bool get _hasAccount => _user != null && !_user!.isAnonymous;

  @override
  void initState() {
    super.initState();
    ServicesRepository.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    ServicesRepository.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    final support = Firebase.apps.isEmpty ? null : _repo.support();
    final mine = _hasAccount ? _repo.listMine() : null;
    setState(() {
      _support = support;
      _mine = mine;
    });
  }

  Future<void> _book(ServiceType type) async {
    final l10n = AppLocalizations.of(context);
    if (!_hasAccount) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.serviceSignInBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.orderKeep)),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.accountSignIn)),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
        _reload();
      }
      return;
    }
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ServiceRequestScreen(type: type, repository: _repo)),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.serviceSent)));
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
        centerTitle: false,
        title: Text(l10n.servicesTitle, style: AppTypography.h1.copyWith(fontSize: 20)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          children: [
            Text(l10n.servicesIntro, style: AppTypography.bodyMuted),
            const SizedBox(height: AppSpacing.lg),
            _ServiceCard(
              icon: Icons.solar_power_outlined,
              title: l10n.serviceInstallation,
              subtitle: l10n.serviceInstallationHint,
              onTap: () => _book(ServiceType.installation),
            ),
            const SizedBox(height: AppSpacing.md),
            _ServiceCard(
              icon: Icons.water_drop_outlined,
              title: l10n.serviceCleaning,
              subtitle: l10n.serviceCleaningHint,
              onTap: () => _book(ServiceType.cleaning),
            ),
            const SizedBox(height: AppSpacing.md),
            _CallCenterCard(support: _support),
            if (_hasAccount) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.serviceMyRequests, style: AppTypography.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: AppSpacing.md),
              FutureBuilder<List<ServiceRequest>>(
                future: _mine,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Row(
                      children: [
                        Expanded(child: Text(l10n.homeLoadError, style: AppTypography.bodyMuted)),
                        TextButton(onPressed: _reload, child: Text(l10n.retry)),
                      ],
                    );
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) return Text(l10n.serviceNoRequests, style: AppTypography.bodyMuted);
                  return Column(
                    children: [
                      for (final r in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _RequestCard(request: r, repository: _repo),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 15.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodyMuted),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }
}

class _CallCenterCard extends StatelessWidget {
  const _CallCenterCard({required this.support});

  final Future<SupportInfo>? support;

  Future<void> _open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: FutureBuilder<SupportInfo>(
        future: support,
        builder: (context, snap) {
          final info = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.support_agent_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.serviceCallCenter, style: AppTypography.cardTitle.copyWith(fontSize: 15.5)),
                        const SizedBox(height: 2),
                        Text(
                          info?.hours.isNotEmpty == true ? info!.hours : l10n.serviceCallCenterHint,
                          style: AppTypography.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (snap.connectionState == ConnectionState.done && !(info?.isSet ?? false))
                Text(l10n.serviceSupportNotSet, style: AppTypography.bodyMuted)
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: info == null ? null : () => _open(Uri(scheme: 'tel', path: info.phone)),
                        icon: const Icon(Icons.call_outlined, size: 18),
                        label: Text(l10n.serviceCall),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: info == null
                            ? null
                            : () => _open(Uri.parse('https://wa.me/${info.whatsapp.replaceAll(RegExp(r'\D'), '')}')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text(l10n.serviceWhatsApp),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.request, required this.repository});

  final ServiceRequest request;
  final ServicesRepository repository;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _busy = false;

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.repository.cancel(widget.request.id);
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyFunctionError(e, l10n.orderActionFailed))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.orderActionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.request;
    final ml = MaterialLocalizations.of(context);
    final (label, color) = switch (r.status) {
      ServiceStatus.newRequest => (l10n.serviceStatusNew, AppColors.accent),
      ServiceStatus.scheduled => (l10n.serviceStatusScheduled, AppColors.primary),
      ServiceStatus.completed => (l10n.serviceStatusCompleted, AppColors.success),
      ServiceStatus.cancelled => (l10n.serviceStatusCancelled, AppColors.ink400),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.type == ServiceType.cleaning ? l10n.serviceCleaning : l10n.serviceInstallation,
                  style: AppTypography.cardTitle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.chip)),
                child: Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(r.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMuted),
          if (r.scheduledFor != null) ...[
            const SizedBox(height: 4),
            Text(l10n.serviceScheduledFor(ml.formatMediumDate(r.scheduledFor!)), style: AppTypography.body),
          ],
          if (r.vendorName != null && r.vendorName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(l10n.orderFrom(r.vendorName!), style: AppTypography.bodyMuted),
          ],
          if (r.canCancel)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: _busy ? null : _cancel, child: Text(l10n.serviceCancel)),
            ),
        ],
      ),
    );
  }
}
