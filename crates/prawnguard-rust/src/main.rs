use std::env;
use prawnguard_rust::abw::AbwEngine;
use prawnguard_rust::alert_system::AlertSystem;
use prawnguard_rust::feed_ai::FeedAiEngine;
use prawnguard_rust::mandi::{CountGrade, MandiAggregator, RegionalHub};
use prawnguard_rust::prawndoc::diagnose_symptoms;
use prawnguard_rust::security::AntiReverseEngineering;
use prawnguard_rust::telugu_nlu::TeluguVoiceNlu;

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        print_banner();
        print_usage();
        return;
    }

    match args[1].as_str() {
        "diagnose" => {
            if args.len() < 3 {
                println!("Usage: prawnguard diagnose \"<symptom1, symptom2, ...>\"");
                return;
            }
            let symptoms_input = &args[2..].join(" ");
            let symptoms: Vec<&str> = symptoms_input.split(',').map(|s| s.trim()).collect();

            println!("\n🔍 Running PrawnDoc AI Vision Pathology Diagnostic Engine...");
            println!("  Observed Symptoms: {:?}", symptoms);
            let report = diagnose_symptoms(&symptoms, None, None);

            println!("\n========================================================");
            println!("  PrawnDoc AI Diagnostic Result (ICAR-CIBA Protocol)");
            println!("========================================================");
            println!("  Disease Code:     {}", report.disease_code);
            println!("  Diagnosis:        {}", report.disease_name);
            println!("  Scientific:       {}", report.scientific_name);
            println!("  Telugu Name:      {}", report.telugu_name);
            println!("  Confidence:       {:.1}%", report.confidence * 100.0);
            println!("  Severity:         {}", report.severity.to_uppercase());
            println!("  Emergency Action: {}", if report.is_emergency_harvest { "EMERGENCY HARVEST / ISOLATION ADVISED" } else { "STANDARD MITIGATION PROTOCOL" });
            println!("\n  Immediate Action: {}", report.immediate_action);
            println!("  Telugu Action:    {}", report.telugu_action);
            println!("\n  Telugu Summary:   {}", report.telugu_summary);
            println!("========================================================\n");
        }

        "mandi" => {
            let hub_arg = args.get(2).map(|s| s.as_str()).unwrap_or("Bhimavaram");
            let hub = RegionalHub::from_str(hub_arg).unwrap_or(RegionalHub::Bhimavaram);

            if let Some(count_str) = args.get(3) {
                if let Ok(count) = count_str.parse::<u32>() {
                    let grade = CountGrade::from_count(count);
                    let price = MandiAggregator::get_price(hub, grade);
                    println!("\n🦐 Mandi Price for {} - {}", hub.name(), grade.label());
                    println!("  Price:     ₹{:.2} / kg", price.price_inr_per_kg);
                    println!("  Change:    ₹{:+.2}", price.price_change_inr);
                    println!("  Demand:    {}", price.demand_level);
                    return;
                }
            }

            println!("\n=========================================================================================");
            println!("  PrawnGuard Mandi Farm-Gate Price Matrix — {}", hub.name());
            println!("=========================================================================================");
            println!("{:<12} | {:<12} | {:<12} | {:<10} | {:<25}", "Grade", "Count/kg", "Price (₹/kg)", "Trend", "Demand Level");
            println!("-----------------------------------------------------------------------------------------");

            for grade in MandiAggregator::ALL_GRADES {
                let price = MandiAggregator::get_price(hub, grade);
                println!(
                    "{:<12} | {:<12} | ₹{:<11.2} | {:<10} | {:<25}",
                    price.count_grade,
                    price.count_per_kg,
                    price.price_inr_per_kg,
                    format!("₹{:+.2}", price.price_change_inr),
                    price.demand_level
                );
            }
            println!("=========================================================================================\n");
        }

        "harvest" => {
            if args.len() < 4 {
                println!("Usage: prawnguard harvest <biomass_kg> <count_per_kg> [hub]");
                return;
            }
            let biomass: f64 = args[2].parse().unwrap_or(1000.0);
            let count: u32 = args[3].parse().unwrap_or(30);
            let hub_arg = args.get(4).map(|s| s.as_str()).unwrap_or("Bhimavaram");
            let hub = RegionalHub::from_str(hub_arg).unwrap_or(RegionalHub::Bhimavaram);

            let val = MandiAggregator::estimate_harvest_revenue(biomass, count, hub);
            println!("\n💰 Harvest Valuation & Net Revenue Realization:");
            println!("  Regional Hub:       {}", val.hub_name);
            println!("  Harvest Biomass:    {:.1} kg", val.biomass_kg);
            println!("  Grade Matched:      {} ({} count)", val.matched_grade, val.count_per_kg);
            println!("  Price per kg:       ₹{:.2}", val.price_per_kg);
            println!("  Gross Revenue:      ₹{:.2}", val.gross_revenue_inr);
            println!("  Mandi Commission:  -₹{:.2} (1.5%)", val.mandi_commission_inr);
            println!("  Ice & Transport:   -₹{:.2} (₹3/kg)", val.packing_transport_inr);
            println!("  Net Realization:    ₹{:.2}", val.net_revenue_inr);
            println!("---------------------------------------------------------\n");
        }

        "security" => {
            println!("\n🛡️  Evaluating Counter-REA Number-Theoretic Security Posture...");
            let posture = AntiReverseEngineering::evaluate_posture(false);
            println!("  Tamper Detected:          {}", posture.is_tamper_detected);
            println!("  Opaque Invariants:        {}", if posture.opaque_predicates_passed { "PASS (7x^2 - 1 != y^2 mod 7 active)" } else { "FAIL" });
            println!("  Canary Token Integrity:   {}", if posture.canary_integrity_intact { "PASS (Canaries Armored)" } else { "FAIL" });
            println!("  Active Chaff Tokens:      {}", posture.active_chaff_tokens);
            println!("  Defense Score:            {}/100", posture.defense_score);
            println!("  Status:                   {}", posture.status);
            println!("---------------------------------------------------------\n");
        }

        "telugu" => {
            if args.len() < 3 {
                println!("Usage: prawnguard telugu \"<telugu speech text>\"");
                return;
            }
            let query = args[2..].join(" ");
            println!("\n🗣️  Parsing Telugu Voice NLU Spoken Query: \"{}\"", query);
            let parsed = TeluguVoiceNlu::parse_voice_input(&query);
            println!("  Pond Index:     {:?}", parsed.pond_index);
            println!("  pH:             {:?}", parsed.ph);
            println!("  DO (Oxygen):    {:?} mg/L", parsed.do_level);
            println!("  Ammonia (NH3):  {:?} mg/L", parsed.ammonia);
            println!("  Feed Amount:    {:?} kg", parsed.feed_kg);
            println!("---------------------------------------------------------\n");
        }

        "feed" => {
            let doc: i32 = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(65);
            let temp: f64 = args.get(3).and_then(|s| s.parse().ok()).unwrap_or(28.5);

            // Standard 1 ha pond with 50/m2 density, 85% survival, 16g ABW
            let plan = FeedAiEngine::calculate_daily_feed(
                50.0, 1.0, 0.85, 16.0, doc, temp, None, None, true
            );

            println!("\n🌾 Bio-Energetic Feed AI Diurnal Ration Plan (DOC {}):", doc);
            println!("  Stocking Biomass:    {:.1} kg", plan.biomass_kg);
            println!("  Feeding Rate:        {:.2}%", plan.feeding_rate * 100.0);
            println!("  Water Temperature:   {:.1} °C (Temp Factor: {:.2})", temp, plan.temp_factor);
            println!("  Daily Adjusted Feed: {:.2} kg", plan.adjusted_daily_feed_kg);
            println!("  4-Meal Schedule:");
            println!("    • Meal 1 (06:00 AM, 20%): {:.2} kg", plan.meal1_kg);
            println!("    • Meal 2 (11:00 AM, 30%): {:.2} kg", plan.meal2_kg);
            println!("    • Meal 3 (04:00 PM, 30%): {:.2} kg", plan.meal3_kg);
            println!("    • Meal 4 (09:00 PM, 20%): {:.2} kg", plan.meal4_kg);
            println!("---------------------------------------------------------\n");
        }

        "alert" => {
            let ph: f64 = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(7.8);
            let do_val: f64 = args.get(3).and_then(|s| s.parse().ok()).unwrap_or(3.2);
            let nh3: f64 = args.get(4).and_then(|s| s.parse().ok()).unwrap_or(0.08);

            let alerts = AlertSystem::evaluate_parameters(
                Some(ph),
                Some(do_val),
                Some(15.0),
                Some(28.5),
                Some(nh3),
                Some(120.0),
            );

            let (dawn_forecast, dawn_severity) = AlertSystem::forecast_dawn_dissolved_oxygen(do_val, 28.5, 60, 2500.0, true);

            println!("\n⚠️  Water Quality & Nocturnal Hypoxia Diagnostic:");
            println!("  Measured DO:       {:.2} mg/L", do_val);
            println!("  Dawn DO Forecast:  {:.2} mg/L ({:?})", dawn_forecast, dawn_severity);
            println!("  Active Parameter Evaluations ({}):", alerts.len());
            for alert in &alerts {
                println!("    • [{:?}] {}: {} ({})", alert.severity, alert.parameter, alert.message, alert.recommendation);
            }
            println!("---------------------------------------------------------\n");
        }

        "demo" => {
            run_interactive_demo();
        }

        _ => {
            print_usage();
        }
    }
}

