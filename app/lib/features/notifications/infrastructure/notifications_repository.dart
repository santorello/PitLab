import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/bootstrap/error_reporting.dart';
import '../domain/notification_item.dart';

class NotificationsRepository {
  const NotificationsRepository(this._client);

  final SupabaseClient _client;

  static const int _pageSize = 30;

  /// Loads [_pageSize] notifications for the authenticated user.
  ///
  /// Strategy: query `notifications` (RLS grants access when current user is
  /// a recipient) joined to `notification_recipients` for read_at and the
  /// recipient row id. Order and filter happen on the `notifications` table
  /// columns so the PostgREST query is straightforward.
  Future<List<NotificationItem>> fetchNotifications({
    DateTime? before,
  }) async {
    try {
      // Select from notifications with the recipient join embedded.
      // PostgREST hint: `notification_recipients!inner` ensures only rows
      // where the current user IS a recipient are returned.
      var query = _client
          .from('notifications')
          .select(
            'id, kind, entity_type, entity_id, title, body, payload, created_at, '
            'notification_recipients!inner(read_at, archived_at)',
          )
          .isFilter('notification_recipients.archived_at', null);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(_pageSize);

      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(_fromFlatMap)
          .toList();
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'notifications_repository');
      rethrow;
    }
  }

  /// Parses the flat-join result shape coming from the query above.
  static NotificationItem _fromFlatMap(Map<String, dynamic> map) {
    // notification_recipients comes back as a list with one element (inner join).
    final recipientList = map['notification_recipients'];
    final recipient = recipientList is List && recipientList.isNotEmpty
        ? recipientList.first as Map<String, dynamic>
        : const <String, dynamic>{};

    // notification_recipients has a composite PK (notification_id, user_id) and
    // no `id` column, so the recipient row is identified by notification_id for
    // the current user. Use it as the item id used to mark read.
    return NotificationItem(
      id: map['id'] as String? ?? '',
      notificationId: map['id'] as String? ?? '',
      kind: map['kind'] as String? ?? '',
      entityType: map['entity_type'] as String? ?? '',
      entityId: map['entity_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String?,
      payload: (map['payload'] as Map<String, dynamic>?) ?? const {},
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      readAt: recipient['read_at'] != null
          ? DateTime.tryParse(recipient['read_at'] as String)
          : null,
    );
  }

  /// Returns count of unread, non-archived notifications for the current user.
  Future<int> fetchUnreadCount() async {
    try {
      final response = await _client
          .from('notification_recipients')
          .select('notification_id')
          .isFilter('read_at', null)
          .isFilter('archived_at', null);
      return (response as List<dynamic>).length;
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'notifications_repository');
      return 0;
    }
  }

  /// Marks a single notification_recipient row as read (sets read_at = now()).
  /// The row is identified by notification_id for the current user (composite
  /// PK notification_id + user_id); RLS scopes the update to the caller.
  Future<void> markRead(String notificationId) async {
    try {
      await _client
          .from('notification_recipients')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('notification_id', notificationId);
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'notifications_repository');
    }
  }

  /// Marks all unread notifications for the current user as read.
  Future<void> markAllRead() async {
    try {
      await _client
          .from('notification_recipients')
          .update({'read_at': DateTime.now().toIso8601String()})
          .isFilter('read_at', null)
          .isFilter('archived_at', null);
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'notifications_repository');
    }
  }
}
