use serde::{Deserialize, Serialize};

/// 12 ICAR-CIBA Shrimp Diseases + Healthy state supported by PrawnDoc AI vision diagnostics.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ShrimpDisease {
    Wssv,
    Ahpnd,
    Ehp,
    Wfs,
    BlackGill,
    Rms,
    Lss,
    Imnv,
    Vibriosis,
    Yhv,
    CottonShrimp,
    Healthy,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PathogenType {
    Viral,
    Bacterial,
    Microsporidian,
    Environmental,
    Nutritional,
    None,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DiseaseSeverity {
    None,
    Low,
    Medium,
    High,
    Critical,
}

impl DiseaseSeverity {
    pub fn as_str(&self) -> &'static str {
        match self {
            DiseaseSeverity::None => "none",
            DiseaseSeverity::Low => "low",
            DiseaseSeverity::Medium => "medium",
            DiseaseSeverity::High => "high",
            DiseaseSeverity::Critical => "critical",
        }
    }
}

/// Structured medical and biosecurity treatment protocol.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TreatmentProtocol {
    pub immediate_actions: Vec<String>,
    pub chemical_treatment: Vec<String>,
    pub feed_adjustments: Vec<String>,
    pub biosecurity_measures: Vec<String>,
    pub telugu_summary: String,
    pub telugu_recommendations: Vec<String>,
}

/// Complete disease profile with ICAR-CIBA verified guidelines.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DiseaseInfo {
    pub disease: ShrimpDisease,
    pub code: &'static str,
    pub name: &'static str,
    pub scientific_name: &'static str,
    pub telugu_name: &'static str,
    pub pathogen: PathogenType,
    pub severity: DiseaseSeverity,
    pub is_emergency_harvest: bool,
    pub key_symptoms_en: Vec<&'static str>,
    pub key_symptoms_te: Vec<&'static str>,
    pub water_implications: &'static str,
    pub treatment: TreatmentProtocol,
}

/// Output diagnostic report returned by the heuristic classifier and AI engine.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DiagnosticReport {
    pub disease_code: String,
    pub disease_name: String,
    pub scientific_name: String,
    pub telugu_name: String,
    pub confidence: f64,
    pub severity: String,
    pub is_emergency_harvest: bool,
    pub immediate_action: String,
    pub telugu_action: String,
    pub treatment_plan: Vec<String>,
    pub biosecurity_measures: Vec<String>,
    pub telugu_summary: String,
    pub telugu_recommendations: Vec<String>,
    pub matched_symptoms: Vec<String>,
}

