use serde::{Deserialize, Serialize};

/// Single meal allocation item in the 4-meal daily feeding schedule.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MealScheduleItem {
    pub meal_number: usize,
    pub meal_time: String,
    pub percent_share: f64,
    pub feed_kg: f64,
    pub telugu_label: String,
}

/// Comprehensive daily feed recommendation result calculated by Bio-Energetic Feed AI.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DailyFeedPlan {
    /// Total estimated live shrimp biomass in kg.
    pub biomass_kg: f64,
    /// DOC/ABW-dependent feeding rate percentage as a decimal (0.018 - 0.08).
    pub feeding_rate: f64,
    /// Baseline daily feed requirement before environmental factors in kg.
    pub base_daily_feed_kg: f64,
    /// Water temperature adjustment factor (0.85, 1.00, or 0.90).
    pub temp_factor: f64,
    /// Check-tray consumption adjustment factor (strictly clamped between 0.80 and 1.10).
    pub tray_factor: f64,
    /// Final adjusted daily feed ration in kg.
    pub adjusted_daily_feed_kg: f64,
    /// Alias for adjusted_daily_feed_kg for CLI compatibility.
    pub daily_total_kg: f64,
    /// Meal 1 — 06:00 AM (20% share) in kg.
    pub meal1_kg: f64,
    /// Meal 2 — 11:00 AM (30% share) in kg.
    pub meal2_kg: f64,
    /// Meal 3 — 04:00 PM (30% share) in kg.
    pub meal3_kg: f64,
    /// Meal 4 — 09:00 PM (20% share) in kg.
    pub meal4_kg: f64,
}

impl DailyFeedPlan {
    /// Total sum of all 4 meals in kg.
    pub fn meals_total(&self) -> f64 {
        self.meal1_kg + self.meal2_kg + self.meal3_kg + self.meal4_kg
    }

    /// Estimated daily feed cost in INR at standard feed rate (default ₹92/kg).
    pub fn estimated_daily_cost_inr(&self, feed_price_per_kg: Option<f64>) -> f64 {
        let price = feed_price_per_kg.unwrap_or(92.0);
        self.adjusted_daily_feed_kg * price
    }

    /// Returns structured list of the 4 scheduled meals.
    pub fn meal_schedule(&self) -> Vec<MealScheduleItem> {
        vec![
            MealScheduleItem {
                meal_number: 1,
                meal_time: "06:00 AM".to_string(),
                percent_share: 0.20,
                feed_kg: self.meal1_kg,
                telugu_label: "ఉదయం 1వ మేత (6 AM)".to_string(),
            },
            MealScheduleItem {
                meal_number: 2,
                meal_time: "11:00 AM".to_string(),
                percent_share: 0.30,
                feed_kg: self.meal2_kg,
                telugu_label: "మధ్యాహ్నం 2వ మేత (11 AM)".to_string(),
            },
            MealScheduleItem {
                meal_number: 3,
                meal_time: "04:00 PM".to_string(),
                percent_share: 0.30,
                feed_kg: self.meal3_kg,
                telugu_label: "సాయంత్రం 3వ మేత (4 PM)".to_string(),
            },
            MealScheduleItem {
                meal_number: 4,
                meal_time: "09:00 PM".to_string(),
                percent_share: 0.20,
                feed_kg: self.meal4_kg,
                telugu_label: "రాత్రి 4వ మేత (9 PM)".to_string(),
            },
        ]
    }
}

/// Check-tray physical inspection status after 1.5 - 2 hours of feeding.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum CheckTrayStatus {
    /// Check tray completely empty -> shrimp hungry, increase ration (+10%).
    Clean,
    /// Minimal crumbs / optimal consumption -> slight increase (+5%).
    Trace,
    /// Expected normal consumption -> maintain ration (0%).
    Normal,
    /// Heavy leftovers remaining -> reduce ration (-15%).
    Heavy,
    /// Feed completely untouched -> emergency hold / reduce ration (-20%).
    Uneaten,
}

/// Intelligent Bio-Energetic Feed AI Engine for Penaeus vannamei & Monodon aquaculture.
pub struct FeedAiEngine;

