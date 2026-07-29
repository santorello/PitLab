import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../application/notifications_providers.dart';

/// Bell icon with unread badge.
/// Polls the unread count every [_pollInterval] when the widget is alive.
/// Tap navigates to /notifications (guests are silently ignored — the route
/// itself has no auth redirect but simply shows an empty state).
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(minutes: 2);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  void _startPolling() {
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  void _refresh() {
    ref.invalidate(unreadNotificationCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final count = user == null
        ? 0
        : countAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return IconButton(
      tooltip: l10n.notificationsTitle,
      onPressed: () {
        // Invalidate list so it reloads when screen opens.
        ref.invalidate(notificationsListProvider);
        context.go('/notifications');
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            count > 0
                ? Icons.notifications_outlined
                : Icons.notifications_none_outlined,
            color: Colors.white,
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: _Badge(count: count),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.signalOrange,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.graphite, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
