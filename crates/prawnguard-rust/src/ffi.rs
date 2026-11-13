use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::panic::catch_unwind;

use crate::abw::AbwEngine;
use crate::alert_system::{WaterQualityEngine, WaterQualityReading};
use crate::feed_ai::FeedAiEngine;
use crate::finance::{ExpenseSummary, HarvestSummary, PrawnCreditEngine};
use crate::mandi::{CountGrade, MandiAggregator, RegionalHub};
use crate::models::{Expense, Harvest, Pond, WaterLog};
use crate::prawndoc::diagnose_symptoms;
use crate::security::AntiReverseEngineering;
use crate::telugu_nlu::TeluguVoiceNlu;

/// 1. Returns the engine semver string ("0.1.0\0").
#[no_mangle]
pub extern "C" fn prawnguard_version() -> *const c_char {
    static VERSION: &[u8] = b"0.1.0\0";
    VERSION.as_ptr() as *const c_char
}

/// 2. Frees a heap-allocated C string previously returned by the PrawnGuard Rust FFI.
///
/// # Safety
/// The pointer must have been returned by one of the `prawnguard_*` functions.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        let _ = CString::from_raw(ptr);
    }
}

/// 3. Diagnoses shrimp symptoms from a comma-separated symptoms string.
/// Returns a JSON-serialized `DiagnosticReport` string.
///
/// # Safety
/// `symptoms_csv` must be a valid null-terminated UTF-8 string pointer.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_diagnose_symptoms(
    symptoms_csv: *const c_char,
) -> *mut c_char {
    let result = catch_unwind(|| {
        if symptoms_csv.is_null() {
            return CString::new("{\"error\": \"null_pointer\"}").unwrap().into_raw();
        }

        let c_str = CStr::from_ptr(symptoms_csv);
        let text = match c_str.to_str() {
            Ok(s) => s,
            Err(_) => return CString::new("{\"error\": \"invalid_utf8\"}").unwrap().into_raw(),
        };

        let symptoms: Vec<&str> = text
            .split(',')
            .map(|s| s.trim())
            .filter(|s| !s.is_empty())
            .collect();

        let report = diagnose_symptoms(&symptoms, None, None);
        let json_str = serde_json::to_string(&report).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

/// 4. Returns Mandi market price in INR/kg for a given regional hub and count grade.
///
/// # Safety
/// `hub_str` must be a valid null-terminated UTF-8 string pointer.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_get_mandi_price(
    hub_str: *const c_char,
    count_per_kg: u32,
) -> f64 {
    let result = catch_unwind(|| {
        if hub_str.is_null() {
            return -1.0;
        }

        let c_str = CStr::from_ptr(hub_str);
        let s = match c_str.to_str() {
            Ok(v) => v,
            Err(_) => return -1.0,
        };

        let hub = RegionalHub::from_str(s).unwrap_or(RegionalHub::Bhimavaram);
        let grade = CountGrade::from_count(count_per_kg);
        MandiAggregator::get_price(hub, grade).price_inr_per_kg
    });

    result.unwrap_or(-1.0)
}

/// 5. Estimates harvest valuation and net revenue realization.
/// Returns JSON-serialized `HarvestValuation`.
///
/// # Safety
/// `hub_str` must be a valid null-terminated UTF-8 string pointer.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_estimate_harvest(
    hub_str: *const c_char,
    biomass_kg: f64,
    count_per_kg: u32,
) -> *mut c_char {
    let result = catch_unwind(|| {
        let s = if hub_str.is_null() {
            "Bhimavaram"
        } else {
            match CStr::from_ptr(hub_str).to_str() {
                Ok(v) => v,
                Err(_) => "Bhimavaram",
            }
        };

        let hub = RegionalHub::from_str(s).unwrap_or(RegionalHub::Bhimavaram);
        let valuation = MandiAggregator::estimate_harvest_revenue(biomass_kg, count_per_kg, hub);

        let json_str = serde_json::to_string(&valuation).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

/// 6. Evaluates Counter-REA number-theoretic invariants and memory canaries.
/// Returns JSON-serialized `SecurityReport`.
#[no_mangle]
pub extern "C" fn prawnguard_verify_security() -> *mut c_char {
    let result = catch_unwind(|| {
        let report = AntiReverseEngineering::evaluate_posture(false);
        let json_str = serde_json::to_string(&report).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

/// 7. Calculates bio-energetic feed ration and 4-meal diurnal schedule.
/// Returns JSON-serialized `DailyFeedPlan`.
#[no_mangle]
pub extern "C" fn prawnguard_calculate_feed(
    stocking_density_per_m2: f64,
    area_ha: f64,
    survival_rate: f64,
    current_abw_g: f64,
    doc: u32,
    water_temp_c: f64,
    prev_tray_leftover_pct: f64,
    critical_water_alert: u8,
    high_ammonia_alert: u8,
) -> *mut c_char {
    let result = catch_unwind(|| {
        let tray_adjustment = if prev_tray_leftover_pct > 0.0 {
            Some(-(prev_tray_leftover_pct / 100.0).clamp(0.0, 0.30))
        } else {
            None
        };

        let mut plan = FeedAiEngine::calculate_daily_feed(
            stocking_density_per_m2,
            area_ha,
            survival_rate,
            current_abw_g,
            doc as i32,
            water_temp_c,
            tray_adjustment,
            None,
            true,
        );

        // Water stress adjustments
        if critical_water_alert == 1 {
            plan.adjusted_daily_feed_kg *= 0.5;
            plan.daily_total_kg = plan.adjusted_daily_feed_kg;
            plan.meal1_kg *= 0.5;
            plan.meal2_kg *= 0.5;
            plan.meal3_kg *= 0.5;
            plan.meal4_kg *= 0.5;
        } else if high_ammonia_alert == 1 {
            plan.adjusted_daily_feed_kg *= 0.7;
            plan.daily_total_kg = plan.adjusted_daily_feed_kg;
            plan.meal1_kg *= 0.7;
            plan.meal2_kg *= 0.7;
            plan.meal3_kg *= 0.7;
            plan.meal4_kg *= 0.7;
        }

        let json_str = serde_json::to_string(&plan).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

/// 8. Evaluates water quality telemetry against scientific aquaculture thresholds.
/// Returns JSON-serialized `WaterQualityEvaluation`.
#[no_mangle]
pub extern "C" fn prawnguard_evaluate_water_quality(
    ph: f64,
    do_mg_l: f64,
    salinity_ppt: f64,
    temp_c: f64,
    ammonia_tan_mg_l: f64,
    alkalinity_ppm: f64,
) -> *mut c_char {
    let result = catch_unwind(|| {
        let reading = WaterQualityReading {
            ph,
            dissolved_oxygen: do_mg_l,
            temperature_c: temp_c,
            salinity_ppt,
            ammonia_mg_l: ammonia_tan_mg_l,
            alkalinity_mg_l: alkalinity_ppm,
        };

        let evaluation = WaterQualityEngine::evaluate(&reading);
        let json_str = serde_json::to_string(&evaluation).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

/// 9. Parses natural Telugu voice telemetry transcripts.
/// Returns JSON-serialized `ParsedTelemetry`.
///
/// # Safety
/// `transcript_ptr` must be a valid null-terminated UTF-8 string pointer.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_parse_telugu_voice(
    transcript_ptr: *const c_char,
) -> *mut c_char {
    let result = catch_unwind(|| {
        if transcript_ptr.is_null() {
            return CString::new("{\"error\": \"null_pointer\"}").unwrap().into_raw();
        }

        let c_str = CStr::from_ptr(transcript_ptr);
        let text = match c_str.to_str() {
            Ok(s) => s,
            Err(_) => return CString::new("{\"error\": \"invalid_utf8\"}").unwrap().into_raw(),
        };

        let telemetry = TeluguVoiceNlu::parse_voice_input(text);
        let json_str = serde_json::to_string(&telemetry).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

/// 10. Analyzes sampling measurements of shrimp body lengths (cm).
/// Returns JSON-serialized `AbwSampleResult`.
///
/// # Safety
/// `lengths_json_ptr` must be a valid null-terminated UTF-8 JSON array pointer.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_analyze_abw(
    lengths_json_ptr: *const c_char,
    doc: u32,
) -> *mut c_char {
    let result = catch_unwind(|| {
        if lengths_json_ptr.is_null() {
            return CString::new("{\"error\": \"null_pointer\"}").unwrap().into_raw();
        }

        let c_str = CStr::from_ptr(lengths_json_ptr);
        let json_text = match c_str.to_str() {
            Ok(s) => s,
            Err(_) => return CString::new("{\"error\": \"invalid_utf8\"}").unwrap().into_raw(),
        };

        let lengths: Vec<f64> = match serde_json::from_str(json_text) {
            Ok(l) => l,
            Err(_) => return CString::new("{\"error\": \"invalid_json\"}").unwrap().into_raw(),
        };

        let sample_result = AbwEngine::analyze_sampling(&lengths, doc as i32);
        let json_str = serde_json::to_string(&sample_result).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

/// 11. Evaluates 5-pillar PrawnCredit score and underwriting tiers.
/// Returns JSON-serialized `PrawnCreditScore`.
///
/// # Safety
/// Pointers must be valid null-terminated UTF-8 JSON array strings or null.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_evaluate_credit_score(
    ponds_json_ptr: *const c_char,
    water_logs_json_ptr: *const c_char,
    expenses_json_ptr: *const c_char,
    harvests_json_ptr: *const c_char,
    total_feed_kg: f64,
) -> *mut c_char {
    let result = catch_unwind(|| {
        let ponds: Vec<Pond> = if !ponds_json_ptr.is_null() {
            CStr::from_ptr(ponds_json_ptr)
                .to_str()
                .ok()
                .and_then(|s| serde_json::from_str(s).ok())
                .unwrap_or_default()
        } else {
            Vec::new()
        };

        let water_logs: Vec<WaterLog> = if !water_logs_json_ptr.is_null() {
            CStr::from_ptr(water_logs_json_ptr)
                .to_str()
                .ok()
                .and_then(|s| serde_json::from_str(s).ok())
                .unwrap_or_default()
        } else {
            Vec::new()
        };

        let expenses: Vec<Expense> = if !expenses_json_ptr.is_null() {
            CStr::from_ptr(expenses_json_ptr)
                .to_str()
                .ok()
                .and_then(|s| serde_json::from_str(s).ok())
                .unwrap_or_default()
        } else {
            Vec::new()
        };

        let harvests: Vec<Harvest> = if !harvests_json_ptr.is_null() {
            CStr::from_ptr(harvests_json_ptr)
                .to_str()
                .ok()
                .and_then(|s| serde_json::from_str(s).ok())
                .unwrap_or_default()
        } else {
            Vec::new()
        };

        let total_area_ha: f64 = if !ponds.is_empty() {
            ponds.iter().map(|p| p.area_ha).sum()
        } else {
            1.0
        };

        let avg_survival: f64 = if !ponds.is_empty() {
            ponds.iter().map(|p| p.survival_rate).sum::<f64>() / ponds.len() as f64
        } else {
            0.85
        };

        let exp_summary = ExpenseSummary::compute(&expenses);
        let hrv_summary = HarvestSummary::compute(&harvests, exp_summary.total_amount);

        let fcr = if total_feed_kg > 0.0 && hrv_summary.total_biomass_kg > 0.0 {
            total_feed_kg / hrv_summary.total_biomass_kg
        } else {
            1.35
        };

        let score = PrawnCreditEngine::evaluate(
            fcr,
            avg_survival,
            hrv_summary.roi_percent,
            water_logs.len(),
            total_area_ha,
        );

        let json_str = serde_json::to_string(&score).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version_ffi() {
        let ver = prawnguard_version();
        assert!(!ver.is_null());
        let c_str = unsafe { CStr::from_ptr(ver) };
        assert_eq!(c_str.to_str().unwrap(), "0.1.0");
    }

    #[test]
    fn test_diagnose_symptoms_ffi() {
        let input = CString::new("white spots, red body").unwrap();
        let ptr = unsafe { prawnguard_diagnose_symptoms(input.as_ptr()) };
        assert!(!ptr.is_null());

        let json_str = unsafe { CStr::from_ptr(ptr).to_str().unwrap() };
        assert!(json_str.contains("WSSV"));

        unsafe { prawnguard_free_string(ptr) };
    }

    #[test]
    fn test_get_mandi_price_ffi() {
        let hub = CString::new("Nellore").unwrap();
        let price = unsafe { prawnguard_get_mandi_price(hub.as_ptr(), 30) };
        assert!(price > 400.0);
    }

    #[test]
    fn test_verify_security_ffi() {
        let ptr = prawnguard_verify_security();
        assert!(!ptr.is_null());
        let json_str = unsafe { CStr::from_ptr(ptr).to_str().unwrap() };
        assert!(json_str.contains("defense_score"));
        unsafe { prawnguard_free_string(ptr) };
    }

    #[test]
    fn test_calculate_feed_ffi() {
        let ptr = prawnguard_calculate_feed(60.0, 1.0, 0.85, 18.0, 75, 29.0, 0.0, 0, 0);
        assert!(!ptr.is_null());
        let json_str = unsafe { CStr::from_ptr(ptr).to_str().unwrap() };
        assert!(json_str.contains("adjusted_daily_feed_kg"));
        unsafe { prawnguard_free_string(ptr) };
    }

    #[test]
    fn test_evaluate_water_quality_ffi() {
        let ptr = prawnguard_evaluate_water_quality(7.8, 5.5, 15.0, 29.0, 0.2, 120.0);
        assert!(!ptr.is_null());
        let json_str = unsafe { CStr::from_ptr(ptr).to_str().unwrap() };
        assert!(json_str.contains("severity"));
        unsafe { prawnguard_free_string(ptr) };
    }

    #[test]
    fn test_parse_telugu_voice_ffi() {
        let input = CString::new("cheruvu 1 lo pH 7.8 DO 3.2").unwrap();
        let ptr = unsafe { prawnguard_parse_telugu_voice(input.as_ptr()) };
        assert!(!ptr.is_null());
        let json_str = unsafe { CStr::from_ptr(ptr).to_str().unwrap() };
        assert!(json_str.contains("7.8"));
        unsafe { prawnguard_free_string(ptr) };
    }

    #[test]
    fn test_analyze_abw_ffi() {
        let input = CString::new("[12.0, 12.5, 13.0, 12.2, 12.8]").unwrap();
        let ptr = unsafe { prawnguard_analyze_abw(input.as_ptr(), 65) };
        assert!(!ptr.is_null());
        let json_str = unsafe { CStr::from_ptr(ptr).to_str().unwrap() };
        assert!(json_str.contains("mean_abw_grams"));
        unsafe { prawnguard_free_string(ptr) };
    }

    #[test]
    fn test_evaluate_credit_score_ffi() {
        let ponds = CString::new("[{\"id\":\"p1\",\"user_id\":\"u1\",\"name\":\"Pond 1\",\"species\":\"vannamei\",\"area_ha\":1.0,\"stocking_density\":60.0,\"doc\":75,\"stocking_date\":\"2026-08-01\",\"initial_abw\":0.02,\"current_abw\":18.0,\"survival_rate\":0.88,\"status\":\"Active\",\"version\":1}]").unwrap();
        let ptr = unsafe { prawnguard_evaluate_credit_score(ponds.as_ptr(), std::ptr::null(), std::ptr::null(), std::ptr::null(), 5000.0) };
        assert!(!ptr.is_null());
        let json_str = unsafe { CStr::from_ptr(ptr).to_str().unwrap() };
        assert!(json_str.contains("score"));
        unsafe { prawnguard_free_string(ptr) };
    }
}