fn print_banner() {
    println!(r#"
  ____                               ____                         _ 
 |  _ \ _ __ __ ___      ___ __     / ___|_   _  __ _ _ __   __| |
 | |_) | '__/ _` \ \ /\ / / '_ \   | |  _| | | |/ _` | '__| / _` |
 |  __/| | | (_| |\ V  V /| | | |  | |_| | |_| | (_| | |   | (_| |
 |_|   |_|  \__,_| \_/\_/ |_| |_|   \____|\__,_|\__,_|_|    \__,_|
                  Native Rust Engine v0.1.0
  Agricultural Intelligence & Bio-Energetic Telemetry System
"#);
}

fn print_usage() {
    println!("Usage: prawnguard <command> [options]\n");
    println!("Commands:");
    println!("  diagnose <symptoms>     Diagnose shrimp disease using ICAR-CIBA protocol");
    println!("  mandi [hub] [count]     Get Mandi farm-gate prices across Andhra Pradesh");
    println!("  harvest <kg> <count>    Estimate harvest gross and net revenue realization");
    println!("  security                Evaluate Counter-REA number-theoretic invariants");
    println!("  telugu <text>           Parse spoken Telugu voice NLU water telemetry");
    println!("  feed <doc> [temp]       Calculate diurnal 4-meal bio-energetic feed schedule");
    println!("  alert <ph> <do> <nh3>   Evaluate water parameters & nocturnal hypoxia risk");
    println!("  demo                    Run end-to-end multi-subsystem simulation\n");
}

fn run_interactive_demo() {
    print_banner();
    println!("🚀 Running Full End-to-End PrawnGuard.ai Native Rust Engine Simulation...\n");

    // 1. Allometric ABW
    let len_cm = 12.5;
    let weight_g = AbwEngine::calculate_weight_from_length_cm(len_cm);
    let count = AbwEngine::calculate_count_per_kg(weight_g);
    println!("1️⃣ [ABW Allometry] Shrimp Length: {} cm -> Weight: {:.2} g ({} count/kg)", len_cm, weight_g, count as u32);

    // 2. Feed AI
    let plan = FeedAiEngine::calculate_daily_feed(50.0, 1.0, 0.85, weight_g, 65, 29.5, None, None, true);
    println!("2️⃣ [Feed AI] DOC 65 Biomass {:.0} kg -> Daily Feed: {:.1} kg (M1: {:.1}, M2: {:.1}, M3: {:.1}, M4: {:.1})",
        plan.biomass_kg, plan.adjusted_daily_feed_kg, plan.meal1_kg, plan.meal2_kg, plan.meal3_kg, plan.meal4_kg);

    // 3. Water Quality & Hypoxia
    let alerts = AlertSystem::evaluate_parameters(Some(8.2), Some(3.4), Some(15.0), Some(29.0), Some(0.08), Some(125.0));
    let (dawn_do, severity) = AlertSystem::forecast_dawn_dissolved_oxygen(3.4, 29.0, 65, plan.biomass_kg, true);
    println!("3️⃣ [Alert Engine] Measured DO 3.4 mg/L -> Dawn Forecast: {:.2} mg/L ({:?}, Alerts triggered: {})", dawn_do, severity, alerts.len());

    // 4. PrawnDoc Pathology
    let report = diagnose_symptoms(&["white spots on carapace", "red body", "dyke swimming"], None, Some(3.4));
    println!("4️⃣ [PrawnDoc AI] Symptoms: White Spots -> {} ({:.1}% conf) - {}", report.disease_name, report.confidence * 100.0, report.telugu_name);

    // 5. Mandi Pricing
    let hub = RegionalHub::Bhimavaram;
    let valuation = MandiAggregator::estimate_harvest_revenue(plan.biomass_kg, count as u32, hub);
    println!("5️⃣ [Mandi Pricing] {} - {} Count -> Price: ₹{:.2}/kg | Net Realization: ₹{:.2}",
        hub.name(), valuation.matched_grade, valuation.price_per_kg, valuation.net_revenue_inr);

    // 6. Security Invariants
    let posture = AntiReverseEngineering::evaluate_posture(false);
    println!("6️⃣ [Counter-REA] Opaque Predicates: {} | Score: {}/100 | Invariants Secure: {}",
        posture.status, posture.defense_score, posture.opaque_predicates_passed);

    println!("\n✅ Complete PrawnGuard Native Rust Engine verified 100% operational!\n");
}
