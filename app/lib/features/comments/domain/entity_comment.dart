// Modello commento polimorfico.
// Il join su profiles (embed Supabase) porta display_name e avatar_url
// dell'autore in un'unica query.

class CommentAuthor {
  const CommentAuthor({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;

  factory CommentAuthor.fromMap(Map<String, dynamic> map) {
    return CommentAuthor(
      id: map['id'] as String? ?? '',
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? (map['display_name'] as String).trim()
          : 'Pilota PitLap',
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}

class EntityComment {
  const EntityComment({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.authorId,
    required this.body,
    required this.isHidden,
    required this.reportedCount,
    required this.createdAt,
    required this.updatedAt,
    this.author,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String authorId;
  final String body;
  final bool isHidden;
  final int reportedCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CommentAuthor? author;

  factory EntityComment.fromMap(Map<String, dynamic> map) {
    CommentAuthor? author;
    final profileRaw = map['author'] ?? map['profiles'];
    if (profileRaw is Map<String, dynamic>) {
      final profileWithId = Map<String, dynamic>.from(profileRaw);
      // author_id is top-level; inject it so CommentAuthor.id is populated.
      profileWithId['id'] = map['author_id'] as String? ?? '';
      author = CommentAuthor.fromMap(profileWithId);
    }

    return EntityComment(
      id: map['id'] as String? ?? '',
      entityType: map['entity_type'] as String? ?? '',
      entityId: map['entity_id'] as String? ?? '',
      authorId: map['author_id'] as String? ?? '',
      body: map['body'] as String? ?? '',
      isHidden: map['is_hidden'] as bool? ?? false,
      reportedCount: (map['reported_count'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.tryParse(map['created_at'] as String) ?? DateTime.now(),
      updatedAt: map['updated_at'] == null
          ? DateTime.now()
          : DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now(),
      author: author,
    );
  }
}
