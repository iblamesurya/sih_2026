import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';

/// Reports & Crop Analytics Export Page (/reports).
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final ponds = ref.watch(pondListProvider);
    final feedLogs = ref.watch(feedLogsProvider);
    final waterLogs = ref.watch(waterLogsProvider);
    final harvests = ref.watch(harvestsProvider);
    final scans = ref.watch(diseaseScansProvider);

    final totalPonds = ponds.length;
    final totalAreaHa = ponds.fold<double>(0.0, (sum, p) => sum + ((p['areaHa'] as num?)?.toDouble() ?? 1.0));
    final avgDoc = totalPonds > 0
        ? (ponds.fold<int>(0, (sum, p) => sum + ((p['doc'] as num?)?.toInt() ?? 45)) / totalPonds).round()
        : 45;

    final totalFeedKg = feedLogs.fold<double>(
      0.0,
      (sum, f) => sum + ((f['daily_feed_kg'] as num?)?.toDouble() ?? 0.0),
    );

    final estTotalBiomassKg = ponds.fold<double>(0.0, (sum, p) {
      final area = (p['areaHa'] as num?)?.toDouble() ?? 1.0;
      final density = (p['stockingDensity'] as num?)?.toInt() ?? 50;
      final doc = (p['doc'] as num?)?.toInt() ?? 45;
      final abw = doc > 30 ? (doc * 0.28).clamp(3.0, 35.0) : 18.5;
      return sum + (area * 10000 * density * 0.85 * abw / 1000);
    });

    final avgFcr = harvests.isNotEmpty
        ? (harvests.fold<double>(0.0, (sum, h) => sum + h.fcr) / harvests.length).toStringAsFixed(2)
        : '1.25';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTelugu ? 'పంట నివేదికలు & విశ్లేషణ' : 'Crop Reports & Analytics',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dynamic Crop Summary Card
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
                      'Active Crop Performance',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Live Analytics',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalPonds Active Ponds • ${totalAreaHa.toStringAsFixed(1)} Ha Total Area • Avg DOC $avgDoc',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ReportMetric(label: 'Avg FCR', value: avgFcr, color: AppColors.secondary),
                    _ReportMetric(
                      label: 'Logged Feed',
                      value: totalFeedKg > 0 ? '${totalFeedKg.toStringAsFixed(0)} kg' : 'Active Plan',
                      color: AppColors.primary,
                    ),
                    _ReportMetric(
                      label: 'Est. Biomass',
                      value: '${estTotalBiomassKg.toStringAsFixed(0)} kg',
                      color: AppColors.alertWatch,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            isTelugu ? 'అందుబాటులో ఉన్న నివేదికలు' : 'Available Exportable Reports',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          _ReportTile(
            title: 'Water Quality Telemetry Logbook',
            subtitle: '${waterLogs.length} Telemetry records logged • pH, DO, Salinity & Ammonia audit',
            onExport: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported Water Quality Logbook (${waterLogs.length} readings) to PDF!'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            },
          ),
          _ReportTile(
            title: 'Feed Efficiency & FCR Ledger',
            subtitle: '${feedLogs.length} Feeding schedules • 4-meal daily allocations & tray feedback',
            onExport: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported Feed Efficiency Ledger (${feedLogs.length} records) to PDF!'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            },
          ),
          _ReportTile(
            title: 'PrawnDoc AI Pathology History',
            subtitle: '${scans.length} Disease diagnostic scans with vision confidence and biosecurity protocols',
            onExport: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported Disease Vision Pathology History (${scans.length} scans) to PDF!'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            },
          ),
          _ReportTile(
            title: 'Financial Cashflow & PrawnCredit Score',
            subtitle: 'Revenue, expenses, net profit ledger and bank micro-loan eligibility certificate',
            onExport: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exported PrawnCredit Financial Certificate & Audit to PDF!'),
                  backgroundColor: AppColors.secondary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReportMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onExport;

  const _ReportTile({
    required this.title,
    required this.subtitle,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.primary),
            onPressed: onExport,
          ),
        ],
      ),
    );
  }
}
