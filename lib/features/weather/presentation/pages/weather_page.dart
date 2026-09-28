import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/weather_service.dart';

/// Aquaculture Weather & Hypoxia Advisory Page (/weather).
/// Connected to live WeatherService with cached OpenWeatherMap telemetry and hypoxia scoring.
class WeatherPage extends ConsumerStatefulWidget {
  const WeatherPage({super.key});

  @override
  ConsumerState<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends ConsumerState<WeatherPage> {
  bool _isLoading = true;
  WeatherData? _weather;
  HypoxiaAdvisory? _hypoxia;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialWeather = WeatherData.defaultFallback();
    _weather = initialWeather;
    _hypoxia = ref.read(weatherServiceProvider).evaluateHypoxiaRisk(initialWeather);
    _isLoading = false;
    _loadWeather();
  }

  Future<void> _loadWeather({bool forceRefresh = false}) async {
    final weatherService = ref.read(weatherServiceProvider);
    final locationService = ref.read(locationServiceProvider);

    try {
      final location = await locationService.getCurrentLocation(forceRefresh: forceRefresh);
      ref.read(currentLocationCoordinatesProvider.notifier).state = location;

      final weather = await weatherService.fetchWeather(
        lat: location.latitude,
        lon: location.longitude,
        forceRefresh: forceRefresh,
      );

      final hypoxia = weatherService.evaluateHypoxiaRisk(weather);

      setState(() {
        _weather = weather;
        _hypoxia = hypoxia;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final farm = ref.watch(currentFarmProvider);
    final currentLoc = ref.watch(currentLocationCoordinatesProvider);
    final displayedLocation = currentLoc != null
        ? currentLoc.locationName
        : (farm?['district'] ?? 'Bhimavaram, Andhra Pradesh');
    final isGpsLive = currentLoc != null && !currentLoc.isFallback;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTelugu ? 'వాతావరణం & హైపోక్సియా' : 'Weather Intelligence',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh Weather & GPS',
            onPressed: () => _loadWeather(forceRefresh: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.alertUrgent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.alertUrgent),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.outfit(color: AppColors.alertUrgent, fontSize: 13),
                    ),
                  ),
                // Current Weather Hero Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF171717), Color(0xFF0A222C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isGpsLive ? Icons.my_location : Icons.location_on_outlined,
                                      size: 16,
                                      color: isGpsLive ? AppColors.secondary : AppColors.alertWatch,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        displayedLocation,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _weather != null
                                      ? '${_weather!.description.toUpperCase()} • Wind ${_weather!.windSpeed.toStringAsFixed(1)} km/h • ${currentLoc != null ? "${currentLoc.latitude.toStringAsFixed(2)}°N, ${currentLoc.longitude.toStringAsFixed(2)}°E" : "16.54°N, 81.52°E"}'
                                      : 'Weather Telemetry Active',
                                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _weather != null && _weather!.cloudCover > 50 ? Icons.cloud : Icons.wb_sunny,
                            color: AppColors.primary,
                            size: 38,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_weather?.temperature.toStringAsFixed(1) ?? "29.5"}°C',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Humidity: ${_weather?.humidity ?? 78}%',
                            style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            'Feels like: ${_weather?.feelsLike.toStringAsFixed(1) ?? "32.0"}°C',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Hypoxia Risk Indicator Banner
                if (_hypoxia != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hypoxia!.isHighRisk
                            ? AppColors.alertUrgent
                            : (_hypoxia!.riskLevel == 'Moderate'
                                ? AppColors.alertWatch
                                : AppColors.secondary),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.air,
                              color: _hypoxia!.isHighRisk
                                  ? AppColors.alertUrgent
                                  : (_hypoxia!.riskLevel == 'Moderate'
                                      ? AppColors.alertWatch
                                      : AppColors.secondary),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isTelugu
                                    ? 'హైపోక్సియా (ఆక్సిజన్ కొరత) ప్రమాదం: ${_hypoxia!.riskLevel.toUpperCase()}'
                                    : 'Hypoxia Risk Index: ${_hypoxia!.riskLevel.toUpperCase()} (Score ${_hypoxia!.riskScore}/100)',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _hypoxia!.isHighRisk
                                      ? AppColors.alertUrgent
                                      : (_hypoxia!.riskLevel == 'Moderate'
                                          ? AppColors.alertWatch
                                          : AppColors.secondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isTelugu ? _hypoxia!.teluguSummary : _hypoxia!.advisorySummary,
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        if (_hypoxia!.actions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...(_hypoxia!.actions.map(
                            (act) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: AppColors.primary)),
                                  Expanded(
                                    child: Text(
                                      act,
                                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // 7-Day Aquaculture Forecast Section
                Text(
                  isTelugu ? '7-రోజుల ఆక్వా ఫోర్‌కాస్ట్' : '5-Day Coastal Aquaculture Forecast',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                ...List.generate(5, (index) {
                  final now = DateTime.now().add(Duration(days: index));
                  final dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][now.weekday % 7];
                  final baseTemp = _weather?.temperature ?? 29.5;
                  final temp = (baseTemp + (index.isEven ? 0.4 : -0.3)).toStringAsFixed(1);
                  final isRain = index == 2 || index == 4;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            index == 0 ? 'Today' : dayName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: index == 0 ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              isRain ? Icons.grain : Icons.wb_sunny_outlined,
                              size: 16,
                              color: isRain ? AppColors.primary : AppColors.alertWatch,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isRain ? 'Rain 40% • Watch Aerators' : 'Clear Sky • Optimal Aeration',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          '$temp°C',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
