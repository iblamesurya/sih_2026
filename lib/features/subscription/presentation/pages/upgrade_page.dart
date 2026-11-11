import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/subscription_service.dart';

/// Subscription Upgrade, AP Seasonal Crop Pass & Farm ROI Calculator Page (/upgrade).
class UpgradePage extends ConsumerStatefulWidget {
  const UpgradePage({super.key});

  @override
  ConsumerState<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends ConsumerState<UpgradePage> {
  String _selectedPlanKey = 'crop_pass'; // 'monthly' | 'crop_pass' | 'cluster'
  double _farmAreaHa = 2.0; // 2 Hectares (~5 Acres) typical AP progressive farmer

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final subscriptionTier = ref.watch(currentSubscriptionTierProvider);
    final subService = ref.watch(subscriptionServiceProvider);

    final roiMetrics = subService.calculateCropSavingsInr(totalAreaHa: _farmAreaHa);
    final feedSavings = roiMetrics['feedSavingsInr'] ?? 33120.0;
    final mandiGain = roiMetrics['mandiTimingGainInr'] ?? 54000.0;
    final totalSavings = roiMetrics['totalSavingsInr'] ?? 87120.0;
    final roiMultiple = roiMetrics['roiMultiple'] ?? 87.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTelugu ? 'ప్రాన్ గార్డ్ ప్రో (Pro)' : 'PrawnGuard Pro',
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
          // Pro Hero Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF171717), Color(0xFF07242B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified, color: AppColors.primary, size: 42),
                const SizedBox(height: 12),
                Text(
                  'PrawnGuard Pro Plan',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isTelugu
                      ? 'అపరిమిత AI స్కాన్‌లు, బయో-ఎనర్జెటిక్స్, మండి ఆప్టిమైజర్ మరియు 1.05% ప్రాన్ క్రెడిట్ లోన్'
                      : 'Unlimited AI Scans, Finisher Bio-Energetics, Live Mandi Arbitrage & 1.05% KCC Loans',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Text(
                  '₹199 / month • or ₹999 / 120-Day Crop Pass (పంట పాస్)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isTelugu
                      ? 'రోజుకు ₹6.60 మాత్రమే — 70 గ్రాముల రొయ్యల మేత కంటే తక్కువ ఖర్చు!'
                      : 'Just ₹6.60/day — costs less than 70 grams of shrimp feed per day!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Plan Selector Cards (Monthly vs 120-Day Crop Pass vs Cluster)
          Row(
            children: [
              Expanded(
                child: _PlanOptionCard(
                  title: isTelugu ? 'నెలవారీ' : 'Monthly',
                  price: '₹199',
                  subtitle: '/ month',
                  isSelected: _selectedPlanKey == 'monthly',
                  onTap: () => setState(() => _selectedPlanKey = 'monthly'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PlanOptionCard(
                  title: isTelugu ? 'పంట పాస్ (Popular)' : 'Crop Pass (Best)',
                  price: '₹999',
                  subtitle: '120 Days (1 Crop)',
                  isSelected: _selectedPlanKey == 'crop_pass',
                  badge: 'MOST POPULAR',
                  onTap: () => setState(() => _selectedPlanKey = 'crop_pass'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PlanOptionCard(
                  title: isTelugu ? 'క్లస్టర్ ఎస్టేట్' : 'Estate Annual',
                  price: '₹2,499',
                  subtitle: '1 Year + Muneem',
                  isSelected: _selectedPlanKey == 'cluster',
                  onTap: () => setState(() => _selectedPlanKey = 'cluster'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Interactive Andhra Pradesh Farmer Savings & ROI Calculator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isTelugu
                            ? 'ఆంధ్రప్రదేశ్ రైతు నికర లాభం కాలిక్యులేటర్ (1 పంటకు)'
                            : 'AP Farmer Crop Savings Calculator (Per 100-Day Crop)',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${roiMultiple.toStringAsFixed(0)}x ROI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isTelugu
                      ? 'మీ సాగు విస్తీర్ణం: ${_farmAreaHa.toStringAsFixed(1)} Hectares (${(_farmAreaHa * 2.47).toStringAsFixed(1)} Acres)'
                      : 'Your Farm Water Spread: ${_farmAreaHa.toStringAsFixed(1)} Ha (${(_farmAreaHa * 2.47).toStringAsFixed(1)} Acres)',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                ),
                Slider(
                  value: _farmAreaHa,
                  min: 0.5,
                  max: 10.0,
                  divisions: 19,
                  activeColor: AppColors.secondary,
                  onChanged: (v) => setState(() => _farmAreaHa = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu ? '• 0.08 FCR మేత ఆదా (@ ₹92/kg):' : '• 0.08 FCR Feed Saved (@ ₹92/kg):',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '+₹${feedSavings.toStringAsFixed(0)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu
                          ? '• మండి కౌంట్ జంప్ ఆప్టిమైజర్ లాభం:'
                          : '• Mandi Count-Bracket Timing Gain:',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      '+₹${mandiGain.toStringAsFixed(0)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: AppColors.cardBorder),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu ? 'ఒక్క పంటకు మొత్తం అదనపు లాభం:' : 'Estimated Net Extra Profit / Crop:',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '₹${totalSavings.toStringAsFixed(0)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            isTelugu ? 'ఫీచర్ల పోలిక' : 'Free vs Pro Feature Comparison',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              children: [
                _FeatureRow(
                  feature: 'PrawnDoc AI Scans',
                  freeValue: '3 / day',
                  proValue: 'Unlimited (Gemini Vision)',
                ),
                Divider(height: 16),
                _FeatureRow(
                  feature: 'Active Ponds Monitored',
                  freeValue: 'Max 3 Ponds',
                  proValue: 'Unlimited Ponds + Muneem Sync',
                ),
                Divider(height: 16),
                _FeatureRow(
                  feature: 'Feed AI Bio-Energetics',
                  freeValue: '5 calcs / mo',
                  proValue: 'Unlimited 4-Meal + Finisher Curve',
                ),
                Divider(height: 16),
                _FeatureRow(
                  feature: 'Mandi Harvest Optimizer',
                  freeValue: 'Basic Rates',
                  proValue: '7-Day Hold Profit & Plant Alerts',
                ),
                Divider(height: 16),
                _FeatureRow(
                  feature: 'Telugu Voice NLU Assistant',
                  freeValue: 'Included',
                  proValue: 'Included + Custom Prompts',
                ),
                Divider(height: 16),
                _FeatureRow(
                  feature: 'PrawnCredit Micro-Loan Limit',
                  freeValue: 'Basic Tier',
                  proValue: 'Up to ₹5,00,000 @ 1.05%/mo KCC',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upgrade Button
          if (subscriptionTier != SubscriptionTier.pro)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(currentSubscriptionTierProvider.notifier).state = SubscriptionTier.pro;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgraded to PrawnGuard Pro successfully!'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: Text(
                isTelugu
                    ? 'ప్రో ప్లాన్‌కు అప్‌గ్రేడ్ అవ్వండి (UPI / PhonePe)'
                    : 'Upgrade to Pro Now (UPI / PhonePe / GPay)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Center(
                child: Text(
                  'Your Pro Subscription is Active',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanOptionCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _PlanOptionCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.isSelected,
    this.badge,
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
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.background,
                  ),
                ),
              ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String feature;
  final String freeValue;
  final String proValue;

  const _FeatureRow({
    required this.feature,
    required this.freeValue,
    required this.proValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            feature,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            freeValue,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AppColors.textTertiary),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            proValue,
            textAlign: TextAlign.right,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
