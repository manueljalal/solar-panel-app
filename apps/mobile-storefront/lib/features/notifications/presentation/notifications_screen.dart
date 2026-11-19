import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../services/presentation/services_screen.dart';
import '../data/notifications_repository.dart';

/// The signed-in user's notifications, newest first. Everything shown is
/// marked read once it has been on screen.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = NotificationsRepository();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<List<AppNotification>>? _stream = _uid == null ? null : _repository.watch(_uid);

  void _markSeen(List<AppNotification> items) {
    if (items.any((n) => !n.read)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _repository.markRead(items).catchError((_) {}));
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
        scrolledUnderElevation: 0,
        title: Text(l10n.notificationsTitle, style: AppTypography.h1.copyWith(fontSize: 19)),
      ),
      body: _stream == null
          ? _Empty(l10n: l10n)
          : StreamBuilder<List<AppNotification>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text(l10n.homeLoadError, style: AppTypography.bodyMuted));
                }
                final items = snap.data;
                if (items == null) return const Center(child: CircularProgressIndicator());
                if (items.isEmpty) return _Empty(l10n: l10n);
                _markSeen(items);
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 72, color: AppColors.line),
                  itemBuilder: (context, i) => _Tile(item: items[i]),
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_outlined, size: 40, color: AppColors.ink400),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.notificationsEmptyTitle, style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text(l10n.notificationsEmptyBody, textAlign: TextAlign.center, style: AppTypography.bodyMuted),
          ],
        ),
      ),
    );
  }
}

/// Icon, wording and destination for one notification.
({IconData icon, String title, String body, Widget? opens}) describe(
  BuildContext context,
  AppNotification n,
) {
  final l10n = AppLocalizations.of(context);
  final vendor = n.param('vendorName');
  final status = n.param('status');
  switch (n.type) {
    case 'order_status':
      final (icon, title, body) = switch (status) {
        'confirmed' => (Icons.check_circle_outline, l10n.notifOrderConfirmedTitle, l10n.notifOrderConfirmedBody(vendor)),
        'out_for_delivery' => (Icons.local_shipping_outlined, l10n.notifOrderShippedTitle, l10n.notifOrderShippedBody(vendor)),
        'delivered' => (Icons.inventory_2_outlined, l10n.notifOrderDeliveredTitle, l10n.notifOrderDeliveredBody(vendor)),
        _ => (Icons.cancel_outlined, l10n.notifOrderCancelledTitle, l10n.notifOrderCancelledBody(vendor)),
      };
      return (icon: icon, title: title, body: body, opens: const OrdersScreen());
    case 'service_status':
      final service = n.param('serviceType') == 'cleaning' ? l10n.serviceCleaning : l10n.serviceInstallation;
      final when = n.params['scheduledFor'];
      final date = when is num
          ? MaterialLocalizations.of(context).formatMediumDate(DateTime.fromMillisecondsSinceEpoch(when.toInt()))
          : null;
      final (icon, title, body) = switch (status) {
        'scheduled' => (
            Icons.event_available_outlined,
            l10n.notifServiceScheduledTitle,
            date == null ? l10n.notifServiceScheduledNoDateBody(service) : l10n.notifServiceScheduledBody(service, date),
          ),
        'completed' => (Icons.task_alt, l10n.notifServiceCompletedTitle, l10n.notifServiceCompletedBody(service)),
        _ => (Icons.event_busy_outlined, l10n.notifServiceCancelledTitle, l10n.notifServiceCancelledBody(service)),
      };
      return (icon: icon, title: title, body: body, opens: const ServicesScreen());
    case 'announcement':
      // Written by the super admin in all three languages; show the reader's.
      final code = Localizations.localeOf(context).languageCode;
      final key = code == 'ckb' ? 'ku' : code;
      String pick(String field) {
        final m = n.params[field];
        if (m is! Map) return '';
        final v = m[key] ?? m['en'];
        return v?.toString() ?? '';
      }
      return (icon: Icons.campaign_outlined, title: pick('title'), body: pick('body'), opens: null);
    default:
      return (
        icon: Icons.request_quote_outlined,
        title: l10n.notifQuoteTitle,
        body: l10n.notifQuoteBody(vendor, n.param('productTitle')),
        opens: null,
      );
  }
}

String timeAgo(AppLocalizations l10n, MaterialLocalizations ml, DateTime at, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(at);
  if (d.inMinutes < 1) return l10n.timeJustNow;
  if (d.inHours < 1) return l10n.timeMinutesAgo(d.inMinutes);
  if (d.inDays < 1) return l10n.timeHoursAgo(d.inHours);
  if (d.inDays < 7) return l10n.timeDaysAgo(d.inDays);
  return ml.formatMediumDate(at);
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = describe(context, item);
    final opens = d.opens;
    return InkWell(
      onTap: opens == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => opens)),
      child: Container(
        color: item.read ? null : AppColors.primarySoft.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: Icon(d.icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(d.title, style: AppTypography.cardTitle.copyWith(fontSize: 14.5))),
                      Text(
                        timeAgo(l10n, MaterialLocalizations.of(context), item.createdAt),
                        style: AppTypography.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(d.body, style: AppTypography.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
