/**
 * 12 ICAR-CIBA Shrimp Diseases + Healthy state supported by PrawnDoc AI vision diagnostics.
 */
export type ShrimpDisease =
  | 'wssv'
  | 'ahpnd'
  | 'ehp'
  | 'wfs'
  | 'blackGill'
  | 'rms'
  | 'lss'
  | 'imnv'
  | 'vibriosis'
  | 'yhv'
  | 'cottonShrimp'
  | 'healthy';

export type PathogenType =
  | 'viral'
  | 'bacterial'
  | 'microsporidian'
  | 'environmental'
  | 'nutritional'
  | 'none';

export type DiseaseSeverity = 'none' | 'low' | 'medium' | 'high' | 'critical';

export interface TreatmentProtocol {
  immediateActions: string[];
  chemicalTreatment: string[];
  feedAdjustments: string[];
  biosecurityMeasures: string[];
  teluguSummary: string;
  teluguRecommendations: string[];
}

export interface DiseaseInfo {
  disease: ShrimpDisease;
  code: string;
  name: string;
  scientificName: string;
  teluguName: string;
  pathogen: PathogenType;
  severity: DiseaseSeverity;
  isEmergencyHarvest: boolean;
  keySymptomsEn: string[];
  keySymptomsTe: string[];
  waterImplications: string;
  treatment: TreatmentProtocol;
}

export interface DiagnosticReport {
  diseaseCode: string;
  diseaseName: string;
  scientificName: string;
  teluguName: string;
  confidence: number;
  severity: DiseaseSeverity;
  isEmergencyHarvest: boolean;
  immediateAction: string;
  teluguAction: string;
  treatmentPlan: string[];
  biosecurityMeasures: string[];
  teluguSummary: string;
  teluguRecommendations: string[];
  matchedSymptoms: string[];
}