impl FeedAiEngine {
    /// Calculates total live shrimp biomass in kg.
    ///
    /// Formula:
    /// `Biomass (kg) = (Stocking Density [pcs/m²] * Pond Area [m²] * Survival Rate * (ABW [g] / 1000))`
    ///
    /// [area_ha] is the pond surface area in hectares (1 ha = 10,000 m²).
    /// Safely handles zero or negative inputs, returning 0.0 kg without producing NaN.
    pub fn calculate_biomass(
        density: f64,
        area_ha: f64,
        survival_rate: f64,
        abw: f64,
    ) -> f64 {
        if density <= 0.0 || area_ha <= 0.0 || survival_rate <= 0.0 || abw <= 0.0 {
            return 0.0;
        }
        let area_m2 = area_ha * 10_000.0;
        Self::calculate_biomass_from_sq_meters(density, area_m2, survival_rate, abw)
    }

    /// Calculates total live shrimp biomass in kg given pond area directly in square meters.
    pub fn calculate_biomass_from_sq_meters(
        density: f64,
        area_m2: f64,
        survival_rate: f64,
        abw: f64,
    ) -> f64 {
        if density <= 0.0 || area_m2 <= 0.0 || survival_rate <= 0.0 || abw <= 0.0 {
            return 0.0;
        }
        // Normalize survival rate if given as percentage (e.g. 85 -> 0.85)
        let normalized_survival = if survival_rate > 1.0 {
            (survival_rate / 100.0).clamp(0.0, 1.0)
        } else {
            survival_rate.clamp(0.0, 1.0)
        };

        let total_count = density * area_m2;
        let live_count = total_count * normalized_survival;
        let biomass_kg = (live_count * abw) / 1000.0;

        if biomass_kg.is_nan() || biomass_kg.is_infinite() {
            0.0
        } else {
            biomass_kg
        }
    }

    /// Calculates DOC-dependent feeding rate percentage clamped between 3.0% (0.03) and 8.0% (0.08).
    ///
    /// Formula: `clamp(0.08 - (DOC * 0.0005), 0.03, 0.08)`
    pub fn calculate_feeding_rate(doc: i32) -> f64 {
        let safe_doc = doc.max(0) as f64;
        let base_rate = 0.08 - (safe_doc * 0.0005);
        base_rate.clamp(0.03, 0.08)
    }

    /// ICAR-CIBA & CP/Avanti Bio-Energetic Finisher Curve that accounts for both DOC and large ABW (>22g).
    ///
    /// When shrimp exceed 22g, metabolic feed demand per gram of body weight drops
    /// from 3.0% down to 1.8% (at 34g+) to prevent bottom sludge and ammonia spikes.
    pub fn calculate_bioenergetic_feeding_rate(doc: i32, abw_grams: f64) -> f64 {
        let doc_rate = Self::calculate_feeding_rate(doc);
        if abw_grams <= 22.0 {
            return doc_rate;
        }
        // Linearly taper from 3.0% at 22g down to 1.8% at 34g+
        let excess_grams = (abw_grams - 22.0).clamp(0.0, 12.0);
        let abw_tapered_rate = (0.030 - (excess_grams * 0.001)).clamp(0.018, 0.030);
        if abw_tapered_rate < doc_rate {
            abw_tapered_rate
        } else {
            doc_rate
        }
    }

    /// Calculates water temperature adjustment factor F_T:
    /// - `T < 24.0°C` -> `0.85` (Reduced metabolic rate & digestion)
    /// - `24.0°C <= T <= 32.0°C` -> `1.00` (Optimal growth window)
    /// - `T > 32.0°C` -> `0.90` (Heat stress, high oxygen demand)
    pub fn calculate_temp_factor(temperature: f64) -> f64 {
        if temperature < 24.0 {
            0.85
        } else if temperature <= 32.0 {
            1.00
        } else {
            0.90
        }
    }

    /// Calculates check-tray adjustment factor clamped strictly to `[0.80, 1.10]`.
    pub fn calculate_tray_factor(tray_adjustment: Option<f64>) -> f64 {
        match tray_adjustment {
            Some(adj) => (1.0 + adj).clamp(0.80, 1.10),
            None => 1.00,
        }
    }

    /// Converts a [CheckTrayStatus] enum into a standard adjustment delta decimal.
    pub fn tray_adjustment_from_status(status: CheckTrayStatus) -> f64 {
        match status {
            CheckTrayStatus::Clean => 0.10,    // +10%
            CheckTrayStatus::Trace => 0.05,    // +5%
            CheckTrayStatus::Normal => 0.00,   // 0%
            CheckTrayStatus::Heavy => -0.15,   // -15%
            CheckTrayStatus::Uneaten => -0.20, // -20%
        }
    }

