class TrackWeatherDay {
  const TrackWeatherDay({
    required this.date,
    required this.weatherCode,
    required this.temperatureMaxC,
    required this.precipitationProbabilityMax,
  });

  final DateTime date;
  final int weatherCode;
  final double? temperatureMaxC;
  final int? precipitationProbabilityMax;
}

class TrackWeatherRequest {
  const TrackWeatherRequest({
    required this.trackId,
    required this.latitude,
    required this.longitude,
  });

  final String trackId;
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) {
    return other is TrackWeatherRequest &&
        other.trackId == trackId &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(trackId, latitude, longitude);
}
