use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Severity levels for water quality telemetry and system alerts.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AlertSeverity {
    Optimal,
    Watch,
    Urgent,
    Critical,
}

impl AlertSeverity {
    pub fn is_urgent_or_critical(&self) -> bool {
        matches!(self, AlertSeverity::Urgent | AlertSeverity::Critical)
    }
}

/// Structured representation of a water parameter evaluation alert.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WaterAlert {
    pub parameter: String,
    pub value: f64,
    pub unit: String,
    pub severity: AlertSeverity,
    pub message: String,
    pub recommendation: String,
    pub telugu_message: String,
    pub telugu_recommendation: String,
}

/// Represents a critical life-safety aquaculture emergency alarm.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EmergencyAlarm {
    pub id: String,
    pub pond_id: String,
    pub pond_name: String,
    pub parameter: String,
    pub measured_value: String,
    pub title: String,
    pub telugu_title: String,
    pub checklist: Vec<String>,
    pub telugu_checklist: Vec<String>,
    pub triggered_at: DateTime<Utc>,
    pub acknowledged: bool,
}

/// Alert System evaluating aquaculture telemetry parameters against
/// established ICAR-CIBA & MPEDA Vannamei / Monodon scientific thresholds.
pub struct AlertSystem;

impl AlertSystem {
    /// Computes toxic Un-ionized Ammonia (NH3 in mg/L) from Total Ammonia Nitrogen (TAN in mg/L),
    /// pond pH, and water temperature (°C) using the Emerson et al. (1975) dissociation model:
    /// - pKa = 0.09018 + (2729.92 / (T_c + 273.15))
    /// - fraction NH3 = 1 / (1 + 10^(pKa - pH))
    /// - Un-ionized NH3 (mg/L) = TAN * fraction NH3
    pub fn calculate_unionized_nh3_from_tan(
        tan_mg_l: f64,
        ph: f64,
        temperature_c: f64,
    ) -> f64 {
        if tan_mg_l <= 0.0 {
            return 0.0;
        }
        let temp_k = temperature_c.clamp(10.0, 45.0) + 273.15;
        let p_ka = 0.09018 + (2729.92 / temp_k);
        let safe_ph = ph.clamp(5.0, 11.0);
        let exponent = p_ka - safe_ph;
        let fraction_nh3 = 1.0 / (1.0 + 10.0_f64.powf(exponent));
        let nh3 = tan_mg_l * fraction_nh3;
        (nh3 * 10000.0).round() / 10000.0
    }

    /// Evaluates all provided water parameters and returns a vector of [WaterAlert]s.
    pub fn evaluate_parameters(
        ph: Option<f64>,
        dissolved_oxygen: Option<f64>,
        ammonia: Option<f64>,
        alkalinity: Option<f64>,
        salinity: Option<f64>,
        temperature: Option<f64>,
    ) -> Vec<WaterAlert> {
        let mut alerts = Vec::new();
        if let Some(v) = ph {
            alerts.push(Self::evaluate_ph(v));
        }
        if let Some(v) = dissolved_oxygen {
            alerts.push(Self::evaluate_do(v));
        }
        if let Some(v) = ammonia {
            alerts.push(Self::evaluate_ammonia(v));
        }
        if let Some(v) = alkalinity {
            alerts.push(Self::evaluate_alkalinity(v));
        }
        if let Some(v) = salinity {
            alerts.push(Self::evaluate_salinity(v));
        }
        if let Some(v) = temperature {
            alerts.push(Self::evaluate_temperature(v));
        }
        alerts
    }