/// Returns the static ICAR-CIBA protocol record for a given disease.
pub fn get_disease_info(disease: ShrimpDisease) -> DiseaseInfo {
    match disease {
        ShrimpDisease::Wssv => DiseaseInfo {
            disease: ShrimpDisease::Wssv,
            code: "WSSV",
            name: "White Spot Syndrome Virus",
            scientific_name: "Whispovirus (Nimaviridae)",
            telugu_name: "తెల్ల మచ్చల వైరస్ వ్యాధి (WSSV)",
            pathogen: PathogenType::Viral,
            severity: DiseaseSeverity::Critical,
            is_emergency_harvest: true,
            key_symptoms_en: vec![
                "White spots (0.5 - 2.0 mm) on inside of carapace and rostrum",
                "Rapid reduction in feed consumption within 24 hours",
                "Lethargic swimming along pond dykes near water surface",
                "Reddish discoloration of body and appendages",
                "Mass mortality reaching 80-100% within 48 to 72 hours",
            ],
            key_symptoms_te: vec![
                "తల పెంకు మరియు రోస్ట్రంపై తెల్లని మచ్చలు (0.5 - 2 మి.మీ.)",
                "రొయ్యలు మేత తినడం ఒక్కసారిగా తగ్గించడం",
                "చెరువు గట్ల వెంబడి నీటిపై నీరసంగా ఈదడం",
                "శరీరం మరియు ఈత కాళ్ళు ఎరుపు రంగులోకి మారడం",
                "2-3 రోజుల్లో 80-100% వరకు రొయ్యలు చనిపోవడం",
            ],
            water_implications: "Low DO (< 3.5 mg/L) and sudden water temperature fluctuations trigger virulent WSSV outbreaks.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Stop water exchange immediately to prevent transmitting virus to neighboring farms".into(),
                    "Maximize continuous aeration (keep DO > 5.0 mg/L)".into(),
                    "Immediately cease all feeding to reduce bottom organic load".into(),
                    "Evaluate emergency harvest if shrimp biomass > 15g count".into(),
                ],
                chemical_treatment: vec![
                    "If unmarketable, apply calcium hypochlorite (bleaching powder) at 30-35 ppm to disinfect pond water before discharge".into(),
                ],
                feed_adjustments: vec![
                    "Stop feed completely for affected ponds".into(),
                ],
                biosecurity_measures: vec![
                    "Disinfect all sampling nets and check trays with 50 ppm chlorine solution".into(),
                    "Strictly restrict labor and equipment movement between ponds".into(),
                    "Install bird scare lines to deter predatory birds from spreading dead shrimp".into(),
                ],
                telugu_summary: "తెల్ల మచ్చల వైరస్ వ్యాధి (WSSV) గుర్తించబడింది. వెంటనే నీటి మార్పిడిని ఆపండి, ఎయిరేషన్ పెంచండి మరియు మేత నిలిపివేయండి.".into(),
                telugu_recommendations: vec![
                    "నీటి మార్పిడిని వెంటనే నిలిపివేయండి".into(),
                    "ఎయిరేటర్లను నిరంతరం నడిపి ఆక్సిజన్ 5.0 mg/L పైగా ఉంచండి".into(),
                    "15 గ్రాములకు పైబడి ఉంటే వెంటనే ఎమర్జెన్సీ హార్వెస్ట్ చేయండి".into(),
                    "వలలు మరియు పరికరాలను క్లోరిన్ ద్రావణంతో శుభ్రపరచండి".into(),
                ],
            },
        },
        ShrimpDisease::Ahpnd => DiseaseInfo {
            disease: ShrimpDisease::Ahpnd,
            code: "AHPND",
            name: "Acute Hepatopancreatic Necrosis Disease (EMS/AHPND)",
            scientific_name: "Vibrio parahaemolyticus (carrying PirA/PirB binary toxins)",
            telugu_name: "ఈ ఎం ఎస్ / ఎ హెచ్ పి ఎన్ డి (EMS/AHPND) - పిత్తాశయ క్షీణత",
            pathogen: PathogenType::Bacterial,
            severity: DiseaseSeverity::Critical,
            is_emergency_harvest: false,
            key_symptoms_en: vec![
                "Pale, atrophied, and shrunken hepatopancreas (liver)",
                "Completely empty stomach and midgut line",
                "Sudden acute mortality within early culture phase (DOC 10 to 45)",
                "Soft shell and lethargy",
                "Black streaks in hepatopancreatic tubules",
            ],
            key_symptoms_te: vec![
                "కాలేయం (హెపటోపాంక్రియాస్) పాలిపోయి, చిన్నగా కుంచించుకుపోవడం",
                "కడుపు మరియు ప్రేగు లైను పూర్తిగా ఖాళీగా ఉండడం",
                "సాగు ప్రారంభంలో (10-45 రోజుల మధ్య) అకస్మాత్తుగా రొయ్యలు చనిపోవడం",
                "పెంకు మెత్తబడటం మరియు రొయ్యల్లో చురుకుదనం తగ్గడం",
            ],
            water_implications: "High organic sediment, excessive feeding, and alkaline pH (> 8.4) trigger PirA/PirB toxin expression.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Stop feeding completely for 24 to 48 hours to starve Vibrio populations".into(),
                    "Apply continuous aeration to maintain dissolved oxygen > 5.5 mg/L".into(),
                    "Dose pond with multi-strain Bacillus + Rhodobacter water probiotics at 2.0 kg/acre".into(),
                ],
                chemical_treatment: vec![
                    "Apply potassium diformate (organic acid salts) in feed at 3-5 g/kg when feeding resumes".into(),
                    "Avoid harsh chemical disinfectants that destroy beneficial pond microflora".into(),
                ],
                feed_adjustments: vec![
                    "Resume feeding at 50% ration using fermented probiotic-coated feed".into(),
                    "Supplement feed with gut phytogenics (garlic extract 10 ml/kg + turmeric)".into(),
                ],
                biosecurity_measures: vec![
                    "Siphon black pond bottom sludge daily".into(),
                    "Test water and soil Vibrio green colony counts on TCBS agar plates".into(),
                ],
                telugu_summary: "తీవ్రమైన EMS / AHPND వ్యాధి లక్షణాలు. తక్షణమే మేత ఆపి ప్రోబయోటిక్స్ వేయండి.".into(),
                telugu_recommendations: vec![
                    "24-48 గంటలు మేత ఆపి, ఆపై 50% మాత్రమే వేయండి".into(),
                    "ఎయిరేటర్లను నిరంతరం నడిపి ఆక్సిజన్ 5.5 mg/L పైగా ఉంచండి".into(),
                    "మంచి నాణ్యమైన బాసిల్లస్ ప్రోబయోటిక్స్ వాడండి".into(),
                ],
            },
        },
        ShrimpDisease::Ehp => DiseaseInfo {
            disease: ShrimpDisease::Ehp,
            code: "EHP",
            name: "Enterocytozoon hepatopenaei (Microsporidian)",
            scientific_name: "Enterocytozoon hepatopenaei",
            telugu_name: "ఇ హెచ్ పి (EHP) - పెరుగుదల లోపం వ్యాధి",
            pathogen: PathogenType::Microsporidian,
            severity: DiseaseSeverity::High,
            is_emergency_harvest: false,
            key_symptoms_en: vec![
                "Severe growth retardation and extreme size variation across pond",
                "DOC > 60 but shrimp weight stuck under 10-12g",
                "Floating white fecal strings near feed check trays",
                "FCR spikes drastically above 1.8 to 2.4",
                "Soft shells and empty intestines without acute mass mortality",
            ],
            key_symptoms_te: vec![
                "తీవ్రమైన పెరుగుదల లోపం మరియు సైజుల్లో హెచ్చుతగ్గులు",
                "60 రోజులు దాటినా రొయ్యల బరువు 10-12 గ్రాముల లోపే ఉండడం",
                "చెక్ ట్రేల వద్ద తెల్లటి రెట్ట తీగలు తేలియాడటం",
                "FCR అనూహ్యంగా 1.8 నుండి 2.4 పైకి పెరగడం",
            ],
            water_implications: "EHP spores persist in pond bottom soil and transmit horizontally through cannibalism of infected molts.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Sample hepatopancreatic tissue for spore-count microscopy and PCR screening".into(),
                    "Perform aggressive bottom sludge siphoning twice daily".into(),
                    "Adjust daily feeding rate down to actual consumed biomass to prevent feed wastage".into(),
                ],
                chemical_treatment: vec![
                    "Top-dress feed with herbal anti-microsporidial formulation containing Curcuma longa and thymol".into(),
                    "Dose potassium monopersulfate (KMPS) at 1.5 ppm to oxidize spores in water column".into(),
                ],
                feed_adjustments: vec![
                    "Incorporate gut acidifiers (formic/propionic acid blend) at 4 g/kg feed".into(),
                    "Enrich diet with digestive enzymes and yeast beta-glucans (5 g/kg)".into(),
                ],
                biosecurity_measures: vec![
                    "Screen all post-larvae (PL) via real-time PCR before stocking".into(),
                    "Treat pond bottom soil between crops with quicklime (CaO at 2 metric tons/ha) to achieve soil pH > 12".into(),
                ],
                telugu_summary: "EHP మైక్రోస్పోరిడియన్ పెరుగుదల లోపం గుర్తించబడింది. మేతను నియంత్రించండి మరియు గట్ ప్రోబయోటిక్స్ వేయండి.".into(),
                telugu_recommendations: vec![
                    "మేత వృధా కాకుండా చెక్ ట్రేల ఆధారంగా తగ్గించండి".into(),
                    "రొయ్యల జీర్ణశక్తిని పెంచే ఆర్గానిక్ యాసిడ్లు, ఎంజైములు మేతలో కలపండి".into(),
                    "చెరువు అడుగున వ్యర్థాలను సైఫన్ ద్వారా తొలగించండి".into(),
                ],
            },
        },
        ShrimpDisease::Wfs => DiseaseInfo {
            disease: ShrimpDisease::Wfs,
            code: "WFS",
            name: "White Feces Syndrome",
            scientific_name: "Transformed microvilli / Vibrio harveyi / EHP interaction",
            telugu_name: "తెల్ల రెట్ట వ్యాధి (White Feces Syndrome - WFS)",
            pathogen: PathogenType::Bacterial,
            severity: DiseaseSeverity::High,
            is_emergency_harvest: false,
            key_symptoms_en: vec![
                "Floating strings of white feces on pond water surface and check trays",
                "White or vermiform strings packed with sloughed transformed microvilli",
                "Drastic drop in feed intake (30-50% drop within 48 hours)",
                "Loose, spongy exoskeleton and dark, congested hepatopancreas",
                "Gradual daily mortality at pond bottom",
            ],
            key_symptoms_te: vec![
                "నీటి ఉపరితలంపై మరియు చెక్ ట్రేలలో తెల్లటి రెట్ట తీగలు తేలియాడడం",
                "రొయ్యల మేత వినియోగం 30-50% వరకు పడిపోవడం",
                "పెంకు వదులుగా మారడం మరియు కాలేయం రంగు మారడం",
                "రోజువారీ చనిపోయే రొయ్యల సంఖ్య క్రమంగా పెరగడం",
            ],
            water_implications: "Excess organic loading, blue-green algae blooms, and elevated bottom vibrio colonies trigger WFS shedding.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Immediately cut feeding ration by 40-50% for 3 to 5 days".into(),
                    "Skim and physically remove floating fecal strings from pond surface using fine mesh scoop nets".into(),
                    "Boost aeration to oxidize dissolved organics".into(),
                ],
                chemical_treatment: vec![
                    "Apply yucca extract and zeolite to bind toxic ammonia and hydrogen sulfide".into(),
                    "Incorporate garlic paste (15 g/kg) and activated carbon (5 g/kg) in feed as toxin binder".into(),
                ],
                feed_adjustments: vec![
                    "Coat pellets with high-potency lactic acid bacteria (Lactobacillus acidophilus)".into(),
                    "Add Vitamin C (5 g/kg) to stimulate gut epithelial tissue regeneration".into(),
                ],
                biosecurity_measures: vec![
                    "Avoid sudden salinity shocks or drastic water exchanges".into(),
                    "Control toxic cyanobacterial (microcystis) blooms".into(),
                ],
                telugu_summary: "తెల్ల రెట్ట వ్యాధి (WFS) సోకింది. మేత 40% తగ్గించి, వెల్లుల్లి గుజ్జు మరియు లాక్టోబాసిల్లస్ ప్రోబయోటిక్స్ అందించండి.".into(),
                telugu_recommendations: vec![
                    "మేతను వెంటనే 40-50% తగ్గించండి".into(),
                    "తేలియాడే తెల్ల రెట్టను వలలతో తొలగించండి".into(),
                    "మేతలో వెల్లుల్లి రసం (10-15 మి.లీ/కిలో) మరియు ప్రోబయోటిక్స్ కలపండి".into(),
                ],
            },
        },
        ShrimpDisease::BlackGill => DiseaseInfo {
            disease: ShrimpDisease::BlackGill,
            code: "BLACK_GILL",
            name: "Black Gill Disease / Melanization",
            scientific_name: "Fusarium solani / Heavy silt clogging / Hydrogen sulfide melanization",
            telugu_name: "నల్ల మొప్పల వ్యాధి (Black Gill Disease)",
            pathogen: PathogenType::Environmental,
            severity: DiseaseSeverity::Medium,
            is_emergency_harvest: false,
            key_symptoms_en: vec![
                "Brown, brownish-black or jet black discoloration of gill branchial filaments",
                "Severe respiratory distress; shrimp congregate near aerator splash zones",
                "Accumulation of black organic detritus in branchial chambers",
                "Foul odor in water and black toxic hydrogen sulfide sludge on pond bottom",
            ],
            key_symptoms_te: vec![
                "మొప్పల భాగాలు గోధుమ లేదా నలుపు రంగులోకి మారడం",
                "శ్వాస తీసుకోవడంలో ఇబ్బంది పడుతూ రొయ్యలు ఎయిరేటర్ల దగ్గరకు చేరడం",
                "మొప్పలలో బురద, వ్యర్థాలు పేరుకుపోవడం",
                "చెరువు అడుగున నల్లటి బురద మరియు హైడ్రోజన్ సల్ఫైడ్ దుర్వాసన",
            ],
            water_implications: "Caused by low bottom DO (< 3.0 mg/L), acidic bottom soil, and hydrogen sulfide (H2S > 0.03 mg/L).",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Increase aeration immediately to maintain bottom DO > 4.5 mg/L".into(),
                    "Perform bottom drain flushing or siphon off dead black sludge".into(),
                    "Apply agricultural quicklime (CaO at 50 kg/acre) or dolomite to stabilize pH > 7.8".into(),
                ],
                chemical_treatment: vec![
                    "Dose hydrogen peroxide (30%) at 2-3 liters/acre for rapid bottom oxygenation".into(),
                    "Apply benzalkonium chloride (BKC 50%) at 1.0 ppm if fungal hyphae (Fusarium) confirmed under microscope".into(),
                ],
                feed_adjustments: vec![
                    "Reduce daily feed by 25% until gill clearing is observed".into(),
                    "Fortify feed with Vitamin C (5 g/kg) and mineral binders".into(),
                ],
                biosecurity_measures: vec![
                    "Test bottom soil oxidation-reduction potential (ORP) and keep above -100 mV".into(),
                    "Ensure aerators are angled properly to sweep sludge toward central drain".into(),
                ],
                telugu_summary: "నల్ల మొప్పల వ్యాధి గుర్తించబడింది. ఎయిరేషన్ పెంచి, అడుగు బురదను శుభ్రం చేయండి మరియు డోలమైట్ వేయండి.".into(),
                telugu_recommendations: vec![
                    "ఎయిరేటర్లు పెంచి ఆక్సిజన్ 4.5 mg/L పైగా ఉండేలా చూడండి".into(),
                    "చెరువు అడుగున పేరుకున్న నల్ల బురదను సైఫన్ చేయండి".into(),
                    "ఎకరాకు 50 కిలోల డోలమైట్ లేదా సున్నం చల్లండి".into(),
                ],
            },
        },
        ShrimpDisease::Rms => DiseaseInfo {
            disease: ShrimpDisease::Rms,
            code: "RMS",
            name: "Running Mortality Syndrome",
            scientific_name: "Complex etiology (Vibrio + viral co-infections + organic stress)",
            telugu_name: "రన్నింగ్ మోర్టాలిటీ సిండ్రోమ్ (RMS)",
            pathogen: PathogenType::Bacterial,
            severity: DiseaseSeverity::High,
            is_emergency_harvest: false,
            key_symptoms_en: vec![
                "Continuous low-level mortality (1-3% daily) over extended culture period",
                "Dead and moribund shrimp found at bottom during check-tray inspection",
                "Empty digestive tract and pale whitish musculature",
                "Absence of distinct white spots or visible external lesions",
            ],
            key_symptoms_te: vec![
                "రోజువారీ స్వల్పంగా 1-3% చొప్పున రొయ్యలు చనిపోతూ ఉండడం",
                "చెక్ ట్రేలలో లేదా అడుగున చనిపోయిన రొయ్యలు కనిపించడం",
                "ఖాళీ పేగు మరియు కండరాలలో పాలిపోయిన రంగు",
                "ఎలాంటి స్పష్టమైన తెల్ల మచ్చలు లేకుండానే చనిపోవడం",
            ],
            water_implications: "Exacerbated by deteriorating bottom conditions, high unionized ammonia, and mineral depletion.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Cut feed by 30% and inspect feed consumption every 2 hours".into(),
                    "Continuous paddle-wheel aeration day and night".into(),
                    "Perform deep bottom siphoning to purge decaying organic detritus".into(),
                ],
                chemical_treatment: vec![
                    "Dose multi-strain photosynthetic bacteria (Rhodobacter) at 5 L/acre".into(),
                    "Broadcast agricultural gypsum and magnesium chloride to stabilize ionic balance".into(),
                ],
                feed_adjustments: vec![
                    "Add beta-glucans (10 g/kg) and Vitamin C (5 g/kg) as immune boosters".into(),
                    "Incorporate spirulina powder (5 g/kg) in feed".into(),
                ],
                biosecurity_measures: vec![
                    "Maintain strict water filtration (300 micron mesh nets on intake canal)".into(),
                    "Avoid drastic salinity swings during monsoon season".into(),
                ],
                telugu_summary: "రన్నింగ్ మోర్టాలిటీ సిండ్రోమ్ (RMS) గుర్తించబడింది. మేత 30% తగ్గించి, రోడోబాక్టర్ బ్యాక్టీరియా మరియు ఇమ్యూనోస్టిమ్యులెంట్స్ వాడండి.".into(),
                telugu_recommendations: vec![
                    "మేతను 30% తగ్గించి క్రమం తప్పకుండా గమనించండి".into(),
                    "రోడోబాక్టర్ వంటి కిరణజన్య సంయోగ బ్యాక్టీరియాను చెరువులో వేయండి".into(),
                    "విటమిన్ సి మరియు బీటా-గ్లూకాన్లను మేతలో కలపండి".into(),
                ],
            },
        },
        ShrimpDisease::Lss => DiseaseInfo {
            disease: ShrimpDisease::Lss,
            code: "LSS",
            name: "Loose Shell Syndrome",
            scientific_name: "Nutritional mineral imbalance / Chronic environmental stress",
            telugu_name: "వదులు పెంకు వ్యాధి (Loose Shell Syndrome - LSS)",
            pathogen: PathogenType::Nutritional,
            severity: DiseaseSeverity::Medium,
            is_emergency_harvest: false,
            key_symptoms_en: vec![
                "Spongy, loose exoskeleton with visible fluid pocket between carapace and muscle",
                "Flaccid, watery muscular tissue upon peeling",
                "Incomplete molting (exuviae trapped on walking legs)",
                "Soft rostrum and poor survival during harvesting",
            ],
            key_symptoms_te: vec![
                "పెంకు వదులుగా మారి, కండరానికి పెంకుకి మధ్య నీరు చేరడం",
                "రొయ్య ఒంటి భాగం మెత్తగా మరియు నీరుగా ఉండడం",
                "కుబుసం విడవడంలో ఆటంకాలు ఏర్పడడం (సగమే కుబుసం విడవడం)",
            ],
            water_implications: "Deficiency in dissolved calcium (Ca), magnesium (Mg), potassium (K), or alkalinity < 100 mg/L.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Measure pond water hardness, total alkalinity, and Mg:Ca:K ionic ratio".into(),
                    "Target ionic ratio: Mg ~ 3x Ca, K ~ 1x Ca relative to salinity".into(),
                    "Apply mineral supplements immediately to reach alkalinity > 130 mg/L".into(),
                ],
                chemical_treatment: vec![
                    "Broadcast calcium chloride (CaCl2 at 25 kg/acre) and magnesium sulfate (MgSO4 at 50 kg/acre)".into(),
                    "Dose agricultural dolomite at 100 kg/acre to buffer pH and carbonate levels".into(),
                ],
                feed_adjustments: vec![
                    "Top-dress feed with bio-available chelated mineral pre-mix at 20 g/kg feed".into(),
                    "Add cholesterol and lecithin (5 g/kg) to promote ecdysteroid synthesis for complete molting".into(),
                ],
                biosecurity_measures: vec![
                    "Avoid harvesting during active lunar molting cycles (full moon / new moon)".into(),
                    "Maintain stable salinity and avoid abrupt low-salinity bore well surges".into(),
                ],
                telugu_summary: "వదులు పెంకు వ్యాధి (LSS) ఖనిజ లవణాల లోపం వల్ల వచ్చింది. మెగ్నీషియం, కాల్షియం మరియు డోలమైట్ వేయండి.".into(),
                telugu_recommendations: vec![
                    "చెరువులో ఆల్కలీనిటీ 130 mg/L కంటే ఎక్కువ ఉండేలా డోలమైట్ వేయండి".into(),
                    "మెగ్నీషియం సల్ఫేట్, కాల్షియం క్లోరైడ్ ఖనిజాలు చల్లండి".into(),
                    "మేతలో కీలేటెడ్ మినరల్ పౌడర్ (20 గ్రా/కిలో) కలపండి".into(),
                ],
            },
        },
        ShrimpDisease::Imnv => DiseaseInfo {
            disease: ShrimpDisease::Imnv,
            code: "IMNV",
            name: "Infectious Myonecrosis Virus",
            scientific_name: "Infectious myonecrosis virus (Totiviridae)",
            telugu_name: "కండరాల క్షీణత వైరస్ (IMNV)",
            pathogen: PathogenType::Viral,
            severity: DiseaseSeverity::Critical,
            is_emergency_harvest: true,
            key_symptoms_en: vec![
                "Focal to extensive white opaque necrotic areas in striated abdominal muscle",
                "Opaque cooked-meat appearance of the tail muscle segments",
                "Tail fan reddening and necrosis",
                "Acute mortality following severe stress events (cast netting, DO drop, temperature drop)",
            ],
            key_symptoms_te: vec![
                "రొయ్య తోక కండరాలు తెల్లగా ఉడికించిన మాంసంలా మారడం",
                "తోక కండరాలలో రక్తస్రావ మచ్చలు మరియు తోక ఎరుపు రంగు తిరగడం",
                "ఒత్తిడి (వలలు వేసినప్పుడు లేదా ఆక్సిజన్ తగ్గినప్పుడు) తక్షణ మరణాలు",
            ],
            water_implications: "Environmental stressors (sudden temperature change > 3°C or DO < 3.0 mg/L) induce lethal systemic viremia.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Strictly isolate pond; prohibit cast netting and unnecessary pond sampling".into(),
                    "Maintain continuous maximum aeration with DO > 5.5 mg/L".into(),
                    "Cease feeding for 24 hours to reduce metabolic oxygen demand".into(),
                    "Emergency harvest if shrimp are at marketable weight (> 14g)".into(),
                ],
                chemical_treatment: vec![
                    "Apply potassium monopersulfate (KMPS 50%) at 1.0 ppm as mild biosecurity water sanitizer".into(),
                ],
                feed_adjustments: vec![
                    "Resume feed at 50% with high-dose Vitamin C (10 g/kg) and anti-stress electrolytes".into(),
                    "Avoid high-protein feeds that increase nitrogenous waste".into(),
                ],
                biosecurity_measures: vec![
                    "Sanitize all equipment with 200 ppm chlorine solution".into(),
                    "Do not transfer water or animals between ponds".into(),
                ],
                telugu_summary: "IMNV కండరాల క్షీణత వైరస్ గుర్తించబడింది. ఒత్తిడిని తగ్గించండి, ఎయిరేషన్ పెంచండి మరియు అవసరమైతే హార్వెస్ట్ చేయండి.".into(),
                telugu_recommendations: vec![
                    "వలలు వేయడం ఆపండి, రొయ్యలను ఒత్తిడికి గురిచేయవద్దు".into(),
                    "ఆక్సిజన్ 5.5 mg/L పైగా ఉండేలా ఎయిరేటర్లు నిరంతరం నడపండి".into(),
                    "మార్కెట్ సైజు ఉంటే వెంటనే హార్వెస్ట్ చేయడం శ్రేయస్కరం".into(),
                ],
            },
        },
        ShrimpDisease::Vibriosis => DiseaseInfo {
            disease: ShrimpDisease::Vibriosis,
            code: "VIBRIOSIS",
            name: "Luminescent Bacterial Vibriosis",
            scientific_name: "Vibrio harveyi / Vibrio alginolyticus / Vibrio vulnificus",
            telugu_name: "విబ్రియోసిస్ / మెరిసే బ్యాక్టీరియా వ్యాధి (Vibriosis)",
            pathogen: PathogenType::Bacterial,
            severity: DiseaseSeverity::High,
            is_emergency_harvest: false,
            key_symptoms_en: vec![
                "Greenish bioluminescence visible in dark night conditions across body",
                "Melanized black erosive lesions on cuticle and appendages (shell rot)",
                "Cloudy hepatopancreas and brown or dark coloration of body",
                "High bacterial CFU counts (> 10^3 CFU/ml green colonies on TCBS agar)",
            ],
            key_symptoms_te: vec![
                "చీకటిలో రొయ్యలు ఆకుపచ్చ రంగులో మెరవడం (బయోల్యూమినిసెన్స్)",
                "పెంకు మరియు కాళ్ళపై నల్లటి మచ్చలు (షెల్ రాట్)",
                "రొయ్యల కాలేయం మసకబారడం మరియు చురుకుదనం తగ్గడం",
            ],
            water_implications: "Triggered by high salinity (> 25 ppt), water temperatures > 30°C, and accumulation of unconsumed feed.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Reduce daily feed allowance by 35% immediately".into(),
                    "Broadcast multi-strain competitive Bacillus subtilis + licheniformis probiotics at 2.5 kg/acre".into(),
                    "Aerate aggressively to prevent hypoxic stratification".into(),
                ],
                chemical_treatment: vec![
                    "Apply biodegradable disinfectant (e.g. iodine 20% at 1.0 L/acre) if luminescence is severe".into(),
                ],
                feed_adjustments: vec![
                    "Feed fermented yeast culture (Saccharomyces cerevisiae) to outcompete vibrio in gut".into(),
                    "Add oregano oil or thymol blend (2 ml/kg feed) as natural bactericide".into(),
                ],
                biosecurity_measures: vec![
                    "Monitor weekly luminous bacteria plate counts on TCBS agar".into(),
                    "Avoid sudden salinity rises; flush pond surface during extreme heatwaves".into(),
                ],
                telugu_summary: "విబ్రియోసిస్ (మెరిసే బ్యాక్టీరియా) వ్యాధి గుర్తించబడింది. మేత తగ్గించి, అయోడిన్ లేదా బాసిల్లస్ ప్రోబయోటిక్స్ వేయండి.".into(),
                telugu_recommendations: vec![
                    "మేతను 35% తగ్గించండి".into(),
                    "రాత్రి వేళల్లో మెరిసే స్వభావం ఉంటే అయోడిన్ (20%) ఎకరాకు 1 లీటరు వేయండి".into(),
                    "మరుసటి రోజు నాణ్యమైన బాసిల్లస్ ప్రోబయోటిక్స్ వేసి బ్యాక్టీరియాను అణచివేయండి".into(),
                ],
            },
        },
        ShrimpDisease::Yhv => DiseaseInfo {
            disease: ShrimpDisease::Yhv,
            code: "YHV",
            name: "Yellow Head Virus",
            scientific_name: "Yellow head virus genotype 1 (Roniviridae)",
            telugu_name: "పసుపు తల వైరస్ వ్యాధి (Yellow Head Virus - YHV)",
            pathogen: PathogenType::Viral,
            severity: DiseaseSeverity::Critical,
            is_emergency_harvest: true,
            key_symptoms_en: vec![
                "Marked yellowish discoloration of the cephalothorax (head) and gills",
                "Bleaching and pale translucency of the overall shrimp body",
                "Abnormally rapid feed intake spike for 1-2 days followed by total feeding cessation",
                "Shrimp swim erratically near pond edge followed by catastrophic mass mortality within 3-5 days",
            ],
            key_symptoms_te: vec![
                "రొయ్య తల భాగం మరియు మొప్పలు పసుపు రంగులోకి మారడం",
                "శరీరం మొత్తం పాలిపోయి కాంతిహీనంగా మారడం",
                "రెండు రోజులు విపరీతంగా మేత తిని, ఆపై అకస్మాత్తుగా మేత పూర్తిగా ఆపేయడం",
                "గట్ల వెంబడి రొయ్యలు తిరుగుతూ 3-5 రోజుల్లో పెద్ద సంఖ్యలో చనిపోవడం",
            ],
            water_implications: "Water temperatures > 32°C and high organic loading compound explosive viral replication.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Completely quarantine the infected pond; cease water discharge and exchange".into(),
                    "Halt all feeding immediately".into(),
                    "If shrimp > 12g, perform emergency harvest with zero discharge containment".into(),
                ],
                chemical_treatment: vec![
                    "In unmarketable crops, treat water with 30 ppm calcium hypochlorite (active chlorine) to destroy viral particles".into(),
                ],
                feed_adjustments: vec![
                    "Zero feed in infected ponds".into(),
                ],
                biosecurity_measures: vec![
                    "Dispose of dead shrimp safely by deep pit burial with lime".into(),
                    "Establish crab fencing and bird nets to prevent vector transmission".into(),
                ],
                telugu_summary: "ప్రమాదకరమైన పసుపు తల వైరస్ (YHV) వ్యాధి. నీటి మార్పిడి పూర్తిగా ఆపి, తక్షణ ఎమర్జెన్సీ హార్వెస్ట్ చేపట్టండి.".into(),
                telugu_recommendations: vec![
                    "చెరువు నుండి నీటిని బయటకు వదలవద్దు".into(),
                    "రొయ్యల సైజు బాగుంటే వెంటనే ఎమర్జెన్సీ హార్వెస్ట్ చేయండి".into(),
                    "మేత పూర్తిగా నిలిపివేయండి".into(),
                ],
            },
        },
        ShrimpDisease::CottonShrimp => DiseaseInfo {
            disease: ShrimpDisease::CottonShrimp,
            code: "COTTON_SHRIMP",
            name: "Microsporidiosis / Cotton Shrimp (Milky Disease)",
            scientific_name: "Thelohania / Agmasoma penaei (Microsporidian)",
            telugu_name: "దూది రొయ్య వ్యాధి / కాటన్ ష్రింప్ (Cotton Shrimp Disease)",
            pathogen: PathogenType::Microsporidian,
            severity: DiseaseSeverity::Medium,
            is_emergency_harvest: false,
            key_symptoms_en: vec![
                "Milky white, cotton-like opacity throughout abdominal musculature",
                "Loss of muscle elasticity and rubbery flesh texture",
                "Blue-black pigmentation spots on abdominal cuticular segments",
                "Sluggish crawl along pond bottom with poor market value upon harvest",
            ],
            key_symptoms_te: vec![
                "తోక కండరాలు దూది వలే తెల్లగా మసకబారిపోవడం",
                "కండరాల స్థితిస్థాపకత కోల్పోయి రబ్బరులా మారడం",
                "రొయ్యలు చురుగ్గా ఈదలేక అడుగున నెమ్మదిగా కదలడం",
            ],
            water_implications: "Microsporidian spores are ingested through benthic detritus and intermediate fish/crustacean hosts.",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Cull visibly affected milky shrimp during check-tray monitoring".into(),
                    "Never discard culled shrimp back into the pond water or canal".into(),
                    "Perform intermediate pond siphoning to remove organic bottom detritus".into(),
                ],
                chemical_treatment: vec![
                    "Disinfect pond water column with chlorine dioxide at 0.5 ppm".into(),
                ],
                feed_adjustments: vec![
                    "Supplement feed with garlic extract (10 ml/kg) and thymol essential oil".into(),
                    "Add gut probiotic strains capable of competitive spore suppression".into(),
                ],
                biosecurity_measures: vec![
                    "Eradicate wild fish and crabs which act as intermediate spore reservoirs".into(),
                    "Apply quicklime (CaO at 200 kg/acre) during pond preparation to sterilize soil spores".into(),
                ],
                telugu_summary: "కాటన్ ష్రింప్ / దూది రొయ్య వ్యాధి గుర్తించబడింది. సోకిన రొయ్యలను తొలగించండి మరియు గార్లిక్ ఎక్స్‌ట్రాక్ట్ అందించండి.".into(),
                telugu_recommendations: vec![
                    "దూదిలా మారిన రొయ్యలను చెక్ ట్రేల నుంచి ఎప్పటికప్పుడు ఏరివేయండి".into(),
                    "మేతలో వెల్లుల్లి రసం మరియు రోగనిరోధక పౌడర్ కలపండి".into(),
                    "చెరువులో ఇతర చేపలు, పీతలు చేరకుండా ఫిల్టర్లు వాడండి".into(),
                ],
            },
        },
        ShrimpDisease::Healthy => DiseaseInfo {
            disease: ShrimpDisease::Healthy,
            code: "HEALTHY",
            name: "Healthy Specimen (Penaeus vannamei)",
            scientific_name: "Litopenaeus vannamei (Optimal physiological condition)",
            telugu_name: "ఆరోగ్యకరమైన రొయ్యలు (Healthy Specimen)",
            pathogen: PathogenType::None,
            severity: DiseaseSeverity::None,
            is_emergency_harvest: false,
            key_symptoms_en: vec![
                "Clear, glassy, translucent carapace and muscular tissue",
                "Completely full, uniform dark digestive tract (gut line)",
                "Clean pinkish branchial gill filaments with zero silt or fouling",
                "Active, energetic escape response and crisp exoskeleton firmness",
                "Even pigmentation across uropods and telson without redness or lesions",
            ],
            key_symptoms_te: vec![
                "స్వచ్ఛమైన గాజు లాంటి పారదర్శక శరీర రూపం",
                "మేతతో పూర్తిగా నిండిన నల్లటి ఆహార నాళం (ప్రేగు)",
                "ఎలాంటి బురద లేకుండా శుభ్రంగా ఉన్న గులాబీ రంగు మొప్పలు",
                "ఎంతో చురుకుగా ఈదే శక్తి మరియు గట్టి పెంకు",
            ],
            water_implications: "Water quality parameters are within optimal ranges (DO > 4.5 mg/L, pH 7.6 - 8.3, Ammonia < 0.05 mg/L).",
            treatment: TreatmentProtocol {
                immediate_actions: vec![
                    "Maintain standard scientific feeding schedule based on daily check-tray consumption".into(),
                    "Keep paddle-wheel aeration running according to biomass load".into(),
                ],
                chemical_treatment: vec![
                    "No chemical intervention required. Continue regular probiotic maintenance dosing".into(),
                ],
                feed_adjustments: vec![
                    "Feed high-protein standard crumble or pellet feed tailored for current DOC and ABW".into(),
                ],
                biosecurity_measures: vec![
                    "Continue weekly biometry sampling (ABW, CV% uniformity, health index)".into(),
                    "Maintain bio-security boundary nets and sanitizing footbaths at pond dykes".into(),
                ],
                telugu_summary: "రొయ్యలు సంపూర్ణ ఆరోగ్యంగా ఉన్నాయి! ప్రస్తుత మేత మరియు నీటి యాజమాన్య పద్ధతులను కొనసాగించండి.".into(),
                telugu_recommendations: vec![
                    "ప్రస్తుత మేత పట్టికను యథావిధిగా కొనసాగించండి".into(),
                    "ఆక్సిజన్ ఎల్లప్పుడూ 4.5 mg/L పైగా ఉండేలా చూసుకోండి".into(),
                    "వారం వారం రొయ్యల బరువు మరియు పెరుగుదలను రికార్డ్ చేయండి".into(),
                ],
            },
        },
    }
}

