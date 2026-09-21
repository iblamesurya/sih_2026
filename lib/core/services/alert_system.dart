/// Severity levels for water quality telemetry and system alerts.
enum AlertSeverity {
  optimal,
  watch,
  urgent,
}

/// Structured representation of a water parameter evaluation alert.
class WaterAlert {
  final String parameter;
  final double value;
  final String unit;
  final AlertSeverity severity;
  final String message;
  final String recommendation;
  final String teluguMessage;
  final String teluguRecommendation;

  const WaterAlert({
    required this.parameter,
    required this.value,
    required this.unit,
    required this.severity,
    required this.message,
    required this.recommendation,
    required this.teluguMessage,
    required this.teluguRecommendation,
  });

  bool get isUrgent => severity == AlertSeverity.urgent;
  bool get isWatch => severity == AlertSeverity.watch;
  bool get isOptimal => severity == AlertSeverity.optimal;

  Map<String, dynamic> toJson() => {
        'parameter': parameter,
        'value': value,
        'unit': unit,
        'severity': severity.name,
        'message': message,
        'recommendation': recommendation,
        'teluguMessage': teluguMessage,
        'teluguRecommendation': teluguRecommendation,
      };

  @override
  String toString() =>
      'WaterAlert($parameter: $value $unit, severity: ${severity.name}, msg: $message)';
}

/// Alert System evaluating aquaculture telemetry parameters against
/// established Vannamei / Monodon scientific thresholds.
class AlertSystem {
  const AlertSystem();

  /// Evaluates all provided water parameters and returns a list of [WaterAlert]s.
  List<WaterAlert> evaluateParameters({
    double? ph,
    double? dissolvedOxygen,
    double? ammonia,
    double? alkalinity,
    double? salinity,
    double? temperature,
  }) {
    final List<WaterAlert> alerts = [];

    if (ph != null) {
      alerts.add(evaluatePh(ph));
    }

    if (dissolvedOxygen != null) {
      alerts.add(evaluateDO(dissolvedOxygen));
    }

    if (ammonia != null) {
      alerts.add(evaluateAmmonia(ammonia));
    }

    if (alkalinity != null) {
      alerts.add(evaluateAlkalinity(alkalinity));
    }

    if (salinity != null) {
      alerts.add(evaluateSalinity(salinity));
    }

    if (temperature != null) {
      alerts.add(evaluateTemperature(temperature));
    }

    return alerts;
  }

  /// Evaluates pH level:
  /// - Urgent: < 7.0 or > 9.0
  /// - Watch: 7.0 - 7.5 or 8.5 - 9.0
  /// - Optimal: 7.5 - 8.5
  WaterAlert evaluatePh(double ph) {
    if (ph < 7.0) {
      return WaterAlert(
        parameter: 'pH',
        value: ph,
        unit: '',
        severity: AlertSeverity.urgent,
        message: 'Critical low pH ($ph). High acidity risk to shrimp shell and gill tissue.',
        recommendation: 'Apply agricultural lime (CaCO3) or dolomite at 10-15 kg/acre immediately.',
        teluguMessage: 'తీవ్రమైన తక్కువ pH ($ph). రొయ్యల కవచం మరియు మొప్పలకు ప్రమాదం.',
        teluguRecommendation: 'ఎకరాకు 10-15 కిలోల వ్యవసాయ సున్నం (CaCO3) లేదా డోలమైట్ వెంటనే వేయండి.',
      );
    } else if (ph > 9.0) {
      return WaterAlert(
        parameter: 'pH',
        value: ph,
        unit: '',
        severity: AlertSeverity.urgent,
        message: 'Critical high pH ($ph). Extreme risk of toxic un-ionized ammonia conversion.',
        recommendation: 'Apply fermented jaggery or molasses (5-10 kg/acre) with probiotic yeast to buffer alkalinity.',
        teluguMessage: 'తీవ్రమైన అధిక pH ($ph). విషపూరిత అమ్మోనియా ప్రమాదం.',
        teluguRecommendation: 'ఎకరాకు 5-10 కిలోల బెల్లం మరియు ప్రోబయోటిక్ మిశ్రమాన్ని వేయండి.',
      );
    } else if ((ph >= 7.0 && ph < 7.5) || (ph > 8.5 && ph <= 9.0)) {
      return WaterAlert(
        parameter: 'pH',
        value: ph,
        unit: '',
        severity: AlertSeverity.watch,
        message: ph < 7.5
            ? 'Sub-optimal low pH ($ph). Pond buffering capacity is decreasing.'
            : 'Sub-optimal high pH ($ph). Afternoon photosynthetic bloom driving pH up.',
        recommendation: ph < 7.5
            ? 'Apply mild lime (5 kg/acre) and check morning alkalinity.'
            : 'Dilute with fresh water exchange or apply probiotics in early morning.',
        teluguMessage: ph < 7.5
            ? 'pH కొద్దిగా తక్కువగా ఉంది ($ph).'
            : 'pH కొద్దిగా ఎక్కువగా ఉంది ($ph).',
        teluguRecommendation: ph < 7.5
            ? 'ఎకరాకు 5 కిలోల సున్నం వేయండి.'
            : 'ఉదయాన్నే ప్రోబయోటిక్స్ వేయండి మరియు తాజా నీటిని కలపండి.',
      );
    } else {
      return WaterAlert(
        parameter: 'pH',
        value: ph,
        unit: '',
        severity: AlertSeverity.optimal,
        message: 'Optimal pH ($ph). Excellent ionic balance for shrimp growth.',
        recommendation: 'Maintain current feeding and liming schedule.',
        teluguMessage: 'సరైన pH ($ph). రొయ్యల పెరుగుదలకు చాలా మంచిది.',
        teluguRecommendation: 'ప్రస్తుత మేత మరియు సున్నం నిర్వహణను కొనసాగించండి.',
      );
    }
  }