    /// Evaluates pH level:
    /// - Urgent: < 7.0 or > 9.0
    /// - Watch: 7.0 - 7.5 or 8.5 - 9.0
    /// - Optimal: 7.5 - 8.5
    pub fn evaluate_ph(ph: f64) -> WaterAlert {
        if ph < 7.0 {
            WaterAlert {
                parameter: "pH".to_string(),
                value: ph,
                unit: "".to_string(),
                severity: AlertSeverity::Urgent,
                message: format!("Critical low pH ({:.1}). High acidity risk to shrimp shell and gill tissue.", ph),
                recommendation: "Apply agricultural lime (CaCO3) or dolomite at 10-15 kg/acre immediately.".to_string(),
                telugu_message: format!("తీవ్రమైన తక్కువ pH ({:.1}). రొయ్యల కవచం మరియు మొప్పలకు ప్రమాదం.", ph),
                telugu_recommendation: "ఎకరాకు 10-15 కిలోల వ్యవసాయ సున్నం (CaCO3) లేదా డోలమైట్ వెంటనే వేయండి.".to_string(),
            }
        } else if ph > 9.0 {
            WaterAlert {
                parameter: "pH".to_string(),
                value: ph,
                unit: "".to_string(),
                severity: AlertSeverity::Urgent,
                message: format!("Critical high pH ({:.1}). Extreme risk of toxic un-ionized ammonia conversion.", ph),
                recommendation: "Apply fermented jaggery or molasses (5-10 kg/acre) with probiotic yeast to buffer alkalinity.".to_string(),
                telugu_message: format!("తీవ్రమైన అధిక pH ({:.1}). విషపూరిత అమ్మోనియా ప్రమాదం.", ph),
                telugu_recommendation: "ఎకరాకు 5-10 కిలోల బెల్లం మరియు ప్రోబయోటిక్ మిశ్రమాన్ని వేయండి.".to_string(),
            }
        } else if (7.0..7.5).contains(&ph) || (8.5..=9.0).contains(&ph) {
            WaterAlert {
                parameter: "pH".to_string(),
                value: ph,
                unit: "".to_string(),
                severity: AlertSeverity::Watch,
                message: if ph < 7.5 {
                    format!("Sub-optimal low pH ({:.1}). Pond buffering capacity is decreasing.", ph)
                } else {
                    format!("Sub-optimal high pH ({:.1}). Afternoon photosynthetic bloom driving pH up.", ph)
                },
                recommendation: if ph < 7.5 {
                    "Apply mild lime (5 kg/acre) and check morning alkalinity.".to_string()
                } else {
                    "Dilute with fresh water exchange or apply probiotics in early morning.".to_string()
                },
                telugu_message: if ph < 7.5 {
                    format!("pH కొద్దిగా తక్కువగా ఉంది ({:.1}).", ph)
                } else {
                    format!("pH కొద్దిగా ఎక్కువగా ఉంది ({:.1}).", ph)
                },
                telugu_recommendation: if ph < 7.5 {
                    "ఎకరాకు 5 కిలోల సున్నం వేయండి.".to_string()
                } else {
                    "ఉదయాన్నే ప్రోబయోటిక్స్ వేయండి మరియు తాజా నీటిని కలపండి.".to_string()
                },
            }
        } else {
            WaterAlert {
                parameter: "pH".to_string(),
                value: ph,
                unit: "".to_string(),
                severity: AlertSeverity::Optimal,
                message: format!("Optimal pH ({:.1}). Excellent ionic balance for shrimp growth.", ph),
                recommendation: "Maintain current feeding and liming schedule.".to_string(),
                telugu_message: format!("సరైన pH ({:.1}). రొయ్యల పెరుగుదలకు చాలా మంచిది.", ph),
                telugu_recommendation: "ప్రస్తుత మేత మరియు సున్నం నిర్వహణను కొనసాగించండి.".to_string(),
            }
        }
    }

