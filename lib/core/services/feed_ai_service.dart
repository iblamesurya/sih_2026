import 'package:flutter/foundation.dart';

/// Single meal allocation item in the 4-meal daily feeding schedule.
@immutable
class MealScheduleItem {
  final int mealNumber;
  final String mealTime;
  final double percentShare;
  final double feedKg;
  final String teluguLabel;

  const MealScheduleItem({
    required this.mealNumber,
    required this.mealTime,
    required this.percentShare,
    required this.feedKg,
    required this.teluguLabel,
  });

  Map<String, dynamic> toJson() => {
        'mealNumber': mealNumber,
        'mealTime': mealTime,
        'percentShare': percentShare,
        'feedKg': feedKg,
        'teluguLabel': teluguLabel,
      };

  @override
  String toString() =>
      'Meal $mealNumber ($mealTime): ${feedKg.toStringAsFixed(2)} kg (${(percentShare * 100).toStringAsFixed(0)}%)';
}

/// Comprehensive daily feed recommendation result calculated by [FeedAIService].
@immutable
class DailyFeedPlan {
  /// Total estimated live shrimp biomass in kg.
  final double biomassKg;

  /// DOC-dependent feeding rate percentage as a decimal (0.03 - 0.08).
  final double feedingRate;

  /// Baseline daily feed requirement before environmental factors in kg.
  final double baseDailyFeedKg;

  /// Water temperature adjustment factor (0.85, 1.00, or 0.90).
  final double tempFactor;

  /// Check-tray consumption adjustment factor (clamped between 0.80 and 1.10).
  final double trayFactor;

  /// Final adjusted daily feed ration in kg.
  final double adjustedDailyFeedKg;

  /// Meal 1 — 06:00 AM (20% share) in kg.
  final double meal1Kg;

  /// Meal 2 — 11:00 AM (30% share) in kg.
  final double meal2Kg;

  /// Meal 3 — 04:00 PM (30% share) in kg.
  final double meal3Kg;

  /// Meal 4 — 09:00 PM (20% share) in kg.
  final double meal4Kg;

  const DailyFeedPlan({
    required this.biomassKg,
    required this.feedingRate,
    required this.baseDailyFeedKg,
    required this.tempFactor,
    required this.trayFactor,
    required this.adjustedDailyFeedKg,
    required this.meal1Kg,
    required this.meal2Kg,
    required this.meal3Kg,
    required this.meal4Kg,
  });

  /// Total sum of all 4 meals in kg.
  double get mealsTotal => meal1Kg + meal2Kg + meal3Kg + meal4Kg;

  /// Returns structured list of the 4 scheduled meals.
  List<MealScheduleItem> get mealSchedule => [
        MealScheduleItem(
          mealNumber: 1,
          mealTime: '06:00 AM',
          percentShare: 0.20,
          feedKg: meal1Kg,
          teluguLabel: 'ఉదయం 1వ మేత (6 AM)',
        ),
        MealScheduleItem(
          mealNumber: 2,
          mealTime: '11:00 AM',
          percentShare: 0.30,
          feedKg: meal2Kg,
          teluguLabel: 'మధ్యాహ్నం 2వ మేత (11 AM)',
        ),
        MealScheduleItem(
          mealNumber: 3,
          mealTime: '04:00 PM',
          percentShare: 0.30,
          feedKg: meal3Kg,
          teluguLabel: 'సాయంత్రం 3వ మేత (4 PM)',
        ),
        MealScheduleItem(
          mealNumber: 4,
          mealTime: '09:00 PM',
          percentShare: 0.20,
          feedKg: meal4Kg,
          teluguLabel: 'రాత్రి 4వ మేత (9 PM)',
        ),
      ];

  Map<String, dynamic> toJson() => {
        'biomassKg': biomassKg,
        'feedingRate': feedingRate,
        'baseDailyFeedKg': baseDailyFeedKg,
        'tempFactor': tempFactor,
        'trayFactor': trayFactor,
        'adjustedDailyFeedKg': adjustedDailyFeedKg,
        'meal1Kg': meal1Kg,
        'meal2Kg': meal2Kg,
        'meal3Kg': meal3Kg,
        'meal4Kg': meal4Kg,
        'mealsTotal': mealsTotal,
        'mealSchedule': mealSchedule.map((m) => m.toJson()).toList(),
      };

  @override
  String toString() =>
      'DailyFeedPlan(Biomass: ${biomassKg.toStringAsFixed(1)} kg, Rate: ${(feedingRate * 100).toStringAsFixed(2)}%, AdjustedFeed: ${adjustedDailyFeedKg.toStringAsFixed(2)} kg)';
}

