import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';

/// Ponds Overview & Management Page (Tab 1).
class PondListPage extends ConsumerWidget {
  const PondListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final ponds = ref.watch(pondListProvider);

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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => context.push('/add-pond'),
                      icon: const Icon(Icons.add),
                      label: Text(
                        isTelugu ? 'మొదటి చెరువును జోడించండి' : 'Add First Pond',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                      ),
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
                final status = pond['status']?.toString() ?? 'Optimal';

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
                                  color: status == 'Urgent'
                                      ? AppColors.alertUrgent.withValues(alpha: 0.15)
                                      : (status == 'Watch'
                                          ? AppColors.alertWatch.withValues(alpha: 0.15)
                                          : AppColors.secondary.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: status == 'Urgent'
                                        ? AppColors.alertUrgent
                                        : (status == 'Watch' ? AppColors.alertWatch : AppColors.secondary),
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'Urgent'
                                        ? AppColors.alertUrgent
                                        : (status == 'Watch' ? AppColors.alertWatch : AppColors.secondary),
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
                                'DO: 4.8 mg/L • pH: 7.9 • Salinity: 18 ppt',
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
