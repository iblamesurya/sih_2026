/// Supported subscription tiers in PrawnGuard.ai.
enum SubscriptionTier {
  free,
  pro,
}

/// Status of a specific quota check.
class QuotaStatus {
  final bool isAllowed;
  final int remaining;
  final int limit;
  final String? upgradePrompt;

  const QuotaStatus({
    required this.isAllowed,
    required this.remaining,
    required this.limit,
    this.upgradePrompt,
  });

  Map<String, dynamic> toJson() => {
        'isAllowed': isAllowed,
        'remaining': remaining,
        'limit': limit,
        'upgradePrompt': upgradePrompt,
      };

  @override
  String toString() =>
      'QuotaStatus(isAllowed: $isAllowed, remaining: $remaining/$limit, prompt: $upgradePrompt)';
}

/// Service managing Free vs Pro subscription tier quotas and gatekeeping.
class SubscriptionService {
  // Free Tier Constants
  static const int freeTierDailyScansLimit = 3;
  static const int freeTierMonthlyScansLimit = 20;
  static const int freeTierMaxPonds = 3;
  static const int freeTierMonthlyFeedCalcs = 5;
  static const int freeTierMonthlyReports = 3;

  // Pro Tier Price
  static const int proTierMonthlyPriceInr = 199;

  const SubscriptionService();

  /// Resolves the enum tier based on boolean flag.
  SubscriptionTier getTier(bool isPro) =>
      isPro ? SubscriptionTier.pro : SubscriptionTier.free;

  /// Checks if a disease scan can be performed today.
  bool canPerformScan({
    required int currentScansToday,
    required bool isPro,
  }) {
    if (isPro) return true;
    return currentScansToday < freeTierDailyScansLimit;
  }

  /// Calculates remaining scans available for today.
  int getRemainingScans({
    required int currentScansToday,
    required bool isPro,
  }) {
    if (isPro) return 999999; // Unlimited
    final remaining = freeTierDailyScansLimit - currentScansToday;
    return remaining > 0 ? remaining : 0;
  }

  /// Checks whether a new pond can be registered under the account.
  bool canAddPond({
    required int currentPondCount,
    required bool isPro,
  }) {
    if (isPro) return true;
    return currentPondCount < freeTierMaxPonds;
  }

  /// Checks if a Feed AI bio-energetic calculation can be executed.
  bool canPerformFeedCalculation({
    required int currentCalcsThisMonth,
    required bool isPro,
  }) {
    if (isPro) return true;
    return currentCalcsThisMonth < freeTierMonthlyFeedCalcs;
  }

  /// Checks if a PDF crop summary report can be exported.
  bool canExportReport({
    required int currentReportsThisMonth,
    required bool isPro,
  }) {
    if (isPro) return true;
    return currentReportsThisMonth < freeTierMonthlyReports;
  }

  /// Detailed quota assessment for PrawnDoc AI disease vision scans.
  QuotaStatus checkScanQuota({
    required int currentScansToday,
    required bool isPro,
  }) {
    if (isPro) {
      return const QuotaStatus(
        isAllowed: true,
        remaining: 999999,
        limit: -1,
      );
    }

    final remaining = freeTierDailyScansLimit - currentScansToday;
    final isAllowed = remaining > 0;

    return QuotaStatus(
      isAllowed: isAllowed,
      remaining: remaining > 0 ? remaining : 0,
      limit: freeTierDailyScansLimit,
      upgradePrompt: isAllowed
          ? null
          : 'You have used all $freeTierDailyScansLimit free PrawnDoc AI scans for today. Upgrade to Pro (₹$proTierMonthlyPriceInr/mo) for unlimited instant disease diagnoses.',
    );
  }

  /// Detailed quota assessment for pond registrations.
  QuotaStatus checkPondQuota({
    required int currentPondCount,
    required bool isPro,
  }) {
    if (isPro) {
      return const QuotaStatus(
        isAllowed: true,
        remaining: 999999,
        limit: -1,
      );
    }

    final remaining = freeTierMaxPonds - currentPondCount;
    final isAllowed = remaining > 0;

    return QuotaStatus(
      isAllowed: isAllowed,
      remaining: remaining > 0 ? remaining : 0,
      limit: freeTierMaxPonds,
      upgradePrompt: isAllowed
          ? null
          : 'Free tier allows up to $freeTierMaxPonds ponds. Upgrade to Pro (₹$proTierMonthlyPriceInr/mo) to track unlimited ponds across multiple farms.',
    );
  }

  /// Generates a standardized upgrade prompt for a specific feature key.
  String getUpgradePrompt(String featureKey) {
    switch (featureKey.toLowerCase()) {
      case 'scans':
      case 'prawndoc':
        return 'Upgrade to PrawnGuard Pro (₹$proTierMonthlyPriceInr/mo) for unlimited AI disease diagnosis, lab report integration, and expert WhatsApp consultations.';
      case 'ponds':
        return 'Upgrade to PrawnGuard Pro (₹$proTierMonthlyPriceInr/mo) to manage unlimited ponds and farms with real-time multi-user synchronization.';
      case 'feed_ai':
      case 'feed':
        return 'Upgrade to PrawnGuard Pro (₹$proTierMonthlyPriceInr/mo) for unlimited automated daily feed scheduling, tray feedback learning, and biomass projections.';
      case 'reports':
      case 'finance':
        return 'Upgrade to PrawnGuard Pro (₹$proTierMonthlyPriceInr/mo) for unlimited PrawnCredit financial ledger exports, buyer receipts, and harvest yield analytics.';
      default:
        return 'Upgrade to PrawnGuard Pro (₹$proTierMonthlyPriceInr/mo) to unlock full aquaculture intelligence features.';
    }
  }
}
