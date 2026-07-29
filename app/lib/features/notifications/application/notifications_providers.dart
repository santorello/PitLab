import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/notification_item.dart';
import '../infrastructure/notifications_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final notificationsRepositoryProvider =
    Provider<NotificationsRepository?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) return null;
  return NotificationsRepository(client);
});

// ── Unread count (polled) ─────────────────────────────────────────────────────

/// Unread notification count for the authenticated user.
/// Returns 0 for guests. Re-read whenever [notificationsListProvider] is
/// invalidated (mark-read / mark-all-read).
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  final repository = ref.watch(notificationsRepositoryProvider);
  if (repository == null) return 0;
  try {
    return repository.fetchUnreadCount();
  } catch (_) {
    return 0;
  }
});

// ── Notification list controller ──────────────────────────────────────────────

final notificationsListProvider =
    AsyncNotifierProvider<NotificationsListController, List<NotificationItem>>(
  NotificationsListController.new,
);

class NotificationsListController
    extends AsyncNotifier<List<NotificationItem>> {
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<NotificationItem>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    final repository = ref.watch(notificationsRepositoryProvider);
    if (repository == null) return const [];
    _hasMore = true;
    return _fetchPage(repository, before: null);
  }

  Future<List<NotificationItem>> _fetchPage(
    NotificationsRepository repository, {
    required DateTime? before,
  }) async {
    final items = await repository.fetchNotifications(before: before);
    if (items.length < 30) _hasMore = false;
    return items;
  }

  /// Loads the next page and appends to the current list.
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.value;
    if (current == null || current.isEmpty) return;
    final repository = ref.read(notificationsRepositoryProvider);
    if (repository == null) return;

    final oldest = current.last.createdAt;
    try {
      final next = await _fetchPage(repository, before: oldest);
      state = AsyncData([...current, ...next]);
    } catch (e, st) {
      // Surface error without losing existing data.
      state = AsyncError(e, st);
    }
  }

  /// Optimistically marks a single item read and persists in background.
  void markRead(String recipientId) {
    final current = state.value;
    if (current == null) return;
    final updated = current.map((item) {
      if (item.id == recipientId && item.isUnread) {
        return item.copyWith(readAt: DateTime.now());
      }
      return item;
    }).toList();
    state = AsyncData(updated);
    final repository = ref.read(notificationsRepositoryProvider);
    unawaited(repository?.markRead(recipientId).then((_) {
      ref.invalidate(unreadNotificationCountProvider);
    }));
  }

  /// Optimistically marks all items read and persists in background.
  void markAllRead() {
    final current = state.value;
    if (current == null) return;
    final now = DateTime.now();
    final updated = current
        .map((item) => item.isUnread ? item.copyWith(readAt: now) : item)
        .toList();
    state = AsyncData(updated);
    final repository = ref.read(notificationsRepositoryProvider);
    unawaited(repository?.markAllRead().then((_) {
      ref.invalidate(unreadNotificationCountProvider);
    }));
  }
}
