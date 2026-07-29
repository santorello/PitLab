/// Domain model for a notification as seen by the current user.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.notificationId,
    required this.kind,
    required this.entityType,
    required this.entityId,
    required this.title,
    this.body,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

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

  final String title;
  final String? body;

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
      title: title,
      body: body,
      payload: payload,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
