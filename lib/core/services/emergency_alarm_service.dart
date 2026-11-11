import 'package:flutter/services.dart';

/// Represents a critical life-safety aquaculture alarm (e.g. nocturnal DO crash
/// or toxic ammonia spike) requiring immediate farmer intervention and acknowledgment.
class EmergencyAlarm {
  final String id;
  final String pondId;
  final String pondName;
  final String parameter;
  final String measuredValue;
  final String title;
  final String teluguTitle;
  final List<String> checklist;
  final List<String> teluguChecklist;
  final DateTime triggeredAt;
  final bool acknowledged;

  const EmergencyAlarm({
    required this.id,
    required this.pondId,
    required this.pondName,
    required this.parameter,
    required this.measuredValue,
    required this.title,
    required this.teluguTitle,
    required this.checklist,
    required this.teluguChecklist,
    required this.triggeredAt,
    this.acknowledged = false,
  });

  EmergencyAlarm copyWith({bool? acknowledged}) {
    return EmergencyAlarm(
      id: id,
      pondId: pondId,
      pondName: pondName,
      parameter: parameter,
      measuredValue: measuredValue,
      title: title,
      teluguTitle: teluguTitle,
      checklist: checklist,
      teluguChecklist: teluguChecklist,
      triggeredAt: triggeredAt,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pondId': pondId,
        'pondName': pondName,
        'parameter': parameter,
        'measuredValue': measuredValue,
        'title': title,
        'teluguTitle': teluguTitle,
        'checklist': checklist,
        'teluguChecklist': teluguChecklist,
        'triggeredAt': triggeredAt.toIso8601String(),
        'acknowledged': acknowledged,
      };

  factory EmergencyAlarm.fromJson(Map<String, dynamic> json) => EmergencyAlarm(
        id: (json['id'] ?? '').toString(),
        pondId: (json['pondId'] ?? 'p1').toString(),
        pondName: (json['pondName'] ?? 'Pond 1').toString(),
        parameter: (json['parameter'] ?? 'Dissolved Oxygen').toString(),
        measuredValue: (json['measuredValue'] ?? '--').toString(),
        title: (json['title'] ?? 'Critical Water Emergency').toString(),
        teluguTitle: (json['teluguTitle'] ?? 'అత్యవసర చెరువు హెచ్చరిక').toString(),
        checklist: List<String>.from(json['checklist'] as List? ?? const []),
        teluguChecklist:
            List<String>.from(json['teluguChecklist'] as List? ?? const []),
        triggeredAt: DateTime.tryParse((json['triggeredAt'] ?? '').toString()) ??
            DateTime.now(),
        acknowledged: json['acknowledged'] == true,
      );
}

/// Service that monitors water telemetry and weather hypoxia forecasts to
/// trigger audible/haptic life-safety alarms and actionable emergency checklists.
class EmergencyAlarmService {
  const EmergencyAlarmService();

