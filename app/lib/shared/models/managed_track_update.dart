class ManagedTrackUpdate {
  const ManagedTrackUpdate({
    required this.status,
    required this.message,
    required this.updatedAt,
    required this.updatedBy,
  });

  final String status;
  final String message;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory ManagedTrackUpdate.fromMap(Map<String, dynamic> map) {
    return ManagedTrackUpdate(
      status: map['status'] as String? ?? 'unknown',
      message: map['message'] as String? ?? '',
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'] as String),
      updatedBy: map['updated_by'] as String?,
    );
  }
}
