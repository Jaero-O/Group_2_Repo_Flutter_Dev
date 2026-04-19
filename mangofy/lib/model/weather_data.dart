class WeatherData {
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;
  final double temperatureCelsius;
  final double humidityPct;
  final double rainfallMm;
  final double windSpeedKmh;
  final String condition;
  final String rawJson;

  const WeatherData({
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
    required this.temperatureCelsius,
    required this.humidityPct,
    required this.rainfallMm,
    required this.windSpeedKmh,
    required this.condition,
    required this.rawJson,
  });

  bool isExpired({int ttlHours = 3}) {
    return DateTime.now().toUtc().difference(fetchedAt.toUtc()).inHours >=
        ttlHours;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'latitude': latitude,
      'longitude': longitude,
      'fetched_at': fetchedAt.toUtc().toIso8601String(),
      'temp_c': temperatureCelsius,
      'humidity_pct': humidityPct,
      'rainfall_mm': rainfallMm,
      'wind_speed': windSpeedKmh,
      'condition': condition,
      'raw_json': rawJson,
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    double parseDouble(Object? value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    final fetchedRaw = map['fetched_at']?.toString() ?? '';
    final parsed = DateTime.tryParse(fetchedRaw.replaceFirst(' ', 'T'));

    return WeatherData(
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      fetchedAt: parsed ?? DateTime.now().toUtc(),
      temperatureCelsius: parseDouble(map['temp_c']),
      humidityPct: parseDouble(map['humidity_pct']),
      rainfallMm: parseDouble(map['rainfall_mm']),
      windSpeedKmh: parseDouble(map['wind_speed']),
      condition: (map['condition']?.toString() ?? '').trim(),
      rawJson: map['raw_json']?.toString() ?? '{}',
    );
  }
}