const DISEASE_DATABASE: Record<ShrimpDisease, DiseaseInfo> = {
  wssv: {
    disease: 'wssv',
    code: 'WSSV',
    name: 'White Spot Syndrome Virus',
    scientificName: 'Whispovirus (Nimaviridae)',
    teluguName: 'తెల్ల మచ్చల వైరస్ వ్యాధి (WSSV)',
    pathogen: 'viral',
    severity: 'critical',
    isEmergencyHarvest: true,
    keySymptomsEn: [
      'White spots (0.5 - 2.0 mm) on inside of carapace and rostrum',
      'Rapid reduction in feed consumption within 24 hours',
      'Lethargic swimming along pond dykes near water surface',
      'Reddish discoloration of body and appendages',
      'Mass mortality reaching 80-100% within 48 to 72 hours',
    ],
    keySymptomsTe: [
      'తల పెంకు మరియు రోస్ట్రంపై తెల్లని మచ్చలు (0.5 - 2 మి.మీ.)',
      'రొయ్యలు మేత తినడం ఒక్కసారిగా తగ్గించడం',
      'చెరువు గట్ల వెంబడి నీటిపై నీరసంగా ఈదడం',
      'శరీరం మరియు ఈత కాళ్ళు ఎరుపు రంగులోకి మారడం',
      '2-3 రోజుల్లో 80-100% వరకు రొయ్యలు చనిపోవడం',
    ],
    waterImplications: 'Low DO (< 3.5 mg/L) and sudden water temperature fluctuations trigger virulent WSSV outbreaks.',
    treatment: {
      immediateActions: [
        'Stop water exchange immediately to prevent transmitting virus to neighboring farms',
        'Maximize continuous aeration (keep DO > 5.0 mg/L)',
        'Immediately cease all feeding to reduce bottom organic load',
        'Evaluate emergency harvest if shrimp biomass > 15g count',
      ],
      chemicalTreatment: [
        'If unmarketable, apply calcium hypochlorite (bleaching powder) at 30-35 ppm to disinfect pond water before discharge',
      ],
      feedAdjustments: [
        'Stop feed completely for affected ponds',
      ],
      biosecurityMeasures: [
        'Disinfect all sampling nets and check trays with 50 ppm chlorine solution',
        'Strictly restrict labor and equipment movement between ponds',
        'Install bird scare lines to deter predatory birds from spreading dead shrimp',
      ],
      teluguSummary: 'తెల్ల మచ్చల వైరస్ వ్యాధి (WSSV) గుర్తించబడింది. వెంటనే నీటి మార్పిడిని ఆపండి, ఎయిరేషన్ పెంచండి మరియు మేత నిలిపివేయండి.',
      teluguRecommendations: [
        'నీటి మార్పిడిని వెంటనే నిలిపివేయండి',
        'ఎయిరేటర్లను నిరంతరం నడిపి ఆక్సిజన్ 5.0 mg/L పైగా ఉంచండి',
        '15 గ్రాములకు పైబడి ఉంటే వెంటనే ఎమర్జెన్సీ హార్వెస్ట్ చేయండి',
        'వలలు మరియు పరికరాలను క్లోరిన్ ద్రావణంతో శుభ్రపరచండి',
      ],
    },
  },

  ahpnd: {
    disease: 'ahpnd',
    code: 'AHPND',
    name: 'Acute Hepatopancreatic Necrosis Disease (EMS/AHPND)',
    scientificName: 'Vibrio parahaemolyticus (carrying PirA/PirB binary toxins)',
    teluguName: 'ఈ ఎం ఎస్ / ఎ హెచ్ పి ఎన్ డి (EMS/AHPND) - పిత్తాశయ క్షీణత',
    pathogen: 'bacterial',
    severity: 'critical',
    isEmergencyHarvest: false,
    keySymptomsEn: [
      'Pale, atrophied, and shrunken hepatopancreas (liver)',
      'Completely empty stomach and midgut line',
      'Sudden acute mortality within early culture phase (DOC 10 to 45)',
      'Soft shell and lethargy',
      'Black streaks in hepatopancreatic tubules',
    ],
    keySymptomsTe: [
      'కాలేయం (హెపటోపాంక్రియాస్) పాలిపోయి, చిన్నగా కుంచించుకుపోవడం',
      'కడుపు మరియు ప్రేగు లైను పూర్తిగా ఖాళీగా ఉండడం',
      'సాగు ప్రారంభంలో (10-45 రోజుల మధ్య) అకస్మాత్తుగా రొయ్యలు చనిపోవడం',
      'పెంకు మెత్తబడటం మరియు రొయ్యల్లో చురుకుదనం తగ్గడం',
    ],
    waterImplications: 'High organic sediment, excessive feeding, and alkaline pH (> 8.4) trigger PirA/PirB toxin expression.',
    treatment: {
      immediateActions: [
        'Stop feeding completely for 24 to 48 hours to starve Vibrio populations',
        'Apply continuous aeration to maintain dissolved oxygen > 5.5 mg/L',
        'Dose pond with multi-strain Bacillus + Rhodobacter water probiotics at 2.0 kg/acre',
      ],
      chemicalTreatment: [
        'Apply potassium diformate (organic acid salts) in feed at 3-5 g/kg when feeding resumes',
        'Avoid harsh chemical disinfectants that destroy beneficial pond microflora',
      ],
      feedAdjustments: [
        'Resume feeding at 50% ration using fermented probiotic-coated feed',
        'Supplement feed with gut phytogenics (garlic extract 10 ml/kg + turmeric)',
      ],
      biosecurityMeasures: [
        'Siphon black pond bottom sludge daily',
        'Test water and soil Vibrio green colony counts on TCBS agar plates',
      ],
      teluguSummary: 'తీవ్రమైన EMS / AHPND వ్యాధి లక్షణాలు. తక్షణమే మేత ఆపి ప్రోబయోటిక్స్ వేయండి.',
      teluguRecommendations: [
        '24-48 గంటలు మేత ఆపి, ఆపై 50% మాత్రమే వేయండి',
        'ఎయిరేటర్లను నిరంతరం నడిపి ఆక్సిజన్ 5.5 mg/L పైగా ఉంచండి',
        'మంచి నాణ్యమైన బాసిల్లస్ ప్రోబయోటిక్స్ వాడండి',
      ],
    },
  },

  ehp: {
    disease: 'ehp',
    code: 'EHP',
    name: 'Enterocytozoon hepatopenaei (Microsporidian)',
    scientificName: 'Enterocytozoon hepatopenaei',
    teluguName: 'ఇ హెచ్ పి (EHP) - పెరుగుదల లోపం వ్యాధి',
    pathogen: 'microsporidian',
    severity: 'high',
    isEmergencyHarvest: false,
    keySymptomsEn: [
      'Severe growth retardation and extreme size variation across pond',
      'DOC > 60 but shrimp weight stuck under 10-12g',
      'Floating white fecal strings near feed check trays',
      'FCR spikes drastically above 1.8 to 2.4',
      'Soft shells and empty intestines without acute mass mortality',
    ],
    keySymptomsTe: [
      'తీవ్రమైన పెరుగుదల లోపం మరియు సైజుల్లో హెచ్చుతగ్గులు',
      '60 రోజులు దాటినా రొయ్యల బరువు 10-12 గ్రాముల లోపే ఉండడం',
      'చెక్ ట్రేల వద్ద తెల్లటి రెట్ట తీగలు తేలియాడటం',
      'FCR అనూహ్యంగా 1.8 నుండి 2.4 పైకి పెరగడం',
    ],
    waterImplications: 'EHP spores persist in pond bottom soil and transmit horizontally through cannibalism of infected molts.',
    treatment: {
      immediateActions: [
        'Sample hepatopancreatic tissue for spore-count microscopy and PCR screening',
        'Perform aggressive bottom sludge siphoning twice daily',
        'Adjust daily feeding rate down to actual consumed biomass to prevent feed wastage',
      ],
      chemicalTreatment: [
        'Top-dress feed with herbal anti-microsporidial formulation containing Curcuma longa and thymol',
        'Dose potassium monopersulfate (KMPS) at 1.5 ppm to oxidize spores in water column',
      ],
      feedAdjustments: [
        'Incorporate gut acidifiers (formic/propionic acid blend) at 4 g/kg feed',
        'Enrich diet with digestive enzymes and yeast beta-glucans (5 g/kg)',
      ],
      biosecurityMeasures: [
        'Screen all post-larvae (PL) via real-time PCR before stocking',
        'Treat pond bottom soil between crops with quicklime (CaO at 2 metric tons/ha) to achieve soil pH > 12',
      ],
      teluguSummary: 'EHP మైక్రోస్పోరిడియన్ పెరుగుదల లోపం గుర్తించబడింది. మేతను నియంత్రించండి మరియు గట్ ప్రోబయోటిక్స్ వేయండి.',
      teluguRecommendations: [
        'మేత వృధా కాకుండా చెక్ ట్రేల ఆధారంగా తగ్గించండి',
        'రొయ్యల జీర్ణశక్తిని పెంచే ఆర్గానిక్ యాసిడ్లు, ఎంజైములు మేతలో కలపండి',
        'చెరువు అడుగున వ్యర్థాలను సైఫన్ ద్వారా తొలగించండి',
      ],
    },
  },

  wfs: {
    disease: 'wfs',
    code: 'WFS',
    name: 'White Feces Syndrome',
    scientificName: 'Transformed microvilli / Vibrio harveyi / EHP interaction',
    teluguName: 'తెల్ల రెట్ట వ్యాధి (White Feces Syndrome - WFS)',
    pathogen: 'bacterial',
    severity: 'high',
    isEmergencyHarvest: false,
    keySymptomsEn: [
      'Floating strings of white feces on pond water surface and check trays',
      'White or vermiform strings packed with sloughed transformed microvilli',
      'Drastic drop in feed intake (30-50% drop within 48 hours)',
      'Loose, spongy exoskeleton and dark, congested hepatopancreas',
      'Gradual daily mortality at pond bottom',
    ],
    keySymptomsTe: [
      'నీటి ఉపరితలంపై మరియు చెక్ ట్రేలలో తెల్లటి రెట్ట తీగలు తేలియాడడం',
      'రొయ్యల మేత వినియోగం 30-50% వరకు పడిపోవడం',
      'పెంకు వదులుగా మారడం మరియు కాలేయం రంగు మారడం',
      'రోజువారీ చనిపోయే రొయ్యల సంఖ్య క్రమంగా పెరగడం',
    ],
    waterImplications: 'Excess organic loading, blue-green algae blooms, and elevated bottom vibrio colonies trigger WFS shedding.',
    treatment: {
      immediateActions: [
        'Immediately cut feeding ration by 40-50% for 3 to 5 days',
        'Skim and physically remove floating fecal strings from pond surface using fine mesh scoop nets',
        'Boost aeration to oxidize dissolved organics',
      ],
      chemicalTreatment: [
        'Apply yucca extract and zeolite to bind toxic ammonia and hydrogen sulfide',
        'Incorporate garlic paste (15 g/kg) and activated carbon (5 g/kg) in feed as toxin binder',
      ],
      feedAdjustments: [
        'Coat pellets with high-potency lactic acid bacteria (Lactobacillus acidophilus)',
        'Add Vitamin C (5 g/kg) to stimulate gut epithelial tissue regeneration',
      ],
      biosecurityMeasures: [
        'Avoid sudden salinity shocks or drastic water exchanges',
        'Control toxic cyanobacterial (microcystis) blooms',
      ],
      teluguSummary: 'తెల్ల రెట్ట వ్యాధి (WFS) సోకింది. మేత 40% తగ్గించి, వెల్లుల్లి గుజ్జు మరియు లాక్టోబాసిల్లస్ ప్రోబయోటిక్స్ అందించండి.',
      teluguRecommendations: [
        'మేతను వెంటనే 40-50% తగ్గించండి',
        'తేలియాడే తెల్ల రెట్టను వలలతో తొలగించండి',
        'మేతలో వెల్లుల్లి రసం (10-15 మి.లీ/కిలో) మరియు ప్రోబయోటిక్స్ కలపండి',
      ],
    },
  },

  blackGill: {
    disease: 'blackGill',
    code: 'BLACK_GILL',
    name: 'Black Gill Disease / Melanization',
    scientificName: 'Fusarium solani / Heavy silt clogging / Hydrogen sulfide melanization',
    teluguName: 'నల్ల మొప్పల వ్యాధి (Black Gill Disease)',
    pathogen: 'environmental',
    severity: 'medium',
    isEmergencyHarvest: false,
    keySymptomsEn: [
      'Brown, brownish-black or jet black discoloration of gill branchial filaments',
      'Severe respiratory distress; shrimp congregate near aerator splash zones',
      'Accumulation of black organic detritus in branchial chambers',
      'Foul odor in water and black toxic hydrogen sulfide sludge on pond bottom',
    ],
    keySymptomsTe: [
      'మొప్పల భాగాలు గోధుమ లేదా నలుపు రంగులోకి మారడం',
      'శ్వాస తీసుకోవడంలో ఇబ్బంది పడుతూ రొయ్యలు ఎయిరేటర్ల దగ్గరకు చేరడం',
      'మొప్పలలో బురద, వ్యర్థాలు పేరుకుపోవడం',
      'చెరువు అడుగున నల్లటి బురద మరియు హైడ్రోజన్ సల్ఫైడ్ దుర్వాసన',
    ],
    waterImplications: 'Caused by low bottom DO (< 3.0 mg/L), acidic bottom soil, and hydrogen sulfide (H2S > 0.03 mg/L).',
    treatment: {
      immediateActions: [
        'Increase aeration immediately to maintain bottom DO > 4.5 mg/L',
        'Perform bottom drain flushing or siphon off dead black sludge',
        'Apply agricultural quicklime (CaO at 50 kg/acre) or dolomite to stabilize pH > 7.8',
      ],
      chemicalTreatment: [
        'Dose hydrogen peroxide (30%) at 2-3 liters/acre for rapid bottom oxygenation',
        'Apply benzalkonium chloride (BKC 50%) at 1.0 ppm if fungal hyphae (Fusarium) confirmed under microscope',
      ],
      feedAdjustments: [
        'Reduce daily feed by 25% until gill clearing is observed',
        'Fortify feed with Vitamin C (5 g/kg) and mineral binders',
      ],
      biosecurityMeasures: [
        'Test bottom soil oxidation-reduction potential (ORP) and keep above -100 mV',
        'Ensure aerators are angled properly to sweep sludge toward central drain',
      ],
      teluguSummary: 'నల్ల మొప్పల వ్యాధి గుర్తించబడింది. ఎయిరేషన్ పెంచి, అడుగు బురదను శుభ్రం చేయండి మరియు డోలమైట్ వేయండి.',
      teluguRecommendations: [
        'ఎయిరేటర్లు పెంచి ఆక్సిజన్ 4.5 mg/L పైగా ఉండేలా చూడండి',
        'చెరువు అడుగున పేరుకున్న నల్ల బురదను సైఫన్ చేయండి',
        'ఎకరాకు 50 కిలోల డోలమైట్ లేదా సున్నం చల్లండి',
      ],
    },
  },

  rms: {
    disease: 'rms',
    code: 'RMS',
    name: 'Running Mortality Syndrome',
    scientificName: 'Complex etiology (Vibrio + viral co-infections + organic stress)',
    teluguName: 'రన్నింగ్ మోర్టాలిటీ సిండ్రోమ్ (RMS)',
    pathogen: 'bacterial',
    severity: 'high',
    isEmergencyHarvest: false,
    keySymptomsEn: [
      'Continuous low-level mortality (1-3% daily) over extended culture period',
      'Dead and moribund shrimp found at bottom during check-tray inspection',
      'Empty digestive tract and pale whitish musculature',
      'Absence of distinct white spots or visible external lesions',
    ],
    keySymptomsTe: [
      'రోజువారీ స్వల్పంగా 1-3% చొప్పున రొయ్యలు చనిపోతూ ఉండడం',
      'చెక్ ట్రేలలో లేదా అడుగున చనిపోయిన రొయ్యలు కనిపించడం',
      'ఖాళీ పేగు మరియు కండరాలలో పాలిపోయిన రంగు',
      'ఎలాంటి స్పష్టమైన తెల్ల మచ్చలు లేకుండానే చనిపోవడం',
    ],
    waterImplications: 'Exacerbated by deteriorating bottom conditions, high unionized ammonia, and mineral depletion.',
    treatment: {
      immediateActions: [
        'Cut feed by 30% and inspect feed consumption every 2 hours',
        'Continuous paddle-wheel aeration day and night',
        'Perform deep bottom siphoning to purge decaying organic detritus',
      ],
      chemicalTreatment: [
        'Dose multi-strain photosynthetic bacteria (Rhodobacter) at 5 L/acre',
        'Broadcast agricultural gypsum and magnesium chloride to stabilize ionic balance',
      ],
      feedAdjustments: [
        'Add beta-glucans (10 g/kg) and Vitamin C (5 g/kg) as immune boosters',
        'Incorporate spirulina powder (5 g/kg) in feed',
      ],
      biosecurityMeasures: [
        'Maintain strict water filtration (300 micron mesh nets on intake canal)',
        'Avoid drastic salinity swings during monsoon season',
      ],
      teluguSummary: 'రన్నింగ్ మోర్టాలిటీ సిండ్రోమ్ (RMS) గుర్తించబడింది. మేత 30% తగ్గించి, రోడోబాక్టర్ బ్యాక్టీరియా మరియు ఇమ్యూనోస్టిమ్యులెంట్స్ వాడండి.',
      teluguRecommendations: [
        'మేతను 30% తగ్గించి క్రమం తప్పకుండా గమనించండి',
        'రోడోబాక్టర్ వంటి కిరణజన్య సంయోగ బ్యాక్టీరియాను చెరువులో వేయండి',
        'విటమిన్ సి మరియు బీటా-గ్లూకాన్లను మేతలో కలపండి',
      ],
    },
  },

  lss: {
    disease: 'lss',
    code: 'LSS',
    name: 'Loose Shell Syndrome',
    scientificName: 'Nutritional mineral imbalance / Chronic environmental stress',
    teluguName: 'వదులు పెంకు వ్యాధి (Loose Shell Syndrome - LSS)',
    pathogen: 'nutritional',
    severity: 'medium',
    isEmergencyHarvest: false,
    keySymptomsEn: [
      'Spongy, loose exoskeleton with visible fluid pocket between carapace and muscle',
      'Flaccid, watery muscular tissue upon peeling',
      'Incomplete molting (exuviae trapped on walking legs)',
      'Soft rostrum and poor survival during harvesting',
    ],
    keySymptomsTe: [
      'పెంకు వదులుగా మారి, కండరానికి పెంకుకి మధ్య నీరు చేరడం',
      'రొయ్య ఒంటి భాగం మెత్తగా మరియు నీరుగా ఉండడం',
      'కుబుసం విడవడంలో ఆటంకాలు ఏర్పడడం (సగమే కుబుసం విడవడం)',
    ],
    waterImplications: 'Deficiency in dissolved calcium (Ca), magnesium (Mg), potassium (K), or alkalinity < 100 mg/L.',
    treatment: {
      immediateActions: [
        'Measure pond water hardness, total alkalinity, and Mg:Ca:K ionic ratio',
        'Target ionic ratio: Mg ~ 3x Ca, K ~ 1x Ca relative to salinity',
        'Apply mineral supplements immediately to reach alkalinity > 130 mg/L',
      ],
      chemicalTreatment: [
        'Broadcast calcium chloride (CaCl2 at 25 kg/acre) and magnesium sulfate (MgSO4 at 50 kg/acre)',
        'Dose agricultural dolomite at 100 kg/acre to buffer pH and carbonate levels',
      ],
      feedAdjustments: [
        'Top-dress feed with bio-available chelated mineral pre-mix at 20 g/kg feed',
        'Add cholesterol and lecithin (5 g/kg) to promote ecdysteroid synthesis for complete molting',
      ],
      biosecurityMeasures: [
        'Avoid harvesting during active lunar molting cycles (full moon / new moon)',
        'Maintain stable salinity and avoid abrupt low-salinity bore well surges',
      ],
      teluguSummary: 'వదులు పెంకు వ్యాధి (LSS) ఖనిజ లవణాల లోపం వల్ల వచ్చింది. మెగ్నీషియం, కాల్షియం మరియు డోలమైట్ వేయండి.',
      teluguRecommendations: [
        'చెరువులో ఆల్కలీనిటీ 130 mg/L కంటే ఎక్కువ ఉండేలా డోలమైట్ వేయండి',
        'మెగ్నీషియం సల్ఫేట్, కాల్షియం క్లోరైడ్ ఖనిజాలు చల్లండి',
        'మేతలో కీలేటెడ్ మినరల్ పౌడర్ (20 గ్రా/కిలో) కలపండి',
      ],
    },
  },

  imnv: {
    disease: 'imnv',
    code: 'IMNV',
    name: 'Infectious Myonecrosis Virus',
    scientificName: 'Infectious myonecrosis virus (Totiviridae)',
    teluguName: 'కండరాల క్షీణత వైరస్ (IMNV)',
    pathogen: 'viral',
    severity: 'critical',
    isEmergencyHarvest: true,
    keySymptomsEn: [
      'Focal to extensive white opaque necrotic areas in striated abdominal muscle',
      'Opaque cooked-meat appearance of the tail muscle segments',
      'Tail fan reddening and necrosis',
      'Acute mortality following severe stress events (cast netting, DO drop, temperature drop)',
    ],
    keySymptomsTe: [
      'రొయ్య తోక కండరాలు తెల్లగా ఉడికించిన మాంసంలా మారడం',
      'తోక కండరాలలో రక్తస్రావ మచ్చలు మరియు తోక ఎరుపు రంగు తిరగడం',
      'ఒత్తిడి (వలలు వేసినప్పుడు లేదా ఆక్సిజన్ తగ్గినప్పుడు) తక్షణ మరణాలు',
    ],
    waterImplications: 'Environmental stressors (sudden temperature change > 3°C or DO < 3.0 mg/L) induce lethal systemic viremia.',
    treatment: {
      immediateActions: [
        'Strictly isolate pond; prohibit cast netting and unnecessary pond sampling',
        'Maintain continuous maximum aeration with DO > 5.5 mg/L',
        'Cease feeding for 24 hours to reduce metabolic oxygen demand',
        'Emergency harvest if shrimp are at marketable weight (> 14g)',
      ],
      chemicalTreatment: [
        'Apply potassium monopersulfate (KMPS 50%) at 1.0 ppm as mild biosecurity water sanitizer',
      ],
      feedAdjustments: [
        'Resume feed at 50% with high-dose Vitamin C (10 g/kg) and anti-stress electrolytes',
        'Avoid high-protein feeds that increase nitrogenous waste',
      ],
      biosecurityMeasures: [
        'Sanitize all equipment with 200 ppm chlorine solution',
        'Do not transfer water or animals between ponds',
      ],
      teluguSummary: 'IMNV కండరాల క్షీణత వైరస్ గుర్తించబడింది. ఒత్తిడిని తగ్గించండి, ఎయిరేషన్ పెంచండి మరియు అవసరమైతే హార్వెస్ట్ చేయండి.',
      teluguRecommendations: [
        'వలలు వేయడం ఆపండి, రొయ్యలను ఒత్తిడికి గురిచేయవద్దు',
        'ఆక్సిజన్ 5.5 mg/L పైగా ఉండేలా ఎయిరేటర్లు నిరంతరం నడపండి',
        'మార్కెట్ సైజు ఉంటే వెంటనే హార్వెస్ట్ చేయడం శ్రేయస్కరం',
      ],
    },
  },

  vibriosis: {
    disease: 'vibriosis',
    code: 'VIBRIOSIS',
    name: 'Luminescent Bacterial Vibriosis',
    scientificName: 'Vibrio harveyi / Vibrio alginolyticus / Vibrio vulnificus',
    teluguName: 'విబ్రియోసిస్ / మెరిసే బ్యాక్టీరియా వ్యాధి (Vibriosis)',
    pathogen: 'bacterial',
    severity: 'high',
    isEmergencyHarvest: false,
    keySymptomsEn: [
      'Greenish bioluminescence visible in dark night conditions across body',
      'Melanized black erosive lesions on cuticle and appendages (shell rot)',
      'Cloudy hepatopancreas and brown or dark coloration of body',
      'High bacterial CFU counts (> 10^3 CFU/ml green colonies on TCBS agar)',
    ],
    keySymptomsTe: [
      'చీకటిలో రొయ్యలు ఆకుపచ్చ రంగులో మెరవడం (బయోల్యూమినిసెన్స్)',
      'పెంకు మరియు కాళ్ళపై నల్లటి మచ్చలు (షెల్ రాట్)',
      'రొయ్యల కాలేయం మసకబారడం మరియు చురుకుదనం తగ్గడం',
    ],
    waterImplications: 'Triggered by high salinity (> 25 ppt), water temperatures > 30°C, and accumulation of unconsumed feed.',
    treatment: {
      immediateActions: [
        'Reduce daily feed allowance by 35% immediately',
        'Broadcast multi-strain competitive Bacillus subtilis + licheniformis probiotics at 2.5 kg/acre',
        'Aerate aggressively to prevent hypoxic stratification',
      ],
      chemicalTreatment: [
        'Apply biodegradable disinfectant (e.g. iodine 20% at 1.0 L/acre) if luminescence is severe',
      ],
      feedAdjustments: [
        'Feed fermented yeast culture (Saccharomyces cerevisiae) to outcompete vibrio in gut',
        'Add oregano oil or thymol blend (2 ml/kg feed) as natural bactericide',
      ],
      biosecurityMeasures: [
        'Monitor weekly luminous bacteria plate counts on TCBS agar',
        'Avoid sudden salinity rises; flush pond surface during extreme heatwaves',
      ],
      teluguSummary: 'విబ్రియోసిస్ (మెరిసే బ్యాక్టీరియా) వ్యాధి గుర్తించబడింది. మేత తగ్గించి, అయోడిన్ లేదా బాసిల్లస్ ప్రోబయోటిక్స్ వేయండి.',
      teluguRecommendations: [
        'మేతను 35% తగ్గించండి',
        'రాత్రి వేళల్లో మెరిసే స్వభావం ఉంటే అయోడిన్ (20%) ఎకరాకు 1 లీటరు వేయండి',
        'మరుసటి రోజు నాణ్యమైన బాసిల్లస్ ప్రోబయోటిక్స్ వేసి బ్యాక్టీరియాను అణచివేయండి',
      ],
    },
  },

  yhv: {
    disease: 'yhv',
    code: 'YHV',
    name: 'Yellow Head Virus',
    scientificName: 'Yellow head virus genotype 1 (Roniviridae)',
    teluguName: 'పసుపు తల వైరస్ వ్యాధి (Yellow Head Virus - YHV)',
    pathogen: 'viral',
    severity: 'critical',
    isEmergencyHarvest: true,
    keySymptomsEn: [
      'Marked yellowish discoloration of the cephalothorax (head) and gills',
      'Bleaching and pale translucency of the overall shrimp body',
      'Abnormally rapid feed intake spike for 1-2 days followed by total feeding cessation',
      'Shrimp swim erratically near pond edge followed by catastrophic mass mortality within 3-5 days',
    ],
    keySymptomsTe: [
      'రొయ్య తల భాగం మరియు మొప్పలు పసుపు రంగులోకి మారడం',
      'శరీరం మొత్తం పాలిపోయి కాంతిహీనంగా మారడం',
      'రెండు రోజులు విపరీతంగా మేత తిని, ఆపై అకస్మాత్తుగా మేత పూర్తిగా ఆపేయడం',
      'గట్ల వెంబడి రొయ్యలు తిరుగుతూ 3-5 రోజుల్లో పెద్ద సంఖ్యలో చనిపోవడం',
    ],
    waterImplications: 'Water temperatures > 32°C and high organic loading compound explosive viral replication.',
    treatment: {
      immediateActions: [
        'Completely quarantine the infected pond; cease water discharge and exchange',
        'Halt all feeding immediately',
        'If shrimp > 12g, perform emergency harvest with zero discharge containment',
      ],
      chemicalTreatment: [
        'In unmarketable crops, treat water with 30 ppm calcium hypochlorite (active chlorine) to destroy viral particles',
      ],
      feedAdjustments: [
        'Zero feed in infected ponds',
      ],
      biosecurityMeasures: [
        'Dispose of dead shrimp safely by deep pit burial with lime',
        'Establish crab fencing and bird nets to prevent vector transmission',
      ],
      teluguSummary: 'ప్రమాదకరమైన పసుపు తల వైరస్ (YHV) వ్యాధి. నీటి మార్పిడి పూర్తిగా ఆపి, తక్షణ ఎమర్జెన్సీ హార్వెస్ట్ చేపట్టండి.',
      teluguRecommendations: [
        'చెరువు నుండి నీటిని బయటకు వదలవద్దు',
        'రొయ్యల సైజు బాగుంటే వెంటనే ఎమర్జెన్సీ హార్వెస్ట్ చేయండి',
        'మేత పూర్తిగా నిలిపివేయండి',
      ],
    },
  },

  cottonShrimp: {
    disease: 'cottonShrimp',
    code: 'COTTON_SHRIMP',
    name: 'Microsporidiosis / Cotton Shrimp (Milky Disease)',
    scientificName: 'Thelohania / Agmasoma penaei (Microsporidian)',
    teluguName: 'దూది రొయ్య వ్యాధి / కాటన్ ష్రింప్ (Cotton Shrimp Disease)',
    pathogen: 'microsporidian',
    severity: 'medium',
    isEmergencyHarvest: false,
    keySymptomsEn: [
      'Milky white, cotton-like opacity throughout abdominal musculature',
      'Loss of muscle elasticity and rubbery flesh texture',
      'Blue-black pigmentation spots on abdominal cuticular segments',
      'Sluggish crawl along pond bottom with poor market value upon harvest',
    ],
    keySymptomsTe: [
      'తోక కండరాలు దూది వలే తెల్లగా మసకబారిపోవడం',
      'కండరాల స్థితిస్థాపకత కోల్పోయి రబ్బరులా మారడం',
      'రొయ్యలు చురుగ్గా ఈదలేక అడుగున నెమ్మదిగా కదలడం',
    ],
    waterImplications: 'Microsporidian spores are ingested through benthic detritus and intermediate fish/crustacean hosts.',
    treatment: {
      immediateActions: [
        'Cull visibly affected milky shrimp during check-tray monitoring',
        'Never discard culled shrimp back into the pond water or canal',
        'Perform intermediate pond siphoning to remove organic bottom detritus',
      ],
      chemicalTreatment: [
        'Disinfect pond water column with chlorine dioxide at 0.5 ppm',
      ],
      feedAdjustments: [
        'Supplement feed with garlic extract (10 ml/kg) and thymol essential oil',
        'Add gut probiotic strains capable of competitive spore suppression',
      ],
      biosecurityMeasures: [
        'Eradicate wild fish and crabs which act as intermediate spore reservoirs',
        'Apply quicklime (CaO at 200 kg/acre) during pond preparation to sterilize soil spores',
      ],
      teluguSummary: 'కాటన్ ష్రింప్ / దూది రొయ్య వ్యాధి గుర్తించబడింది. సోకిన రొయ్యలను తొలగించండి మరియు గార్లిక్ ఎక్స్‌ట్రాక్ట్ అందించండి.',
      teluguRecommendations: [
        'దూదిలా మారిన రొయ్యలను చెక్ ట్రేల నుంచి ఎప్పటికప్పుడు ఏరివేయండి',
        'మేతలో వెల్లుల్లి రసం మరియు రోగనిరోధక పౌడర్ కలపండి',
        'చెరువులో ఇతర చేపలు, పీతలు చేరకుండా ఫిల్టర్లు వాడండి',
      ],
    },
  },

  healthy: {
    disease: 'healthy',
    code: 'HEALTHY',
    name: 'Healthy Specimen (Penaeus vannamei)',
    scientificName: 'Litopenaeus vannamei (Optimal physiological condition)',
    teluguName: 'ఆరోగ్యకరమైన రొయ్యలు (Healthy Specimen)',
    pathogen: 'none',
    severity: 'none',
    isEmergencyHarvest: false,
    keySymptomsEn: [
      'Clear, glassy, translucent carapace and muscular tissue',
      'Completely full, uniform dark digestive tract (gut line)',
      'Clean pinkish branchial gill filaments with zero silt or fouling',
      'Active, energetic escape response and crisp exoskeleton firmness',
      'Even pigmentation across uropods and telson without redness or lesions',
    ],
    keySymptomsTe: [
      'స్వచ్ఛమైన గాజు లాంటి పారదర్శక శరీర రూపం',
      'మేతతో పూర్తిగా నిండిన నల్లటి ఆహార నాళం (ప్రేగు)',
      'ఎలాంటి బురద లేకుండా శుభ్రంగా ఉన్న గులాబీ రంగు మొప్పలు',
      'ఎంతో చురుకుగా ఈదే శక్తి మరియు గట్టి పెంకు',
    ],
    waterImplications: 'Water quality parameters are within optimal ranges (DO > 4.5 mg/L, pH 7.6 - 8.3, Ammonia < 0.05 mg/L).',
    treatment: {
      immediateActions: [
        'Maintain standard scientific feeding schedule based on daily check-tray consumption',
        'Keep paddle-wheel aeration running according to biomass load',
      ],
      chemicalTreatment: [
        'No chemical intervention required. Continue regular probiotic maintenance dosing',
      ],
      feedAdjustments: [
        'Feed high-protein standard crumble or pellet feed tailored for current DOC and ABW',
      ],
      biosecurityMeasures: [
        'Continue weekly biometry sampling (ABW, CV% uniformity, health index)',
        'Maintain bio-security boundary nets and sanitizing footbaths at pond dykes',
      ],
      teluguSummary: 'రొయ్యలు సంపూర్ణ ఆరోగ్యంగా ఉన్నాయి! ప్రస్తుత మేత మరియు నీటి యాజమాన్య పద్ధతులను కొనసాగించండి.',
      teluguRecommendations: [
        'ప్రస్తుత మేత పట్టికను యథావిధిగా కొనసాగించండి',
        'ఆక్సిజన్ ఎల్లప్పుడూ 4.5 mg/L పైగా ఉండేలా చూసుకోండి',
        'వారం వారం రొయ్యల బరువు మరియు పెరుగుదలను రికార్డ్ చేయండి',
      ],
    },
  },
};

