/**
 * Severity levels for water quality telemetry and system alerts.
 */
export type AlertSeverity = 'optimal' | 'watch' | 'urgent' | 'critical';

/**
 * Structured representation of a water parameter evaluation alert.
 */
export interface WaterAlert {
  parameter: string;
  value: number;
  unit: string;
  severity: AlertSeverity;
  message: string;
  recommendation: string;
  teluguMessage: string;
  teluguRecommendation: string;
}

/**
 * Represents a critical life-safety aquaculture emergency alarm.
 */
export interface EmergencyAlarm {
  id: string;
  pondId: string;
  pondName: string;
  parameter: string;
  measuredValue: string;
  title: string;
  teluguTitle: string;
  checklist: string[];
  teluguChecklist: string[];
  triggeredAt: string;
  acknowledged: boolean;
}

/**
 * Structured water quality reading input.
 */
export interface WaterQualityReading {
  ph: number;
  dissolvedOxygen: number;
  temperatureC: number;
  salinityPpt: number;
  ammoniaMgL: number;
  alkalinityMgL: number;
}

/**
 * Comprehensive water evaluation report for CLI and dashboards.
 */
export interface WaterQualityEvaluation {
  severity: string;
  summary: string;
  nocturnalForecast: string;
  alarms: string[];
}

/**
 * Alert System evaluating aquaculture telemetry parameters against
 * established ICAR-CIBA & MPEDA Vannamei / Monodon scientific thresholds.
 */
export class AlertSystem {
  /**
   * Computes toxic Un-ionized Ammonia (NH3 in mg/L) from Total Ammonia Nitrogen (TAN in mg/L),
   * pond pH, and water temperature (°C) using the Emerson et al. (1975) dissociation model:
   * - pKa = 0.09018 + (2729.92 / (T_c + 273.15))
   * - fraction NH3 = 1 / (1 + 10^(pKa - pH))
   * - Un-ionized NH3 (mg/L) = TAN * fraction NH3
   */
  static calculateUnIonizedNh3FromTan(
    tanMgL: number,
    ph: number,
    temperatureC: number
  ): number {
    if (tanMgL <= 0) return 0.0;
    const tempK = Math.min(Math.max(temperatureC, 10.0), 45.0) + 273.15;
    const pKa = 0.09018 + 2729.92 / tempK;
    const safePh = Math.min(Math.max(ph, 5.0), 11.0);
    const exponent = pKa - safePh;
    const fractionNh3 = 1.0 / (1.0 + Math.pow(10.0, exponent));
    const nh3 = tanMgL * fractionNh3;
    return Math.round(nh3 * 10000) / 10000;
  }

  /**
   * Evaluates all provided water parameters and returns a list of WaterAlerts.
   */
  static evaluateParameters(params: {
    ph?: number;
    dissolvedOxygen?: number;
    ammonia?: number;
    alkalinity?: number;
    salinity?: number;
    temperature?: number;
  }): WaterAlert[] {
    const alerts: WaterAlert[] = [];
    if (params.ph !== undefined) {
      alerts.push(this.evaluatePh(params.ph));
    }
    if (params.dissolvedOxygen !== undefined) {
      alerts.push(this.evaluateDO(params.dissolvedOxygen));
    }
    if (params.ammonia !== undefined) {
      alerts.push(this.evaluateAmmonia(params.ammonia));
    }
    if (params.alkalinity !== undefined) {
      alerts.push(this.evaluateAlkalinity(params.alkalinity));
    }
    if (params.salinity !== undefined) {
      alerts.push(this.evaluateSalinity(params.salinity));
    }
    if (params.temperature !== undefined) {
      alerts.push(this.evaluateTemperature(params.temperature));
    }
    return alerts;
  }

