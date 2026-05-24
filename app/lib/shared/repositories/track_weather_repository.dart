import '../models/track_weather_day.dart';

abstract class TrackWeatherRepository {
  Future<List<TrackWeatherDay>> fetchForecast({
    required double latitude,
    required double longitude,
    int days = 3,
  });
}