    /// Comprehensive bio-energetic daily feed calculation with 4-meal schedule.
    #[allow(clippy::too_many_arguments)]
    pub fn calculate_daily_feed(
        density: f64,
        area_ha: f64,
        survival_rate: f64,
        abw: f64,
        doc: i32,
        temperature: f64,
        tray_adjustment: Option<f64>,
        tray_status: Option<CheckTrayStatus>,
        apply_large_shrimp_curve: bool,
    ) -> DailyFeedPlan {
        let biomass = Self::calculate_biomass(density, area_ha, survival_rate, abw);
        let feeding_rate = if apply_large_shrimp_curve {
            Self::calculate_bioenergetic_feeding_rate(doc, abw)
        } else {
            Self::calculate_feeding_rate(doc)
        };
        let base_feed = biomass * feeding_rate;
        let temp_factor = Self::calculate_temp_factor(temperature);

        let effective_tray_adj = tray_adjustment
            .or_else(|| tray_status.map(Self::tray_adjustment_from_status));
        let tray_factor = Self::calculate_tray_factor(effective_tray_adj);

        let adjusted_daily_feed = base_feed * temp_factor * tray_factor;

        // 4-Meal Diurnal Split:
        // Meal 1 (06:00 AM): 20%
        // Meal 2 (11:00 AM): 30%
        // Meal 3 (04:00 PM): 30%
        // Meal 4 (09:00 PM): 20%
        let meal1 = adjusted_daily_feed * 0.20;
        let meal2 = adjusted_daily_feed * 0.30;
        let meal3 = adjusted_daily_feed * 0.30;
        let meal4 = adjusted_daily_feed * 0.20;

        DailyFeedPlan {
            biomass_kg: biomass,
            feeding_rate,
            base_daily_feed_kg: base_feed,
            temp_factor,
            tray_factor,
            adjusted_daily_feed_kg: adjusted_daily_feed,
            daily_total_kg: adjusted_daily_feed,
            meal1_kg: meal1,
            meal2_kg: meal2,
            meal3_kg: meal3,
            meal4_kg: meal4,
        }
    }
}

/// Context for feed ration calculation used in CLI and FFI.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeedingContext {
    pub doc: u32,
    pub biomass_kg: f64,
    pub temperature_c: f64,
    pub check_tray_status: String,
    pub previous_tray_leftover_pct: f64,
}

/// BioFeedEngine adapter for CLI and service integration.
pub struct BioFeedEngine;

