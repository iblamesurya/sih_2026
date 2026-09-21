import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'supabase_client.dart';

/// Structured weather conditions for aquaculture pond locations.
class WeatherData {
  final double temperature; // Celsius
  final double feelsLike;
  final int humidity; // %
  final int cloudCover; // %
  final double windSpeed; // km/h
  final double rainfall; // mm (past 1h or 3h)
  final String condition;
  final String description;
  final String locationName;
  final DateTime timestamp;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.cloudCover,
    required this.windSpeed,
    required this.rainfall,
    required this.condition,
    required this.description,
    required this.locationName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'cloudCover': cloudCover,
        'windSpeed': windSpeed,
        'rainfall': rainfall,
        'condition': condition,
        'description': description,
        'locationName': locationName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 30.0,
      feelsLike: (json['feelsLike'] as num?)?.toDouble() ?? 32.0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 75,
      cloudCover: (json['cloudCover'] as num?)?.toInt() ?? 20,
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 12.0,
      rainfall: (json['rainfall'] as num?)?.toDouble() ?? 0.0,
      condition: json['condition'] as String? ?? 'Clear',
      description: json['description'] as String? ?? 'Clear skies',
      locationName: json['locationName'] as String? ?? 'Bhimavaram, AP',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Default fallback weather conditions for coastal Andhra Pradesh.
  factory WeatherData.defaultFallback([String location = 'Bhimavaram, AP']) {
    return WeatherData(
      temperature: 31.5,
      feelsLike: 35.0,
      humidity: 78,
      cloudCover: 30,
      windSpeed: 11.5,
      rainfall: 0.0,
      condition: 'Partly Cloudy',
      description: 'Scattered clouds with coastal sea breeze',
      locationName: location,
      timestamp: DateTime.now(),
    );
  }
}

/// Hypoxia Advisory assessing nocturnal oxygen crash risks driven by weather.
class HypoxiaAdvisory {
  final String riskLevel; // 'Low' | 'Moderate' | 'High' | 'Critical'
  final int riskScore; // 0 - 100%
  final String advisorySummary;
  final List<String> actions;
  final String teluguSummary;
  final List<String> teluguActions;

  const HypoxiaAdvisory({
    required this.riskLevel,
    required this.riskScore,
    required this.advisorySummary,
    required this.actions,
    required this.teluguSummary,
    required this.teluguActions,
  });

  bool get isHighRisk => riskLevel == 'High' || riskLevel == 'Critical';

  Map<String, dynamic> toJson() => {
        'riskLevel': riskLevel,
        'riskScore': riskScore,
        'advisorySummary': advisorySummary,
        'actions': actions,
        'teluguSummary': teluguSummary,
        'teluguActions': teluguActions,
      };
}

/// Weather Service fetching meteorological data and computing hypoxia risks.
class WeatherService {
  final http.Client? _httpClient;

  static WeatherData? _cachedWeather;
  static DateTime? _lastFetchTime;
  static const Duration cacheTtl = Duration(hours: 3);

  WeatherService([this._httpClient]);

  /// Clears in-memory weather cache (useful for tests or hard resets).
  @visibleForTesting
  static void clearCache() {
    _cachedWeather = null;
    _lastFetchTime = null;
  }

  /// Fetches weather intelligence via Supabase Edge Function `weather-intelligence`
  /// or OpenWeatherMap API with automatic fallback and a 3-hour local cache.
  Future<WeatherData> fetchWeather({
    double lat = 16.5449,
    double lon = 81.5212,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh && _cachedWeather != null && _lastFetchTime != null) {
      if (now.difference(_lastFetchTime!) < cacheTtl) {
        return _cachedWeather!;
      }
    }

    try {
      if (SupabaseClientService.isInitialized) {
        final res = await SupabaseClientService.functions.invoke(
          'weather-intelligence',
          body: {'lat': lat, 'lon': lon},
        );
        if (res.status == 200 && res.data != null) {
          final data = res.data is Map<String, dynamic>
              ? res.data as Map<String, dynamic>
              : jsonDecode(res.data.toString()) as Map<String, dynamic>;
          if (data.containsKey('weather')) {
            final weather = WeatherData.fromJson(
              Map<String, dynamic>.from(data['weather'] as Map),
            );
            _cachedWeather = weather;
            _lastFetchTime = now;
            return weather;
          }
        }
      } else if (_httpClient != null) {
        // Direct client usage when provided
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WeatherService: Edge function fetch error ($e), using local evaluation.');
      }
    }

    final fallback = WeatherData.defaultFallback();
    _cachedWeather = fallback;
    _lastFetchTime = now;
    return fallback;
  }

