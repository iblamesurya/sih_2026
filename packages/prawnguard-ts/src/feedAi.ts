/**
 * Single meal allocation item in the 4-meal daily feeding schedule.
 */
export interface MealScheduleItem {
  mealNumber: number;
  mealTime: string;
  percentShare: number;
  feedKg: number;
  teluguLabel: string;
}

/**
 * Check-tray physical inspection status after 1.5 - 2 hours of feeding.
 */
export type CheckTrayStatus = 'clean' | 'trace' | 'normal' | 'heavy' | 'uneaten';

/**
 * Comprehensive daily feed recommendation result calculated by Bio-Energetic Feed AI.
 */
export interface DailyFeedPlan {
  /** Total estimated live shrimp biomass in kg. */
  biomassKg: number;
  /** DOC/ABW-dependent feeding rate percentage as a decimal (0.018 - 0.08). */
  feedingRate: number;
  /** Baseline daily feed requirement before environmental factors in kg. */
  baseDailyFeedKg: number;
  /** Water temperature adjustment factor (0.85, 1.00, or 0.90). */
  tempFactor: number;
  /** Check-tray consumption adjustment factor (strictly clamped between 0.80 and 1.10). */
  trayFactor: number;
  /** Final adjusted daily feed ration in kg. */
  adjustedDailyFeedKg: number;
  /** Alias for adjustedDailyFeedKg for CLI / API compatibility. */
  dailyTotalKg: number;
  /** Meal 1 — 06:00 AM (20% share) in kg. */
  meal1Kg: number;
  /** Meal 2 — 11:00 AM (30% share) in kg. */
  meal2Kg: number;
  /** Meal 3 — 04:00 PM (30% share) in kg. */
  meal3Kg: number;
  /** Meal 4 — 09:00 PM (20% share) in kg. */
  meal4Kg: number;
  /** Sum of all 4 scheduled meals in kg. */
  mealsTotal: number;
  /** Structured list of the 4 scheduled meals. */
  mealSchedule: MealScheduleItem[];
}

/**
 * Feeding Context object for quick ration calculations.
 */
export interface FeedingContext {
  doc: number;
  biomassKg: number;
  temperatureC: number;
  checkTrayStatus?: CheckTrayStatus | string;
  previousTrayLeftoverPct?: number;
}

/**
 * Parameters for the full comprehensive daily feed calculation.
 */
export interface CalculateFeedParams {
  density: number;
  areaHa: number;
  survivalRate: number;
  abw: number;
  doc: number;
  temperature: number;
  trayAdjustment?: number;
  trayStatus?: CheckTrayStatus;
  applyLargeShrimpCurve?: boolean;
}

/**
 * Intelligent Bio-Energetic Feed AI Engine for Penaeus vannamei & Monodon aquaculture.
 */
export class FeedAiEngine {
  /**
   * Calculates total live shrimp biomass in kg.
   *
   * Formula:
   * Biomass (kg) = (Stocking Density [pcs/m²] * Pond Area [m²] * Survival Rate * (ABW [g] / 1000))
   */
  static calculateBiomass(
    density: number,
    areaHa: number,
    survivalRate: number,
    abw: number
  ): number {
    if (density <= 0 || areaHa <= 0 || survivalRate <= 0 || abw <= 0) {
      return 0.0;
    }
    const areaM2 = areaHa * 10000.0;
    return this.calculateBiomassFromSqMeters(density, areaM2, survivalRate, abw);
  }

  /**
   * Calculates total live shrimp biomass in kg given pond area directly in square meters.
   */
  static calculateBiomassFromSqMeters(
    density: number,
    areaM2: number,
    survivalRate: number,
    abw: number
  ): number {
    if (density <= 0 || areaM2 <= 0 || survivalRate <= 0 || abw <= 0) {
      return 0.0;
    }
    const normalizedSurvival =
      survivalRate > 1.0 ? Math.min(Math.max(survivalRate / 100.0, 0.0), 1.0) : Math.min(Math.max(survivalRate, 0.0), 1.0);

    const totalCount = density * areaM2;
    const liveCount = totalCount * normalizedSurvival;
    const biomassKg = (liveCount * abw) / 1000.0;

    return Number.isFinite(biomassKg) ? Math.round(biomassKg * 100) / 100 : 0.0;
  }