  /**
   * Evaluates pH level:
   * - Urgent: < 7.0 or > 9.0
   * - Watch: 7.0 - 7.5 or 8.5 - 9.0
   * - Optimal: 7.5 - 8.5
   */
  static evaluatePh(ph: number): WaterAlert {
    if (ph < 7.0) {
      return {
        parameter: 'pH',
        value: ph,
        unit: '',
        severity: 'urgent',
        message: `Critical low pH (${ph.toFixed(1)}). High acidity risk to shrimp shell and gill tissue.`,
        recommendation: 'Apply agricultural lime (CaCO3) or dolomite at 10-15 kg/acre immediately.',
        teluguMessage: `తీవ్రమైన తక్కువ pH (${ph.toFixed(1)}). రొయ్యల కవచం మరియు మొప్పలకు ప్రమాదం.`,
        teluguRecommendation: 'ఎకరాకు 10-15 కిలోల వ్యవసాయ సున్నం (CaCO3) లేదా డోలమైట్ వెంటనే వేయండి.',
      };
    } else if (ph > 9.0) {
      return {
        parameter: 'pH',
        value: ph,
        unit: '',
        severity: 'urgent',
        message: `Critical high pH (${ph.toFixed(1)}). Extreme risk of toxic un-ionized ammonia conversion.`,
        recommendation: 'Apply fermented jaggery or molasses (5-10 kg/acre) with probiotic yeast to buffer alkalinity.',
        teluguMessage: `తీవ్రమైన అధిక pH (${ph.toFixed(1)}). విషపూరిత అమ్మోనియా ప్రమాదం.`,
        teluguRecommendation: 'ఎకరాకు 5-10 కిలోల బెల్లం మరియు ప్రోబయోటిక్ మిశ్రమాన్ని వేయండి.',
      };
    } else if ((ph >= 7.0 && ph < 7.5) || (ph > 8.5 && ph <= 9.0)) {
      return {
        parameter: 'pH',
        value: ph,
        unit: '',
        severity: 'watch',
        message:
          ph < 7.5
            ? `Sub-optimal low pH (${ph.toFixed(1)}). Pond buffering capacity is decreasing.`
            : `Sub-optimal high pH (${ph.toFixed(1)}). Afternoon photosynthetic bloom driving pH up.`,
        recommendation:
          ph < 7.5
            ? 'Apply mild lime (5 kg/acre) and check morning alkalinity.'
            : 'Dilute with fresh water exchange or apply probiotics in early morning.',
        teluguMessage: ph < 7.5 ? `pH కొద్దిగా తక్కువగా ఉంది (${ph.toFixed(1)}).` : `pH కొద్దిగా ఎక్కువగా ఉంది (${ph.toFixed(1)}).`,
        teluguRecommendation:
          ph < 7.5 ? 'ఎకరాకు 5 కిలోల సున్నం వేయండి.' : 'ఉదయాన్నే ప్రోబయోటిక్స్ వేయండి మరియు తాజా నీటిని కలపండి.',
      };
    } else {
      return {
        parameter: 'pH',
        value: ph,
        unit: '',
        severity: 'optimal',
        message: `Optimal pH (${ph.toFixed(1)}). Excellent ionic balance for shrimp growth.`,
        recommendation: 'Maintain current feeding and liming schedule.',
        teluguMessage: `సరైన pH (${ph.toFixed(1)}). రొయ్యల పెరుగుదలకు చాలా మంచిది.`,
        teluguRecommendation: 'ప్రస్తుత మేత మరియు సున్నం నిర్వహణను కొనసాగించండి.',
      };
    }
  }

  /**
   * Evaluates Dissolved Oxygen (DO) in mg/L:
   * - Urgent: < 3.0 mg/L (Critical Hypoxia Siren)
   * - Watch: 3.0 - 4.0 mg/L
   * - Optimal: > 4.0 mg/L
   */
  static evaluateDO(dissolvedOxygen: number): WaterAlert {
    if (dissolvedOxygen < 3.0) {
      return {
        parameter: 'Dissolved Oxygen',
        value: dissolvedOxygen,
        unit: 'mg/L',
        severity: 'urgent',
        message: `Critical Hypoxia Risk (${dissolvedOxygen.toFixed(1)} mg/L)! Immediate shrimp asphyxiation risk.`,
        recommendation: 'Activate 100% aerators immediately. Apply Sodium Percarbonate (2-3 kg/acre) emergency oxygen booster.',
        teluguMessage: `తీవ్రమైన ఆక్సిజన్ కొరత (${dissolvedOxygen.toFixed(1)} mg/L)! రొయ్యలు ఊపిరాడక చనిపోయే ప్రమాదం.`,
        teluguRecommendation: 'అన్ని ఎయిరేటర్లను వెంటనే ఆన్ చేయండి. ఎకరాకు 2-3 కిలోల ఆక్సిజన్ మాత్రలు వేయండి.',
      };
    } else if (dissolvedOxygen <= 4.0) {
      return {
        parameter: 'Dissolved Oxygen',
        value: dissolvedOxygen,
        unit: 'mg/L',
        severity: 'watch',
        message: `Low Dissolved Oxygen (${dissolvedOxygen.toFixed(1)} mg/L). Stress threshold approaching.`,
        recommendation: 'Turn on additional paddle aerators and reduce feed quantity by 25%.',
        teluguMessage: `ఆక్సిజన్ స్థాయి తక్కువగా ఉంది (${dissolvedOxygen.toFixed(1)} mg/L).`,
        teluguRecommendation: 'ఎయిరేటర్లను ఆన్ చేయండి మరియు మేతను 25% తగ్గించండి.',
      };
    } else {
      return {
        parameter: 'Dissolved Oxygen',
        value: dissolvedOxygen,
        unit: 'mg/L',
        severity: 'optimal',
        message: `Optimal Dissolved Oxygen (${dissolvedOxygen.toFixed(1)} mg/L). High saturation level.`,
        recommendation: 'Maintain continuous aerator cycle during nocturnal hours.',
        teluguMessage: `సరైన ఆక్సిజన్ స్థాయి (${dissolvedOxygen.toFixed(1)} mg/L).`,
        teluguRecommendation: 'రాత్రి సమయాల్లో ఎయిరేటర్లు సరిగ్గా పనిచేసేలా చూసుకోండి.',
      };
    }
  }

