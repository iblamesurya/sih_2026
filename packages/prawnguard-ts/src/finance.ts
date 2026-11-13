/**
 * PrawnGuard.ai TypeScript Financial & PrawnCredit Engine
 * Expense breakdown, harvest yield realization, FCR biological rating,
 * and 300-900 risk-adjusted aquaculture credit scoring.
 */

import type { Expense, Harvest } from './models.ts';

export interface ExpenseSummary {
  totalAmount: number;
  categoryBreakdown: Record<string, number>;
  categoryPercentages: Record<string, number>;
  expenseCount: number;
}

export function computeExpenseSummary(expenses: Expense[]): ExpenseSummary {
  const breakdown: Record<string, number> = {};
  let total = 0.0;

  for (const exp of expenses) {
    total += exp.amount;
    breakdown[exp.category] = (breakdown[exp.category] ?? 0.0) + exp.amount;
  }

  const percentages: Record<string, number> = {};
  if (total > 0.0) {
    for (const [cat, amt] of Object.entries(breakdown)) {
      percentages[cat] = (amt / total) * 100.0;
    }
  }

  return {
    totalAmount: total,
    categoryBreakdown: breakdown,
    categoryPercentages: percentages,
    expenseCount: expenses.len ?? expenses.length,
  };
}

export interface HarvestSummary {
  totalBiomassKg: number;
  totalRevenueInr: number;
  averagePricePerKg: number;
  averageCountPerKg: number;
  harvestCount: number;
  netProfitInr: number;
  profitMarginPercent: number;
  roiPercent: number;
}

export function computeHarvestSummary(harvests: Harvest[], totalExpenses: number): HarvestSummary {
  let biomass = 0.0;
  let revenue = 0.0;
  let countWeighted = 0.0;

  for (const h of harvests) {
    biomass += h.biomassKg;
    const rev = h.totalRevenue > 0.0 ? h.totalRevenue : h.biomassKg * h.pricePerKg;
    revenue += rev;
    countWeighted += h.countPerKg * h.biomassKg;
  }

  const avgPrice = biomass > 0.0 ? revenue / biomass : 0.0;
  const avgCount = biomass > 0.0 ? countWeighted / biomass : 0.0;
  const netProfit = revenue - totalExpenses;
  const margin = revenue > 0.0 ? (netProfit / revenue) * 100.0 : 0.0;
  const roi = totalExpenses > 0.0 ? (netProfit / totalExpenses) * 100.0 : 0.0;

  return {
    totalBiomassKg: biomass,
    totalRevenueInr: revenue,
    averagePricePerKg: avgPrice,
    averageCountPerKg: avgCount,
    harvestCount: harvests.length,
    netProfitInr: netProfit,
    profitMarginPercent: margin,
    roiPercent: roi,
  };
}

export interface FcrAnalysis {
  fcr: number;
  totalFeedKg: number;
  totalBiomassKg: number;
  rating: 'Optimal' | 'Good' | 'Moderate' | 'Poor';
  recommendation: string;
}

export function computeFcr(totalFeedKg: number, totalBiomassKg: number): FcrAnalysis {
  const fcr = totalBiomassKg > 0.0 ? totalFeedKg / totalBiomassKg : 0.0;

  let rating: 'Optimal' | 'Good' | 'Moderate' | 'Poor';
  let recommendation: string;

  if (fcr <= 1.20) {
    rating = 'Optimal';
    recommendation = 'Exceptional feed conversion. Biological efficiency peak.';
  } else if (fcr <= 1.40) {
    rating = 'Good';
    recommendation = 'Standard commercial efficiency. Maintain diurnal feeding schedule.';
  } else if (fcr <= 1.60) {
    rating = 'Moderate';
    recommendation = 'Elevated FCR. Inspect check trays and reduce morning ration by 15%.';
  } else {
    rating = 'Poor';
    recommendation = 'Critical feed wastage or mortality. Immediate check-tray audit required.';
  }

  return {
    fcr,
    totalFeedKg,
    totalBiomassKg,
    rating,
    recommendation,
  };
}