/// Heuristic symptom-matching diagnostic engine.
/// Evaluates visual keyword findings and environmental factors to produce an ICAR-CIBA diagnosis.
pub fn diagnose_symptoms(
    symptoms: &[&str],
    doc: Option<u32>,
    do_mg_l: Option<f64>,
) -> DiagnosticReport {
    let combined_text = symptoms.join(" ").to_lowercase();

    // Check for clear healthy markers first if explicit
    if combined_text.contains("healthy")
        || combined_text.contains("glassy")
        || combined_text.contains("clean gills")
        || (combined_text.contains("full gut") && !combined_text.contains("spot") && !combined_text.contains("feces"))
    {
        return build_report_from_info(get_disease_info(ShrimpDisease::Healthy), 0.96, symptoms);
    }

    let mut scores: Vec<(ShrimpDisease, f64)> = vec![
        (ShrimpDisease::Wssv, 0.0),
        (ShrimpDisease::Ahpnd, 0.0),
        (ShrimpDisease::Ehp, 0.0),
        (ShrimpDisease::Wfs, 0.0),
        (ShrimpDisease::BlackGill, 0.0),
        (ShrimpDisease::Rms, 0.0),
        (ShrimpDisease::Lss, 0.0),
        (ShrimpDisease::Imnv, 0.0),
        (ShrimpDisease::Vibriosis, 0.0),
        (ShrimpDisease::Yhv, 0.0),
        (ShrimpDisease::CottonShrimp, 0.0),
    ];

    for (disease, score) in scores.iter_mut() {
        match disease {
            ShrimpDisease::Wssv => {
                if combined_text.contains("white spot") || combined_text.contains("white spots") { *score += 0.85; }
                if combined_text.contains("carapace") && combined_text.contains("spot") { *score += 0.40; }
                if combined_text.contains("reddish") || combined_text.contains("red body") { *score += 0.25; }
                if combined_text.contains("mass mortality") || combined_text.contains("rapid mortality") { *score += 0.30; }
                if combined_text.contains("surface swimming") || combined_text.contains("dyke") { *score += 0.20; }
                if let Some(d) = do_mg_l { if d < 3.5 { *score += 0.15; } }
            }
            ShrimpDisease::Ahpnd => {
                if combined_text.contains("atrophied") || combined_text.contains("shrunken hepatopancreas") || combined_text.contains("pale liver") { *score += 0.85; }
                if combined_text.contains("empty gut") || combined_text.contains("empty stomach") { *score += 0.40; }
                if combined_text.contains("ems") || combined_text.contains("ahpnd") { *score += 0.90; }
                if let Some(d) = doc { if d <= 45 { *score += 0.35; } }
            }
            ShrimpDisease::Ehp => {
                if combined_text.contains("growth retardation") || combined_text.contains("stunted") || combined_text.contains("size variation") { *score += 0.80; }
                if combined_text.contains("fcr high") || combined_text.contains("spores") || combined_text.contains("ehp") { *score += 0.85; }
                if combined_text.contains("white faecal") || combined_text.contains("white feces") { *score += 0.30; }
            }
            ShrimpDisease::Wfs => {
                if combined_text.contains("white feces") || combined_text.contains("white faeces") || combined_text.contains("fecal string") { *score += 0.90; }
                if combined_text.contains("floating strings") || combined_text.contains("white string") { *score += 0.60; }
                if combined_text.contains("drop in feed") || combined_text.contains("feed intake drop") { *score += 0.25; }
            }
            ShrimpDisease::BlackGill => {
                if combined_text.contains("black gill") || combined_text.contains("brown gill") || combined_text.contains("melanization") { *score += 0.90; }
                if combined_text.contains("silt") || combined_text.contains("respiratory distress") { *score += 0.40; }
                if combined_text.contains("aerator crowd") || combined_text.contains("sludge") { *score += 0.30; }
            }
            ShrimpDisease::Rms => {
                if combined_text.contains("running mortality") || combined_text.contains("rms") || combined_text.contains("daily mortality") { *score += 0.85; }
                if combined_text.contains("dying at bottom") || combined_text.contains("chronic") { *score += 0.40; }
            }
            ShrimpDisease::Lss => {
                if combined_text.contains("loose shell") || combined_text.contains("spongy") || combined_text.contains("soft shell") { *score += 0.85; }
                if combined_text.contains("molt trap") || combined_text.contains("mineral") || combined_text.contains("calcium") { *score += 0.40; }
            }
            ShrimpDisease::Imnv => {
                if combined_text.contains("imnv") || combined_text.contains("myonecrosis") || combined_text.contains("muscle opacity") || combined_text.contains("opaque tail") { *score += 0.90; }
                if combined_text.contains("cooked meat") || combined_text.contains("tail reddening") { *score += 0.50; }
            }
            ShrimpDisease::Vibriosis => {
                if combined_text.contains("luminescent") || combined_text.contains("glow") || combined_text.contains("bioluminescence") || combined_text.contains("green glow") { *score += 0.95; }
                if combined_text.contains("vibrio") || combined_text.contains("tcbs") || combined_text.contains("shell rot") { *score += 0.45; }
            }
            ShrimpDisease::Yhv => {
                if combined_text.contains("yellow head") || combined_text.contains("yellowish cephalothorax") || combined_text.contains("yhv") { *score += 0.95; }
                if combined_text.contains("bleached body") || combined_text.contains("catastrophic") { *score += 0.35; }
            }
            ShrimpDisease::CottonShrimp => {
                if combined_text.contains("cotton") || combined_text.contains("milky") || combined_text.contains("thelohania") { *score += 0.90; }
                if combined_text.contains("loss of elasticity") || combined_text.contains("rubbery") { *score += 0.40; }
            }
            ShrimpDisease::Healthy => {}
        }
    }

    scores.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

    let top = scores[0];
    if top.1 > 0.3 {
        let confidence = (top.1.min(1.0) * 100.0).round() / 100.0;
        let info = get_disease_info(top.0);
        build_report_from_info(info, confidence.max(0.70), symptoms)
    } else {
        // Fallback to WSSV if critical or unknown lesion
        let info = get_disease_info(ShrimpDisease::Wssv);
        build_report_from_info(info, 0.50, symptoms)
    }
}

