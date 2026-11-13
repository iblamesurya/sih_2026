use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::panic::catch_unwind;

use crate::mandi::{CountGrade, MandiAggregator, RegionalHub};
use crate::prawndoc::diagnose_symptoms;
use crate::security::AntiReverseEngineering;

/// Returns the engine semver string.
#[no_mangle]
pub extern "C" fn prawnguard_version() -> *const c_char {
    static VERSION: &[u8] = b"0.1.0\0";
    VERSION.as_ptr() as *const c_char
}

/// Frees a heap-allocated C string previously returned by the PrawnGuard Rust FFI.
///
/// # Safety
/// The pointer must have been returned by one of the `prawnguard_*` functions.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        let _ = CString::from_raw(ptr);
    }
}

/// Diagnoses shrimp symptoms from a comma-separated symptoms string.
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

/// Returns the Mandi market price for a given regional hub and count grade as JSON.
///
/// # Safety
/// `hub_name` must be a valid null-terminated UTF-8 string pointer.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_get_mandi_price(
    hub_name: *const c_char,
    count_per_kg: u32,
) -> *mut c_char {
    let result = catch_unwind(|| {
        if hub_name.is_null() {
            return CString::new("{\"error\": \"null_pointer\"}").unwrap().into_raw();
        }

        let c_str = CStr::from_ptr(hub_name);
        let hub_str = match c_str.to_str() {
            Ok(s) => s,
            Err(_) => return CString::new("{\"error\": \"invalid_utf8\"}").unwrap().into_raw(),
        };

        let hub = RegionalHub::from_str(hub_str).unwrap_or(RegionalHub::Bhimavaram);
        let grade = CountGrade::from_count(count_per_kg);
        let price = MandiAggregator::get_price(hub, grade);

        let json_str = serde_json::to_string(&price).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

/// Estimates harvest valuation and net revenue realization.
///
/// # Safety
/// `hub_name` must be a valid null-terminated UTF-8 string pointer.
#[no_mangle]
pub unsafe extern "C" fn prawnguard_estimate_harvest(
    biomass_kg: f64,
    count_per_kg: u32,
    hub_name: *const c_char,
) -> *mut c_char {
    let result = catch_unwind(|| {
        let hub_str = if hub_name.is_null() {
            "Bhimavaram"
        } else {
            CStr::from_ptr(hub_name).to_str().unwrap_or("Bhimavaram")
        };

        let hub = RegionalHub::from_str(hub_str).unwrap_or(RegionalHub::Bhimavaram);
        let valuation = MandiAggregator::estimate_harvest_revenue(biomass_kg, count_per_kg, hub);

        let json_str = serde_json::to_string(&valuation).unwrap_or_else(|_| "{}".to_string());
        CString::new(json_str).unwrap().into_raw()
    });

    result.unwrap_or_else(|_| {
        CString::new("{\"error\": \"panic_caught\"}").unwrap().into_raw()
    })
}

/// Evaluates Counter-REA number-theoretic invariants.
/// Returns `1` if secure and all invariant barriers hold, `0` if tampering detected.
#[no_mangle]
pub extern "C" fn prawnguard_verify_security(is_demo: i32) -> i32 {
    let result = catch_unwind(|| {
        let report = AntiReverseEngineering::evaluate_posture(is_demo != 0);
        if !report.is_tamper_detected && report.opaque_predicates_passed {
            1
        } else {
            0
        }
    });

    result.unwrap_or(0)
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
        let ptr = unsafe { prawnguard_get_mandi_price(hub.as_ptr(), 30) };
        assert!(!ptr.is_null());

        let json_str = unsafe { CStr::from_ptr(ptr).to_str().unwrap() };
        assert!(json_str.contains("445")); // Nellore +10 over 435

        unsafe { prawnguard_free_string(ptr) };
    }

    #[test]
    fn test_verify_security_ffi() {
        let res = prawnguard_verify_security(1);
        assert_eq!(res, 1);
    }
}
