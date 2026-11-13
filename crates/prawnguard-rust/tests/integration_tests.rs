use std::sync::Arc;
use std::thread;
use serde_json::json;
use prawnguard_rust::abw::AbwEngine;
use prawnguard_rust::alert_system::AlertSystem;
use prawnguard_rust::feed_ai::{CheckTrayStatus, FeedAiEngine};
use prawnguard_rust::ffi::*;
use prawnguard_rust::finance::{ExpenseSummary, FcrAnalysis, HarvestSummary, PrawnCreditEngine};
use prawnguard_rust::mandi::{MandiAggregator, RegionalHub};
use prawnguard_rust::models::{Expense, Harvest, Pond, WaterLog};
use prawnguard_rust::outbox::OfflineOutboxEngine;
use prawnguard_rust::prawndoc::diagnose_symptoms;
use prawnguard_rust::security::AntiReverseEngineering;
use prawnguard_rust::telugu_nlu::TeluguVoiceNlu;

#[test]
fn test_end_to_end_aquaculture_cycle() {
    // 1. Pond Model Initialization
    let pond = Pond {
        id: "pond_bhimavaram_01".to_string(),
        user_id: "usr_surya_01".to_string(),
        farmer_id: Some("frm_koteswara_rao".to_string()),
        farm_id: Some("farm_godavari_delta".to_string()),
        name: "Godavari West Pond 1".to_string(),
        species: "L. vannamei".to_string(),
        area_ha: 1.0,
        stocking_density: 60.0, // 60 pcs/m2
        doc: 75,
        stocking_date: "2026-08-25".to_string(),
        initial_abw: 0.02,
        current_abw: 18.5,
        survival_rate: 0.88,
        status: "Active".to_string(),
        version: 1,
        created_at: Some("2026-08-25T06:00:00Z".to_string()),
        updated_at: Some("2026-11-12T00:00:00Z".to_string()),
    };

    let estimated_biomass = pond.estimated_biomass_kg();
    assert!(estimated_biomass > 9000.0 && estimated_biomass < 10000.0);

    // 2. Outbox Queue Enqueue & Mutation State
    let queue = OfflineOutboxEngine::new(100);
    let mut_pond = queue.enqueue("ponds", "INSERT", json!({ "id": pond.id, "name": pond.name }), Some(1));
    let pond_mut_id = mut_pond.id.clone();
    assert_eq!(queue.queue_len(), 1);

    // 3. Bio-Energetic Feed AI Computation
    let feed_plan = FeedAiEngine::calculate_daily_feed(
        pond.stocking_density,
        pond.area_ha,
        pond.survival_rate,
        pond.current_abw,
        pond.doc as i32,
        29.0,
        None,
        Some(CheckTrayStatus::Normal),
        true,
    );

    assert!(feed_plan.daily_total_kg > 0.0);
    assert_eq!(feed_plan.meal_schedule().len(), 4);
    assert!((feed_plan.meals_total() - feed_plan.adjusted_daily_feed_kg).abs() < 0.01);

    // 4. Water Quality & Hypoxia Crash Forecast
    let water_log = WaterLog {
        id: "wl_001".to_string(),
        user_id: Some(pond.user_id.clone()),
        pond_id: pond.id.clone(),
        ph: Some(7.8),
        dissolved_oxygen: Some(3.2), // Low DO
        salinity: Some(15.0),
        temperature: Some(29.0),
        ammonia: Some(0.08),
        alkalinity: Some(130.0),
        turbidity_cm: Some(35.0),
        overall_severity: "watch".to_string(),
        source: "voice".to_string(),
        idempotency_key: None,
        recorded_at: "2026-11-12T22:00:00Z".to_string(),
    };

    let alerts = AlertSystem::evaluate_parameters(
        water_log.ph,
        water_log.dissolved_oxygen,
        water_log.ammonia,
        water_log.alkalinity,
        water_log.salinity,
        water_log.temperature,
    );
    assert!(!alerts.is_empty());

    // Forecast Dawn Dissolved Oxygen
    let (dawn_do, severity) = AlertSystem::forecast_dawn_dissolved_oxygen(
        3.2,
        29.0,
        pond.doc as i32,
        estimated_biomass,
        false,
    );
    assert!(dawn_do < 3.0); // Predicts critical nocturnal hypoxia drop
    assert!(severity.is_urgent_or_critical());

    // 5. Spoken Telugu Voice NLU Parsing
    let voice_transcript = "cheruvu 1 lo pH 7.8 DO 3.2 ammonia 0.08 feed 35kg";
    let nlu_result = TeluguVoiceNlu::parse_voice_input(voice_transcript);
    assert_eq!(nlu_result.pond_number, Some(1));
    assert_eq!(nlu_result.ph, Some(7.8));
    assert_eq!(nlu_result.dissolved_oxygen, Some(3.2));
    assert_eq!(nlu_result.ammonia, Some(0.08));
    assert_eq!(nlu_result.feed_kg, Some(35.0));

    // 6. Morphometric ABW Allometric Calculations
    let length_cm = 12.8;
    let computed_abw = AbwEngine::calculate_weight_from_length_cm(length_cm);
    let count_per_kg = AbwEngine::calculate_count_per_kg(computed_abw);
    assert!(computed_abw > 18.0 && computed_abw < 20.0);
    assert!(count_per_kg > 45.0 && count_per_kg < 55.0);

    // 7. PrawnDoc Disease Diagnostic Classifier
    let symptoms = vec!["white spots on carapace", "reddish coloration", "lethargic at pond surface"];
    let diagnosis = diagnose_symptoms(&symptoms, Some(75), Some(3.2));
    assert_eq!(diagnosis.disease_code, "WSSV");
    assert!(diagnosis.confidence > 0.85);
    assert!(diagnosis.is_emergency_harvest);
    assert!(!diagnosis.telugu_name.is_empty());
    assert!(!diagnosis.telugu_action.is_empty());

    // 8. Mandi Farm-Gate Price & Harvest Valuation
    let hub = RegionalHub::Bhimavaram;
    let valuation = MandiAggregator::estimate_harvest_revenue(estimated_biomass, count_per_kg as u32, hub);
    assert!(valuation.gross_revenue_inr > 0.0);
    assert!(valuation.net_revenue_inr > 0.0);
    assert!(valuation.net_revenue_inr < valuation.gross_revenue_inr); // After commission & transport

    // 9. Financial PrawnCredit & FCR Scoring
    let expenses = vec![
        Expense {
            id: "exp_01".to_string(),
            user_id: Some(pond.user_id.clone()),
            pond_id: pond.id.clone(),
            pond_name: pond.name.clone(),
            category: "Feed".to_string(),
            amount: 850000.0,
            supplier: Some("CP Aqua".to_string()),
            notes: Some("CP 3804 Feed Bags".to_string()),
            idempotency_key: None,
            expense_date: "2026-10-15".to_string(),
        },
        Expense {
            id: "exp_02".to_string(),
            user_id: Some(pond.user_id.clone()),
            pond_id: pond.id.clone(),
            pond_name: pond.name.clone(),
            category: "Electricity".to_string(),
            amount: 120000.0,
            supplier: Some("APEPDCL".to_string()),
            notes: Some("Aeration Power".to_string()),
            idempotency_key: None,
            expense_date: "2026-10-20".to_string(),
        },
    ];

    let harvests = vec![
        Harvest {
            id: "hrv_01".to_string(),
            user_id: Some(pond.user_id.clone()),
            pond_id: pond.id.clone(),
            pond_name: pond.name.clone(),
            harvest_type: "Full".to_string(),
            biomass_kg: estimated_biomass,
            count_per_kg: count_per_kg as u32,
            price_per_kg: valuation.price_per_kg,
            total_revenue: valuation.gross_revenue_inr,
            fcr: 1.3,
            buyer_name: Some("Devi Sea Foods Ltd".to_string()),
            idempotency_key: None,
            harvest_date: "2026-11-12".to_string(),
        }
    ];

    let exp_summary = ExpenseSummary::compute(&expenses);
    let hrv_summary = HarvestSummary::compute(&harvests, exp_summary.total_amount);
    assert_eq!(exp_summary.expense_count, 2);
    assert!(hrv_summary.net_profit_inr > 0.0);

    let fcr = FcrAnalysis::compute(12500.0, estimated_biomass);
    assert!(fcr.fcr >= 1.2 && fcr.fcr <= 1.5);
    assert_eq!(fcr.rating, "Good");

    let credit_score = PrawnCreditEngine::evaluate(
        fcr.fcr,
        pond.survival_rate,
        hrv_summary.roi_percent,
        35,
        pond.area_ha,
    );
    assert!(credit_score.score >= 700 && credit_score.score <= 900);
    assert_eq!(credit_score.tier, "Tier-1 Elite");

    // 10. Counter-REA Opaque Invariants & Security
    let posture = AntiReverseEngineering::evaluate_posture(false);
    assert!(posture.opaque_predicates_passed);
    assert!(posture.canary_integrity_intact);
    assert_eq!(posture.defense_score, 98);

    // Clean up queue
    assert!(queue.remove_mutation(&pond_mut_id));
    assert_eq!(queue.queue_len(), 0);
}