    /// Evaluates Dissolved Oxygen (DO) in mg/L:
    /// - Urgent: < 3.0 mg/L (Critical Hypoxia Siren)
    /// - Watch: 3.0 - 4.0 mg/L
    /// - Optimal: > 4.0 mg/L
    pub fn evaluate_do(dissolved_oxygen: f64) -> WaterAlert {
        if dissolved_oxygen < 3.0 {
            WaterAlert {
                parameter: "Dissolved Oxygen".to_string(),
                value: dissolved_oxygen,
                unit: "mg/L".to_string(),
                severity: AlertSeverity::Urgent,
                message: format!("Critical Hypoxia Risk ({:.1} mg/L)! Immediate shrimp asphyxiation risk.", dissolved_oxygen),
                recommendation: "Activate 100% aerators immediately. Apply Sodium Percarbonate (2-3 kg/acre) emergency oxygen booster.".to_string(),
                telugu_message: format!("తీవ్రమైన ఆక్సిజన్ కొరత ({:.1} mg/L)! రొయ్యలు ఊపిరాడక చనిపోయే ప్రమాదం.", dissolved_oxygen),
                telugu_recommendation: "అన్ని ఎయిరేటర్లను వెంటనే ఆన్ చేయండి. ఎకరాకు 2-3 కిలోల ఆక్సిజన్ మాత్రలు వేయండి.".to_string(),
            }
        } else if dissolved_oxygen <= 4.0 {
            WaterAlert {
                parameter: "Dissolved Oxygen".to_string(),
                value: dissolved_oxygen,
                unit: "mg/L".to_string(),
                severity: AlertSeverity::Watch,
                message: format!("Low Dissolved Oxygen ({:.1} mg/L). Stress threshold approaching.", dissolved_oxygen),
                recommendation: "Turn on additional paddle aerators and reduce feed quantity by 25%.".to_string(),
                telugu_message: format!("ఆక్సిజన్ స్థాయి తక్కువగా ఉంది ({:.1} mg/L).", dissolved_oxygen),
                telugu_recommendation: "ఎయిరేటర్లను ఆన్ చేయండి మరియు మేతను 25% తగ్గించండి.".to_string(),
            }
        } else {
            WaterAlert {
                parameter: "Dissolved Oxygen".to_string(),
                value: dissolved_oxygen,
                unit: "mg/L".to_string(),
                severity: AlertSeverity::Optimal,
                message: format!("Optimal Dissolved Oxygen ({:.1} mg/L). High saturation level.", dissolved_oxygen),
                recommendation: "Maintain continuous aerator cycle during nocturnal hours.".to_string(),
                telugu_message: format!("సరైన ఆక్సిజన్ స్థాయి ({:.1} mg/L).", dissolved_oxygen),
                telugu_recommendation: "రాత్రి సమయాల్లో ఎయిరేటర్లు సరిగ్గా పనిచేసేలా చూసుకోండి.".to_string(),
            }
        }
    }

    /// Evaluates Un-ionized Ammonia (NH3) in mg/L:
    /// - Urgent: > 0.1 mg/L
    /// - Watch: 0.05 - 0.1 mg/L
    /// - Optimal: < 0.05 mg/L
    pub fn evaluate_ammonia(ammonia: f64) -> WaterAlert {
        if ammonia > 0.1 {
            WaterAlert {
                parameter: "Ammonia (NH3)".to_string(),
                value: ammonia,
                unit: "mg/L".to_string(),
                severity: AlertSeverity::Urgent,
                message: format!("Toxic Un-ionized Ammonia Spike ({:.2} mg/L NH3)! Severe gill damage and mortality risk.", ammonia),
                recommendation: "Perform 20% bottom water exchange, stop feeding for 1 meal, apply Yucca extract + Zeolite (25 kg/acre) and nitrifying bacteria.".to_string(),
                telugu_message: format!("తీవ్రమైన విషపూరిత అమ్మోనియా ({:.2} mg/L NH3)! మొప్పలు దెబ్బతినే ప్రమాదం.", ammonia),
                telugu_recommendation: "20% కింద నీటిని మార్చండి, ఒక పూట మేత ఆపండి, యుక్కా, జియోలైట్ మరియు నైట్రిఫైయింగ్ ప్రోబయోటిక్స్ వేయండి.".to_string(),
            }
        } else if ammonia >= 0.05 {
            WaterAlert {
                parameter: "Ammonia (NH3)".to_string(),
                value: ammonia,
                unit: "mg/L".to_string(),
                severity: AlertSeverity::Watch,
                message: format!("Elevated Un-ionized Ammonia ({:.2} mg/L NH3). Organic waste accumulation detected.", ammonia),
                recommendation: "Reduce daily feed by 15% and apply concentrated Bacillus soil probiotics.".to_string(),
                telugu_message: format!("అమ్మోనియా పెరుగుతోంది ({:.2} mg/L NH3). వ్యర్థాలు పేరుకుపోతున్నాయి.", ammonia),
                telugu_recommendation: "మేతను 15% తగ్గించి, బాసిల్లస్ ప్రోబయోటిక్స్ వేయండి.".to_string(),
            }
        } else {
            WaterAlert {
                parameter: "Ammonia (NH3)".to_string(),
                value: ammonia,
                unit: "mg/L".to_string(),
                severity: AlertSeverity::Optimal,
                message: format!("Safe Un-ionized Ammonia level ({:.2} mg/L NH3). Clean pond bottom ecosystem.", ammonia),
                recommendation: "Maintain regular sludge removal and bi-weekly probiotic dosing.".to_string(),
                telugu_message: format!("సురక్షితమైన అమ్మోనియా స్థాయి ({:.2} mg/L NH3).", ammonia),
                telugu_recommendation: "చెరువు అడుగుభాగాన్ని శుభ్రంగా ఉంచుకోండి.".to_string(),
            }
        }
    }

