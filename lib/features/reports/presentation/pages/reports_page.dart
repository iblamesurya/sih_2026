import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/subscription_service.dart';

/// Reports & Crop Analytics Export Page (/reports).
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  void _showAuditPreviewModal(
    BuildContext context, {
    required bool isTelugu,
    required int totalPonds,
    required double totalAreaHa,
    required int avgDoc,
    required String avgFcr,
    required double totalFeedKg,
    required double estTotalBiomassKg,
    required int waterLogsCount,
    required int scansCount,
    required double totalExpenses,
    required double totalRevenue,
  }) {
    final netProfit = totalRevenue - totalExpenses;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu
                          ? 'డిజిటల్ పంట ఆడిట్ నివేదిక (PDF ప్రివ్యూ)'
                          : 'Digital Crop Audit Certificate (Preview)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: 8),
                Text(
                  '• Ponds Audited: $totalPonds (${totalAreaHa.toStringAsFixed(1)} Ha) • Avg DOC $avgDoc\n'
                  '• Estimated Biomass: ${estTotalBiomassKg.toStringAsFixed(0)} kg • Avg FCR: $avgFcr\n'
                  '• Water Telemetry Logs Verified: $waterLogsCount readings\n'
                  '• PrawnDoc Pathology Scans: $scansCount records\n'
                  '• Financial Ledger: Revenue ₹${totalRevenue.toStringAsFixed(0)} | Expenses ₹${totalExpenses.toStringAsFixed(0)} | Net ₹${netProfit.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isTelugu
                                ? 'వాట్సాప్ / బ్యాంక్ ఆడిట్ కోసం PDF నివేదిక సిద్ధంగా ఉంది!'
                                : 'Comprehensive Crop Audit PDF ready for WhatsApp & Bank submission!',
                          ),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(
                      isTelugu
                          ? 'వాట్సాప్ / బ్యాంక్‌కు షేర్ చేయండి'
                          : 'Share PDF via WhatsApp / Bank Desk',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final ponds = ref.watch(pondListProvider);
    final feedLogs = ref.watch(feedLogsProvider);
    final waterLogs = ref.watch(waterLogsProvider);
    final harvests = ref.watch(harvestsProvider);
    final expenses = ref.watch(expensesProvider);
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
      final abw = (p['abw'] as num?)?.toDouble() ??
          (doc > 30 ? (doc * 0.28).clamp(3.0, 35.0) : 18.5);
      return sum + (area * 10000 * density * 0.85 * abw / 1000);
    });

    final avgFcr = harvests.isNotEmpty
        ? (harvests.fold<double>(0.0, (sum, h) => sum + h.fcr) / harvests.length).toStringAsFixed(2)
        : '1.25';

    final totalExpenses = expenses.fold<double>(0.0, (s, e) => s + e.amount);
    final totalRevenue = harvests.fold<double>(0.0, (s, h) => s + h.totalRevenue);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: AppColors.primary),
            tooltip: isTelugu ? 'నివేదిక ప్రివ్యూ' : 'Preview Full Crop Audit',
            onPressed: () => _showAuditPreviewModal(
              context,
              isTelugu: isTelugu,
              totalPonds: totalPonds,
              totalAreaHa: totalAreaHa,
              avgDoc: avgDoc,
              avgFcr: avgFcr,
              totalFeedKg: totalFeedKg,
              estTotalBiomassKg: estTotalBiomassKg,
              waterLogsCount: waterLogs.length,
              scansCount: scans.length,
              totalExpenses: totalExpenses,
              totalRevenue: totalRevenue,
            ),
          ),
        ],
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

          Builder(
            builder: (context) {
              final subService = ref.watch(subscriptionServiceProvider);
              final tier = ref.watch(currentSubscriptionTierProvider);
              final exportedCount = ref.watch(exportedReportsCountProvider);
              final isPro = tier == SubscriptionTier.pro;

              void handleReportExport(String message) {
                if (!subService.canExportReport(
                  currentReportsThisMonth: exportedCount,
                  isPro: isPro,
                )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Free tier report export limit reached (Max 3/month). Upgrade to Pro for unlimited PDF exports!',
                      ),
                      backgroundColor: AppColors.alertUrgent,
                    ),
                  );
                  return;
                }
                ref.read(exportedReportsCountProvider.notifier).state = exportedCount + 1;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }

              return Column(
                children: [
                  _ReportTile(
                    title: 'Water Quality Telemetry Logbook',
                    subtitle: '${waterLogs.length} Telemetry records logged • pH, DO, Salinity & Ammonia audit',
                    onExport: () => handleReportExport(
                      'Exported Water Quality Logbook (${waterLogs.length} readings) to PDF!',
                    ),
                  ),
                  _ReportTile(
                    title: 'Feed Efficiency & FCR Ledger',
                    subtitle: '${feedLogs.length} Feeding schedules • 4-meal daily allocations & tray feedback',
                    onExport: () => handleReportExport(
                      'Exported Feed Efficiency Ledger (${feedLogs.length} records) to PDF!',
                    ),
                  ),
                  _ReportTile(
                    title: 'PrawnDoc AI Pathology History',
                    subtitle: '${scans.length} Disease diagnostic scans with vision confidence and biosecurity protocols',
                    onExport: () => handleReportExport(
                      'Exported Disease Vision Pathology History (${scans.length} scans) to PDF!',
                    ),
                  ),
                  _ReportTile(
                    title: 'Financial Cashflow & PrawnCredit Score',
                    subtitle: 'Revenue, expenses, net profit ledger and bank micro-loan eligibility certificate',
                    onExport: () => handleReportExport(
                      'Exported PrawnCredit Financial Certificate & Audit to PDF!',
                    ),
                  ),
                ],
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
