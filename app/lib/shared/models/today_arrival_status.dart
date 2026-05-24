class TodayArrivalStatus {
  const TodayArrivalStatus({
    required this.status,
    this.updatedAt,
  });

  final String status;
  final DateTime? updatedAt;
}
