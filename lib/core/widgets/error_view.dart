import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Categories of application network/system errors.
enum AppErrorType {
  offline,
  server,
  timeout,
  unknown;

  String defaultEnglishTitle() {
    switch (this) {
      case AppErrorType.offline:
        return 'No Network Connection';
      case AppErrorType.server:
        return 'AquaCloud Server Unavailable';
      case AppErrorType.timeout:
        return 'Connection Timed Out';
      case AppErrorType.unknown:
        return 'Something Went Wrong';
    }
  }

  String defaultTeluguTitle() {
    switch (this) {
      case AppErrorType.offline:
        return 'ఇంటర్నెట్ కనెక్షన్ లేదు';
      case AppErrorType.server:
        return 'సర్వర్ స్పందించలేదు';
      case AppErrorType.timeout:
        return 'కనెక్షన్ సమయం ముగిసింది';
      case AppErrorType.unknown:
        return 'సాంకేతిక సమస్య ఎదురైంది';
    }
  }

  String defaultEnglishMessage() {
    switch (this) {
      case AppErrorType.offline:
        return 'Pond dyke 2G connectivity might be unavailable. Your local changes are saved offline in FIFO queue.';
      case AppErrorType.server:
        return 'Our aquaculture intelligence backend is experiencing brief downtime. Cached farm data remains available.';
      case AppErrorType.timeout:
        return 'Weak rural cellular signal caused request timeout. Please retry with a stronger link.';
      case AppErrorType.unknown:
        return 'An unexpected issue occurred. Please retry or access your locally cached pond data.';
    }
  }

  String defaultTeluguMessage() {
    switch (this) {
      case AppErrorType.offline:
        return 'చెరువు గట్ల వద్ద 2G సిగ్నల్ బలహీనంగా ఉండవచ్చు. మీ డేటా ఆఫ్‌లైన్ క్యూలో సురక్షితంగా సేవ్ చేయబడింది.';
      case AppErrorType.server:
        return 'క్లౌడ్ సర్వర్‌లో సమస్య ఏర్పడింది. కాష్ చేయబడిన చెరువు వివరాలు అందుబాటులో ఉన్నాయి.';
      case AppErrorType.timeout:
        return 'సిగ్నల్ నెమ్మదిగా ఉండటం వల్ల సమయం ముగిసింది. దయచేసి మళ్ళీ ప్రయత్నించండి.';
      case AppErrorType.unknown:
        return 'సమస్య ఎదురైంది. దయచేసి మళ్ళీ ప్రయత్నించండి లేదా ఆఫ్‌లైన్ డేటాను పరిశీలించండి.';
    }
  }

  IconData get icon {
    switch (this) {
      case AppErrorType.offline:
        return Icons.wifi_off_rounded;
      case AppErrorType.server:
        return Icons.cloud_off_rounded;
      case AppErrorType.timeout:
        return Icons.timer_off_outlined;
      case AppErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  Color get iconColor {
    switch (this) {
      case AppErrorType.offline:
        return AppColors.alertWatch;
      case AppErrorType.server:
        return AppColors.alertUrgent;
      case AppErrorType.timeout:
        return AppColors.alertWatch;
      case AppErrorType.unknown:
        return AppColors.alertUrgent;
    }
  }
}

/// Dedicated, Reusable Deep Ocean Matte Error/Offline Page Component.
///
/// Designed specifically for coastal Andhra Pradesh aquaculture conditions:
/// - High sunlight legibility on dark matte surfaces
/// - Clear bilingual Telugu & English headings and explanations
/// - Prominent retry button with tactile hit-target (>48px) for wet fingers
/// - Option to proceed in 100% offline cached mode
class AppErrorView extends StatelessWidget {
  final AppErrorType errorType;
  final String? title;
  final String? message;
  final String? teluguTitle;
  final String? teluguMessage;
  final bool isTelugu;
  final VoidCallback? onRetry;
  final VoidCallback? onUseOfflineData;
  final bool hasOfflineData;
  final bool isCompact;

  const AppErrorView({
    super.key,
    this.errorType = AppErrorType.offline,
    this.title,
    this.message,
    this.teluguTitle,
    this.teluguMessage,
    this.isTelugu = false,
    this.onRetry,
    this.onUseOfflineData,
    this.hasOfflineData = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = isTelugu
        ? (teluguTitle ?? errorType.defaultTeluguTitle())
        : (title ?? errorType.defaultEnglishTitle());

    final effectiveMessage = isTelugu
        ? (teluguMessage ?? errorType.defaultTeluguMessage())
        : (message ?? errorType.defaultEnglishMessage());

    if (isCompact) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: errorType.iconColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(errorType.icon, color: errorType.iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    effectiveTitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    effectiveMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                tooltip: isTelugu ? 'మళ్ళీ ప్రయత్నించండి' : 'Retry',
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with glowing matte aura
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: errorType.iconColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: errorType.iconColor.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: errorType.iconColor.withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                errorType.icon,
                size: 42,
                color: errorType.iconColor,
              ),
            ),
            const SizedBox(height: 24),

            // Error Title
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Error Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                effectiveMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Primary Action: Retry Button
            if (onRetry != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      isTelugu ? 'మళ్ళీ ప్రయత్నించండి' : 'Retry Connection',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Secondary Action: Continue with Offline Cache
            if (hasOfflineData && onUseOfflineData != null) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onUseOfflineData,
                    icon: const Icon(Icons.cloud_done_outlined, size: 18),
                    label: Text(
                      isTelugu
                          ? 'ఆఫ్‌లైన్ కాష్ ఉపయోగించండి'
                          : 'Use Offline Cached Data',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ambient Offline Status Banner at the top of active screens.
class OfflineStatusBar extends StatelessWidget {
  final bool isOffline;
  final String? lastSyncTime;
  final bool isTelugu;
  final VoidCallback? onSyncNow;

  const OfflineStatusBar({
    super.key,
    required this.isOffline,
    this.lastSyncTime,
    this.isTelugu = false,
    this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C180E),
        border: Border(
          bottom: BorderSide(
            color: AppColors.alertWatch.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: AppColors.alertWatch,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isTelugu
                  ? 'ఆఫ్‌లైన్ మోడ్ — స్థానిక కాష్ డేటా చురుకుగా ఉంది'
                  : 'Offline Mode — Showing local cached farm data',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.alertWatch,
              ),
            ),
          ),
          if (onSyncNow != null)
            InkWell(
              onTap: onSyncNow,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sync,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isTelugu ? 'సింక్' : 'Sync',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
