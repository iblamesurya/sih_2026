use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use crate::models::{Expense, Harvest};

/// Financial category breakdown and expenditure totals.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ExpenseSummary {
    pub total_amount: f64,
    pub category_breakdown: HashMap<String, f64>,
    pub category_percentages: HashMap<String, f64>,
    pub expense_count: usize,
}

impl ExpenseSummary {
    pub fn compute(expenses: &[Expense]) -> Self {
        let mut breakdown: HashMap<String, f64> = HashMap::new();
        let mut total = 0.0;

        for exp in expenses {
            total += exp.amount;
            *breakdown.entry(exp.category.clone()).or_insert(0.0) += exp.amount;
        }

        let mut percentages: HashMap<String, f64> = HashMap::new();
        if total > 0.0 {
            for (cat, amt) in &breakdown {
                percentages.insert(cat.clone(), (amt / total) * 100.0);
            }
        }

        Self {
            total_amount: total,
            category_breakdown: breakdown,
            category_percentages: percentages,
            expense_count: expenses.len(),
        }
    }
}

/// Harvest yield, revenue realization, and profit metrics.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HarvestSummary {
    pub total_biomass_kg: f64,
    pub total_revenue_inr: f64,
    pub average_price_per_kg: f64,
    pub average_count_per_kg: f64,
    pub harvest_count: usize,
    pub net_profit_inr: f64,
    pub profit_margin_percent: f64,
    pub roi_percent: f64,
}

impl HarvestSummary {
    pub fn compute(harvests: &[Harvest], total_expenses: f64) -> Self {
        let mut biomass = 0.0;
        let mut revenue = 0.0;
        let mut count_weighted = 0.0;

        for h in harvests {
            biomass += h.biomass_kg;
            let rev = if h.total_revenue > 0.0 { h.total_revenue } else { h.biomass_kg * h.price_per_kg };
            revenue += rev;
            count_weighted += (h.count_per_kg as f64) * h.biomass_kg;
        }

        let avg_price = if biomass > 0.0 { revenue / biomass } else { 0.0 };
        let avg_count = if biomass > 0.0 { count_weighted / biomass } else { 0.0 };
        let net_profit = revenue - total_expenses;
        let margin = if revenue > 0.0 { (net_profit / revenue) * 100.0 } else { 0.0 };
        let roi = if total_expenses > 0.0 { (net_profit / total_expenses) * 100.0 } else { 0.0 };

        Self {
            total_biomass_kg: biomass,
            total_revenue_inr: revenue,
            average_price_per_kg: avg_price,
            average_count_per_kg: avg_count,
            harvest_count: harvests.len(),
            net_profit_inr: net_profit,
            profit_margin_percent: margin,
            roi_percent: roi,
        }
    }
}

/// FCR (Feed Conversion Ratio) analysis and metabolic efficiency rating.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct FcrAnalysis {
    pub fcr: f64,
    pub total_feed_kg: f64,
    pub total_biomass_kg: f64,
    pub rating: String,      // "Optimal", "Good", "Moderate", "Poor"
    pub recommendation: String,
}

impl FcrAnalysis {
    pub fn compute(total_feed_kg: f64, total_biomass_kg: f64) -> Self {
        let fcr = if total_biomass_kg > 0.0 {
            total_feed_kg / total_biomass_kg
        } else {
            0.0
        };

        let (rating, recommendation) = if fcr <= 1.20 {
            ("Optimal", "Exceptional feed conversion. Biological efficiency peak.")
        } else if fcr <= 1.40 {
            ("Good", "Standard commercial efficiency. Maintain diurnal feeding schedule.")
        } else if fcr <= 1.60 {
            ("Moderate", "Elevated FCR. Inspect check trays and reduce morning ration by 15%.")
        } else {
            ("Poor", "Critical feed wastage or mortality. Immediate check-tray audit required.")
        };

        Self {
            fcr,
            total_feed_kg,
            total_biomass_kg,
            rating: rating.to_string(),
            recommendation: recommendation.to_string(),
        }
    }
}

/// PrawnCredit underwriting and aquaculture credit risk score (300 to 900).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PrawnCreditScore {
    pub score: i32,
    pub tier: String,
    pub max_credit_limit: f64,
    pub monthly_interest_rate: f64,
    pub risk_level: String,
    pub score_factors: HashMap<String, i32>,
}

/// Evaluates PrawnCredit score based on aquaculture operational metrics.
pub struct PrawnCreditEngine;