/// Check-tray physical inspection status after 1.5 - 2 hours of feeding.
enum CheckTrayStatus {
  /// Check tray completely empty -> shrimp underfed, increase ration (+10%).
  clean,

  /// Minimal crumbs / optimal consumption -> adjust slightly (+5% to +10%).
  trace,

  /// Expected normal consumption -> slight routine reduction (-10%).
  normal,

  /// Heavy leftovers remaining -> reduce ration (-15%).
  heavy,

  /// Feed completely untouched -> emergency hold / reduce ration (-20%).
  uneaten,
}

/// Intelligent Bio-Energetic Feed AI Engine for Penaeus vannamei & Monodon aquaculture.
///
/// Implements:
/// - Biomass calculation: `(Density [pcs/m²] * Area [m²] * SurvivalRate * (ABW [g] / 1000))`
/// - DOC-based feeding rate curve: `clamp(0.08 - (DOC * 0.0005), 0.03, 0.08)`
/// - Temperature adjustment factors: `T < 24°C: 0.85; 24°C <= T <= 32°C: 1.00; T > 32°C: 0.90`
/// - Check-tray feedback adjustments: `clamp(1.0 + trayAdjustment, 0.80, 1.10)`
/// - 4-Meal daily distribution: 20% (6 AM), 30% (11 AM), 30% (4 PM), 20% (9 PM).
class FeedAIService {
  const FeedAIService();

  /// Calculates total live shrimp biomass in kg.
  ///
  /// Formula:
  /// `Biomass (kg) = (Stocking Density [pcs/m²] * Pond Area [m²] * Survival Rate * (ABW [g] / 1000))`
  ///
  /// [areaHa] is the pond surface area in hectares (1 ha = 10,000 m²).
  /// Safely handles zero or negative inputs, returning 0.0 kg without throwing or producing NaN.
  double calculateBiomass({
    required double density,
    required double areaHa,
    required double survivalRate,
    required double abw,
  }) {
    if (density <= 0 || areaHa <= 0 || survivalRate <= 0 || abw <= 0) {
      return 0.0;
    }
    final areaSqMeters = areaHa * 10000.0;
    return calculateBiomassFromSqMeters(
      density: density,
      areaM2: areaSqMeters,
      survivalRate: survivalRate,
      abw: abw,
    );
  }

  /// Calculates total live shrimp biomass in kg given pond area directly in square meters.
  double calculateBiomassFromSqMeters({
    required double density,
    required double areaM2,
    required double survivalRate,
    required double abw,
  }) {
    if (density <= 0 || areaM2 <= 0 || survivalRate <= 0 || abw <= 0) {
      return 0.0;
    }
    // Normalize survival rate if given as percentage (e.g. 85 -> 0.85)
    final normalizedSurvival =
        survivalRate > 1.0 ? (survivalRate / 100.0).clamp(0.0, 1.0) : survivalRate.clamp(0.0, 1.0);

    final totalCount = density * areaM2;
    final liveCount = totalCount * normalizedSurvival;
    final biomassKg = (liveCount * abw) / 1000.0;

    return biomassKg.isNaN || biomassKg.isInfinite ? 0.0 : biomassKg;
  }

  /// Calculates DOC-dependent feeding rate percentage clamped between 3.0% (0.03) and 8.0% (0.08).
  ///
  /// Formula: `clamp(0.08 - (DOC * 0.0005), 0.03, 0.08)`
  /// - At DOC 0 (stocking): 8.0% body weight daily.
  /// - At DOC 40: 6.0% body weight daily.
  /// - At DOC 100+: 3.0% body weight daily.
  double calculateFeedingRate(int doc) {
    if (doc < 0) doc = 0;
    final baseRate = 0.08 - (doc * 0.0005);
    return baseRate.clamp(0.03, 0.08);
  }

  /// Calculates water temperature adjustment factor $F_T$:
  /// - `T < 24.0°C` -> `0.85` (Reduced metabolic rate & digestion)
  /// - `24.0°C <= T <= 32.0°C` -> `1.00` (Optimal growth window)
  /// - `T > 32.0°C` -> `0.90` (Heat stress, high oxygen demand, feed decay risk)
  double calculateTempFactor(double temperature) {
    if (temperature < 24.0) {
      return 0.85;
    } else if (temperature <= 32.0) {
      return 1.00;
    } else {
      return 0.90;
    }
  }

