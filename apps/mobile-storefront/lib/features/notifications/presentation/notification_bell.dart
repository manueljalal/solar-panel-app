import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/notifications_repository.dart';
import 'notifications_screen.dart';

/// Bell in the Home header with a live unread count. Follows the auth
/// state, so signing in or out switches to that account's notifications.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    // Widget tests run without Firebase; show the plain bell there.
    if (Firebase.apps.isEmpty) return _Bell(count: 0, onTap: () {});
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, auth) {
        final uid = auth.data?.uid;
        void open() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        if (uid == null) return _Bell(count: 0, onTap: open);
        return StreamBuilder<int>(
          stream: NotificationsRepository().watchUnreadCount(uid),
          builder: (context, count) => _Bell(count: count.data ?? 0, onTap: open),
        );
      },
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).notificationsTitle,
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: const Color(0xFFD64545),
        label: Text(count > 9 ? '9+' : '$count'),
        child: Icon(count > 0 ? Icons.notifications : Icons.notifications_none_outlined, color: AppColors.ink900),
      ),
    );
  }
}
