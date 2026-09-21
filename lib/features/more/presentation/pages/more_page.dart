import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/subscription_service.dart';

/// More / Settings & Hub Navigation Page (Tab 4).
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final isTelugu = locale.languageCode == 'te';
    final subscriptionTier = ref.watch(currentSubscriptionTierProvider);
    final offlineSync = ref.watch(offlineSyncProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          isTelugu ? 'మరిన్ని ఎంపికలు' : 'More & Settings',
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
          // Farmer Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF171717), Color(0xFF0F1E26)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: AppColors.primary, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Surya Tummala',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: subscriptionTier == SubscriptionTier.pro
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.alertWatch.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subscriptionTier == SubscriptionTier.pro ? 'PRO' : 'FREE',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: subscriptionTier == SubscriptionTier.pro
                                    ? AppColors.primary
                                    : AppColors.alertWatch,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+91 98765 43210 • Bhimavaram Farm #1',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                  onPressed: () => context.push('/profile-setup'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bilingual Language Toggle Tile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTelugu ? 'భాష ఎంపిక (Language)' : 'App Language',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isTelugu ? 'తెలుగు సక్రియంగా ఉంది' : 'English is active',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: isTelugu,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    ref.read(currentLocaleProvider.notifier).state =
                        val ? const Locale('te') : const Locale('en');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Navigation Hub Items
          _SettingsTile(
            icon: Icons.cloud_outlined,
            iconColor: AppColors.primary,
            title: isTelugu ? 'వాతావరణం & హైపోక్సియా' : 'Weather Intelligence',
            subtitle: isTelugu ? '7-రోజుల ఆక్వాకల్చర్ ఫోర్‌కాస్ట్' : 'Hypoxia risks & wind advisories',
            onTap: () => context.push('/weather'),
          ),
          _SettingsTile(
            icon: Icons.assessment_outlined,
            iconColor: AppColors.secondary,
            title: isTelugu ? 'నివేదికలు & FCR విశ్లేషణ' : 'Reports & Analytics',
            subtitle: isTelugu ? 'FCR మరియు బయోమాస్ చార్టులు' : 'Crop cycle performance & PDF export',
            onTap: () => context.push('/reports'),
          ),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.alertInfo,
            title: isTelugu ? 'ప్రాన్ క్రెడిట్ & ఫైనాన్స్' : 'PrawnCredit & Finance',
            subtitle: isTelugu ? 'ఖర్చులు & రొయ్యల లోన్ స్కోరు' : 'Expenses, harvest cashflow & loan limits',
            onTap: () => context.push('/finance'),
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            iconColor: AppColors.alertWatch,
            title: isTelugu ? 'ప్రో ప్లాన్‌కు అప్‌గ్రేడ్' : 'Subscription & Upgrades',
            subtitle: isTelugu ? 'అపరిమిత స్కాన్‌లు & చెరువులు' : 'Unlock unlimited AI scans & ponds',
            onTap: () => context.push('/upgrade'),
          ),
          _SettingsTile(
            icon: Icons.forum_outlined,
            iconColor: const Color(0xFF9C27B0),
            title: isTelugu ? 'రైతుల కమ్యూనిటీ' : 'Farmer Community Forum',
            subtitle: isTelugu ? 'ఆక్వాకల్చర్ చర్చలు & నిపుణులు' : 'Q&A, disease warnings & expert advice',
            onTap: () => context.push('/community'),
          ),
          _SettingsTile(
            icon: Icons.admin_panel_settings_outlined,
            iconColor: AppColors.alertUrgent,
            title: isTelugu ? 'అడ్మిన్ డాష్‌బోర్డ్' : 'Admin Web Portal',
            subtitle: isTelugu ? 'మండి ధరలు & ప్రకటనలు' : 'Farm map, live mandi prices & broadcasts',
            onTap: () => context.push('/admin'),
          ),
          const SizedBox(height: 16),

          // Offline Sync Drain Action Tile
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTelugu ? 'ఆఫ్‌లైన్ సమకాలీకరణ' : 'Offline Sync Queue',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isTelugu ? 'ఆటో-సింక్ బ్యాక్‌ఆఫ్ యాక్టివ్‌గా ఉంది' : 'FIFO max 100 queue with backoff drain',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () async {
                    await offlineSync.drainQueue();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Offline mutation queue drained & synced!'),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                    }
                  },
                  child: Text(
                    isTelugu ? 'సింక్ చేయండి' : 'Drain Queue',
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sign Out Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.alertUrgent,
              side: const BorderSide(color: AppColors.alertUrgent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Sign out and clear state
              ref.clearUserData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out successfully. User state cleared.'),
                  backgroundColor: AppColors.alertUrgent,
                ),
              );
              context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 18),
            label: Text(
              isTelugu ? 'లాగ్ అవుట్' : 'Sign Out',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
