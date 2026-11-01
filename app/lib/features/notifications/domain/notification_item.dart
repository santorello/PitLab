import 'package:pitlap_app/app/l10n/tr.dart';
/// Domain model for a notification as seen by the current user.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.notificationId,
    required this.kind,
    required this.entityType,
    required this.entityId,
    required String title,
    String? body,
    required this.payload,
    required this.createdAt,
    this.readAt,
  })  : _title = title,
        _body = body;

  /// notification_id (UUID) — identifies the recipient row for the current
  /// user (notification_recipients has a composite PK, no own id); used to mark read.
  final String id;

  /// notifications.id (UUID)
  final String notificationId;

  /// notifications.kind (e.g. 'new_follower', 'followed_activity')
  final String kind;

  /// notifications.entity_type
  final String entityType;

  /// notifications.entity_id (UUID string)
  final String entityId;

  // Testi scritti in italiano dai trigger: tradotti alla lettura.
  final String _title;
  final String? _body;
  String get title => trDb(_title);
  String? get body => _body == null ? null : trDb(_body);

  /// notifications.payload (raw JSON map)
  final Map<String, dynamic> payload;

  final DateTime createdAt;

  /// null = unread
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  NotificationItem copyWith({DateTime? readAt}) {
    return NotificationItem(
      id: id,
      notificationId: notificationId,
      kind: kind,
      entityType: entityType,
      entityId: entityId,
      title: _title,
      body: _body,
      payload: payload,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