  /// Evaluates Dissolved Oxygen (DO) in mg/L:
  /// - Urgent: < 3.0 mg/L
  /// - Watch: 3.0 - 4.0 mg/L
  /// - Optimal: > 4.0 mg/L
  WaterAlert evaluateDO(double dissolvedOxygen) {
    if (dissolvedOxygen < 3.0) {
      return WaterAlert(
        parameter: 'Dissolved Oxygen',
        value: dissolvedOxygen,
        unit: 'mg/L',
        severity: AlertSeverity.urgent,
        message: 'Critical Hypoxia Risk ($dissolvedOxygen mg/L)! Immediate shrimp asphyxiation risk.',
        recommendation: 'Activate 100% aerators immediately. Apply hydrogen peroxide or oxygen tablets emergency booster.',
        teluguMessage: 'తీవ్రమైన ఆక్సిజన్ కొరత ($dissolvedOxygen mg/L)! రొయ్యలు ఊపిరాడక చనిపోయే ప్రమాదం.',
        teluguRecommendation: 'అన్ని ఎయిరేటర్లను వెంటనే ఆన్ చేయండి. ఆక్సిజన్ మాత్రలు వేయండి.',
      );
    } else if (dissolvedOxygen <= 4.0) {
      return WaterAlert(
        parameter: 'Dissolved Oxygen',
        value: dissolvedOxygen,
        unit: 'mg/L',
        severity: AlertSeverity.watch,
        message: 'Low Dissolved Oxygen ($dissolvedOxygen mg/L). Stress threshold approaching.',
        recommendation: 'Turn on additional paddle aerators and reduce feed quantity by 25%.',
        teluguMessage: 'ఆక్సిజన్ స్థాయి తక్కువగా ఉంది ($dissolvedOxygen mg/L).',
        teluguRecommendation: 'ఎయిరేటర్లను ఆన్ చేయండి మరియు మేతను 25% తగ్గించండి.',
      );
    } else {
      return WaterAlert(
        parameter: 'Dissolved Oxygen',
        value: dissolvedOxygen,
        unit: 'mg/L',
        severity: AlertSeverity.optimal,
        message: 'Optimal Dissolved Oxygen ($dissolvedOxygen mg/L). High saturation level.',
        recommendation: 'Maintain continuous aerator cycle during nocturnal hours.',
        teluguMessage: 'సరైన ఆక్సిజన్ స్థాయి ($dissolvedOxygen mg/L).',
        teluguRecommendation: 'రాత్రి సమయాల్లో ఎయిరేటర్లు సరిగ్గా పనిచేసేలా చూసుకోండి.',
      );
    }
  }