  /**
   * Evaluates Un-ionized Ammonia (NH3) in mg/L:
   * - Urgent: > 0.1 mg/L
   * - Watch: 0.05 - 0.1 mg/L
   * - Optimal: < 0.05 mg/L
   */
  static evaluateAmmonia(ammonia: number): WaterAlert {
    if (ammonia > 0.1) {
      return {
        parameter: 'Ammonia (NH3)',
        value: ammonia,
        unit: 'mg/L',
        severity: 'urgent',
        message: `Toxic Un-ionized Ammonia Spike (${ammonia.toFixed(2)} mg/L NH3)! Severe gill damage and mortality risk.`,
        recommendation: 'Perform 20% bottom water exchange, stop feeding for 1 meal, apply Yucca extract + Zeolite (25 kg/acre) and nitrifying bacteria.',
        teluguMessage: `తీవ్రమైన విషపూరిత అమ్మోనియా (${ammonia.toFixed(2)} mg/L NH3)! మొప్పలు దెబ్బతినే ప్రమాదం.`,
        teluguRecommendation: '20% కింద నీటిని మార్చండి, ఒక పూట మేత ఆపండి, యుక్కా, జియోలైట్ మరియు నైట్రిఫైయింగ్ ప్రోబయోటిక్స్ వేయండి.',
      };
    } else if (ammonia >= 0.05) {
      return {
        parameter: 'Ammonia (NH3)',
        value: ammonia,
        unit: 'mg/L',
        severity: 'watch',
        message: `Elevated Un-ionized Ammonia (${ammonia.toFixed(2)} mg/L NH3). Organic waste accumulation detected.`,
        recommendation: 'Reduce daily feed by 15% and apply concentrated Bacillus soil probiotics.',
        teluguMessage: `అమ్మోనియా పెరుగుతోంది (${ammonia.toFixed(2)} mg/L NH3). వ్యర్థాలు పేరుకుపోతున్నాయి.`,
        teluguRecommendation: 'మేతను 15% తగ్గించి, బాసిల్లస్ ప్రోబయోటిక్స్ వేయండి.',
      };
    } else {
      return {
        parameter: 'Ammonia (NH3)',
        value: ammonia,
        unit: 'mg/L',
        severity: 'optimal',
        message: `Safe Un-ionized Ammonia level (${ammonia.toFixed(2)} mg/L NH3). Clean pond bottom ecosystem.`,
        recommendation: 'Maintain regular sludge removal and bi-weekly probiotic dosing.',
        teluguMessage: `సురక్షితమైన అమ్మోనియా స్థాయి (${ammonia.toFixed(2)} mg/L NH3).`,
        teluguRecommendation: 'చెరువు అడుగుభాగాన్ని శుభ్రంగా ఉంచుకోండి.',
      };
    }
  }

