import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/subscription_service.dart';

/// Subscription Upgrade & Pro Quota Page (/upgrade).
class UpgradePage extends ConsumerWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final subscriptionTier = ref.watch(currentSubscriptionTierProvider);

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
                      ? 'అపరిమిత AI స్కాన్‌లు, బయో-ఎనర్జెటిక్స్ మరియు ప్రాన్ క్రెడిట్ లోన్ సదుపాయం'
                      : 'Unlimited AI Scans, Advanced Bio-Energetics & Priority Pre-Approved Micro-Loans',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  '₹999 / month • or ₹7,999 / crop cycle',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
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
            child: Column(
              children: const [
                _FeatureRow(
                  feature: 'PrawnDoc AI Scans',
                  freeValue: '3 / day',
                  proValue: 'Unlimited (Gemini Vision)',
                ),
                Divider(height: 16),
                _FeatureRow(
                  feature: 'Active Ponds Monitored',
                  freeValue: 'Max 3 Ponds',
                  proValue: 'Unlimited Ponds',
                ),
                Divider(height: 16),
                _FeatureRow(
                  feature: 'Feed AI Bio-Energetics',
                  freeValue: '5 calcs / mo',
                  proValue: 'Unlimited 4-Meal Splits',
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
                  proValue: 'Up to ₹3,50,000 Instant',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upgrade Button
          if (subscriptionTier != SubscriptionTier.pro)
            ElevatedButton(
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
              child: Text(
                isTelugu ? 'ప్రో ప్లాన్‌కు అప్‌గ్రేడ్ అవ్వండి' : 'Upgrade to Pro Now',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
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