    /// Evaluates Alkalinity (CaCO3) in mg/L:
    /// - Watch: < 100 mg/L or > 150 mg/L
    /// - Optimal: 100 - 150 mg/L
    pub fn evaluate_alkalinity(alkalinity: f64) -> WaterAlert {
        if alkalinity < 100.0 {
            WaterAlert {
                parameter: "Alkalinity".to_string(),
                value: alkalinity,
                unit: "mg/L".to_string(),
                severity: AlertSeverity::Watch,
                message: format!("Low Alkalinity ({:.0} mg/L). Inadequate buffer causes wild pH swings and soft shell.", alkalinity),
                recommendation: "Apply sodium bicarbonate (NaHCO3) at 10-15 kg/acre or dolomite to raise above 120 mg/L.".to_string(),
                telugu_message: format!("క్షారత్వం తక్కువగా ఉంది ({:.0} mg/L). pH హెచ్చుతగ్గులు ఏర్పడతాయి.", alkalinity),
                telugu_recommendation: "ఎకరాకు 10-15 కిలోల సోడియం బైకార్బోనేట్ (సోడా) లేదా డోలమైట్ వేయండి.".to_string(),
            }
        } else if alkalinity <= 150.0 {
            WaterAlert {
                parameter: "Alkalinity".to_string(),
                value: alkalinity,
                unit: "mg/L".to_string(),
                severity: AlertSeverity::Optimal,
                message: format!("Optimal Alkalinity ({:.0} mg/L). Strong buffering capacity against pH fluctuation.", alkalinity),
                recommendation: "Maintain current mineral supplementation schedule.".to_string(),
                telugu_message: format!("సరైన క్షారత్వం ({:.0} mg/L). స్థిరమైన నీటి నాణ్యత.", alkalinity),
                telugu_recommendation: "ఖనిజ లవణాల నిర్వహణను ఇలాగే కొనసాగించండి.".to_string(),
            }
        } else {
            WaterAlert {
                parameter: "Alkalinity".to_string(),
                value: alkalinity,
                unit: "mg/L".to_string(),
                severity: AlertSeverity::Watch,
                message: format!("High Alkalinity ({:.0} mg/L). Potential mineral precipitation.", alkalinity),
                recommendation: "Monitor morning and evening pH; moderate lime applications.".to_string(),
                telugu_message: format!("అధిక క్షారత్వం ({:.0} mg/L).", alkalinity),
                telugu_recommendation: "సున్నం వాడకాన్ని తగ్గించండి మరియు pH ను గమనించండి.".to_string(),
            }
        }
    }