fn build_report_from_info(
    info: DiseaseInfo,
    confidence: f64,
    observed_symptoms: &[&str],
) -> DiagnosticReport {
    DiagnosticReport {
        disease_code: info.code.to_string(),
        disease_name: info.name.to_string(),
        scientific_name: info.scientific_name.to_string(),
        telugu_name: info.telugu_name.to_string(),
        confidence,
        severity: info.severity.as_str().to_string(),
        is_emergency_harvest: info.is_emergency_harvest,
        immediate_action: info.treatment.immediate_actions.first().cloned().unwrap_or_default(),
        telugu_action: info.treatment.telugu_recommendations.first().cloned().unwrap_or_default(),
        treatment_plan: info.treatment.immediate_actions.clone(),
        biosecurity_measures: info.treatment.biosecurity_measures.clone(),
        telugu_summary: info.treatment.telugu_summary.clone(),
        telugu_recommendations: info.treatment.telugu_recommendations.clone(),
        matched_symptoms: observed_symptoms.iter().map(|s| s.to_string()).collect(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_all_12_diseases_defined() {
        let diseases = [
            ShrimpDisease::Wssv,
            ShrimpDisease::Ahpnd,
            ShrimpDisease::Ehp,
            ShrimpDisease::Wfs,
            ShrimpDisease::BlackGill,
            ShrimpDisease::Rms,
            ShrimpDisease::Lss,
            ShrimpDisease::Imnv,
            ShrimpDisease::Vibriosis,
            ShrimpDisease::Yhv,
            ShrimpDisease::CottonShrimp,
            ShrimpDisease::Healthy,
        ];

        for d in diseases {
            let info = get_disease_info(d);
            assert!(!info.name.is_empty());
            assert!(!info.telugu_name.is_empty());
            assert!(!info.treatment.telugu_summary.is_empty());
            assert!(!info.treatment.immediate_actions.is_empty());
        }
    }

    #[test]
    fn test_diagnose_wssv() {
        let report = diagnose_symptoms(&["White spots on carapace", "rapid mortality"], None, Some(3.0));
        assert_eq!(report.disease_code, "WSSV");
        assert!(report.is_emergency_harvest);
        assert!(report.confidence >= 0.80);
    }

    #[test]
    fn test_diagnose_ahpnd() {
        let report = diagnose_symptoms(&["atrophied pale hepatopancreas", "empty gut"], Some(25), None);
        assert_eq!(report.disease_code, "AHPND");
    }

    #[test]
    fn test_diagnose_healthy() {
        let report = diagnose_symptoms(&["healthy glassy body", "full gut"], None, None);
        assert_eq!(report.disease_code, "HEALTHY");
        assert_eq!(report.severity, "none");
    }
}