impl PrawnCreditEngine {
    pub fn evaluate(
        fcr: f64,
        survival_rate: f64,
        roi_percent: f64,
        water_logs_count: usize,
        total_pond_area_ha: f64,
    ) -> PrawnCreditScore {
        let mut factors = HashMap::new();

        // 1. FCR Efficiency Score (0-100 base)
        let fcr_score = if fcr <= 1.25 {
            95
        } else if fcr <= 1.35 {
            88
        } else if fcr <= 1.45 {
            78
        } else if fcr <= 1.60 {
            65
        } else {
            40
        };
        factors.insert("FCR Efficiency".to_string(), fcr_score);

        // 2. Water Telemetry Logging Consistency (0-100 base)
        let log_score = if water_logs_count >= 50 {
            95
        } else if water_logs_count >= 25 {
            85
        } else if water_logs_count >= 10 {
            70
        } else {
            50
        };
        factors.insert("Water Log Consistency".to_string(), log_score);

        // 3. Survival Rate & Biosecurity Predictability (0-100 base)
        let survival_score = if survival_rate >= 0.85 {
            92
        } else if survival_rate >= 0.75 {
            82
        } else if survival_rate >= 0.65 {
            70
        } else {
            45
        };
        factors.insert("Yield Predictability".to_string(), survival_score);

        // 4. Profitability & ROI Performance (0-100 base)
        let roi_score = if roi_percent >= 30.0 {
            95
        } else if roi_percent >= 15.0 {
            85
        } else if roi_percent >= 0.0 {
            70
        } else {
            45
        };
        factors.insert("Profit Margin & ROI".to_string(), roi_score);

        // Weighted Composite Score mapped to 300 - 900
        // Weighting: 35% FCR, 25% Survival, 25% ROI, 15% Logging
        let composite = (fcr_score as f64 * 0.35)
            + (survival_score as f64 * 0.25)
            + (roi_score as f64 * 0.25)
            + (log_score as f64 * 0.15);

        // Map [0, 100] -> [300, 900]
        let scaled_score = (300.0 + (composite / 100.0) * 600.0).round() as i32;
        let score = scaled_score.clamp(300, 900);

        // Determine Tier, Limits, and Interest Rates
        let (tier, risk_level, base_limit_per_ha, interest_rate) = if score >= 750 {
            ("Tier-1 Elite", "Low", 500_000.0, 0.011) // 1.1% per month
        } else if score >= 650 {
            ("Tier-2 Preferred", "Moderate", 350_000.0, 0.014) // 1.4% per month
        } else {
            ("Tier-3 Basic", "High", 200_000.0, 0.018) // 1.8% per month
        };

        let effective_ha = if total_pond_area_ha > 0.0 { total_pond_area_ha } else { 1.0 };
        let max_credit_limit = base_limit_per_ha * effective_ha;

        PrawnCreditScore {
            score,
            tier: tier.to_string(),
            max_credit_limit,
            monthly_interest_rate: interest_rate,
            risk_level: risk_level.to_string(),
            score_factors: factors,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{Expense, Harvest};

    #[test]
    fn test_expense_and_harvest_summaries() {
        let expenses = vec![
            Expense {
                id: "e1".to_string(),
                user_id: None,
                pond_id: "p1".to_string(),
                pond_name: "Pond 1".to_string(),
                category: "feed".to_string(),
                amount: 70_000.0,
                supplier: None,
                notes: None,
                idempotency_key: None,
                expense_date: "2026-09-01".to_string(),
            },
            Expense {
                id: "e2".to_string(),
                user_id: None,
                pond_id: "p1".to_string(),
                pond_name: "Pond 1".to_string(),
                category: "seedPL".to_string(),
                amount: 30_000.0,
                supplier: None,
                notes: None,
                idempotency_key: None,
                expense_date: "2026-09-02".to_string(),
            },
        ];

        let exp_summary = ExpenseSummary::compute(&expenses);
        assert_eq!(exp_summary.total_amount, 100_000.0);
        assert_eq!(exp_summary.category_percentages.get("feed"), Some(&70.0));
        assert_eq!(exp_summary.category_percentages.get("seedPL"), Some(&30.0));

        let harvests = vec![
            Harvest {
                id: "h1".to_string(),
                user_id: None,
                pond_id: "p1".to_string(),
                pond_name: "Pond 1".to_string(),
                harvest_type: "Complete".to_string(),
                biomass_kg: 1000.0,
                count_per_kg: 40,
                price_per_kg: 350.0,
                total_revenue: 350_000.0,
                fcr: 1.3,
                buyer_name: None,
                idempotency_key: None,
                harvest_date: "2026-10-01".to_string(),
            }
        ];

        let hrv_summary = HarvestSummary::compute(&harvests, exp_summary.total_amount);
        assert_eq!(hrv_summary.total_revenue_inr, 350_000.0);
        assert_eq!(hrv_summary.net_profit_inr, 250_000.0);
        assert_eq!(hrv_summary.roi_percent, 250.0);
    }

    #[test]
    fn test_fcr_analysis() {
        let analysis = FcrAnalysis::compute(1300.0, 1000.0);
        assert_eq!(analysis.fcr, 1.3);
        assert_eq!(analysis.rating, "Good");
    }

    #[test]
    fn test_prawn_credit_score_tier1() {
        let credit = PrawnCreditEngine::evaluate(1.22, 0.88, 35.0, 60, 2.0);
        assert!(credit.score >= 750);
        assert_eq!(credit.tier, "Tier-1 Elite");
        assert_eq!(credit.risk_level, "Low");
        assert_eq!(credit.max_credit_limit, 1_000_000.0); // 500k * 2 ha
    }
}