    /// Evaluates Salinity in ppt:
    /// - Watch: < 5 ppt or > 35 ppt
    /// - Optimal: 5 - 35 ppt
    pub fn evaluate_salinity(salinity: f64) -> WaterAlert {
        if !(5.0..=35.0).contains(&salinity) {
            WaterAlert {
                parameter: "Salinity".to_string(),
                value: salinity,
                unit: "ppt".to_string(),
                severity: AlertSeverity::Watch,
                message: if salinity < 5.0 {
                    format!("Low Inland Salinity ({:.1} ppt). Osmotic stress risk during molting.", salinity)
                } else {
                    format!("High Salinity ({:.1} ppt). Retarded growth rate and high mineral stress.", salinity)
                },
                recommendation: if salinity < 5.0 {
                    "Supplement Muriate of Potash (KCl @ 10 kg/acre) and Magnesium Sulfate (MgSO4 @ 15 kg/acre).".to_string()
                } else {
                    "Dilute with low-salinity freshwater if available.".to_string()
                },
                telugu_message: if salinity < 5.0 {
                    format!("ఉప్పు శాతం తక్కువగా ఉంది ({:.1} ppt). కుబుసం విడిచే సమయంలో ఒత్తిడి.", salinity)
                } else {
                    format!("ఉప్పు శాతం అధికంగా ఉంది ({:.1} ppt).", salinity)
                },
                telugu_recommendation: if salinity < 5.0 {
                    "ఎకరాకు 10 కిలోల పొటాష్ (KCl) మరియు 15 కిలోల మెగ్నీషియం సల్ఫేట్ అందించండి.".to_string()
                } else {
                    "సాధ్యమైతే మంచి నీటిని కలపండి.".to_string()
                },
            }
        } else {
            WaterAlert {
                parameter: "Salinity".to_string(),
                value: salinity,
                unit: "ppt".to_string(),
                severity: AlertSeverity::Optimal,
                message: format!("Optimal Salinity ({:.1} ppt). Excellent osmoregulation range.", salinity),
                recommendation: "Maintain standard water exchange regimen.".to_string(),
                telugu_message: format!("సరైన ఉప్పు శాతం ({:.1} ppt).", salinity),
                telugu_recommendation: "నీటి యాజమాన్యాన్ని ఇలాగే కొనసాగించండి.".to_string(),
            }
        }
    }

    /// Evaluates Water Temperature in °C:
    /// - Watch: < 24.0°C or > 33.0°C
    /// - Optimal: 24.0 - 33.0°C
    pub fn evaluate_temperature(temperature: f64) -> WaterAlert {
        if !(24.0..=33.0).contains(&temperature) {
            WaterAlert {
                parameter: "Temperature".to_string(),
                value: temperature,
                unit: "°C".to_string(),
                severity: AlertSeverity::Watch,
                message: if temperature < 24.0 {
                    format!("Low Water Temperature ({:.1}°C). Suppressed feeding metabolism and enzymatic slowdown.", temperature)
                } else {
                    format!("High Water Temperature ({:.1}°C). Accelerated DO depletion and biological oxygen demand.", temperature)
                },
                recommendation: if temperature < 24.0 {
                    "Reduce feeding by 15-20% and avoid cold early morning feedings.".to_string()
                } else {
                    "Increase aeration and monitor check trays 90 minutes after feeding.".to_string()
                },
                telugu_message: if temperature < 24.0 {
                    format!("తక్కువ ఉష్ణోగ్రత ({:.1}°C). మేత తీసుకోవడం తగ్గుతుంది.", temperature)
                } else {
                    format!("అధిక ఉష్ణోగ్రత ({:.1}°C). ఆక్సిజన్ వినియోగం వేగవంతం అవుతుంది.", temperature)
                },
                telugu_recommendation: if temperature < 24.0 {
                    "మేతను 15-20% తగ్గించండి.".to_string()
                } else {
                    "ఎయిరేటర్లను పెంచండి మరియు మేత తట్టలను 90 నిమిషాల తర్వాత పరిశీలించండి.".to_string()
                },
            }
        } else {
            WaterAlert {
                parameter: "Temperature".to_string(),
                value: temperature,
                unit: "°C".to_string(),
                severity: AlertSeverity::Optimal,
                message: format!("Optimal Temperature ({:.1}°C). Peak metabolic efficiency for penaeid shrimp.", temperature),
                recommendation: "Maintain 4-meal diurnal feeding schedule.".to_string(),
                telugu_message: format!("సరైన ఉష్ణోగ్రత ({:.1}°C).", temperature),
                telugu_recommendation: "4 పూటల మేత విధానాన్ని అనుసరించండి.".to_string(),
            }
        }
    }

