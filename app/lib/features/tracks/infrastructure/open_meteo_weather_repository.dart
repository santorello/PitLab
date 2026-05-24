import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/models/track_weather_day.dart';
import '../../../shared/repositories/track_weather_repository.dart';

class OpenMeteoWeatherRepository implements TrackWeatherRepository {
  OpenMeteoWeatherRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<TrackWeatherDay>> fetchForecast({
    required double latitude,
    required double longitude,
    int days = 3,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'daily':
            'weather_code,temperature_2m_max,precipitation_probability_max',
        'forecast_days': days.toString(),
        'timezone': 'auto',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Open-Meteo request failed (${response.statusCode})',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = body['daily'] as Map<String, dynamic>?;
    if (daily == null) {
      return const [];
    }

    final dates = (daily['time'] as List<dynamic>? ?? const [])
        .map((value) => DateTime.tryParse(value as String? ?? ''))
        .toList();
    final weatherCodes = (daily['weather_code'] as List<dynamic>? ?? const [])
        .map((value) => (value as num?)?.toInt())
        .toList();
    final temperatures =
        (daily['temperature_2m_max'] as List<dynamic>? ?? const [])
            .map((value) => (value as num?)?.toDouble())
            .toList();
    final precipitation =
        (daily['precipitation_probability_max'] as List<dynamic>? ?? const [])
            .map((value) => (value as num?)?.toInt())
            .toList();

    final length = [
      dates.length,
      weatherCodes.length,
      temperatures.length,
      precipitation.length,
    ].reduce((value, element) => value < element ? value : element);

    return List.generate(length, (index) {
      final date = dates[index];
      if (date == null) {
        throw Exception('Open-Meteo returned an invalid date');
      }

      return TrackWeatherDay(
        date: date,
        weatherCode: weatherCodes[index] ?? -1,
        temperatureMaxC: temperatures[index],
        precipitationProbabilityMax: precipitation[index],
      );
    });
  }
}