  /**
   * Calculates DOC-dependent feeding rate percentage clamped between 3.0% (0.03) and 8.0% (0.08).
   *
   * Formula: clamp(0.08 - (DOC * 0.0005), 0.03, 0.08)
   */
  static calculateFeedingRate(doc: number): number {
    const safeDoc = Math.max(0, doc);
    const baseRate = 0.08 - safeDoc * 0.0005;
    return Math.min(Math.max(baseRate, 0.03), 0.08);
  }

  /**
   * ICAR-CIBA & CP/Avanti Bio-Energetic Finisher Curve that accounts for both DOC and large ABW (>22g).
   */
  static calculateBioEnergeticFeedingRate(doc: number, abwGrams: number): number {
    const docRate = this.calculateFeedingRate(doc);
    if (abwGrams <= 22.0) {
      return docRate;
    }
    const excessGrams = Math.min(Math.max(abwGrams - 22.0, 0.0), 12.0);
    const abwTaperedRate = Math.min(Math.max(0.03 - excessGrams * 0.001, 0.018), 0.03);
    return Math.min(abwTaperedRate, docRate);
  }

  /**
   * Calculates water temperature adjustment factor F_T:
   * - T < 24.0°C -> 0.85 (Reduced metabolic rate & digestion)
   * - 24.0°C <= T <= 32.0°C -> 1.00 (Optimal growth window)
   * - T > 32.0°C -> 0.90 (Heat stress, high oxygen demand)
   */
  static calculateTempFactor(temperature: number): number {
    if (temperature < 24.0) {
      return 0.85;
    } else if (temperature <= 32.0) {
      return 1.0;
    } else {
      return 0.9;
    }
  }

  /**
   * Calculates check-tray adjustment factor clamped strictly to [0.80, 1.10].
   */
  static calculateTrayFactor(trayAdjustment?: number): number {
    if (trayAdjustment === undefined || trayAdjustment === null) {
      return 1.0;
    }
    return Math.min(Math.max(1.0 + trayAdjustment, 0.8), 1.1);
  }

  /**
   * Converts a CheckTrayStatus into a standard adjustment delta decimal.
   */
  static trayAdjustmentFromStatus(status: CheckTrayStatus | string): number {
    switch (status.toLowerCase()) {
      case 'clean':
        return 0.1; // +10%
      case 'trace':
        return 0.05; // +5%
      case 'heavy':
        return -0.15; // -15%
      case 'uneaten':
        return -0.2; // -20%
      case 'normal':
      default:
        return 0.0; // 0%
    }
  }

