import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/services/emergency_alarm_service.dart';

/// Main Home / Dashboard page of PrawnGuard.ai (Tab 0).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  WeatherData? _weather;
  HypoxiaAdvisory? _hypoxia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardWeather();
    });
  }

  Future<void> _loadDashboardWeather() async {
    try {
      final weatherService = ref.read(weatherServiceProvider);
      final locationService = ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();
      ref.read(currentLocationCoordinatesProvider.notifier).state = location;

      final weather = await weatherService.fetchWeather(
        lat: location.latitude,
        lon: location.longitude,
      );
      final hypoxia = weatherService.evaluateHypoxiaRisk(weather);
      if (mounted) {
        setState(() {
          _weather = weather;
          _hypoxia = hypoxia;
        });
      }
    } catch (_) {}
  }

  void _showEmergencyAlarmModal(EmergencyAlarm alarm, bool isTelugu) {
    final checklist = isTelugu ? alarm.teluguChecklist : alarm.checklist;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, color: AppColors.alertUrgent, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isTelugu ? alarm.teluguTitle : alarm.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertUrgent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...checklist.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final all = ref.read(activeEmergencyAlarmsProvider);
                    ref.read(activeEmergencyAlarmsProvider.notifier).state = all
                        .map((a) => a.id == alarm.id ? a.copyWith(acknowledged: true) : a)
                        .toList();
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.verified, size: 18),
                  label: Text(
                    isTelugu
                        ? 'ఏరేటర్లు ఆన్ చేయబడ్డాయి (Acknowledge)'
                        : 'Acknowledge — Aerators & Remediation Active',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final alerts = ref.watch(alertsProvider);
    final emergencyAlarms = ref
        .watch(activeEmergencyAlarmsProvider)
        .where((a) => !a.acknowledged)
        .toList();
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);
    final ponds = ref.watch(pondListProvider);
    final farm = ref.watch(currentFarmProvider);
    final feedPlan = ref.watch(activeFeedPlanProvider);
    final subscriptionTier = ref.watch(currentSubscriptionTierProvider);

    final currentLoc = ref.watch(currentLocationCoordinatesProvider);
    final farmName = farm?['farmName'] ?? (isTelugu ? 'నా ఆక్వాకల్చర్ ఫార్మ్' : 'My Aquaculture Farm');
    final farmLocation = currentLoc?.locationName ?? farm?['district'] ?? 'Coastal Andhra Pradesh';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.water_drop, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PrawnGuard.ai',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    farm != null ? '$farmName • $farmLocation' : farmLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Pill
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              ref.read(currentLocaleProvider.notifier).state =
                  isTelugu ? const Locale('en') : const Locale('te');
            },
            icon: const Icon(Icons.language, size: 14, color: AppColors.primary),
            label: Text(
              isTelugu ? 'తెలుగు' : 'EN',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Subscription Badge
          IconButton(
            icon: Icon(
              subscriptionTier == SubscriptionTier.pro
                  ? Icons.verified
                  : Icons.star_border,
              color: subscriptionTier == SubscriptionTier.pro
                  ? AppColors.primary
                  : AppColors.alertWatch,
            ),
            onPressed: () => context.push('/upgrade'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active Unacknowledged Life-Safety Emergency Alarm Banner
          if (emergencyAlarms.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.alertUrgent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.alertUrgent, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: AppColors.alertUrgent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTelugu
                              ? emergencyAlarms.first.teluguTitle
                              : emergencyAlarms.first.title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.alertUrgent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTelugu
                              ? 'అత్యవసర ఏరేటర్ ప్రోటోకాల్ చూడటానికి నొక్కండి'
                              : 'Tap to open emergency aerator & lime checklist',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _showEmergencyAlarmModal(emergencyAlarms.first, isTelugu),
                    child: Text(
                      isTelugu ? 'ప్రోటోకాల్' : 'Protocol',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertUrgent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Pending Offline Sync Status Strip
          if (pendingSyncCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isTelugu
                            ? '$pendingSyncCount ఆఫ్‌లైన్ రీడింగ్‌లు సింక్ కోసం సిద్ధంగా ఉన్నాయి'
                            : '$pendingSyncCount offline readings queued for cloud sync',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      final sync = ref.read(offlineSyncProvider);
                      await sync.drainQueue();
                      await ref
                          .read(dataHydrationServiceProvider)
                          .refreshPendingSyncCount(ref, offlineSync: sync);
                    },
                    child: Text(
                      isTelugu ? 'సింక్' : 'Sync Now',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Urgent Alert Notification Banner
          if (alerts.any((a) => a.isUrgent))
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.alertUrgent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.alertUrgent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.alertUrgent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTelugu ? 'అత్యవసర హెచ్చరిక' : 'Critical Water Alert',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.alertUrgent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTelugu
                              ? 'చెరువులో ఆక్సిజన్ లేదా pH ప్రమాదకర స్థాయికి పడిపోయింది.'
                              : 'One or more water parameters breached critical safety thresholds.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/quick-log'),
                    child: Text(
                      isTelugu ? 'చూడండి' : 'Review',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertUrgent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Live Weather & Hypoxia Advisory Card
          InkWell(
            onTap: () => context.push('/weather'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF171717), Color(0xFF0C2229)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cloud_queue, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              isTelugu ? 'వాతావరణ నివేదిక' : 'Aquaculture Weather & Hypoxia',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _weather != null
                              ? '${_weather!.temperature.toStringAsFixed(1)}°C • ${_weather!.humidity}% Humidity • ${_weather!.description}'
                              : '29.5°C • 76% Humidity • Live Telemetry Active',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hypoxia != null
                              ? (isTelugu
                                  ? 'హైపోక్సియా ప్రమాదం: ${_hypoxia!.riskLevel.toUpperCase()} • ${_hypoxia!.teluguActions.isNotEmpty ? _hypoxia!.teluguActions.first : _hypoxia!.teluguSummary}'
                                  : 'Hypoxia Risk: ${_hypoxia!.riskLevel.toUpperCase()} • ${_hypoxia!.actions.isNotEmpty ? _hypoxia!.actions.first : _hypoxia!.advisorySummary}')
                              : (isTelugu
                                  ? 'హైపోక్సియా ప్రమాదం: తక్కువ (ఏరేటర్లు సరిపోతాయి)'
                                  : 'Hypoxia Risk: Low • Standard aeration optimal'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _hypoxia?.isHighRisk == true
                                ? AppColors.alertUrgent
                                : AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions Grid
          Text(
            isTelugu ? 'త్వరిత చర్యలు' : 'Quick Actions',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _QuickActionCard(
                icon: Icons.mic,
                iconColor: AppColors.primary,
                title: isTelugu ? 'వాయిస్ లాగ్' : 'Telugu Voice Log',
                subtitle: isTelugu ? 'ఫోన్ మాట్లాడండి' : 'Hands-free input',
                onTap: () => context.push('/quick-log'),
              ),
              _QuickActionCard(
                icon: Icons.restaurant,
                iconColor: AppColors.secondary,
                title: isTelugu ? 'మేత లెక్క' : 'Feed AI Calculator',
                subtitle: isTelugu ? '4-సార్లు షెడ్యూల్' : 'Bio-energetic ratio',
                onTap: () => context.go('/feed'),
              ),
              _QuickActionCard(
                icon: Icons.biotech,
                iconColor: AppColors.alertWatch,
                title: isTelugu ? 'రొయ్య డాక్టర్' : 'PrawnDoc Vision',
                subtitle: isTelugu ? 'కెమెరా AI స్కాన్' : 'Camera Disease Scan',
                onTap: () => context.go('/prawndoc'),
              ),
              _QuickActionCard(
                icon: Icons.account_balance_wallet,
                iconColor: AppColors.alertInfo,
                title: isTelugu ? 'ఫైనాన్స్ & క్రెడిట్' : 'PrawnCredit',
                subtitle: isTelugu ? 'ఖర్చులు & అమ్మకాలు' : 'Cashflow ledger',
                onTap: () => context.push('/finance'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live AP Mandi Rates & AI Camera ABW Strip
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/market-prices'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTelugu ? 'మండి ధరలు (30c)' : 'AP Mandi (30c)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                isTelugu ? '₹390/kg • భీమవరం' : '₹390/kg • Bhimavaram',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/abw-sampling'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.straighten, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTelugu ? 'AI కెమెరా ABW' : 'Camera ABW Size',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                isTelugu ? 'ట్రే ఫోటో కౌంట్' : 'Tray count & CV%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Active Ponds Summary Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTelugu ? 'నా చెరువులు (${ponds.length})' : 'Active Ponds (${ponds.length})',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/ponds'),
                child: Text(
                  isTelugu ? 'అన్నీ చూడండి' : 'View All',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (ponds.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.water, size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: 10),
                  Text(
                    isTelugu ? 'చెరువులు ఇంకా జోడించబడలేదు' : 'No ponds registered yet',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTelugu
                        ? 'మీ మొదటి చెరువును నమోదు చేయడానికి ఇక్కడ నొక్కండి'
                        : 'Tap below to configure your first aquaculture pond',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => context.push('/add-pond'),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          isTelugu ? 'చెరువును జోడించండి' : 'Add Pond',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ref.read(pondListProvider.notifier).state = [
                            {
                              'id': '1',
                              'name': 'Pond 1 (North Field)',
                              'areaHa': 1.2,
                              'stockingDensity': 50,
                              'doc': 52,
                              'species': 'L. vannamei',
                              'initialAbw': 0.02,
                              'status': 'Optimal',
                              'created_at': DateTime.now().subtract(const Duration(days: 52)).toIso8601String(),
                            },
                            {
                              'id': '2',
                              'name': 'Pond 2 (South Field)',
                              'areaHa': 1.0,
                              'stockingDensity': 45,
                              'doc': 38,
                              'species': 'L. vannamei',
                              'initialAbw': 0.02,
                              'status': 'Optimal',
                              'created_at': DateTime.now().subtract(const Duration(days: 38)).toIso8601String(),
                            },
                          ];
                          ref.read(waterLogsProvider.notifier).state = [
                            {
                              'id': 'log_init_1',
                              'pond_id': '1',
                              'ph': 7.85,
                              'dissolved_oxygen': 4.8,
                              'salinity': 18.0,
                              'temperature': 28.5,
                              'ammonia': 0.04,
                              'feed_kg': 25.0,
                              'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
                            },
                            {
                              'id': 'log_init_2',
                              'pond_id': '2',
                              'ph': 7.95,
                              'dissolved_oxygen': 5.1,
                              'salinity': 17.5,
                              'temperature': 28.0,
                              'ammonia': 0.02,
                              'feed_kg': 22.0,
                              'timestamp': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
                            },
                          ];
                        },
                        icon: const Icon(Icons.science_outlined, size: 16),
                        label: Text(
                          'Load Demo Farm',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            ...ponds.take(3).map((pond) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/pond/${pond['id']}'),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pond['name']?.toString() ?? 'Pond ${pond['id']}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'DOC: ${pond['doc'] ?? 45} • Area: ${pond['areaHa'] ?? 1.0} Ha • ${pond['species'] ?? 'L. vannamei'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 20),

          // Daily 4-Meal Schedule Tracker Card (Connected to activeFeedPlanProvider)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu ? 'నేటి మేత షెడ్యూల్ (4 సార్లు)' : 'Today\'s 4-Meal Schedule',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/feed'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          feedPlan != null ? '${feedPlan.adjustedDailyFeedKg.toStringAsFixed(1)} kg Total' : 'Calculate Feed',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (feedPlan != null)
                  Builder(
                    builder: (context) {
                      final completedMeals = ref.watch(completedMealsProvider);
                      void toggleMeal(int mealNum) {
                        final next = Set<int>.from(completedMeals);
                        if (next.contains(mealNum)) {
                          next.remove(mealNum);
                        } else {
                          next.add(mealNum);
                        }
                        ref.read(completedMealsProvider.notifier).state = next;
                      }

                      return Row(
                        children: [
                          _MealPill(
                            time: '06:00 AM',
                            share: '${feedPlan.meal1Kg.toStringAsFixed(1)} kg (20%)',
                            isCompleted: completedMeals.contains(1),
                            onTap: () => toggleMeal(1),
                          ),
                          const SizedBox(width: 8),
                          _MealPill(
                            time: '11:00 AM',
                            share: '${feedPlan.meal2Kg.toStringAsFixed(1)} kg (30%)',
                            isCompleted: completedMeals.contains(2),
                            onTap: () => toggleMeal(2),
                          ),
                          const SizedBox(width: 8),
                          _MealPill(
                            time: '04:00 PM',
                            share: '${feedPlan.meal3Kg.toStringAsFixed(1)} kg (30%)',
                            isCompleted: completedMeals.contains(3),
                            onTap: () => toggleMeal(3),
                          ),
                          const SizedBox(width: 8),
                          _MealPill(
                            time: '09:00 PM',
                            share: '${feedPlan.meal4Kg.toStringAsFixed(1)} kg (20%)',
                            isCompleted: completedMeals.contains(4),
                            onTap: () => toggleMeal(4),
                          ),
                        ],
                      );
                    },
                  )
                else
                  const Row(
                    children: [
                      _MealPill(time: '06:00 AM', share: '20%', isCompleted: false),
                      SizedBox(width: 8),
                      _MealPill(time: '11:00 AM', share: '30%', isCompleted: false),
                      SizedBox(width: 8),
                      _MealPill(time: '04:00 PM', share: '30%', isCompleted: false),
                      SizedBox(width: 8),
                      _MealPill(time: '09:00 PM', share: '20%', isCompleted: false),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealPill extends StatelessWidget {
  final String time;
  final String share;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _MealPill({
    required this.time,
    required this.share,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.secondary.withValues(alpha: 0.15)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCompleted ? AppColors.secondary : AppColors.cardBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.schedule,
                size: 14,
                color: isCompleted ? AppColors.secondary : AppColors.textTertiary,
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                share,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: isCompleted ? AppColors.secondary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
