use crate::models::MarketPrice;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum RegionalHub {
    Bhimavaram,
    Nellore,
    Kaikaluru,
    Kakinada,
}

impl RegionalHub {
    pub fn name(&self) -> &'static str {
        match self {
            RegionalHub::Bhimavaram => "Bhimavaram (West Godavari, AP)",
            RegionalHub::Nellore => "Nellore (Andhra Pradesh)",
            RegionalHub::Kaikaluru => "Kaikaluru (Krishna, AP)",
            RegionalHub::Kakinada => "Kakinada (East Godavari, AP)",
        }
    }

    pub fn code(&self) -> &'static str {
        match self {
            RegionalHub::Bhimavaram => "BVLM",
            RegionalHub::Nellore => "NLR",
            RegionalHub::Kaikaluru => "KKL",
            RegionalHub::Kakinada => "KKD",
        }
    }

    /// Regional price offset in INR per kg relative to baseline Bhimavaram Mandi
    pub fn price_offset(&self) -> f64 {
        match self {
            RegionalHub::Bhimavaram => 0.0,   // Baseline market
            RegionalHub::Nellore => 10.0,      // +₹10 export proximity to Chennai port
            RegionalHub::Kaikaluru => -5.0,    // -₹5 inland transit freight offset
            RegionalHub::Kakinada => 5.0,      // +₹5 direct deepwater seaport terminal
        }
    }

    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Option<Self> {
        let lower = s.to_lowercase();
        if lower.contains("bhima") {
            Some(RegionalHub::Bhimavaram)
        } else if lower.contains("nellore") {
            Some(RegionalHub::Nellore)
        } else if lower.contains("kaik") {
            Some(RegionalHub::Kaikaluru)
        } else if lower.contains("kakinada") {
            Some(RegionalHub::Kakinada)
        } else {
            None
        }
    }
}

/// Commercial Penaeus vannamei count bracket (number of shrimp per kg)
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub enum CountGrade {
    Count20 = 20,
    Count30 = 30,
    Count40 = 40,
    Count50 = 50,
    Count60 = 60,
    Count80 = 80,
    Count100 = 100,
}

impl CountGrade {
    pub fn count(&self) -> u32 {
        *self as u32
    }

    pub fn label(&self) -> &'static str {
        match self {
            CountGrade::Count20 => "20 Count",
            CountGrade::Count30 => "30 Count",
            CountGrade::Count40 => "40 Count",
            CountGrade::Count50 => "50 Count",
            CountGrade::Count60 => "60 Count",
            CountGrade::Count80 => "80 Count",
            CountGrade::Count100 => "100 Count",
        }
    }

    /// Base benchmark price at Bhimavaram Mandi (INR / kg)
    pub fn base_price_inr(&self) -> f64 {
        match self {
            CountGrade::Count20 => 560.0,
            CountGrade::Count30 => 435.0,
            CountGrade::Count40 => 375.0,
            CountGrade::Count50 => 325.0,
            CountGrade::Count60 => 285.0,
            CountGrade::Count80 => 235.0,
            CountGrade::Count100 => 195.0,
        }
    }

    pub fn daily_trend_inr(&self) -> f64 {
        match self {
            CountGrade::Count20 => 15.0,
            CountGrade::Count30 => 10.0,
            CountGrade::Count40 => 5.0,
            CountGrade::Count50 => 0.0,
            CountGrade::Count60 => -5.0,
            CountGrade::Count80 => -5.0,
            CountGrade::Count100 => -10.0,
        }
    }

    pub fn demand(&self) -> &'static str {
        match self {
            CountGrade::Count20 => "Very High (US/EU Export)",
            CountGrade::Count30 => "High (Export Prime)",
            CountGrade::Count40 => "High (Domestic/Export)",
            CountGrade::Count50 => "Moderate",
            CountGrade::Count60 => "Moderate",
            CountGrade::Count80 => "Normal",
            CountGrade::Count100 => "Low",
        }
    }

    /// Resolves nearest standard grade for a raw count per kg
    pub fn from_count(count: u32) -> Self {
        if count <= 25 {
            CountGrade::Count20
        } else if count <= 35 {
            CountGrade::Count30
        } else if count <= 45 {
            CountGrade::Count40
        } else if count <= 55 {
            CountGrade::Count50
        } else if count <= 70 {
            CountGrade::Count60
        } else if count <= 90 {
            CountGrade::Count80
        } else {
            CountGrade::Count100
        }
    }
}