  /**
   * Comprehensive bio-energetic daily feed calculation with 4-meal schedule.
   */
  static calculateDailyFeed(params: CalculateFeedParams): DailyFeedPlan {
    const biomass = this.calculateBiomass(
      params.density,
      params.areaHa,
      params.survivalRate,
      params.abw
    );

    const feedingRate = params.applyLargeShrimpCurve
      ? this.calculateBioEnergeticFeedingRate(params.doc, params.abw)
      : this.calculateFeedingRate(params.doc);

    const baseDailyFeedKg = Math.round(biomass * feedingRate * 100) / 100;
    const tempFactor = this.calculateTempFactor(params.temperature);

    const effectiveTrayAdj =
      params.trayAdjustment !== undefined
        ? params.trayAdjustment
        : params.trayStatus
        ? this.trayAdjustmentFromStatus(params.trayStatus)
        : undefined;

    const trayFactor = this.calculateTrayFactor(effectiveTrayAdj);

    const adjustedDailyFeedKg =
      Math.round(baseDailyFeedKg * tempFactor * trayFactor * 100) / 100;

    // 4-Meal Diurnal Split:
    // Meal 1 (06:00 AM): 20%
    // Meal 2 (11:00 AM): 30%
    // Meal 3 (04:00 PM): 30%
    // Meal 4 (09:00 PM): 20%
    const meal1Kg = Math.round(adjustedDailyFeedKg * 0.2 * 100) / 100;
    const meal2Kg = Math.round(adjustedDailyFeedKg * 0.3 * 100) / 100;
    const meal3Kg = Math.round(adjustedDailyFeedKg * 0.3 * 100) / 100;
    const meal4Kg = Math.round(adjustedDailyFeedKg * 0.2 * 100) / 100;
    const mealsTotal = Math.round((meal1Kg + meal2Kg + meal3Kg + meal4Kg) * 100) / 100;

    const mealSchedule: MealScheduleItem[] = [
      {
        mealNumber: 1,
        mealTime: '06:00 AM',
        percentShare: 0.2,
        feedKg: meal1Kg,
        teluguLabel: 'ఉదయం 1వ మేత (6 AM)',
      },
      {
        mealNumber: 2,
        mealTime: '11:00 AM',
        percentShare: 0.3,
        feedKg: meal2Kg,
        teluguLabel: 'మధ్యాహ్నం 2వ మేత (11 AM)',
      },
      {
        mealNumber: 3,
        mealTime: '04:00 PM',
        percentShare: 0.3,
        feedKg: meal3Kg,
        teluguLabel: 'సాయంత్రం 3వ మేత (4 PM)',
      },
      {
        mealNumber: 4,
        mealTime: '09:00 PM',
        percentShare: 0.2,
        feedKg: meal4Kg,
        teluguLabel: 'రాత్రి 4వ మేత (9 PM)',
      },
    ];

    return {
      biomassKg: biomass,
      feedingRate: Math.round(feedingRate * 10000) / 10000,
      baseDailyFeedKg,
      tempFactor,
      trayFactor,
      adjustedDailyFeedKg,
      dailyTotalKg: adjustedDailyFeedKg,
      meal1Kg,
      meal2Kg,
      meal3Kg,
      meal4Kg,
      mealsTotal,
      mealSchedule,
    };
  }

  /**
   * Adapter for FeedingContext queries.
   */
  static calculateRation(ctx: FeedingContext): DailyFeedPlan {
    const doc = ctx.doc;
    const rate = this.calculateFeedingRate(doc);
    const baseFeed = Math.round(ctx.biomassKg * rate * 100) / 100;
    const tempFactor = this.calculateTempFactor(ctx.temperatureC);
    const trayAdj = ctx.checkTrayStatus ? this.trayAdjustmentFromStatus(ctx.checkTrayStatus) : 0;
    const trayFactor = this.calculateTrayFactor(trayAdj);
    const adjustedFeed = Math.round(baseFeed * tempFactor * trayFactor * 100) / 100;

    const m1 = Math.round(adjustedFeed * 0.2 * 100) / 100;
    const m2 = Math.round(adjustedFeed * 0.3 * 100) / 100;
    const m3 = Math.round(adjustedFeed * 0.3 * 100) / 100;
    const m4 = Math.round(adjustedFeed * 0.2 * 100) / 100;
    const total = Math.round((m1 + m2 + m3 + m4) * 100) / 100;

    return {
      biomassKg: ctx.biomassKg,
      feedingRate: Math.round(rate * 10000) / 10000,
      baseDailyFeedKg: baseFeed,
      tempFactor,
      trayFactor,
      adjustedDailyFeedKg: adjustedFeed,
      dailyTotalKg: adjustedFeed,
      meal1Kg: m1,
      meal2Kg: m2,
      meal3Kg: m3,
      meal4Kg: m4,
      mealsTotal: total,
      mealSchedule: [
        { mealNumber: 1, mealTime: '06:00 AM', percentShare: 0.2, feedKg: m1, teluguLabel: 'ఉదయం 1వ మేత (6 AM)' },
        { mealNumber: 2, mealTime: '11:00 AM', percentShare: 0.3, feedKg: m2, teluguLabel: 'మధ్యాహ్నం 2వ మేత (11 AM)' },
        { mealNumber: 3, mealTime: '04:00 PM', percentShare: 0.3, feedKg: m3, teluguLabel: 'సాయంత్రం 3వ మేత (4 PM)' },
        { mealNumber: 4, mealTime: '09:00 PM', percentShare: 0.2, feedKg: m4, teluguLabel: 'రాత్రి 4వ మేత (9 PM)' },
      ],
    };
  }
}

/** Alias for CLI & interoperability */
export const BioFeedEngine = FeedAiEngine;