    /// Evaluates water telemetry log for life-safety emergency alarms.
    pub fn evaluate_water_log_for_emergency(
        pond_id: &str,
        pond_name: &str,
        dissolved_oxygen: Option<f64>,
        ammonia: Option<f64>,
        triggered_at: DateTime<Utc>,
    ) -> Vec<EmergencyAlarm> {
        let mut alarms = Vec::new();

        if let Some(do_val) = dissolved_oxygen {
            if do_val < 3.5 {
                let is_lethal = do_val < 2.8;
                alarms.push(EmergencyAlarm {
                    id: format!("alarm_do_{}_{}", pond_id, triggered_at.timestamp_millis()),
                    pond_id: pond_id.to_string(),
                    pond_name: pond_name.to_string(),
                    parameter: "Dissolved Oxygen".to_string(),
                    measured_value: format!("{:.1} mg/L", do_val),
                    title: if is_lethal {
                        format!("LETHAL HYPOXIA CRASH in {} ({:.1} mg/L)", pond_name, do_val)
                    } else {
                        format!("Critical Low Dissolved Oxygen in {} ({:.1} mg/L)", pond_name, do_val)
                    },
                    telugu_title: if is_lethal {
                        format!("{} లో ప్రాణాంతక ఆక్సిజన్ పతనం ({:.1} mg/L)", pond_name, do_val)
                    } else {
                        format!("{} లో ఆక్సిజన్ ప్రమాదకర స్థాయికి పడిపోయింది ({:.1} mg/L)", pond_name, do_val)
                    },
                    checklist: vec![
                        "Turn ON all paddlewheel and spiral aerators at 100% capacity immediately.".to_string(),
                        "Broadcast Sodium Percarbonate (Oxygen tablets/granules) @ 2–3 kg/acre.".to_string(),
                        "HALT all feeding meals immediately until DO stabilizes above 4.5 mg/L.".to_string(),
                        "Start emergency borewell/reservoir water exchange (15–20%) if available.".to_string(),
                    ],
                    telugu_checklist: vec![
                        "తక్షణమే అన్ని ఏరేటర్లను (Paddlewheel Aerators) పూర్తి స్థాయిలో ఆన్ చేయండి.".to_string(),
                        "ఎకరానికి 2–3 కిలోల ఆక్సిజన్ టాబ్లెట్లు/గ్రాన్యూల్స్ (Sodium Percarbonate) చల్లండి.".to_string(),
                        "DO 4.5 mg/L దాటే వరకు మేత వేయడం పూర్తిగా ఆపివేయండి.".to_string(),
                        "అందుబాటులో ఉంటే 15–20% కొత్త నీటిని చెరువులోకి పంపండి.".to_string(),
                    ],
                    triggered_at,
                    acknowledged: false,
                });
            }
        }

        if let Some(nh3_val) = ammonia {
            if nh3_val >= 0.10 {
                alarms.push(EmergencyAlarm {
                    id: format!("alarm_nh3_{}_{}", pond_id, triggered_at.timestamp_millis()),
                    pond_id: pond_id.to_string(),
                    pond_name: pond_name.to_string(),
                    parameter: "Ammonia (TAN)".to_string(),
                    measured_value: format!("{:.2} ppm", nh3_val),
                    title: format!("Toxic Ammonia Spike in {} ({:.2} ppm)", pond_name, nh3_val),
                    telugu_title: format!("{} లో ప్రమాదకర అమోనియా పెరుగుదల ({:.2} ppm)", pond_name, nh3_val),
                    checklist: vec![
                        "Apply Yucca schidigera extract or Zeolite @ 25–40 kg/acre immediately.".to_string(),
                        "Reduce next 2 feed rations by 30% to stop nitrogenous waste buildup.".to_string(),
                        "Add fermented molasses + Bacillus nitrifying probiotics with strong aeration.".to_string(),
                        "Exchange 15–20% bottom water to flush accumulated sludge.".to_string(),
                    ],
                    telugu_checklist: vec![
                        "ఎకరానికి 25–40 కిలోల యుక్కా లేదా జియోలైట్ వేయండి.".to_string(),
                        "తదుపరి 2 పూటల మేతను 30% తగ్గించండి.".to_string(),
                        "బెల్లం మరియు నైట్రిఫైయింగ్ ప్రోబయోటిక్స్ మిశ్రమాన్ని వేయండి.".to_string(),
                        "15–20% అడుగు నీటిని మార్చండి.".to_string(),
                    ],
                    triggered_at,
                    acknowledged: false,
                });
            }
        }

        alarms
    }