  /// Evaluates a water telemetry log map and returns any critical [EmergencyAlarm]s.
  List<EmergencyAlarm> evaluateWaterLog(
    Map<String, dynamic> log, {
    bool triggerSoundAndHaptics = true,
  }) {
    final alarms = <EmergencyAlarm>[];
    final pondId = (log['pondId'] ?? log['pond_id'] ?? 'p1').toString();
    final pondName = (log['pondName'] ?? log['pond_name'] ?? 'Pond $pondId').toString();
    final now = DateTime.tryParse(
          (log['timestamp'] ?? log['logged_at'] ?? '').toString(),
        ) ??
        DateTime.now();

    final doVal = (log['dissolvedOxygen'] ?? log['dissolved_oxygen'] ?? log['do']) as num?;
    final ammoniaVal = (log['ammonia'] ?? log['tan']) as num?;
    final phVal = log['ph'] as num?;

    if (doVal != null && doVal.toDouble() < 3.5) {
      final isLethal = doVal.toDouble() < 2.8;
      alarms.add(
        EmergencyAlarm(
          id: 'alarm_do_${pondId}_${now.millisecondsSinceEpoch}',
          pondId: pondId,
          pondName: pondName,
          parameter: 'Dissolved Oxygen',
          measuredValue: '${doVal.toStringAsFixed(1)} mg/L',
          title: isLethal
              ? 'LETHAL HYPOXIA CRASH in $pondName (${doVal.toStringAsFixed(1)} mg/L)'
              : 'Critical Low Dissolved Oxygen in $pondName (${doVal.toStringAsFixed(1)} mg/L)',
          teluguTitle: isLethal
              ? '$pondName లో ప్రాణాంతక ఆక్సిజన్ పతనం (${doVal.toStringAsFixed(1)} mg/L)'
              : '$pondName లో ఆక్సిజన్ ప్రమాదకర స్థాయికి పడిపోయింది (${doVal.toStringAsFixed(1)} mg/L)',
          checklist: const [
            'Turn ON all paddlewheel and spiral aerators at 100% capacity immediately.',
            'Broadcast Sodium Percarbonate (Oxygen tablets/granules) @ 2–3 kg/acre.',
            'HALT all feeding meals immediately until DO stabilizes above 4.5 mg/L.',
            'Start emergency borewell/reservoir water exchange (15–20%) if available.',
          ],
          teluguChecklist: const [
            'తక్షణమే అన్ని ఏరేటర్లను (Paddlewheel Aerators) పూర్తి స్థాయిలో ఆన్ చేయండి.',
            'ఎకరానికి 2–3 కిలోల ఆక్సిజన్ టాబ్లెట్లు/గ్రాన్యూల్స్ (Sodium Percarbonate) చల్లండి.',
            'DO 4.5 mg/L దాటే వరకు మేత వేయడం పూర్తిగా ఆపివేయండి.',
            'అందుబాటులో ఉంటే 15–20% కొత్త నీటిని చెరువులోకి పంపండి.',
          ],
          triggeredAt: now,
        ),
      );
    }

    if (ammoniaVal != null && ammoniaVal.toDouble() >= 0.1) {
      alarms.add(
        EmergencyAlarm(
          id: 'alarm_nh3_${pondId}_${now.millisecondsSinceEpoch}',
          pondId: pondId,
          pondName: pondName,
          parameter: 'Ammonia (TAN)',
          measuredValue: '${ammoniaVal.toStringAsFixed(2)} ppm',
          title:
              'Toxic Ammonia Spike in $pondName (${ammoniaVal.toStringAsFixed(2)} ppm)',
          teluguTitle:
              '$pondName లో ప్రమాదకర అమోనియా పెరుగుదల (${ammoniaVal.toStringAsFixed(2)} ppm)',
          checklist: const [
            'Apply Yucca schidigera extract or Zeolite @ 25–40 kg/acre immediately.',
            'Reduce next 2 feed rations by 30% to stop nitrogenous waste buildup.',
            'Add fermented molasses + Bacillus nitrifying probiotics with strong aeration.',
            'Exchange 15–20% bottom water to flush accumulated sludge.',
          ],
          teluguChecklist: const [
            'తక్షణమే ఎకరానికి 25–40 కిలోల జియోలైట్ (Zeolite) లేదా యుక్కా ద్రావణం వేయండి.',
            'తదుపరి 2 పూటల మేతను 30% తగ్గించండి.',
            'బెల్లం మరగబెట్టిన ప్రోబయోటిక్స్ (Bacillus) ఏరేషన్‌తో కలిపి చల్లండి.',
            'అడుగు మురికి నీటిని 15–20% బయటకు పంపండి.',
          ],
          triggeredAt: now,
        ),
      );
    }

    if (phVal != null && (phVal.toDouble() < 7.0 || phVal.toDouble() > 9.0)) {
      final isLow = phVal.toDouble() < 7.0;
      alarms.add(
        EmergencyAlarm(
          id: 'alarm_ph_${pondId}_${now.millisecondsSinceEpoch}',
          pondId: pondId,
          pondName: pondName,
          parameter: 'pH Breach',
          measuredValue: phVal.toStringAsFixed(1),
          title: isLow
              ? 'Severe Acidic pH Crash in $pondName (pH ${phVal.toStringAsFixed(1)})'
              : 'Severe Alkaline pH Spike in $pondName (pH ${phVal.toStringAsFixed(1)})',
          teluguTitle: isLow
              ? '$pondName లో pH తీవ్రంగా పడిపోయింది (pH ${phVal.toStringAsFixed(1)})'
              : '$pondName లో pH ప్రమాదకర స్థాయికి పెరిగింది (pH ${phVal.toStringAsFixed(1)})',
          checklist: isLow
              ? const [
                  'Apply Agricultural Lime (CaCO3) @ 50–80 kg/acre in split doses.',
                  'Check total alkalinity and buffer above 120 ppm with Dolomite.',
                  'Maintain continuous aeration to degas dissolved CO2.',
                ]
              : const [
                  'Apply fermented organic carbon (jaggery/molasses @ 10 kg/acre).',
                  'Monitor un-ionized NH3 closely—high pH multiplies ammonia toxicity.',
                  'Exchange 10–15% water during afternoon peak.',
                ],
          teluguChecklist: isLow
              ? const [
                  'ఎకరానికి 50–80 కిలోల వ్యవసాయ సున్నం (Agricultural Lime) విడతల వారీగా వేయండి.',
                  'ఆల్కలినిటీ 120 ppm కంటే ఎక్కువగా ఉండేలా డోలమైట్ వాడండి.',
                  'నిరంతర ఏరేషన్ కొనసాగించండి.',
                ]
              : const [
                  'ఎకరానికి 10 కిలోల బెల్లం/మొలాసిస్ ద్రావణం చల్లండి.',
                  'అధిక pH వల్ల అమోనియా విషతుల్యత పెరుగుతుంది కాబట్టి వెంటనే పరీక్షించండి.',
                  'మధ్యాహ్నం సమయంలో 10–15% నీటిని మార్చండి.',
                ],
          triggeredAt: now,
        ),
      );
    }

    if (alarms.isNotEmpty && triggerSoundAndHaptics) {
      triggerDeviceAlert();
    }

    return alarms;
  }