  /// Evaluates Total / Un-ionized Ammonia ($NH_3$) in mg/L:
  /// - Urgent: > 0.1 mg/L
  /// - Watch: 0.05 - 0.1 mg/L
  /// - Optimal: < 0.05 mg/L
  WaterAlert evaluateAmmonia(double ammonia) {
    if (ammonia > 0.1) {
      return WaterAlert(
        parameter: 'Ammonia (NH3)',
        value: ammonia,
        unit: 'mg/L',
        severity: AlertSeverity.urgent,
        message: 'Toxic Ammonia Spike ($ammonia mg/L)! Severe gill damage and mortality risk.',
        recommendation: 'Perform 20% bottom water exchange, stop feeding for 1 meal, apply Yucca extract and nitrifying bacteria.',
        teluguMessage: 'తీవ్రమైన విషపూరిత అమ్మోనియా ($ammonia mg/L)! మొప్పల దెబ్బతినే ప్రమాదం.',
        teluguRecommendation: '20% కింద నీటిని మార్చండి, ఒక పూట మేత ఆపండి, యుక్కా మరియు నైట్రిఫైయింగ్ ప్రోబయోటిక్స్ వేయండి.',
      );
    } else if (ammonia >= 0.05) {
      return WaterAlert(
        parameter: 'Ammonia (NH3)',
        value: ammonia,
        unit: 'mg/L',
        severity: AlertSeverity.watch,
        message: 'Elevated Ammonia ($ammonia mg/L). Organic waste accumulation detected.',
        recommendation: 'Reduce daily feed by 15% and apply concentrated Bacillus soil probiotics.',
        teluguMessage: 'అమ్మోనియా పెరుగుతోంది ($ammonia mg/L). వ్యర్థాలు పేరుకుపోతున్నాయి.',
        teluguRecommendation: 'మేతను 15% తగ్గించి, బాసిల్లస్ ప్రోబయోటిక్స్ వేయండి.',
      );
    } else {
      return WaterAlert(
        parameter: 'Ammonia (NH3)',
        value: ammonia,
        unit: 'mg/L',
        severity: AlertSeverity.optimal,
        message: 'Safe Ammonia level ($ammonia mg/L). Clean pond bottom ecosystem.',
        recommendation: 'Maintain regular sludge removal and bi-weekly probiotic dosing.',
        teluguMessage: 'సురక్షితమైన అమ్మోనియా స్థాయి ($ammonia mg/L).',
        teluguRecommendation: 'చెరువు అడుగుభాగాన్ని శుభ్రంగా ఉంచుకోండి.',
      );
    }
  }

  /// Evaluates Alkalinity ($CaCO_3$) in mg/L:
  /// - Watch: < 100 mg/L or > 200 mg/L
  /// - Optimal: 100 - 150 mg/L (acceptable up to 200 mg/L)
  WaterAlert evaluateAlkalinity(double alkalinity) {
    if (alkalinity < 100) {
      return WaterAlert(
        parameter: 'Alkalinity',
        value: alkalinity,
        unit: 'mg/L',
        severity: AlertSeverity.watch,
        message: 'Low Alkalinity ($alkalinity mg/L). Inadequate buffer causes wild pH swings.',
        recommendation: 'Apply sodium bicarbonate (NaHCO3) at 10-15 kg/acre or dolomite to raise above 120 mg/L.',
        teluguMessage: 'క్షారత్వం తక్కువగా ఉంది ($alkalinity mg/L). pH హెచ్చుతగ్గులు ఏర్పడతాయి.',
        teluguRecommendation: 'ఎకరాకు 10-15 కిలోల సోడియం బైకార్బోనేట్ (సోడా) లేదా డోలమైట్ వేయండి.',
      );
    } else if (alkalinity <= 150) {
      return WaterAlert(
        parameter: 'Alkalinity',
        value: alkalinity,
        unit: 'mg/L',
        severity: AlertSeverity.optimal,
        message: 'Optimal Alkalinity ($alkalinity mg/L). Strong buffering capacity against pH fluctuation.',
        recommendation: 'Maintain current mineral supplementation schedule.',
        teluguMessage: 'సరైన క్షారత్వం ($alkalinity mg/L). స్థిరమైన నీటి నాణ్యత.',
        teluguRecommendation: 'ఖనిజ లవణాల నిర్వహణను ఇలాగే కొనసాగించండి.',
      );
    } else {
      return WaterAlert(
        parameter: 'Alkalinity',
        value: alkalinity,
        unit: 'mg/L',
        severity: AlertSeverity.watch,
        message: 'High Alkalinity ($alkalinity mg/L). Potential mineral precipitation.',
        recommendation: 'Monitor morning and evening pH; moderate lime applications.',
        teluguMessage: 'అధిక క్షారత్వం ($alkalinity mg/L).',
        teluguRecommendation: 'సున్నం వాడకాన్ని తగ్గించండి మరియు pH ను గమనించండి.',
      );
    }
  }