    /// Nocturnal DO Crash Forecaster:
    /// Estimates dawn Dissolved Oxygen at 05:00 AM based on late-afternoon / evening DO,
    /// water temperature, DOC, estimated biomass, and whether aerators will run overnight.
    pub fn forecast_dawn_dissolved_oxygen(
        evening_do: f64,
        water_temp: f64,
        doc: i32,
        biomass_kg: f64,
        has_aerators_running: bool,
    ) -> (f64, AlertSeverity) {
        // Night respiration period: ~10 hours (7 PM to 5 AM)
        // Base sediment + shrimp respiration rate in mg/L per hour:
        // Biomass factor: 0.05 mg/L/hr per 1000 kg biomass
        let biomass_load = (biomass_kg / 1000.0) * 0.05;
        // Temperature factor: Q10 respiration doubles every 10°C; normalized around 28°C
        let temp_factor = 1.0 + ((water_temp - 28.0) * 0.04).clamp(-0.2, 0.4);
        // DOC factor: Older ponds have deeper sludge layers consuming more oxygen
        let doc_factor = 1.0 + ((doc as f64) * 0.003).clamp(0.0, 0.4);

        let gross_respiration_rate = (0.28 + biomass_load) * temp_factor * doc_factor; // mg/L/hr
        let aerator_replenishment = if has_aerators_running { 0.45 } else { 0.0 }; // mg/L/hr

        let net_hourly_depletion = (gross_respiration_rate - aerator_replenishment).max(0.04);
        let predicted_dawn_do = (evening_do - (net_hourly_depletion * 10.0)).clamp(0.5, 9.0);

        let severity = if predicted_dawn_do < 2.8 {
            AlertSeverity::Critical
        } else if predicted_dawn_do < 3.5 {
            AlertSeverity::Urgent
        } else if predicted_dawn_do < 4.0 {
            AlertSeverity::Watch
        } else {
            AlertSeverity::Optimal
        };

        ((predicted_dawn_do * 10.0).round() / 10.0, severity)
    }
}

/// Structured reading container for CLI and FFI evaluation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WaterQualityReading {
    pub ph: f64,
    pub dissolved_oxygen: f64,
    pub temperature_c: f64,
    pub salinity_ppt: f64,
    pub ammonia_mg_l: f64,
    pub alkalinity_mg_l: f64,
}

/// Comprehensive water evaluation report for CLI and dashboards.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WaterQualityEvaluation {
    pub severity: String,
    pub summary: String,
    pub nocturnal_forecast: String,
    pub alarms: Vec<String>,
}

/// Engine adapter for CLI and service integration.
pub struct WaterQualityEngine;