  /// Evaluates weather-driven nocturnal hypoxia risk and returns a preemptive alarm if high.
  EmergencyAlarm? evaluateHypoxiaForecast({
    required int riskScore,
    required String locationName,
    bool triggerSoundAndHaptics = false,
  }) {
    if (riskScore < 75) return null;

    if (triggerSoundAndHaptics) {
      triggerDeviceAlert();
    }

    return EmergencyAlarm(
      id: 'alarm_weather_hypoxia_${DateTime.now().millisecondsSinceEpoch}',
      pondId: 'all',
      pondName: locationName,
      parameter: 'Nocturnal Hypoxia Risk',
      measuredValue: '$riskScore% Risk Index',
      title: 'Pre-Dawn Nocturnal Hypoxia Warning ($riskScore% Risk)',
      teluguTitle: 'తెల్లవారుజామున ఆక్సిజన్ తగ్గే ప్రమాదం ($riskScore% రిస్క్)',
      checklist: const [
        'Schedule all backup aerators to run continuously from 11:00 PM to 6:00 AM.',
        'Verify diesel generator fuel and auto-changeover switch before nightfall.',
        'Reduce evening 8:00 PM feed ration by 15% to lower biological oxygen demand.',
        'Keep emergency Sodium Percarbonate bags staged on the pond dyke.',
      ],
      teluguChecklist: const [
        'రాత్రి 11:00 నుండి ఉదయం 6:00 వరకు అన్ని అదనపు ఏరేటర్లను ఆన్ చేసి ఉంచండి.',
        'డీజిల్ జనరేటర్ మరియు ఆటో-ఛేంజ్ ఓవర్ స్విచ్ పనితీరును ముందే తనిఖీ చేయండి.',
        'రాత్రి 8:00 గంటల మేతను 15% తగ్గించండి.',
        'అత్యవసర ఆక్సిజన్ గ్రాన్యూల్స్ చెరువు గట్టుపై సిద్ధంగా ఉంచండి.',
      ],
      triggeredAt: DateTime.now(),
    );
  }

  /// Plays system alert sound and heavy haptic feedback safely.
  void triggerDeviceAlert() {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {
      // Safe no-op in headless widget tests or unsupported platforms
    }
  }
}
