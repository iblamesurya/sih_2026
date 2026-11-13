/**
 * Comprehensive summary of an ABW camera or physical sampling event.
 */
export interface AbwSampleResult {
  /** Number of individual shrimp specimens measured. */
  sampledCount: number;
  /** Mean rostrum-to-telson body length in cm. */
  meanLengthCm: number;
  /** Average Body Weight (ABW) in grams derived from allometric formula. */
  meanAbwGrams: number;
  /** Commercial count per kilogram (1000 / ABW). */
  countPerKg: number;
  /** Coefficient of variation (CV%) indicating size uniformity. */
  cvPercent: number;
  /** Uniformity category ("Excellent", "Good", "Moderate", "Poor"). */
  uniformityGrade: string;
  /** Days of Culture (DOC) during sampling. */
  doc: number;
  /** Industry benchmark target ABW for this DOC. */
  benchmarkAbwGrams: number;
  /** Percentage deviation from benchmark (+% ahead, -% stunted). */
  growthDeviationPercent: number;
}

/**
 * Allometric & Morphometric Shrimp ABW Engine for Litopenaeus vannamei.
 */
export class AbwEngine {
  /**
   * Standard L. vannamei allometric length-to-weight formula:
   * W (g) = 0.0082 * L(cm)^3.04
   */
  static calculateWeightFromLengthCm(lengthCm: number): number {
    const safeL = Math.min(Math.max(lengthCm, 4.0), 22.0);
    const raw = 0.0082 * Math.pow(safeL, 3.04);
    return Math.round(raw * 100) / 100;
  }

  /**
   * Inverse allometric weight-to-length formula:
   * L (cm) = (W / 0.0082)^(1 / 3.04)
   */
  static calculateLengthCmFromWeight(weightGrams: number): number {
    const safeW = Math.min(Math.max(weightGrams, 1.0), 45.0);
    const rawL = Math.pow(safeW / 0.0082, 1.0 / 3.04);
    const clamped = Math.min(Math.max(rawL, 6.0), 18.0);
    return Math.round(clamped * 10) / 10;
  }

  /**
   * Commercial count per kg:
   * Count = 1000.0 / W (g)
   */
  static calculateCountPerKg(weightGrams: number): number {
    if (weightGrams <= 0) return 0.0;
    return Math.round((1000.0 / weightGrams) * 10) / 10;
  }

  /**
   * Interpolates industry benchmark target ABW (g) for a given DOC.
   */
  static benchmarkAbwForDoc(doc: number): number {
    const d = Math.max(1, doc);
    if (d <= 30) {
      return Math.round(3.5 * (d / 30.0) * 10) / 10;
    } else if (d <= 45) {
      const abw = 3.5 + ((d - 30.0) / 15.0) * (8.0 - 3.5);
      return Math.round(abw * 10) / 10;
    } else if (d <= 60) {
      const abw = 8.0 + ((d - 45.0) / 15.0) * (14.5 - 8.0);
      return Math.round(abw * 10) / 10;
    } else if (d <= 75) {
      const abw = 14.5 + ((d - 60.0) / 15.0) * (20.0 - 14.5);
      return Math.round(abw * 10) / 10;
    } else if (d <= 90) {
      const abw = 20.0 + ((d - 75.0) / 15.0) * (26.0 - 20.0);
      return Math.round(abw * 10) / 10;
    } else {
      const excess = Math.min(Math.max(d - 90.0, 0.0), 30.0);
      const abw = 26.0 + (excess / 15.0) * 6.0;
      return Math.round(abw * 10) / 10;
    }
  }

  /**
   * Evaluates uniformity classification from CV%:
   * - CV < 8.0% -> "Excellent"
   * - CV <= 12.0% -> "Good"
   * - CV <= 18.0% -> "Moderate"
   * - CV > 18.0% -> "Poor"
   */
  static uniformityGradeFromCv(cvPercent: number): string {
    if (cvPercent < 8.0) {
      return 'Excellent (High Uniformity)';
    } else if (cvPercent <= 12.0) {
      return 'Good (Normal Batch Uniformity)';
    } else if (cvPercent <= 18.0) {
      return 'Moderate (Size Variation Detected)';
    } else {
      return 'Poor (High Disparity / Possible Stunting)';
    }
  }

  /**
   * Analyzes an array of individual specimen length measurements (cm) taken from a check tray.
   */
  static analyzeSampling(lengthsCm: number[], doc: number): AbwSampleResult {
    const benchmark = this.benchmarkAbwForDoc(doc);
    if (!lengthsCm || lengthsCm.length === 0) {
      const defaultL = this.calculateLengthCmFromWeight(benchmark);
      return {
        sampledCount: 0,
        meanLengthCm: defaultL,
        meanAbwGrams: benchmark,
        countPerKg: this.calculateCountPerKg(benchmark),
        cvPercent: 0.0,
        uniformityGrade: 'No Samples',
        doc,
        benchmarkAbwGrams: benchmark,
        growthDeviationPercent: 0.0,
      };
    }

    const n = lengthsCm.length;
    const sumLen = lengthsCm.reduce((acc, l) => acc + l, 0);
    const meanLen = sumLen / n;

    // Convert individual lengths to weights
    const weights = lengthsCm.map((l) => this.calculateWeightFromLengthCm(l));
    const sumW = weights.reduce((acc, w) => acc + w, 0);
    const meanAbw = sumW / n;

    // Variance & standard deviation
    const variance =
      weights.reduce((acc, w) => acc + Math.pow(w - meanAbw, 2), 0) / n;
    const stdDev = Math.sqrt(variance);
    const cvPct = meanAbw > 0 ? (stdDev / meanAbw) * 100.0 : 0.0;

    const growthDev =
      benchmark > 0 ? ((meanAbw - benchmark) / benchmark) * 100.0 : 0.0;

    return {
      sampledCount: n,
      meanLengthCm: Math.round(meanLen * 10) / 10,
      meanAbwGrams: Math.round(meanAbw * 100) / 100,
      countPerKg: this.calculateCountPerKg(meanAbw),
      cvPercent: Math.round(cvPct * 10) / 10,
      uniformityGrade: this.uniformityGradeFromCv(cvPct),
      doc,
      benchmarkAbwGrams: benchmark,
      growthDeviationPercent: Math.round(growthDev * 10) / 10,
    };
  }
}

/**
 * Adapter model for CLI and allometric methods.
 */
export class AllometricModel {
  static lengthToWeight(lengthCm: number): number {
    return AbwEngine.calculateWeightFromLengthCm(lengthCm);
  }

  static weightToCount(weightGrams: number): number {
    return Math.round(AbwEngine.calculateCountPerKg(weightGrams));
  }
}