impl WaterQualityEngine {
    pub fn evaluate(reading: &WaterQualityReading) -> WaterQualityEvaluation {
        let alerts = AlertSystem::evaluate_parameters(
            Some(reading.ph),
            Some(reading.dissolved_oxygen),
            Some(reading.ammonia_mg_l),
            Some(reading.alkalinity_mg_l),
            Some(reading.salinity_ppt),
            Some(reading.temperature_c),
        );
        let emergency_alarms = AlertSystem::evaluate_water_log_for_emergency(
            "p1",
            "Pond 1",
            Some(reading.dissolved_oxygen),
            Some(reading.ammonia_mg_l),
            Utc::now(),
        );

        let max_severity = if alerts.iter().any(|a| a.severity == AlertSeverity::Urgent || a.severity == AlertSeverity::Critical) {
            "CRITICAL / URGENT"
        } else if alerts.iter().any(|a| a.severity == AlertSeverity::Watch) {
            "WATCH / CAUTION"
        } else {
            "OPTIMAL"
        };

        let (dawn_do, dawn_sev) = AlertSystem::forecast_dawn_dissolved_oxygen(
            reading.dissolved_oxygen,
            reading.temperature_c,
            60,
            3000.0,
            true,
        );

        let forecast_msg = format!("Predicted Dawn DO (05:00 AM): {:.1} mg/L ({:?})", dawn_do, dawn_sev);

        let alarm_strings: Vec<String> = emergency_alarms
            .into_iter()
            .map(|a| format!("{}: {}", a.title, a.checklist.first().cloned().unwrap_or_default()))
            .collect();

        WaterQualityEvaluation {
            severity: max_severity.to_string(),
            summary: format!("{} parameter(s) evaluated. Overall: {}", alerts.len(), max_severity),
            nocturnal_forecast: forecast_msg,
            alarms: alarm_strings,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ph_evaluation_boundaries() {
        let urgent_low = AlertSystem::evaluate_ph(6.8);
        assert_eq!(urgent_low.severity, AlertSeverity::Urgent);

        let watch_low = AlertSystem::evaluate_ph(7.2);
        assert_eq!(watch_low.severity, AlertSeverity::Watch);

        let optimal = AlertSystem::evaluate_ph(7.8);
        assert_eq!(optimal.severity, AlertSeverity::Optimal);

        let watch_high = AlertSystem::evaluate_ph(8.8);
        assert_eq!(watch_high.severity, AlertSeverity::Watch);

        let urgent_high = AlertSystem::evaluate_ph(9.2);
        assert_eq!(urgent_high.severity, AlertSeverity::Urgent);
    }

    #[test]
    fn test_do_evaluation_and_hypoxia_alarm() {
        let critical = AlertSystem::evaluate_do(2.4);
        assert_eq!(critical.severity, AlertSeverity::Urgent);

        let watch = AlertSystem::evaluate_do(3.6);
        assert_eq!(watch.severity, AlertSeverity::Watch);

        let optimal = AlertSystem::evaluate_do(5.2);
        assert_eq!(optimal.severity, AlertSeverity::Optimal);

        let alarms = AlertSystem::evaluate_water_log_for_emergency(
            "p1",
            "Pond 1",
            Some(2.5),
            Some(0.03),
            Utc::now(),
        );
        assert_eq!(alarms.len(), 1);
        assert!(alarms[0].title.contains("LETHAL HYPOXIA CRASH"));
        assert!(!alarms[0].checklist.is_empty());
    }

    #[test]
    fn test_emerson_unionized_ammonia_model() {
        // At 29°C, pH 8.0, TAN 1.0 mg/L -> NH3 is ~0.06 - 0.08 mg/L
        let nh3 = AlertSystem::calculate_unionized_nh3_from_tan(1.0, 8.0, 29.0);
        assert!(nh3 > 0.04 && nh3 < 0.12);

        // TAN <= 0 returns 0.0
        assert_eq!(AlertSystem::calculate_unionized_nh3_from_tan(0.0, 8.0, 29.0), 0.0);
        assert_eq!(AlertSystem::calculate_unionized_nh3_from_tan(-1.0, 8.0, 29.0), 0.0);
    }

    #[test]
    fn test_nocturnal_do_crash_forecaster() {
        // Without aerators: high biomass and high temp crashes DO
        let (predicted_do_no_air, severity_no_air) = AlertSystem::forecast_dawn_dissolved_oxygen(
            6.5,
            30.0,
            75,
            6000.0,
            false,
        );
        assert!(predicted_do_no_air < 3.5);
        assert!(severity_no_air.is_urgent_or_critical());

        // With aerators running: DO is replenished
        let (predicted_do_with_air, _severity_with_air) = AlertSystem::forecast_dawn_dissolved_oxygen(
            6.5,
            30.0,
            75,
            6000.0,
            true,
        );
        assert!(predicted_do_with_air > predicted_do_no_air);
    }
}