  /**
   * Evaluates Alkalinity (CaCO3) in mg/L:
   * - Watch: < 100 mg/L or > 150 mg/L
   * - Optimal: 100 - 150 mg/L
   */
  static evaluateAlkalinity(alkalinity: number): WaterAlert {
    if (alkalinity < 100.0) {
      return {
        parameter: 'Alkalinity',
        value: alkalinity,
        unit: 'mg/L',
        severity: 'watch',
        message: `Low Alkalinity (${alkalinity.toFixed(0)} mg/L). Inadequate buffer causes wild pH swings and soft shell.`,
        recommendation: 'Apply sodium bicarbonate (NaHCO3) at 10-15 kg/acre or dolomite to raise above 120 mg/L.',
        teluguMessage: `క్షారత్వం తక్కువగా ఉంది (${alkalinity.toFixed(0)} mg/L). pH హెచ్చుతగ్గులు ఏర్పడతాయి.`,
        teluguRecommendation: 'ఎకరాకు 10-15 కిలోల సోడియం బైకార్బోనేట్ (సోడా) లేదా డోలమైట్ వేయండి.',
      };
    } else if (alkalinity <= 150.0) {
      return {
        parameter: 'Alkalinity',
        value: alkalinity,
        unit: 'mg/L',
        severity: 'optimal',
        message: `Optimal Alkalinity (${alkalinity.toFixed(0)} mg/L). Strong buffering capacity against pH fluctuation.`,
        recommendation: 'Maintain current mineral supplementation schedule.',
        teluguMessage: `సరైన క్షారత్వం (${alkalinity.toFixed(0)} mg/L). స్థిరమైన నీటి నాణ్యత.`,
        teluguRecommendation: 'ఖనిజ లవణాల నిర్వహణను ఇలాగే కొనసాగించండి.',
      };
    } else {
      return {
        parameter: 'Alkalinity',
        value: alkalinity,
        unit: 'mg/L',
        severity: 'watch',
        message: `High Alkalinity (${alkalinity.toFixed(0)} mg/L). Potential mineral precipitation.`,
        recommendation: 'Monitor morning and evening pH; moderate lime applications.',
        teluguMessage: `అధిక క్షారత్వం (${alkalinity.toFixed(0)} mg/L).`,
        teluguRecommendation: 'సున్నం వాడకాన్ని తగ్గించండి మరియు pH ను గమనించండి.',
      };
    }
  }

  /**
   * Evaluates Salinity in ppt:
   * - Watch: < 5 ppt or > 35 ppt
   * - Optimal: 5 - 35 ppt
   */
  static evaluateSalinity(salinity: number): WaterAlert {
    if (salinity < 5.0 || salinity > 35.0) {
      return {
        parameter: 'Salinity',
        value: salinity,
        unit: 'ppt',
        severity: 'watch',
        message:
          salinity < 5.0
            ? `Low Inland Salinity (${salinity.toFixed(1)} ppt). Osmotic stress risk during molting.`
            : `High Salinity (${salinity.toFixed(1)} ppt). Retarded growth rate and high mineral stress.`,
        recommendation:
          salinity < 5.0
            ? 'Supplement Muriate of Potash (KCl @ 10 kg/acre) and Magnesium Sulfate (MgSO4 @ 15 kg/acre).'
            : 'Dilute with low-salinity freshwater if available.',
        teluguMessage:
          salinity < 5.0
            ? `ఉప్పు శాతం తక్కువగా ఉంది (${salinity.toFixed(1)} ppt). కుబుసం విడిచే సమయంలో ఒత్తిడి.`
            : `ఉప్పు శాతం అధికంగా ఉంది (${salinity.toFixed(1)} ppt).`,
        teluguRecommendation:
          salinity < 5.0
            ? 'ఎకరాకు 10 కిలోల పొటాష్ (KCl) మరియు 15 కిలోల మెగ్నీషియం సల్ఫేట్ అందించండి.'
            : 'సాధ్యమైతే మంచి నీటిని కలపండి.',
      };
    } else {
      return {
        parameter: 'Salinity',
        value: salinity,
        unit: 'ppt',
        severity: 'optimal',
        message: `Optimal Salinity (${salinity.toFixed(1)} ppt). Excellent osmoregulation range.`,
        recommendation: 'Maintain standard water exchange regimen.',
        teluguMessage: `సరైన ఉప్పు శాతం (${salinity.toFixed(1)} ppt).`,
        teluguRecommendation: 'నీటి యాజమాన్యాన్ని ఇలాగే కొనసాగించండి.',
      };
    }
  }

