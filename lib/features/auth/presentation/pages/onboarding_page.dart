import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';

/// Onboarding Showcase Page (/onboarding).
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';

    final slides = [
      {
        'icon': Icons.biotech,
        'color': AppColors.primary,
        'title': isTelugu ? 'PrawnDoc AI విజన్' : 'PrawnDoc AI Vision Triage',
        'desc': isTelugu
            ? 'ఫోన్ కెమెరాతో రొయ్యలను స్కాన్ చేసి 12 వ్యాధులను తక్షణమే గుర్తించండి.'
            : 'Scan shrimp specimens with phone camera to diagnose 12 major aquaculture diseases on-device.',
      },
      {
        'icon': Icons.restaurant,
        'color': AppColors.secondary,
        'title': isTelugu ? 'బయో-ఎనర్జెటిక్స్ ఫీడ్ AI' : 'Bio-Energetic Feed AI',
        'desc': isTelugu
            ? 'ఉష్ణోగ్రత మరియు చెక్-ట్రే ఆధారంగా ఖచ్చితమైన 4-సార్ల మేత షెడ్యూల్ పొందండి.'
            : 'Optimize feeding ratios with DOC-dependent curves, temperature compensation and check-tray feedback.',
      },
      {
        'icon': Icons.account_balance_wallet,
        'color': AppColors.alertWatch,
        'title': isTelugu ? 'ప్రాన్ క్రెడిట్ ఫైనాన్స్' : 'PrawnCredit Micro-Loans',
        'desc': isTelugu
            ? 'ఖర్చులు, దిగుబడి నమోదుతో తక్షణ మైక్రో లోన్ క్రెడిట్ స్కోరును నిర్మించుకోండి.'
            : 'Build verifiable digital farm credit score to access pre-approved working capital micro-loans.',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PrawnGuard.ai',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      isTelugu ? 'దాటవేయి' : 'Skip',
                      style: GoogleFonts.spaceGrotesk(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              ...slides.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (s['color'] as Color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['title'] as String,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s['desc'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.go('/login'),
                  child: Text(
                    isTelugu ? 'ప్రారంభించండి' : 'Get Started with Phone OTP',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