export interface PrawnCreditScore {
  score: number;
  tier: 'Tier-1 Elite' | 'Tier-2 Preferred' | 'Tier-3 Basic';
  maxCreditLimit: number;
  monthlyInterestRate: number;
  riskLevel: 'Low' | 'Moderate' | 'High';
  scoreFactors: Record<string, number>;
}

export class PrawnCreditEngine {
  public static evaluate(
    fcr: number,
    survivalRate: number,
    roiPercent: number,
    waterLogsCount: number,
    totalPondAreaHa: number
  ): PrawnCreditScore {
    const factors: Record<string, number> = {};

    // 1. FCR Efficiency Score (0-100 base)
    let fcrScore = 40;
    if (fcr <= 1.25) {
      fcrScore = 95;
    } else if (fcr <= 1.35) {
      fcrScore = 88;
    } else if (fcr <= 1.45) {
      fcrScore = 78;
    } else if (fcr <= 1.60) {
      fcrScore = 65;
    }
    factors['FCR Efficiency'] = fcrScore;

    // 2. Water Telemetry Logging Consistency (0-100 base)
    let logScore = 50;
    if (waterLogsCount >= 50) {
      logScore = 95;
    } else if (waterLogsCount >= 25) {
      logScore = 85;
    } else if (waterLogsCount >= 10) {
      logScore = 70;
    }
    factors['Water Log Consistency'] = logScore;

    // 3. Survival Rate & Biosecurity Predictability (0-100 base)
    let survivalScore = 45;
    if (survivalRate >= 0.85) {
      survivalScore = 92;
    } else if (survivalRate >= 0.75) {
      survivalScore = 82;
    } else if (survivalRate >= 0.65) {
      survivalScore = 70;
    }
    factors['Yield Predictability'] = survivalScore;

    // 4. Profitability & ROI Performance (0-100 base)
    let roiScore = 45;
    if (roiPercent >= 30.0) {
      roiScore = 95;
    } else if (roiPercent >= 15.0) {
      roiScore = 85;
    } else if (roiPercent >= 0.0) {
      roiScore = 70;
    }
    factors['Profit Margin & ROI'] = roiScore;

    // Weighted Composite Score mapped to 300 - 900
    // Weighting: 35% FCR, 25% Survival, 25% ROI, 15% Logging
    const composite =
      fcrScore * 0.35 +
      survivalScore * 0.25 +
      roiScore * 0.25 +
      logScore * 0.15;

    const scaledScore = Math.round(300.0 + (composite / 100.0) * 600.0);
    const score = Math.max(300, Math.min(900, scaledScore));

    let tier: 'Tier-1 Elite' | 'Tier-2 Preferred' | 'Tier-3 Basic';
    let riskLevel: 'Low' | 'Moderate' | 'High';
    let baseLimitPerHa = 200_000.0;
    let interestRate = 0.018; // 1.8% per month

    if (score >= 750) {
      tier = 'Tier-1 Elite';
      riskLevel = 'Low';
      baseLimitPerHa = 500_000.0;
      interestRate = 0.011; // 1.1% per month
    } else if (score >= 650) {
      tier = 'Tier-2 Preferred';
      riskLevel = 'Moderate';
      baseLimitPerHa = 350_000.0;
      interestRate = 0.014; // 1.4% per month
    } else {
      tier = 'Tier-3 Basic';
      riskLevel = 'High';
      baseLimitPerHa = 200_000.0;
      interestRate = 0.018; // 1.8% per month
    }

    const effectiveHa = totalPondAreaHa > 0.0 ? totalPondAreaHa : 1.0;
    const maxCreditLimit = baseLimitPerHa * effectiveHa;

    return {
      score,
      tier,
      maxCreditLimit,
      monthlyInterestRate: interestRate,
      riskLevel,
      scoreFactors: factors,
    };
  }
}