  /**
   * Evaluates Water Temperature in °C:
   * - Watch: < 24.0°C or > 33.0°C
   * - Optimal: 24.0 - 33.0°C
   */
  static evaluateTemperature(temperature: number): WaterAlert {
    if (temperature < 24.0 || temperature > 33.0) {
      return {
        parameter: 'Temperature',
        value: temperature,
        unit: '°C',
        severity: 'watch',
        message:
          temperature < 24.0
            ? `Low Water Temperature (${temperature.toFixed(1)}°C). Suppressed feeding metabolism.`
            : `High Water Temperature (${temperature.toFixed(1)}°C). Accelerated DO depletion.`,
        recommendation:
          temperature < 24.0
            ? 'Reduce feeding by 15-20% and avoid cold early morning feedings.'
            : 'Increase aeration and monitor check trays 90 minutes after feeding.',
        teluguMessage:
          temperature < 24.0
            ? `తక్కువ ఉష్ణోగ్రత (${temperature.toFixed(1)}°C). మేత తీసుకోవడం తగ్గుతుంది.`
            : `అధిక ఉష్ణోగ్రత (${temperature.toFixed(1)}°C). ఆక్సిజన్ వినియోగం వేగవంతం అవుతుంది.`,
        teluguRecommendation:
          temperature < 24.0 ? 'మేతను 15-20% తగ్గించండి.' : 'ఎయిరేటర్లను పెంచండి.',
      };
    } else {
      return {
        parameter: 'Temperature',
        value: temperature,
        unit: '°C',
        severity: 'optimal',
        message: `Optimal Temperature (${temperature.toFixed(1)}°C). Peak metabolic efficiency.`,
        recommendation: 'Maintain 4-meal diurnal feeding schedule.',
        teluguMessage: `సరైన ఉష్ణోగ్రత (${temperature.toFixed(1)}°C).`,
        teluguRecommendation: '4 పూటల మేత విధానాన్ని అనుసరించండి.',
      };
    }
  }

  /**
   * Evaluates water telemetry log for life-safety emergency alarms.
   */
  static evaluateWaterLogForEmergency(
    pondId: string,
    pondName: string,
    dissolvedOxygen?: number,
    ammonia?: number,
    triggeredAt?: string
  ): EmergencyAlarm[] {
    const alarms: EmergencyAlarm[] = [];
    const timestamp = triggeredAt || new Date().toISOString();
    const timeMs = Date.now();

    if (dissolvedOxygen !== undefined && dissolvedOxygen < 3.5) {
      const isLethal = dissolvedOxygen < 2.8;
      alarms.push({
        id: `alarm_do_${pondId}_${timeMs}`,
        pondId,
        pondName,
        parameter: 'Dissolved Oxygen',
        measuredValue: `${dissolvedOxygen.toFixed(1)} mg/L`,
        title: isLethal
          ? `LETHAL HYPOXIA CRASH in ${pondName} (${dissolvedOxygen.toFixed(1)} mg/L)`
          : `Critical Low Dissolved Oxygen in ${pondName} (${dissolvedOxygen.toFixed(1)} mg/L)`,
        teluguTitle: isLethal
          ? `${pondName} లో ప్రాణాంతక ఆక్సిజన్ పతనం (${dissolvedOxygen.toFixed(1)} mg/L)`
          : `${pondName} లో ఆక్సిజన్ ప్రమాదకర స్థాయికి పడిపోయింది (${dissolvedOxygen.toFixed(1)} mg/L)`,
        checklist: [
          'Turn ON all paddlewheel and spiral aerators at 100% capacity immediately.',
          'Broadcast Sodium Percarbonate (Oxygen tablets/granules) @ 2–3 kg/acre.',
          'HALT all feeding meals immediately until DO stabilizes above 4.5 mg/L.',
          'Start emergency borewell/reservoir water exchange (15–20%) if available.',
        ],
        teluguChecklist: [
          'తక్షణమే అన్ని ఏరేటర్లను (Paddlewheel Aerators) పూర్తి స్థాయిలో ఆన్ చేయండి.',
          'ఎకరానికి 2–3 కిలోల ఆక్సిజన్ టాబ్లెట్లు/గ్రాన్యూల్స్ చల్లండి.',
          'DO 4.5 mg/L దాటే వరకు మేత వేయడం పూర్తిగా ఆపివేయండి.',
          '15–20% కొత్త నీటిని చెరువులోకి పంపండి.',
        ],
        triggeredAt: timestamp,
        acknowledged: false,
      });
    }

    if (ammonia !== undefined && ammonia >= 0.1) {
      alarms.push({
        id: `alarm_nh3_${pondId}_${timeMs}`,
        pondId,
        pondName,
        parameter: 'Ammonia (TAN)',
        measuredValue: `${ammonia.toFixed(2)} ppm`,
        title: `Toxic Ammonia Spike in ${pondName} (${ammonia.toFixed(2)} ppm)`,
        teluguTitle: `${pondName} లో ప్రమాదకర అమోనియా పెరుగుదల (${ammonia.toFixed(2)} ppm)`,
        checklist: [
          'Apply Yucca schidigera extract or Zeolite @ 25–40 kg/acre immediately.',
          'Reduce next 2 feed rations by 30% to stop nitrogenous waste buildup.',
          'Add fermented molasses + Bacillus nitrifying probiotics with strong aeration.',
          'Exchange 15–20% bottom water to flush accumulated sludge.',
        ],
        teluguChecklist: [
          'ఎకరానికి 25–40 కిలోల యుక్కా లేదా జియోలైట్ వేయండి.',
          'తదుపరి 2 పూటల మేతను 30% తగ్గించండి.',
          'బెల్లం మరియు నైట్రిఫైయింగ్ ప్రోబయోటిక్స్ వేయండి.',
          '15–20% అడుగు నీటిని మార్చండి.',
        ],
        triggeredAt: timestamp,
        acknowledged: false,
      });
    }

    return alarms;
  }