export function getDiseaseInfo(disease: ShrimpDisease): DiseaseInfo {
  return DISEASE_DATABASE[disease] ?? DISEASE_DATABASE.healthy;
}

export function getAllDiseases(): DiseaseInfo[] {
  return Object.values(DISEASE_DATABASE);
}

/**
 * Heuristic symptom-matching diagnostic engine.
 * Evaluates visual keyword findings and environmental factors to produce an ICAR-CIBA diagnosis.
 */
export function diagnoseSymptoms(
  symptoms: string[],
  doc?: number,
  doMgL?: number
): DiagnosticReport {
  const combinedText = symptoms.join(' ').toLowerCase();

  // Explicit healthy indicators
  if (
    combinedText.includes('healthy') ||
    combinedText.includes('glassy') ||
    combinedText.includes('clean gills') ||
    (combinedText.includes('full gut') && !combinedText.includes('spot') && !combinedText.includes('feces'))
  ) {
    return buildReportFromInfo(DISEASE_DATABASE.healthy, 0.96, symptoms);
  }

  const scores: Record<ShrimpDisease, number> = {
    wssv: 0,
    ahpnd: 0,
    ehp: 0,
    wfs: 0,
    blackGill: 0,
    rms: 0,
    lss: 0,
    imnv: 0,
    vibriosis: 0,
    yhv: 0,
    cottonShrimp: 0,
    healthy: 0,
  };

  // WSSV
  if (combinedText.includes('white spot') || combinedText.includes('white spots')) scores.wssv += 0.85;
  if (combinedText.includes('carapace') && combinedText.includes('spot')) scores.wssv += 0.40;
  if (combinedText.includes('reddish') || combinedText.includes('red body')) scores.wssv += 0.25;
  if (combinedText.includes('mass mortality') || combinedText.includes('rapid mortality')) scores.wssv += 0.30;
  if (combinedText.includes('surface swimming') || combinedText.includes('dyke')) scores.wssv += 0.20;
  if (doMgL !== undefined && doMgL < 3.5) scores.wssv += 0.15;

  // AHPND
  if (combinedText.includes('atrophied') || combinedText.includes('shrunken hepatopancreas') || combinedText.includes('pale liver')) scores.ahpnd += 0.85;
  if (combinedText.includes('empty gut') || combinedText.includes('empty stomach')) scores.ahpnd += 0.40;
  if (combinedText.includes('ems') || combinedText.includes('ahpnd')) scores.ahpnd += 0.90;
  if (doc !== undefined && doc <= 45) scores.ahpnd += 0.35;

  // EHP
  if (combinedText.includes('growth retardation') || combinedText.includes('stunted') || combinedText.includes('size variation')) scores.ehp += 0.80;
  if (combinedText.includes('fcr high') || combinedText.includes('spores') || combinedText.includes('ehp')) scores.ehp += 0.85;
  if (combinedText.includes('white faecal') || combinedText.includes('white feces')) scores.ehp += 0.30;

  // WFS
  if (combinedText.includes('white feces') || combinedText.includes('white faeces') || combinedText.includes('fecal string')) scores.wfs += 0.90;
  if (combinedText.includes('floating strings') || combinedText.includes('white string')) scores.wfs += 0.60;
  if (combinedText.includes('drop in feed') || combinedText.includes('feed intake drop')) scores.wfs += 0.25;

  // Black Gill
  if (combinedText.includes('black gill') || combinedText.includes('brown gill') || combinedText.includes('melanization')) scores.blackGill += 0.90;
  if (combinedText.includes('silt') || combinedText.includes('respiratory distress')) scores.blackGill += 0.40;
  if (combinedText.includes('aerator crowd') || combinedText.includes('sludge')) scores.blackGill += 0.30;

  // RMS
  if (combinedText.includes('running mortality') || combinedText.includes('rms') || combinedText.includes('daily mortality')) scores.rms += 0.85;
  if (combinedText.includes('dying at bottom') || combinedText.includes('chronic')) scores.rms += 0.40;

  // LSS
  if (combinedText.includes('loose shell') || combinedText.includes('spongy') || combinedText.includes('soft shell')) scores.lss += 0.85;
  if (combinedText.includes('molt trap') || combinedText.includes('mineral') || combinedText.includes('calcium')) scores.lss += 0.40;

  // IMNV
  if (combinedText.includes('imnv') || combinedText.includes('myonecrosis') || combinedText.includes('muscle opacity') || combinedText.includes('opaque tail')) scores.imnv += 0.90;
  if (combinedText.includes('cooked meat') || combinedText.includes('tail reddening')) scores.imnv += 0.50;

  // Vibriosis
  if (combinedText.includes('luminescent') || combinedText.includes('glow') || combinedText.includes('bioluminescence') || combinedText.includes('green glow')) scores.vibriosis += 0.95;
  if (combinedText.includes('vibrio') || combinedText.includes('tcbs') || combinedText.includes('shell rot')) scores.vibriosis += 0.45;

  // YHV
  if (combinedText.includes('yellow head') || combinedText.includes('yellowish cephalothorax') || combinedText.includes('yhv')) scores.yhv += 0.95;
  if (combinedText.includes('bleached body') || combinedText.includes('catastrophic')) scores.yhv += 0.35;

  // Cotton Shrimp
  if (combinedText.includes('cotton') || combinedText.includes('milky') || combinedText.includes('thelohania')) scores.cottonShrimp += 0.90;
  if (combinedText.includes('loss of elasticity') || combinedText.includes('rubbery')) scores.cottonShrimp += 0.40;

  const sorted = (Object.entries(scores) as [ShrimpDisease, number][]).sort(
    (a, b) => b[1] - a[1]
  );

  const top = sorted[0];
  if (top && top[1] > 0.3) {
    const confidence = Math.max(0.70, Math.min(1.0, Math.round(top[1] * 100) / 100));
    return buildReportFromInfo(DISEASE_DATABASE[top[0]], confidence, symptoms);
  }

  // Fallback to WSSV if symptoms present but unclear
  return buildReportFromInfo(DISEASE_DATABASE.wssv, 0.50, symptoms);
}

function buildReportFromInfo(
  info: DiseaseInfo,
  confidence: number,
  observedSymptoms: string[]
): DiagnosticReport {
  return {
    diseaseCode: info.code,
    diseaseName: info.name,
    scientificName: info.scientificName,
    teluguName: info.teluguName,
    confidence,
    severity: info.severity,
    isEmergencyHarvest: info.isEmergencyHarvest,
    immediateAction: info.treatment.immediateActions[0] ?? '',
    teluguAction: info.treatment.teluguRecommendations[0] ?? '',
    treatmentPlan: [...info.treatment.immediateActions],
    biosecurityMeasures: [...info.treatment.biosecurityMeasures],
    teluguSummary: info.treatment.teluguSummary,
    teluguRecommendations: [...info.treatment.teluguRecommendations],
    matchedSymptoms: [...observedSymptoms],
  };
}