impl BioFeedEngine {
    pub fn calculate_ration(ctx: &FeedingContext) -> DailyFeedPlan {
        let status = match ctx.check_tray_status.to_lowercase().as_str() {
            "clean" => CheckTrayStatus::Clean,
            "trace" => CheckTrayStatus::Trace,
            "heavy" => CheckTrayStatus::Heavy,
            "uneaten" => CheckTrayStatus::Uneaten,
            _ => CheckTrayStatus::Normal,
        };
        let doc = ctx.doc as i32;
        let rate = FeedAiEngine::calculate_feeding_rate(doc);
        let base_feed = ctx.biomass_kg * rate;
        let temp_factor = FeedAiEngine::calculate_temp_factor(ctx.temperature_c);
        let tray_factor = FeedAiEngine::calculate_tray_factor(Some(FeedAiEngine::tray_adjustment_from_status(status)));
        let adjusted_feed = base_feed * temp_factor * tray_factor;
        let m1 = adjusted_feed * 0.20;
        let m2 = adjusted_feed * 0.30;
        let m3 = adjusted_feed * 0.30;
        let m4 = adjusted_feed * 0.20;

        DailyFeedPlan {
            biomass_kg: ctx.biomass_kg,
            feeding_rate: rate,
            base_daily_feed_kg: base_feed,
            temp_factor,
            tray_factor,
            adjusted_daily_feed_kg: adjusted_feed,
            daily_total_kg: adjusted_feed,
            meal1_kg: m1,
            meal2_kg: m2,
            meal3_kg: m3,
            meal4_kg: m4,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_biomass_calculation() {
        // 50 pcs/m², 1.0 ha (10,000 m²), 85% survival, 16.5g ABW
        // Total pcs: 500,000 * 0.85 = 425,000 shrimp
        // Biomass = 425,000 * 16.5 / 1000 = 7012.5 kg
        let biomass = FeedAiEngine::calculate_biomass(50.0, 1.0, 0.85, 16.5);
        assert!((biomass - 7012.5).abs() < 1e-6);

        // Zero or negative inputs safely produce 0.0
        assert_eq!(FeedAiEngine::calculate_biomass(0.0, 1.0, 0.85, 16.5), 0.0);
        assert_eq!(FeedAiEngine::calculate_biomass(50.0, -1.0, 0.85, 16.5), 0.0);
        assert_eq!(FeedAiEngine::calculate_biomass(50.0, 1.0, 0.0, 16.5), 0.0);
        assert_eq!(FeedAiEngine::calculate_biomass(50.0, 1.0, 0.85, -5.0), 0.0);
    }

    #[test]
    fn test_feeding_rate_clamping() {
        // DOC 0 -> 0.08
        assert_eq!(FeedAiEngine::calculate_feeding_rate(0), 0.08);
        // DOC 40 -> 0.08 - (40 * 0.0005) = 0.06
        assert_eq!(FeedAiEngine::calculate_feeding_rate(40), 0.06);
        // DOC 100 -> 0.08 - (100 * 0.0005) = 0.03
        assert_eq!(FeedAiEngine::calculate_feeding_rate(100), 0.03);
        // DOC 150 -> clamped to 0.03
        assert_eq!(FeedAiEngine::calculate_feeding_rate(150), 0.03);
        // Negative DOC -> clamped to 0.08
        assert_eq!(FeedAiEngine::calculate_feeding_rate(-10), 0.08);
    }

    #[test]
    fn test_large_shrimp_finisher_curve() {
        // ABW <= 22g uses normal DOC rate
        let rate_small = FeedAiEngine::calculate_bioenergetic_feeding_rate(60, 18.0);
        assert_eq!(rate_small, FeedAiEngine::calculate_feeding_rate(60));

        // ABW > 22g tapers down towards 0.018
        let rate_large = FeedAiEngine::calculate_bioenergetic_feeding_rate(90, 30.0);
        assert!(rate_large <= 0.030);
        assert!(rate_large >= 0.018);
    }

    #[test]
    fn test_temperature_factors() {
        assert_eq!(FeedAiEngine::calculate_temp_factor(22.0), 0.85);
        assert_eq!(FeedAiEngine::calculate_temp_factor(23.9), 0.85);
        assert_eq!(FeedAiEngine::calculate_temp_factor(24.0), 1.00);
        assert_eq!(FeedAiEngine::calculate_temp_factor(28.0), 1.00);
        assert_eq!(FeedAiEngine::calculate_temp_factor(32.0), 1.00);
        assert_eq!(FeedAiEngine::calculate_temp_factor(32.1), 0.90);
        assert_eq!(FeedAiEngine::calculate_temp_factor(35.0), 0.90);
    }

    #[test]
    fn test_check_tray_factors_and_clamping() {
        assert_eq!(FeedAiEngine::calculate_tray_factor(None), 1.00);
        assert_eq!(FeedAiEngine::calculate_tray_factor(Some(0.0)), 1.00);
        assert_eq!(FeedAiEngine::calculate_tray_factor(Some(0.10)), 1.10);
        assert_eq!(FeedAiEngine::calculate_tray_factor(Some(0.25)), 1.10); // Clamped at 1.10
        assert_eq!(FeedAiEngine::calculate_tray_factor(Some(-0.15)), 0.85);
        assert_eq!(FeedAiEngine::calculate_tray_factor(Some(-0.35)), 0.80); // Clamped at 0.80

        assert_eq!(
            FeedAiEngine::tray_adjustment_from_status(CheckTrayStatus::Clean),
            0.10
        );
        assert_eq!(
            FeedAiEngine::tray_adjustment_from_status(CheckTrayStatus::Uneaten),
            -0.20
        );
    }

    #[test]
    fn test_comprehensive_daily_feed_plan() {
        let plan = FeedAiEngine::calculate_daily_feed(
            50.0,
            1.0,
            0.85,
            16.5,
            60,
            28.5,
            None,
            Some(CheckTrayStatus::Normal),
            false,
        );

        assert!((plan.biomass_kg - 7012.5).abs() < 1e-6);
        assert_eq!(plan.temp_factor, 1.00);
        assert_eq!(plan.tray_factor, 1.00);
        assert!((plan.meals_total() - plan.adjusted_daily_feed_kg).abs() < 1e-6);

        let schedule = plan.meal_schedule();
        assert_eq!(schedule.len(), 4);
        assert_eq!(schedule[0].percent_share, 0.20);
        assert_eq!(schedule[1].percent_share, 0.30);
        assert_eq!(schedule[2].percent_share, 0.30);
        assert_eq!(schedule[3].percent_share, 0.20);

        let cost = plan.estimated_daily_cost_inr(Some(100.0));
        assert!((cost - (plan.adjusted_daily_feed_kg * 100.0)).abs() < 1e-6);
    }
}
