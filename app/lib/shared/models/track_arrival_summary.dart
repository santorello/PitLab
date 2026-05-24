class TrackArrivalSummary {
  const TrackArrivalSummary({
    required this.comingCount,
    required this.maybeCount,
    required this.cancelledCount,
  });

  final int comingCount;
  final int maybeCount;
  final int cancelledCount;

  int get activeCount => comingCount + maybeCount;

  bool get hasSignals =>
      comingCount > 0 || maybeCount > 0 || cancelledCount > 0;

  factory TrackArrivalSummary.empty() {
    return const TrackArrivalSummary(
      comingCount: 0,
      maybeCount: 0,
      cancelledCount: 0,
    );
  }

  factory TrackArrivalSummary.fromMap(Map<String, dynamic> map) {
    return TrackArrivalSummary(
      comingCount: (map['coming_count'] as num?)?.toInt() ?? 0,
      maybeCount: (map['maybe_count'] as num?)?.toInt() ?? 0,
      cancelledCount: (map['cancelled_count'] as num?)?.toInt() ?? 0,
    );
  }
}
