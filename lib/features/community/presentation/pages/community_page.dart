import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';

/// Community & Farmer Knowledge Exchange Forum Page (/community).
class CommunityPage extends ConsumerWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';

    final discussions = [
      {
        'title': 'Bhimavaram Area WSSV Alert & Biosecurity Precautions',
        'teluguTitle': 'భీమవరం ప్రాంతంలో తెల్లమచ్చ వ్యాధి హెచ్చరిక మరియు జాగ్రత్తలు',
        'author': 'Ramesh Naidu (Field Expert)',
        'time': '2 hours ago',
        'replies': 14,
        'category': 'Biosecurity',
      },
      {
        'title': 'Optimizing FCR during high summer temperatures (>34°C)',
        'teluguTitle': 'ఎండ కాలంలో మేత వాడకం (FCR) తగ్గింపు సూచనలు',
        'author': 'Dr. K. Srinivas Rao (Aquaculturist)',
        'time': 'Yesterday',
        'replies': 29,
        'category': 'Feed Management',
      },
      {
        'title': 'Current Nellore Mandi procurement price for 30 count vannamei',
        'teluguTitle': 'నెల్లూరు మార్కెట్‌లో 30 కౌంట్ రొయ్యల తాజా ధరలు',
        'author': 'Venkatesh P.',
        'time': '2 days ago',
        'replies': 42,
        'category': 'Market Trends',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTelugu ? 'రైతుల కమ్యూనిటీ ఫోరమ్' : 'Aquaculture Community',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.edit),
        label: Text(
          isTelugu ? 'ప్రశ్న అడగండి' : 'Ask Question',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Community posting dialog opened!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Community Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF171717), Color(0xFF1C132E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.forum, color: Color(0xFFCE93D8), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTelugu ? 'ఆంధ్రప్రదేశ్ ఆక్వా రైతుల వేదిక' : 'Andhra Shrimp Farmers Network',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isTelugu
                            ? 'తాజా మార్కెట్ సమాచారం, వ్యాధి జాగ్రత్తలు పంచుకోండి'
                            : 'Connect with local farmers, share feed tips and disease alerts',
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
          ),
          const SizedBox(height: 20),

          Text(
            isTelugu ? 'ట్రెండింగ్ చర్చలు' : 'Trending Discussions',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          ...discussions.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            d['category'] as String,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          d['time'] as String,
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTelugu ? d['teluguTitle'] as String : d['title'] as String,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          d['author'] as String,
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.comment, size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${d['replies']}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
