use serde::{Deserialize, Serialize};

/// Pond domain entity representing an active, fallow, or harvested aquaculture pond.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Pond {
    pub id: String,
    pub user_id: String,
    pub farmer_id: Option<String>,
    pub farm_id: Option<String>,
    pub name: String,
    #[serde(default = "default_species")]
    pub species: String,
    #[serde(default = "default_area")]
    pub area_ha: f64,
    #[serde(default = "default_density")]
    pub stocking_density: f64,
    #[serde(default = "default_doc")]
    pub doc: u32,
    pub stocking_date: String,
    #[serde(default = "default_initial_abw")]
    pub initial_abw: f64,
    #[serde(default = "default_current_abw")]
    pub current_abw: f64,
    #[serde(default = "default_survival")]
    pub survival_rate: f64,
    #[serde(default = "default_status")]
    pub status: String,
    #[serde(default = "default_version")]
    pub version: u32,
    pub created_at: Option<String>,
    pub updated_at: Option<String>,
}

fn default_species() -> String { "L. vannamei".to_string() }
fn default_area() -> f64 { 1.0 }
fn default_density() -> f64 { 50.0 }
fn default_doc() -> u32 { 1 }
fn default_initial_abw() -> f64 { 0.02 }
fn default_current_abw() -> f64 { 15.0 }
fn default_survival() -> f64 { 0.85 }
fn default_status() -> String { "Active".to_string() }
fn default_version() -> u32 { 1 }

impl Pond {
    /// Computes estimated total biomass in kg:
    /// Biomass (kg) = area_ha * 10,000 * stocking_density * survival_rate * (current_abw / 1000.0)
    pub fn estimated_biomass_kg(&self) -> f64 {
        let total_shrimp = self.area_ha * 10_000.0 * self.stocking_density * self.survival_rate;
        (total_shrimp * self.current_abw) / 1000.0
    }
}

/// Water quality telemetry reading logged by sensors, voice, or manual entry.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct WaterLog {
    pub id: String,
    pub user_id: Option<String>,
    pub pond_id: String,
    pub ph: Option<f64>,
    pub dissolved_oxygen: Option<f64>,
    pub salinity: Option<f64>,
    pub temperature: Option<f64>,
    pub ammonia: Option<f64>,
    pub alkalinity: Option<f64>,
    pub turbidity_cm: Option<f64>,
    #[serde(default = "default_severity")]
    pub overall_severity: String,
    #[serde(default = "default_source")]
    pub source: String,
    pub idempotency_key: Option<String>,
    pub recorded_at: String,
}

fn default_severity() -> String { "optimal".to_string() }
fn default_source() -> String { "manual".to_string() }

/// Feeding record for daily rations and check-tray observations.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct FeedLog {
    pub id: String,
    pub user_id: Option<String>,
    pub pond_id: String,
    #[serde(default = "default_doc")]
    pub doc: u32,
    #[serde(default)]
    pub biomass_kg: f64,
    #[serde(default)]
    pub feeding_rate: f64,
    #[serde(default)]
    pub daily_feed_kg: f64,
    pub meal_number: Option<u8>,
    pub scheduled_time: Option<String>,
    pub feed_kg: Option<f64>,
    pub percent_share: Option<f64>,
    #[serde(default)]
    pub meal1_kg: f64,
    #[serde(default)]
    pub meal2_kg: f64,
    #[serde(default)]
    pub meal3_kg: f64,
    #[serde(default)]
    pub meal4_kg: f64,
    #[serde(default)]
    pub meal1_completed: bool,
    #[serde(default)]
    pub meal2_completed: bool,
    #[serde(default)]
    pub meal3_completed: bool,
    #[serde(default)]
    pub meal4_completed: bool,
    #[serde(default = "default_tray")]
    pub check_tray_status: String,
    #[serde(default)]
    pub tray_adjustment: f64,
    #[serde(default = "default_temp")]
    pub temperature_c: f64,
    pub idempotency_key: Option<String>,
    pub fed_at: String,
}

fn default_tray() -> String { "normal".to_string() }
fn default_temp() -> f64 { 28.5 }

/// PrawnDoc AI shrimp pathology vision diagnostic scan.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DiseaseScan {
    pub id: String,
    pub user_id: Option<String>,
    pub pond_id: String,
    pub image_hash: Option<String>,
    pub disease_code: String,
    pub disease_name: String,
    pub telugu_name: Option<String>,
    pub confidence: f64,
    #[serde(default = "default_severity")]
    pub severity: String,
    #[serde(default)]
    pub is_emergency_harvest: bool,
    pub immediate_action: Option<String>,
    pub telugu_action: Option<String>,
    #[serde(default)]
    pub treatment_plan: Vec<String>,
    #[serde(default)]
    pub water_context: serde_json::Value,
    pub farmer_notes: Option<String>,
    pub idempotency_key: Option<String>,
    pub scanned_at: String,
}

/// Farm accounting expense record for PrawnCredit ledger.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Expense {
    pub id: String,
    pub user_id: Option<String>,
    pub pond_id: String,
    #[serde(default = "default_pond_name")]
    pub pond_name: String,
    pub category: String,
    pub amount: f64,
    pub supplier: Option<String>,
    pub notes: Option<String>,
    pub idempotency_key: Option<String>,
    pub expense_date: String,
}

fn default_pond_name() -> String { "Pond 1".to_string() }

/// Harvest yield and revenue realization record.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Harvest {
    pub id: String,
    pub user_id: Option<String>,
    pub pond_id: String,
    #[serde(default = "default_pond_name")]
    pub pond_name: String,
    #[serde(default = "default_harvest_type")]
    pub harvest_type: String,
    pub biomass_kg: f64,
    pub count_per_kg: u32,
    pub price_per_kg: f64,
    pub total_revenue: f64,
    #[serde(default = "default_fcr")]
    pub fcr: f64,
    pub buyer_name: Option<String>,
    pub idempotency_key: Option<String>,
    pub harvest_date: String,
}

fn default_harvest_type() -> String { "Partial".to_string() }
fn default_fcr() -> f64 { 1.3 }

/// Mandi farm-gate price benchmark per hub and count grade.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct MarketPrice {
    pub id: String,
    pub hub_name: String,
    #[serde(default = "default_species")]
    pub species: String,
    pub count_grade: String,
    pub count_per_kg: u32,
    pub price_inr_per_kg: f64,
    #[serde(default)]
    pub price_change_inr: f64,
    #[serde(default = "default_demand")]
    pub demand_level: String,
    pub effective_date: String,
}

fn default_demand() -> String { "High".to_string() }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pond_biomass_calculation() {
        let pond = Pond {
            id: "pond_1".to_string(),
            user_id: "user_1".to_string(),
            farmer_id: None,
            farm_id: None,
            name: "Pond 1".to_string(),
            species: "L. vannamei".to_string(),
            area_ha: 1.0,
            stocking_density: 50.0,
            doc: 45,
            stocking_date: "2026-08-01".to_string(),
            initial_abw: 0.02,
            current_abw: 16.0,
            survival_rate: 0.80,
            status: "Active".to_string(),
            version: 1,
            created_at: None,
            updated_at: None,
        };

        // Total shrimp: 1.0 * 10,000 * 50 * 0.80 = 400,000 shrimp
        // Biomass: 400,000 * 16g / 1000 = 6,400 kg
        assert_eq!(pond.estimated_biomass_kg(), 6400.0);
    }
}
