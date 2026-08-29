import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/finance_models.dart';

class HarvestCard extends StatelessWidget {
  final HarvestRecord harvest;
  final VoidCallback? onShareWhatsApp;
  final VoidCallback? onExportInvoice;

  const HarvestCard({
    super.key,
    required this.harvest,
    this.onShareWhatsApp,
    this.onExportInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy');

    final isComplete = harvest.harvestType.toLowerCase() == 'complete';
    final typeColor = isComplete ? AppColors.secondary : AppColors.alertWatch;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header: Pond & Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.waves, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      harvest.pondName,
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
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor, width: 1),
                  ),
                  child: Text(
                    '${harvest.harvestType} Harvest',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Metrics Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormatter.format(harvest.date),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'FCR: ',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            harvest.fcr.toStringAsFixed(2),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid Metrics (Biomass, Count, Price, Total)
                Row(
                  children: [
                    // Biomass (kg)
                    Expanded(
                      child: _MetricTile(
                        label: 'Biomass / దిగుబడి',
                        value: '${harvest.biomassKg.toStringAsFixed(0)} kg',
                        icon: Icons.scale,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Count/kg
                    Expanded(
                      child: _MetricTile(
                        label: 'Count / కౌంట్',
                        value: '${harvest.countPerKg} /kg',
                        icon: Icons.grain,
                        color: AppColors.alertWatch,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price/kg
                    Expanded(
                      child: _MetricTile(
                        label: 'Price / ధర',
                        value: '₹${harvest.pricePerKg.toStringAsFixed(0)}',
                        icon: Icons.sell,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Total Gross Revenue Highlight Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gross Revenue / మొత్తం ఆదాయం',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            currencyFormatter.format(harvest.totalRevenue),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      if (harvest.buyerName != null)
                        Chip(
                          avatar: const Icon(Icons.store, size: 14, color: AppColors.textPrimary),
                          label: Text(
                            harvest.buyerName!,
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textPrimary),
                          ),
                          backgroundColor: AppColors.surfaceElevated,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card Action Buttons
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onExportInvoice,
                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: AppColors.primary),
                  label: Text(
                    'Export Invoice',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.primary),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onShareWhatsApp,
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
