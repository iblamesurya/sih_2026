import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';

/// Comprehensive Pond Detail Page showing gauges, charts, and actions.
class PondDetailPage extends ConsumerWidget {
  final String pondId;

  const PondDetailPage({super.key, required this.pondId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final ponds = ref.watch(pondListProvider);
    
    final pond = ponds.firstWhere(
      (p) => p['id']?.toString() == pondId,
      orElse: () => {
        'id': pondId,
        'name': 'Pond $pondId',
        'doc': 52,
        'areaHa': 1.2,
        'stockingDensity': 50,
        'species': 'L. vannamei',
        'status': 'Optimal',
      },
    );

    final pondName = pond['name']?.toString() ?? 'Pond $pondId';
    final doc = pond['doc'] ?? 52;
    final area = pond['areaHa'] ?? 1.2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          pondName,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with DOC & Crop Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF171717), Color(0xFF0F1E24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTelugu ? 'పెంపకం రోజులు (DOC)' : 'Days of Culture (DOC)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Day $doc / 120',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: Text(
                        'Growth Phase',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (doc / 120).clamp(0.0, 1.0),
                  backgroundColor: AppColors.surfaceElevated,
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PondSubInfo(label: 'Area', value: '$area Ha'),
                    _PondSubInfo(label: 'Stocking Density', value: '${pond['stockingDensity']} PL/m²'),
                    _PondSubInfo(label: 'Est. Biomass', value: '3,840 kg'),
                    _PondSubInfo(label: 'Target ABW', value: '18.5 g'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Water Parameter Gauges Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTelugu ? 'నీటి నాణ్యత పారామితులు' : 'Water Telemetry',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/quick-log'),
                icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                label: Text(
                  isTelugu ? 'లాగ్ చేయండి' : 'Log Water',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: const [
              _TelemetryGaugeCard(
                parameter: 'Dissolved Oxygen',
                value: '4.8',
                unit: 'mg/L',
                status: 'Optimal',
                statusColor: AppColors.secondary,
                optimalRange: '> 4.0 mg/L',
              ),
              _TelemetryGaugeCard(
                parameter: 'pH Level',
                value: '7.85',
                unit: 'pH',
                status: 'Optimal',
                statusColor: AppColors.secondary,
                optimalRange: '7.5 - 8.5',
              ),
              _TelemetryGaugeCard(
                parameter: 'Salinity',
                value: '18.0',
                unit: 'ppt',
                status: 'Optimal',
                statusColor: AppColors.secondary,
                optimalRange: '10 - 25 ppt',
              ),
              _TelemetryGaugeCard(
                parameter: 'Total Ammonia',
                value: '0.04',
                unit: 'mg/L',
                status: 'Optimal',
                statusColor: AppColors.secondary,
                optimalRange: '< 0.1 mg/L',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Action Hub for this pond
          Text(
            isTelugu ? 'చెరువు చర్యలు' : 'Pond Actions',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  onPressed: () => context.go('/feed'),
                  icon: const Icon(Icons.restaurant, size: 18),
                  label: Text(
                    isTelugu ? 'మేత లెక్క' : 'Feed AI',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.alertWatch,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  onPressed: () => context.go('/prawndoc'),
                  icon: const Icon(Icons.biotech, size: 18),
                  label: Text(
                    isTelugu ? 'స్కాన్' : 'PrawnDoc',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Water Log History
          Text(
            isTelugu ? 'ఇటీవలి లాగ్‌లు' : 'Recent Telemetry History',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _LogItem(time: 'Today 06:30 AM', doLevel: '4.8', ph: '7.8', temp: '27.5°C'),
                const Divider(height: 16),
                _LogItem(time: 'Yesterday 04:30 PM', doLevel: '5.2', ph: '8.1', temp: '29.0°C'),
                const Divider(height: 16),
                _LogItem(time: 'Yesterday 06:00 AM', doLevel: '4.4', ph: '7.7', temp: '26.8°C'),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _PondSubInfo extends StatelessWidget {
  final String label;
  final String value;

  const _PondSubInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TelemetryGaugeCard extends StatelessWidget {
  final String parameter;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final String optimalRange;

  const _TelemetryGaugeCard({
    required this.parameter,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.optimalRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  parameter,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          Text(
            'Target: $optimalRange',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final String time;
  final String doLevel;
  final String ph;
  final String temp;

  const _LogItem({
    required this.time,
    required this.doLevel,
    required this.ph,
    required this.temp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          time,
          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          'DO: $doLevel • pH: $ph • $temp',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
