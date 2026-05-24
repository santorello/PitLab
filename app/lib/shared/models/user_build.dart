class UserBuild {
  const UserBuild({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.meta,
    required this.specs,
    required this.imageUrls,
    required this.isPublic,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String meta;
  final List<String> specs;

  /// Solo URL http/https o storage path. I data-URL base64 vengono
  /// tenuti solo in memoria durante l'editing ma non persistiti su DB.
  final List<String> imageUrls;

  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get primaryImageUrl => imageUrls.isEmpty ? '' : imageUrls.first;

  UserBuild copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? meta,
    List<String>? specs,
    List<String>? imageUrls,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserBuild(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      meta: meta ?? this.meta,
      specs: specs ?? this.specs,
      imageUrls: imageUrls ?? this.imageUrls,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserBuild.fromMap(Map<String, dynamic> map) {
    return UserBuild(
      id: map['id'] as String? ?? '',
      ownerId: map['owner_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      meta: map['meta'] as String? ?? '',
      specs: (map['specs'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      imageUrls: (map['image_urls'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList(),
      isPublic: map['is_public'] as bool? ?? false,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap({required String ownerId}) {
    return {
      'owner_id': ownerId,
      'title': title,
      'meta': meta,
      'specs': specs,
      'image_urls': imageUrls,
      'is_public': isPublic,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'meta': meta,
      'specs': specs,
      'image_urls': imageUrls,
      'is_public': isPublic,
    };
  }
}