  /**
   * Nocturnal DO Crash Forecaster:
   * Predicts dawn DO at 05:00 AM based on evening DO, temperature, DOC, biomass, and aeration.
   */
  static forecastDawnDissolvedOxygen(
    eveningDo: number,
    waterTemp: number,
    doc: number,
    biomassKg: number,
    hasAeratorsRunning: boolean
  ): { predictedDawnDo: number; severity: AlertSeverity } {
    const biomassLoad = (biomassKg / 1000.0) * 0.05;
    const tempFactor = 1.0 + Math.min(Math.max((waterTemp - 28.0) * 0.04, -0.2), 0.4);
    const docFactor = 1.0 + Math.min(Math.max(doc * 0.003, 0.0), 0.4);

    const grossRespirationRate = (0.28 + biomassLoad) * tempFactor * docFactor;
    const aeratorReplenishment = hasAeratorsRunning ? 0.45 : 0.0;

    const netHourlyDepletion = Math.max(grossRespirationRate - aeratorReplenishment, 0.04);
    const predictedDawnDo = Math.min(Math.max(eveningDo - netHourlyDepletion * 10.0, 0.5), 9.0);

    let severity: AlertSeverity = 'optimal';
    if (predictedDawnDo < 2.8) {
      severity = 'critical';
    } else if (predictedDawnDo < 3.5) {
      severity = 'urgent';
    } else if (predictedDawnDo < 4.0) {
      severity = 'watch';
    }

    return {
      predictedDawnDo: Math.round(predictedDawnDo * 10) / 10,
      severity,
    };
  }
}

/**
 * Adapter engine for CLI and dashboard evaluation.
 */
export class WaterQualityEngine {
  static evaluate(reading: WaterQualityReading): WaterQualityEvaluation {
    const alerts = AlertSystem.evaluateParameters({
      ph: reading.ph,
      dissolvedOxygen: reading.dissolvedOxygen,
      ammonia: reading.ammoniaMgL,
      alkalinity: reading.alkalinityMgL,
      salinity: reading.salinityPpt,
      temperature: reading.temperatureC,
    });

    const emergencyAlarms = AlertSystem.evaluateWaterLogForEmergency(
      'p1',
      'Pond 1',
      reading.dissolvedOxygen,
      reading.ammoniaMgL
    );

    let severity = 'OPTIMAL';
    if (alerts.some((a) => a.severity === 'urgent' || a.severity === 'critical')) {
      severity = 'CRITICAL / URGENT';
    } else if (alerts.some((a) => a.severity === 'watch')) {
      severity = 'WATCH / CAUTION';
    }

    const { predictedDawnDo, severity: dawnSev } = AlertSystem.forecastDawnDissolvedOxygen(
      reading.dissolvedOxygen,
      reading.temperatureC,
      60,
      3000,
      true
    );

    const forecastMsg = `Predicted Dawn DO (05:00 AM): ${predictedDawnDo.toFixed(1)} mg/L (${dawnSev.toUpperCase()})`;

    const alarms = emergencyAlarms.map(
      (a) => `${a.title}: ${a.checklist[0] || ''}`
    );

    return {
      severity,
      summary: `${alerts.length} parameter(s) evaluated. Overall: ${severity}`,
      nocturnalForecast: forecastMsg,
      alarms,
    };
  }
}