#[test]
fn test_concurrent_outbox_operations() {
    let queue = Arc::new(OfflineOutboxEngine::new(100));
    let mut handles = vec![];

    // Spawn 8 concurrent threads enqueuing mutations
    for thread_idx in 0..8 {
        let q = Arc::clone(&queue);
        let handle = thread::spawn(move || {
            for item_idx in 0..15 {
                let _ = q.enqueue(
                    "water_logs",
                    "INSERT",
                    json!({ "ph": 7.8, "thread": thread_idx, "item": item_idx }),
                    None,
                );
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    // Capacity must be strictly clamped to <= 100
    assert_eq!(queue.queue_len(), 100);
}

#[test]
fn test_c_ffi_native_interop() {
    // 1. Version
    let ver_ptr = prawnguard_version();
    assert!(!ver_ptr.is_null());
    let ver_cstr = unsafe { std::ffi::CStr::from_ptr(ver_ptr) };
    assert!(ver_cstr.to_str().unwrap().contains("0.1.0"));

    // 2. Mandi Price FFI (returns f64)
    let hub_cstr = std::ffi::CString::new("Bhimavaram").unwrap();
    let price = unsafe { prawnguard_get_mandi_price(hub_cstr.as_ptr(), 30) };
    assert!(price > 350.0);

    // 3. Estimate Harvest FFI
    let est_ptr = unsafe { prawnguard_estimate_harvest(hub_cstr.as_ptr(), 1000.0, 30) };
    assert!(!est_ptr.is_null());
    let est_str = unsafe {
        let s = std::ffi::CStr::from_ptr(est_ptr).to_str().unwrap().to_string();
        prawnguard_free_string(est_ptr);
        s
    };
    assert!(est_str.contains("gross_revenue_inr"));

    // 4. Security Verification FFI (returns *mut c_char)
    let sec_ptr = prawnguard_verify_security();
    assert!(!sec_ptr.is_null());
    let sec_str = unsafe {
        let s = std::ffi::CStr::from_ptr(sec_ptr).to_str().unwrap().to_string();
        prawnguard_free_string(sec_ptr);
        s
    };
    assert!(sec_str.contains("defense_score"));

    // 5. Diagnose Symptoms FFI
    let symptoms_cstr = std::ffi::CString::new("white spots, red body").unwrap();
    let diag_ptr = unsafe { prawnguard_diagnose_symptoms(symptoms_cstr.as_ptr()) };
    assert!(!diag_ptr.is_null());
    let diag_str = unsafe {
        let s = std::ffi::CStr::from_ptr(diag_ptr).to_str().unwrap().to_string();
        prawnguard_free_string(diag_ptr);
        s
    };
    assert!(diag_str.contains("WSSV"));

    // 6. Calculate Feed FFI
    let feed_ptr = prawnguard_calculate_feed(60.0, 1.0, 0.85, 18.0, 75, 29.0, 0.0, 0, 0);
    assert!(!feed_ptr.is_null());
    let feed_str = unsafe {
        let s = std::ffi::CStr::from_ptr(feed_ptr).to_str().unwrap().to_string();
        prawnguard_free_string(feed_ptr);
        s
    };
    assert!(feed_str.contains("adjusted_daily_feed_kg"));

    // 7. Evaluate Water Quality FFI
    let wq_ptr = prawnguard_evaluate_water_quality(7.8, 5.5, 15.0, 29.0, 0.2, 120.0);
    assert!(!wq_ptr.is_null());
    let wq_str = unsafe {
        let s = std::ffi::CStr::from_ptr(wq_ptr).to_str().unwrap().to_string();
        prawnguard_free_string(wq_ptr);
        s
    };
    assert!(wq_str.contains("severity"));

    // 8. Parse Telugu Voice FFI
    let voice_cstr = std::ffi::CString::new("cheruvu 1 lo pH 7.8 DO 3.2 ammonia 0.08").unwrap();
    let tel_ptr = unsafe { prawnguard_parse_telugu_voice(voice_cstr.as_ptr()) };
    assert!(!tel_ptr.is_null());
    let tel_str = unsafe {
        let s = std::ffi::CStr::from_ptr(tel_ptr).to_str().unwrap().to_string();
        prawnguard_free_string(tel_ptr);
        s
    };
    assert!(tel_str.contains("7.8"));

    // 9. Analyze ABW FFI
    let lengths_cstr = std::ffi::CString::new("[12.0, 12.5, 13.0, 12.2, 12.8]").unwrap();
    let abw_ptr = unsafe { prawnguard_analyze_abw(lengths_cstr.as_ptr(), 65) };
    assert!(!abw_ptr.is_null());
    let abw_str = unsafe {
        let s = std::ffi::CStr::from_ptr(abw_ptr).to_str().unwrap().to_string();
        prawnguard_free_string(abw_ptr);
        s
    };
    assert!(abw_str.contains("mean_abw_grams"));

    // 10. Evaluate Credit Score FFI
    let ponds_cstr = std::ffi::CString::new("[{\"id\":\"p1\",\"user_id\":\"u1\",\"name\":\"Pond 1\",\"species\":\"vannamei\",\"area_ha\":1.0,\"stocking_density\":60.0,\"doc\":75,\"stocking_date\":\"2026-08-01\",\"initial_abw\":0.02,\"current_abw\":18.0,\"survival_rate\":0.88,\"status\":\"Active\",\"version\":1}]").unwrap();
    let cred_ptr = unsafe { prawnguard_evaluate_credit_score(ponds_cstr.as_ptr(), std::ptr::null(), std::ptr::null(), std::ptr::null(), 5000.0) };
    assert!(!cred_ptr.is_null());
    let cred_str = unsafe {
        let s = std::ffi::CStr::from_ptr(cred_ptr).to_str().unwrap().to_string();
        prawnguard_free_string(cred_ptr);
        s
    };
    assert!(cred_str.contains("score"));
}
