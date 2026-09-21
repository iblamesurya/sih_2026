import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/subscription_service.dart';

/// Main Home / Dashboard page of PrawnGuard.ai (Tab 0).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final alerts = ref.watch(alertsProvider);
    final ponds = ref.watch(pondListProvider);
    final subscriptionTier = ref.watch(currentSubscriptionTierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.water_drop, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PrawnGuard.ai',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Bhimavaram, West Godavari',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Language Switcher Pill
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              ref.read(currentLocaleProvider.notifier).state =
                  isTelugu ? const Locale('en') : const Locale('te');
            },
            icon: const Icon(Icons.language, size: 14, color: AppColors.primary),
            label: Text(
              isTelugu ? 'తెలుగు' : 'EN',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Subscription Badge
          IconButton(
            icon: Icon(
              subscriptionTier == SubscriptionTier.pro
                  ? Icons.verified
                  : Icons.star_border,
              color: subscriptionTier == SubscriptionTier.pro
                  ? AppColors.primary
                  : AppColors.alertWatch,
            ),
            onPressed: () => context.push('/upgrade'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Urgent Alert Notification Banner
          if (alerts.any((a) => a.isUrgent))
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.alertUrgent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.alertUrgent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.alertUrgent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTelugu ? 'అత్యవసర హెచ్చరిక' : 'Critical Water Alert',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.alertUrgent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTelugu
                              ? 'చెరువులో ఆక్సిజన్ లేదా pH ప్రమాదకర స్థాయికి పడిపోయింది.'
                              : 'One or more water parameters breached critical safety thresholds.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/quick-log'),
                    child: Text(
                      isTelugu ? 'చూడండి' : 'Review',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.alertUrgent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Weather & Hypoxia Advisory Card
          InkWell(
            onTap: () => context.push('/weather'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF171717), Color(0xFF0C2229)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_queue, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isTelugu ? 'వాతావరణ నివేదిక' : 'Aquaculture Weather',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '29.4°C • 78% Humidity • Overcast',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTelugu
                          ? 'హైపోక్సియా ప్రమాదం: తక్కువ (ఏరేటర్లు సరిపోతాయి)'
                          : 'Hypoxia Risk: Low • Aeration optimal',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions Grid
          Text(
            isTelugu ? 'త్వరిత చర్యలు' : 'Quick Actions',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _QuickActionCard(
                icon: Icons.mic,
                iconColor: AppColors.primary,
                title: isTelugu ? 'వాయిస్ లాగ్' : 'Telugu Voice Log',
                subtitle: isTelugu ? 'ఫోన్ మాట్లాడండి' : 'Hands-free input',
                onTap: () => context.push('/quick-log'),
              ),
              _QuickActionCard(
                icon: Icons.restaurant,
                iconColor: AppColors.secondary,
                title: isTelugu ? 'మేత లెక్క' : 'Feed AI Calculator',
                subtitle: isTelugu ? '4-సార్లు షెడ్యూల్' : 'Bio-energetic ratio',
                onTap: () => context.go('/feed'),
              ),
              _QuickActionCard(
                icon: Icons.biotech,
                iconColor: AppColors.alertWatch,
                title: isTelugu ? 'రొయ్య డాక్టర్' : 'PrawnDoc Vision',
                subtitle: isTelugu ? '12 వ్యాధుల స్కానింగ్' : 'AI Disease Scan',
                onTap: () => context.go('/prawndoc'),
              ),
              _QuickActionCard(
                icon: Icons.account_balance_wallet,
                iconColor: AppColors.alertInfo,
                title: isTelugu ? 'ఫైనాన్స్ & క్రెడిట్' : 'PrawnCredit',
                subtitle: isTelugu ? 'ఖర్చులు & అమ్మకాలు' : 'Cashflow ledger',
                onTap: () => context.push('/finance'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Active Ponds Summary Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTelugu ? 'నా చెరువులు (${ponds.length})' : 'Active Ponds (${ponds.length})',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/ponds'),
                child: Text(
                  isTelugu ? 'అన్నీ చూడండి' : 'View All',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (ponds.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.water, size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: 10),
                  Text(
                    isTelugu ? 'చెరువులు ఇంకా జోడించబడలేదు' : 'No ponds registered yet',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTelugu
                        ? 'మీ మొదటి చెరువును నమోదు చేయడానికి ఇక్కడ నొక్కండి'
                        : 'Tap below to configure your first aquaculture pond',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => context.push('/add-pond'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      isTelugu ? 'చెరువును జోడించండి' : 'Add Pond',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else
            ...ponds.take(3).map((pond) => Container(
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.water, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pond['name']?.toString() ?? 'Pond ${pond['id']}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'DOC: ${pond['doc'] ?? 45} • Area: ${pond['areaHa'] ?? 1.0} Ha • ${pond['species'] ?? 'L. vannamei'}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ],
                  ),
                )),
          const SizedBox(height: 20),

          // Daily 4-Meal Schedule Tracker Card
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
                      isTelugu ? 'నేటి మేత షెడ్యూల్ (4 సార్లు)' : 'Today\'s 4-Meal Schedule',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bio-Energetics',
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
                Row(
                  children: [
                    _MealPill(time: '06:00 AM', share: '20%', isCompleted: true),
                    const SizedBox(width: 8),
                    _MealPill(time: '11:00 AM', share: '30%', isCompleted: true),
                    const SizedBox(width: 8),
                    _MealPill(time: '04:00 PM', share: '30%', isCompleted: false),
                    const SizedBox(width: 8),
                    _MealPill(time: '09:00 PM', share: '20%', isCompleted: false),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealPill extends StatelessWidget {
  final String time;
  final String share;
  final bool isCompleted;

  const _MealPill({
    required this.time,
    required this.share,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.secondary.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted ? AppColors.secondary : AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.schedule,
              size: 14,
              color: isCompleted ? AppColors.secondary : AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              share,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: isCompleted ? AppColors.secondary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
