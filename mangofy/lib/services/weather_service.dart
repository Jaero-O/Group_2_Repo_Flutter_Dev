import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../model/weather_data.dart';
import 'local_db.dart';

class WeatherService {
  WeatherService._();

  static final WeatherService instance = WeatherService._();

  Future<WeatherData?> getWeather() async {
    final cached = await LocalDb.instance.getCachedWeather();
    if (cached != null && !cached.isExpired(ttlHours: 3)) {
      return cached;
    }

    try {
      final position = await _resolvePosition();
      final weather = await _fetchWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await LocalDb.instance.saveWeatherCache(weather);
      return weather;
    } catch (_) {
      return cached;
    }
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
  }

  Future<WeatherData> _fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,rain,wind_speed_10m,weather_code',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch weather data (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final current =
        (decoded['current'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    final weatherCode = _toInt(current['weather_code']);

    return WeatherData(
      latitude: latitude,
      longitude: longitude,
      fetchedAt: DateTime.now().toUtc(),
      temperatureCelsius: _toDouble(current['temperature_2m']),
      humidityPct: _toDouble(current['relative_humidity_2m']),
      rainfallMm: _toDouble(current['rain']),
      windSpeedKmh: _toDouble(current['wind_speed_10m']),
      condition: _conditionFromCode(weatherCode),
      rawJson: response.body,
    );
  }

  double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _conditionFromCode(int weatherCode) {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode == 1 || weatherCode == 2 || weatherCode == 3) {
      return 'Cloudy';
    }
    if (weatherCode >= 51 && weatherCode <= 67) return 'Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 99) return 'Storm';
    return 'Unknown';
  }
}