/// Harvest valuation and revenue breakdown
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct HarvestValuation {
    pub hub_name: String,
    pub biomass_kg: f64,
    pub count_per_kg: u32,
    pub matched_grade: String,
    pub price_per_kg: f64,
    pub gross_revenue_inr: f64,
    pub net_revenue_inr: f64,
    pub packing_transport_inr: f64,
    pub mandi_commission_inr: f64,
}

/// Aggregator engine for Mandi farm-gate prices across Andhra Pradesh
pub struct MandiAggregator;

impl MandiAggregator {
    pub const ALL_HUBS: [RegionalHub; 4] = [
        RegionalHub::Bhimavaram,
        RegionalHub::Nellore,
        RegionalHub::Kaikaluru,
        RegionalHub::Kakinada,
    ];

    pub const ALL_GRADES: [CountGrade; 7] = [
        CountGrade::Count20,
        CountGrade::Count30,
        CountGrade::Count40,
        CountGrade::Count50,
        CountGrade::Count60,
        CountGrade::Count80,
        CountGrade::Count100,
    ];

    /// Fetches market price for a specific hub and count grade
    pub fn get_price(hub: RegionalHub, grade: CountGrade) -> MarketPrice {
        let price = grade.base_price_inr() + hub.price_offset();
        MarketPrice {
            id: format!("mandi-{}-{}", hub.code().to_lowercase(), grade.count()),
            hub_name: hub.name().to_string(),
            species: "L. vannamei".to_string(),
            count_grade: grade.label().to_string(),
            count_per_kg: grade.count(),
            price_inr_per_kg: price,
            price_change_inr: grade.daily_trend_inr(),
            demand_level: grade.demand().to_string(),
            effective_date: "2026-11-12".to_string(),
        }
    }

    /// Returns full price matrix for all 4 regional hubs across all count sizes (28 entries)
    pub fn generate_daily_price_sheet() -> Vec<MarketPrice> {
        let mut sheet = Vec::with_capacity(Self::ALL_HUBS.len() * Self::ALL_GRADES.len());
        for hub in Self::ALL_HUBS {
            for grade in Self::ALL_GRADES {
                sheet.push(Self::get_price(hub, grade));
            }
        }
        sheet
    }

    /// Evaluates harvest revenue considering local transport and packing deductions
    pub fn estimate_harvest_revenue(
        biomass_kg: f64,
        count_per_kg: u32,
        hub: RegionalHub,
    ) -> HarvestValuation {
        let grade = CountGrade::from_count(count_per_kg);
        let price_per_kg = grade.base_price_inr() + hub.price_offset();
        let gross = biomass_kg * price_per_kg;

        // Mandi commission standard 1.5% and ice/transport ₹3.0/kg
        let mandi_commission = gross * 0.015;
        let transport_packing = biomass_kg * 3.0;
        let net = gross - mandi_commission - transport_packing;

        HarvestValuation {
            hub_name: hub.name().to_string(),
            biomass_kg,
            count_per_kg,
            matched_grade: grade.label().to_string(),
            price_per_kg,
            gross_revenue_inr: (gross * 100.0).round() / 100.0,
            net_revenue_inr: (net * 100.0).round() / 100.0,
            packing_transport_inr: (transport_packing * 100.0).round() / 100.0,
            mandi_commission_inr: (mandi_commission * 100.0).round() / 100.0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_regional_hub_offsets() {
        let bvlm_30c = MandiAggregator::get_price(RegionalHub::Bhimavaram, CountGrade::Count30);
        let nlr_30c = MandiAggregator::get_price(RegionalHub::Nellore, CountGrade::Count30);
        let kkl_30c = MandiAggregator::get_price(RegionalHub::Kaikaluru, CountGrade::Count30);
        let kkd_30c = MandiAggregator::get_price(RegionalHub::Kakinada, CountGrade::Count30);

        assert_eq!(bvlm_30c.price_inr_per_kg, 435.0);
        assert_eq!(nlr_30c.price_inr_per_kg, 445.0); // +10
        assert_eq!(kkl_30c.price_inr_per_kg, 430.0); // -5
        assert_eq!(kkd_30c.price_inr_per_kg, 440.0); // +5
    }

    #[test]
    fn test_harvest_revenue_estimation() {
        let val = MandiAggregator::estimate_harvest_revenue(
            2500.0, // 2.5 tons
            30,
            RegionalHub::Bhimavaram,
        );

        assert_eq!(val.price_per_kg, 435.0);
        assert_eq!(val.gross_revenue_inr, 1087500.0);
        assert!(val.net_revenue_inr < val.gross_revenue_inr);
    }

    #[test]
    fn test_price_sheet_size() {
        let sheet = MandiAggregator::generate_daily_price_sheet();
        assert_eq!(sheet.len(), 28); // 4 hubs * 7 grades
    }
}
