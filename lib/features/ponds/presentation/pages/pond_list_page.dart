import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';

/// Ponds Overview & Management Page (Tab 1).
class PondListPage extends ConsumerWidget {
  const PondListPage({super.key});

  void _loadDemoPonds(WidgetRef ref) {
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final ponds = ref.watch(pondListProvider);
    final waterLogs = ref.watch(waterLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTelugu ? 'చెరువుల నిర్వహణ' : 'Pond Management',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic, color: AppColors.primary),
            tooltip: isTelugu ? 'వాయిస్ లాగ్' : 'Voice Quick Log',
            onPressed: () => context.push('/quick-log'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: Text(
          isTelugu ? 'కొత్త చెరువు' : 'Add Pond',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        onPressed: () => context.push('/add-pond'),
      ),
      body: ponds.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(Icons.water, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isTelugu ? 'చెరువులేవీ లేవు' : 'No Ponds Found',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTelugu
                          ? 'మీ ఆక్వాకల్చర్ చెరువులను నమోదు చేసి నీటి నాణ్యతను ట్రాక్ చేయండి.'
                          : 'Register your shrimp culture ponds to track telemetry and feed schedules.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => context.push('/add-pond'),
                          icon: const Icon(Icons.add),
                          label: Text(
                            isTelugu ? 'చెరువును జోడించండి' : 'Add Pond',
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(color: AppColors.secondary),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _loadDemoPonds(ref),
                          icon: const Icon(Icons.science_outlined),
                          label: Text(
                            'Load Demo Data',
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ponds.length,
              itemBuilder: (context, index) {
                final pond = ponds[index];
                final pondId = pond['id']?.toString() ?? '${index + 1}';
                final pondName = pond['name']?.toString() ?? 'Pond $pondId';
                final doc = pond['doc'] ?? 45;
                final area = pond['areaHa'] ?? 1.0;
                final density = pond['stockingDensity'] ?? 45;

                // Find latest telemetry log for this pond
                final pondLogs = waterLogs.where((l) => l['pond_id']?.toString() == pondId).toList();
                final latestLog = pondLogs.isNotEmpty ? pondLogs.first : null;

                String status = 'Optimal';
                Color statusColor = AppColors.secondary;

                if (latestLog != null) {
                  final doVal = (latestLog['dissolved_oxygen'] as num?)?.toDouble() ?? 5.0;
                  final phVal = (latestLog['ph'] as num?)?.toDouble() ?? 7.8;
                  final nh3Val = (latestLog['ammonia'] as num?)?.toDouble() ?? 0.02;

                  if (doVal < 3.5 || phVal < 7.0 || phVal > 9.0 || nh3Val > 0.1) {
                    status = 'Urgent';
                    statusColor = AppColors.alertUrgent;
                  } else if (doVal < 4.0 || phVal < 7.5 || phVal > 8.5 || nh3Val > 0.05) {
                    status = 'Watch';
                    statusColor = AppColors.alertWatch;
                  }
                }

                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/pond/$pondId'),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.water_drop, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    pondName,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _PondMetricItem(label: 'DOC', value: 'Day $doc'),
                              _PondMetricItem(label: 'Area', value: '$area Ha'),
                              _PondMetricItem(label: 'Density', value: '$density PL/m²'),
                              _PondMetricItem(label: 'Species', value: pond['species'] ?? 'Vannamei'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                latestLog != null
                                    ? 'DO: ${latestLog['dissolved_oxygen']} mg/L • pH: ${latestLog['ph']} • Salinity: ${latestLog['salinity']} ppt'
                                    : 'No telemetry logged yet • Tap to log water',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textTertiary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PondMetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _PondMetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