  /// Evaluates Salinity in ppt:
  /// - Watch: < 5 ppt or > 35 ppt
  /// - Optimal: 10 - 25 ppt (acceptable 5 - 35 ppt)
  WaterAlert evaluateSalinity(double salinity) {
    if (salinity < 5.0 || salinity > 35.0) {
      return WaterAlert(
        parameter: 'Salinity',
        value: salinity,
        unit: 'ppt',
        severity: AlertSeverity.watch,
        message: salinity < 5.0
            ? 'Low Salinity ($salinity ppt). Osmotic stress risk during molting.'
            : 'High Salinity ($salinity ppt). Retarded growth rate and high mineral stress.',
        recommendation: salinity < 5.0
            ? 'Supplement with magnesium and potassium chloride salts.'
            : 'Dilute with low-salinity freshwater if available.',
        teluguMessage: salinity < 5.0
            ? 'ఉప్పు శాతం తక్కువగా ఉంది ($salinity ppt).'
            : 'ఉప్పు శాతం అధికంగా ఉంది ($salinity ppt).',
        teluguRecommendation: salinity < 5.0
            ? 'మెగ్నీషియం, పొటాషియం ఖనిజాలను అందించండి.'
            : 'సాధ్యమైతే మంచి నీటిని కలపండి.',
      );
    } else {
      return WaterAlert(
        parameter: 'Salinity',
        value: salinity,
        unit: 'ppt',
        severity: AlertSeverity.optimal,
        message: 'Optimal Salinity ($salinity ppt). Excellent for osmoregulation and growth.',
        recommendation: 'Maintain standard mineral ratio (Mg:Ca:K = 3:1:1).',
        teluguMessage: 'సరైన ఉప్పు శాతం ($salinity ppt).',
        teluguRecommendation: 'ఖనిజ నిష్పత్తిని సరిగ్గా నిర్వహించండి.',
      );
    }
  }

  /// Evaluates Water Temperature in °C:
  /// - Urgent: < 22°C or > 34°C
  /// - Watch: 22 - 25°C or 32 - 34°C
  /// - Optimal: 26 - 32°C
  WaterAlert evaluateTemperature(double temp) {
    if (temp < 22.0 || temp > 34.0) {
      return WaterAlert(
        parameter: 'Temperature',
        value: temp,
        unit: '°C',
        severity: AlertSeverity.urgent,
        message: temp < 22.0
            ? 'Critical Low Temperature ($temp°C). Shrimp metabolic cessation.'
            : 'Critical High Temperature ($temp°C). Extreme oxygen depletion and pathogen proliferation.',
        recommendation: temp < 22.0
            ? 'Cut feed by 50% immediately to prevent feed decay.'
            : 'Run aerators, increase pond water depth, cut feed by 30%.',
        teluguMessage: temp < 22.0
            ? 'ఉష్ణోగ్రత చాలా తక్కువగా ఉంది ($temp°C).'
            : 'ఉష్ణోగ్రత చాలా ఎక్కువగా ఉంది ($temp°C).',
        teluguRecommendation: temp < 22.0
            ? 'మేతను 50% తగ్గించండి.'
            : 'నీటి మట్టాన్ని పెంచండి మరియు ఎయిరేటర్లు నడపండి.',
      );
    } else if ((temp >= 22.0 && temp < 26.0) || (temp > 32.0 && temp <= 34.0)) {
      return WaterAlert(
        parameter: 'Temperature',
        value: temp,
        unit: '°C',
        severity: AlertSeverity.watch,
        message: 'Sub-optimal Temperature ($temp°C). Appetite variations expected.',
        recommendation: 'Adjust Feed AI calculation with active temperature coefficient.',
        teluguMessage: 'ఉష్ణోగ్రత హెచ్చుతగ్గులు ($temp°C).',
        teluguRecommendation: 'మేత మొత్తాన్ని ఉష్ణోగ్రత ప్రకారం సర్దుబాటు చేయండి.',
      );
    } else {
      return WaterAlert(
        parameter: 'Temperature',
        value: temp,
        unit: '°C',
        severity: AlertSeverity.optimal,
        message: 'Optimal Temperature ($temp°C). Prime metabolic activity.',
        recommendation: 'Full scheduled bio-energetic feeding program.',
        teluguMessage: 'సరైన ఉష్ణోగ్రత ($temp°C).',
        teluguRecommendation: 'పూర్తి స్థాయి మేత కార్యక్రమాన్ని కొనసాగించండి.',
      );
    }
  }

  /// Calculates the overall aggregate severity for a set of alerts.
  AlertSeverity getOverallSeverity(List<WaterAlert> alerts) {
    if (alerts.any((a) => a.severity == AlertSeverity.urgent)) {
      return AlertSeverity.urgent;
    }
    if (alerts.any((a) => a.severity == AlertSeverity.watch)) {
      return AlertSeverity.watch;
    }
    return AlertSeverity.optimal;
  }
}