  /// Calculates check-tray adjustment factor clamped strictly to `[0.80, 1.10]`.
  ///
  /// [trayAdjustment] represents the percentage adjustment as a signed decimal:
  /// - `-0.20` -> `0.80` (-20% feed cut)
  /// - `+0.10` -> `1.10` (+10% feed boost)
  /// - `null` -> `1.00` (No adjustment)
  double calculateTrayFactor(double? trayAdjustment) {
    if (trayAdjustment == null) return 1.00;
    return (1.0 + trayAdjustment).clamp(0.80, 1.10);
  }

  /// Converts a [CheckTrayStatus] enum into a standard adjustment delta decimal.
  double trayAdjustmentFromStatus(CheckTrayStatus status) {
    switch (status) {
      case CheckTrayStatus.clean:
        return -0.20; // Underfed / fast consumption
      case CheckTrayStatus.trace:
        return 0.10; // Optimal / healthy appetite
      case CheckTrayStatus.normal:
        return -0.10; // Standard maintenance
      case CheckTrayStatus.heavy:
        return -0.15; // Leftover feed in tray
      case CheckTrayStatus.uneaten:
        return -0.20; // Emergency reduction / stress
    }
  }

  /// Comprehensive bio-energetic daily feed calculation with 4-meal schedule.
  ///
  /// Parameters:
  /// - [density]: Stocking density in pcs/m² (e.g. 40 - 60).
  /// - [areaHa]: Pond water spread area in hectares (e.g. 1.0).
  /// - [survivalRate]: Estimated survival rate decimal (e.g. 0.85 for 85%).
  /// - [abw]: Average Body Weight in grams (e.g. 16.5).
  /// - [doc]: Days of Culture (e.g. 45).
  /// - [temperature]: Current pond water temperature in °C.
  /// - [trayAdjustment]: Optional signed adjustment decimal (-0.20 to +0.10).
  /// - [trayStatus]: Optional enum specifying check tray observation.
  DailyFeedPlan calculateDailyFeed({
    required double density,
    required double areaHa,
    required double survivalRate,
    required double abw,
    required int doc,
    required double temperature,
    double? trayAdjustment,
    CheckTrayStatus? trayStatus,
  }) {
    final biomass = calculateBiomass(
      density: density,
      areaHa: areaHa,
      survivalRate: survivalRate,
      abw: abw,
    );

    final feedingRate = calculateFeedingRate(doc);
    final baseFeed = biomass * feedingRate;
    final tempFactor = calculateTempFactor(temperature);

    final effectiveTrayAdjustment =
        trayAdjustment ?? (trayStatus != null ? trayAdjustmentFromStatus(trayStatus) : null);
    final trayFactor = calculateTrayFactor(effectiveTrayAdjustment);

    final adjustedDailyFeed = baseFeed * tempFactor * trayFactor;

    // 4-Meal Split:
    // Meal 1 (06:00 AM): 20%
    // Meal 2 (11:00 AM): 30%
    // Meal 3 (04:00 PM): 30%
    // Meal 4 (09:00 PM): 20%
    final meal1 = adjustedDailyFeed * 0.20;
    final meal2 = adjustedDailyFeed * 0.30;
    final meal3 = adjustedDailyFeed * 0.30;
    final meal4 = adjustedDailyFeed * 0.20;

    return DailyFeedPlan(
      biomassKg: biomass,
      feedingRate: feedingRate,
      baseDailyFeedKg: baseFeed,
      tempFactor: tempFactor,
      trayFactor: trayFactor,
      adjustedDailyFeedKg: adjustedDailyFeed,
      meal1Kg: meal1,
      meal2Kg: meal2,
      meal3Kg: meal3,
      meal4Kg: meal4,
    );
  }

  /// Calculates Food Conversion Ratio (FCR).
  ///
  /// `FCR = Total Feed Distributed (kg) / Total Harvested Biomass (kg)`
  /// Ideal Vannamei FCR is between 1.1 and 1.4.
  double calculateFcr({
    required double totalFeedUsedKg,
    required double biomassHarvestedKg,
  }) {
    if (biomassHarvestedKg <= 0 || totalFeedUsedKg <= 0) return 0.0;
    final fcr = totalFeedUsedKg / biomassHarvestedKg;
    return fcr.isNaN || fcr.isInfinite ? 0.0 : fcr;
  }

  /// Calculates Average Daily Growth (ADG) in grams per day.
  ///
  /// `ADG = (Current ABW [g] - Previous ABW [g]) / Elapsed Days`
  double calculateAdg({
    required double currentAbw,
    required double previousAbw,
    required int days,
  }) {
    if (days <= 0 || currentAbw < previousAbw) return 0.0;
    final adg = (currentAbw - previousAbw) / days;
    return adg.isNaN || adg.isInfinite ? 0.0 : adg;
  }
}