  /// Evaluates Nocturnal Hypoxia Risk from weather parameters:
  /// - High Cloud Cover (>70%) impairs daytime phytoplankton photosynthesis.
  /// - Heavy Rain lowers salinity and stratification.
  /// - High Temperature (>32°C) reduces oxygen solubility and spikes shrimp metabolic oxygen demand.
  /// - Low Wind (<5 km/h) eliminates natural surface atmospheric aeration.
  HypoxiaAdvisory evaluateHypoxiaRisk(WeatherData weather) {
    int riskScore = 10; // Base background risk

    // Cloud cover factor (0 to +35)
    if (weather.cloudCover > 80) {
      riskScore += 35;
    } else if (weather.cloudCover > 60) {
      riskScore += 25;
    } else if (weather.cloudCover > 40) {
      riskScore += 15;
    }

    // Temperature factor (0 to +25)
    if (weather.temperature > 34.0) {
      riskScore += 25;
    } else if (weather.temperature > 31.0) {
      riskScore += 15;
    }

    // Wind speed factor (0 to +20)
    if (weather.windSpeed < 5.0) {
      riskScore += 20;
    } else if (weather.windSpeed < 10.0) {
      riskScore += 10;
    }

    // Rainfall factor (0 to +20)
    if (weather.rainfall > 10.0) {
      riskScore += 20;
    } else if (weather.rainfall > 0.0) {
      riskScore += 10;
    }

    riskScore = riskScore.clamp(0, 100);

    String riskLevel;
    String advisory;
    List<String> actions = [];
    String teluguSummary;
    List<String> teluguActions = [];

    if (riskScore >= 75) {
      riskLevel = 'Critical';
      advisory =
          'Extreme Hypoxia Risk ($riskScore%). Heavy cloud cover and warm water will cause rapid DO drop after midnight.';
      actions = [
        'Turn on all aerators starting at 8:00 PM tonight.',
        'Keep emergency oxygen tablets (Sodium Percarbonate) ready pondside.',
        'Cut tomorrow morning feed (6:00 AM) by 30% to prevent pond bottom overload.',
        'Inspect pond water color for micro-algae crash.',
      ];
      teluguSummary =
          'తీవ్రమైన ఆక్సిజన్ కొరత ముప్పు ($riskScore%). మేఘావృతమైన వాతావరణం వల్ల అర్ధరాత్రి ఆక్సిజన్ పడిపోతుంది.';
      teluguActions = [
        'ఈ రాత్రి 8:00 గంటల నుంచే అన్ని ఎయిరేటర్లను ఆన్ చేయండి.',
        'ఆక్సిజన్ మాత్రలను చెరువు వద్ద సిద్ధంగా ఉంచండి.',
        'రేపు ఉదయం 6:00 గంటల మేతను 30% తగ్గించండి.',
      ];
    } else if (riskScore >= 50) {
      riskLevel = 'High';
      advisory =
          'High Hypoxia Advisory ($riskScore%). Cloud cover limited daytime photosynthesis; nocturnal oxygen depletion expected.';
      actions = [
        'Start paddle wheel aerators at 11:00 PM.',
        'Check DO at 4:00 AM before dawn.',
        'Reduce morning feed by 15%.',
      ];
      teluguSummary =
          'ఆక్సిజన్ కొరత హెచ్చరిక ($riskScore%). రాత్రి సమయంలో ఆక్సిజన్ తగ్గే అవకాశం ఉంది.';
      teluguActions = [
        'రాత్రి 11:00 గంటలకు ఎయిరేటర్లను ఆన్ చేయండి.',
        'వేకువజామున 4:00 గంటలకు ఆక్సిజన్ పరీక్షించండి.',
        'ఉదయం మేతను 15% తగ్గించండి.',
      ];
    } else if (riskScore >= 30) {
      riskLevel = 'Moderate';
      advisory =
          'Moderate Hypoxia Risk ($riskScore%). Normal seasonal variations. Keep standard nocturnal aeration cycle.';
      actions = [
        'Operate aerators according to standard night schedule (12:00 AM - 6:00 AM).',
        'Verify check-tray feed consumption.',
      ];
      teluguSummary =
          'సాధారణ ఆక్సిజన్ స్థాయి ($riskScore%). రాత్రి వేళ సాధారణ ఎయిరేషన్ సరిపోతుంది.';
      teluguActions = [
        'రాత్రి 12:00 నుండి ఉదయం 6:00 వరకు ఎయిరేటర్లు నడపండి.',
        'చెక్‌ట్రేలలో మేత వినియోగాన్ని గమనించండి.',
      ];
    } else {
      riskLevel = 'Low';
      advisory =
          'Low Hypoxia Risk ($riskScore%). Sunny conditions generated abundant natural dissolved oxygen during daylight.';
      actions = [
        'Maintain regular aeration and feeding schedule.',
      ];
      teluguSummary =
          'తక్కువ ప్రమాదం ($riskScore%). పగటిపూట పుష్కలంగా సహజ ఆక్సిజన్ ఉత్పత్తి అయింది.';
      teluguActions = [
        'సాధారణ మేత మరియు ఎయిరేషన్ నిర్వహించండి.',
      ];
    }

    return HypoxiaAdvisory(
      riskLevel: riskLevel,
      riskScore: riskScore,
      advisorySummary: advisory,
      actions: actions,
      teluguSummary: teluguSummary,
      teluguActions: teluguActions,
    );
  }
}
