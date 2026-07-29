import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../application/notifications_providers.dart';
import '../domain/notification_item.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = ref.watch(notificationsListProvider);
    final controller = ref.read(notificationsListProvider.notifier);

    return ContentScaffold(
      title: l10n.notificationsTitle,
      description: l10n.notificationsDescription,
      child: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(l10n: l10n),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(l10n: l10n);
          }
          final hasUnread = items.any((n) => n.isUnread);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Mark-all action bar ─────────────────────────────────
              if (hasUnread)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: controller.markAllRead,
                      icon: const Icon(Icons.done_all_outlined, size: 18),
                      label: Text(l10n.notificationsMarkAllRead),
                    ),
                  ),
                ),
              // ── List ─────────────────────────────────────────────────
              Expanded(
                child: _NotificationList(
                  items: items,
                  controller: controller,
                  l10n: l10n,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── List ──────────────────────────────────────────────────────────────────────

class _NotificationList extends ConsumerWidget {
  const _NotificationList({
    required this.items,
    required this.controller,
    required this.l10n,
  });

  final List<NotificationItem> items;
  final NotificationsListController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMore = controller.hasMore;

    return ListView.builder(
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return _LoadMoreButton(
            onTap: () => controller.loadMore(),
            l10n: l10n,
          );
        }
        final item = items[index];
        return _NotificationTile(
          item: item,
          l10n: l10n,
          onTap: () => _handleTap(context, item),
        );
      },
    );
  }

  void _handleTap(BuildContext context, NotificationItem item) {
    // Mark read.
    if (item.isUnread) {
      controller.markRead(item.id);
    }
    // Navigate based on entity.
    final target = _resolveRoute(item);
    if (target != null) {
      context.go(target);
    }
  }

  String? _resolveRoute(NotificationItem item) {
    switch (item.entityType) {
      case 'user_build':
        final buildId = item.payload['build_id'] as String?;
        final ownerId = item.payload['owner_id'] as String?;
        if (buildId != null && ownerId != null) {
          return '/garage'; // deep-link to specific build not yet wired
        }
        return '/garage';
      case 'community_event':
        final eventId = item.payload['event_id'] as String?;
        if (eventId != null) return '/event/$eventId';
        return '/events';
      case 'profile':
        // new_follower → profile of the follower
        final followerId = item.payload['follower_id'] as String?;
        if (followerId != null && item.entityId.isNotEmpty) {
          // We have the follower UUID but public_profile_screen needs the slug.
          // Navigate to profiles listing as fallback until slug is in payload.
          return '/profiles';
        }
        return '/profiles';
      default:
        return null;
    }
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.l10n,
    required this.onTap,
  });

  final NotificationItem item;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = item.isUnread;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: unread
              ? AppColors.signalOrange.withAlpha(12)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withAlpha(80),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBg(unread),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _kindIcon(item.kind),
                size: 20,
                color: unread ? AppColors.signalOrange : AppColors.steel,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          unread ? FontWeight.w700 : FontWeight.normal,
                      color: AppColors.graphite,
                    ),
                  ),
                  if (item.body != null && item.body!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.body!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.steel),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(item.createdAt),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.steel),
                  ),
                ],
              ),
            ),
            // Unread dot
            if (unread)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.signalOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _iconBg(bool unread) => unread
      ? AppColors.signalOrange.withAlpha(22)
      : const Color(0xFFF2F4F7);

  IconData _kindIcon(String kind) => switch (kind) {
        'new_follower' => Icons.person_add_outlined,
        'followed_activity' => Icons.notifications_active_outlined,
        'approval_requested' => Icons.pending_outlined,
        'approval_decided' => Icons.check_circle_outline,
        'ownership_assigned' => Icons.handshake_outlined,
        _ => Icons.notifications_outlined,
      };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'adesso';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    if (diff.inDays < 7) return '${diff.inDays} g fa';
    return intl.DateFormat('d MMM', 'it').format(dt);
  }
}

// ── Load more ─────────────────────────────────────────────────────────────────

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.onTap, required this.l10n});

  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton(
          onPressed: onTap,
          child: Text(l10n.notificationsLoadMore),
        ),
      ),
    );
  }
}

// ── Empty & error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: AppColors.steel.withAlpha(140),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.notificationsEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notificationsEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.steel,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.steel),
            const SizedBox(height: 16),
            Text(
              l10n.notificationsErrorTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
