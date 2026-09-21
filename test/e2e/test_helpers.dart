import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prawn_guard/core/services/base_repository.dart';
import 'package:prawn_guard/core/services/subscription_service.dart';

/// Test fixture generator and helper simulators for PrawnGuard E2E test suites.

// ---------------------------------------------------------------------------
// 1. SharedPreferences Test Harness
// ---------------------------------------------------------------------------

/// Sets up an isolated, clean mock SharedPreferences instance.
Future<SharedPreferences> setupMockPreferences([
  Map<String, Object> initialValues = const {},
]) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(initialValues));
  return SharedPreferences.getInstance();
}

// ---------------------------------------------------------------------------
// 2. Feed AI Bio-Energetics Engine Helper
// ---------------------------------------------------------------------------

class DailyFeedPlan {
  final double biomassKg;
  final double feedingRate;
  final double baseDailyFeedKg;
  final double tempFactor;
  final double trayFactor;
  final double adjustedDailyFeedKg;
  final double meal1Kg; // 06:00 AM (20%)
  final double meal2Kg; // 11:00 AM (30%)
  final double meal3Kg; // 04:00 PM (30%)
  final double meal4Kg; // 09:00 PM (20%)

  const DailyFeedPlan({
    required this.biomassKg,
    required this.feedingRate,
    required this.baseDailyFeedKg,
    required this.tempFactor,
    required this.trayFactor,
    required this.adjustedDailyFeedKg,
    required this.meal1Kg,
    required this.meal2Kg,
    required this.meal3Kg,
    required this.meal4Kg,
  });

  double get mealsTotal => meal1Kg + meal2Kg + meal3Kg + meal4Kg;

  Map<String, dynamic> toJson() => {
        'biomassKg': biomassKg,
        'feedingRate': feedingRate,
        'baseDailyFeedKg': baseDailyFeedKg,
        'tempFactor': tempFactor,
        'trayFactor': trayFactor,
        'adjustedDailyFeedKg': adjustedDailyFeedKg,
        'meal1Kg': meal1Kg,
        'meal2Kg': meal2Kg,
        'meal3Kg': meal3Kg,
        'meal4Kg': meal4Kg,
        'mealsTotal': mealsTotal,
      };
}

class FeedAIService {
  const FeedAIService();

  /// Calculates total live shrimp biomass in kg.
  ///
  /// Formula: (Density [pcs/m²] * Area [m²] * SurvivalRate * (ABW [g] / 1000))
  double calculateBiomass({
    required double density,
    required double areaHa,
    required double survivalRate,
    required double abw,
  }) {
    if (density <= 0 || areaHa <= 0 || survivalRate <= 0 || abw <= 0) {
      return 0.0;
    }
    final areaSqMeters = areaHa * 10000.0;
    final totalCount = density * areaSqMeters;
    final liveCount = totalCount * survivalRate.clamp(0.0, 1.0);
    return (liveCount * abw) / 1000.0;
  }

  /// Calculates DOC-dependent feeding rate clamped to [0.03, 0.08].
  ///
  /// Formula: clamp(0.08 - (DOC * 0.0005), 0.03, 0.08)
  double calculateFeedingRate(int doc) {
    if (doc < 0) doc = 0;
    final baseRate = 0.08 - (doc * 0.0005);
    return baseRate.clamp(0.03, 0.08);
  }

  /// Calculates temperature adjustment factor $F_T$.
  ///
  /// - T < 24.0°C -> 0.85
  /// - 24.0°C <= T <= 32.0°C -> 1.00
  /// - T > 32.0°C -> 0.90
  double calculateTempFactor(double temperature) {
    if (temperature < 24.0) {
      return 0.85;
    } else if (temperature <= 32.0) {
      return 1.00;
    } else {
      return 0.90;
    }
  }

  /// Calculates tray adjustment factor clamped to [0.80, 1.10].
  ///
  /// E.g. clean tray (-20%) -> 0.80, trace tray (+10%) -> 1.10
  double calculateTrayFactor(double? trayAdjustment) {
    if (trayAdjustment == null) return 1.00;
    return (1.0 + trayAdjustment).clamp(0.80, 1.10);
  }

  /// Comprehensive bio-energetic daily feed calculation with 4-meal distribution.
  DailyFeedPlan calculateDailyFeed({
    required double density,
    required double areaHa,
    required double survivalRate,
    required double abw,
    required int doc,
    required double temperature,
    double? trayAdjustment,
  }) {
    final biomass = calculateBiomass(
      density: density,
      areaHa: areaHa,
      survivalRate: survivalRate,
      abw: abw,
    );
    final feedingRate = calculateFeedingRate(doc);
    final baseFeed = biomass * feedingRate;
    final tempFactor = calculateTempFactor(temperature);
    final trayFactor = calculateTrayFactor(trayAdjustment);

    final adjustedDailyFeed = baseFeed * tempFactor * trayFactor;

    // 4-Meal Split: 20% (6 AM), 30% (11 AM), 30% (4 PM), 20% (9 PM)
    final meal1 = adjustedDailyFeed * 0.20;
    final meal2 = adjustedDailyFeed * 0.30;
    final meal3 = adjustedDailyFeed * 0.30;
    final meal4 = adjustedDailyFeed * 0.20;

    return DailyFeedPlan(
      biomassKg: biomass,
      feedingRate: feedingRate,
      baseDailyFeedKg: baseFeed,
      tempFactor: tempFactor,
      trayFactor: trayFactor,
      adjustedDailyFeedKg: adjustedDailyFeed,
      meal1Kg: meal1,
      meal2Kg: meal2,
      meal3Kg: meal3,
      meal4Kg: meal4,
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Telugu Voice NLU Regex Parser Helper
// ---------------------------------------------------------------------------

class ParsedTelemetry {
  final int? pondIndex;
  final double? ph;
  final double? doLevel;
  final double? salinity;
  final double? temperature;
  final double? ammonia;
  final double? feedKg;

  const ParsedTelemetry({
    this.pondIndex,
    this.ph,
    this.doLevel,
    this.salinity,
    this.temperature,
    this.ammonia,
    this.feedKg,
  });

  bool get isEmpty =>
      pondIndex == null &&
      ph == null &&
      doLevel == null &&
      salinity == null &&
      temperature == null &&
      ammonia == null &&
      feedKg == null;

  Map<String, dynamic> toJson() => {
        'pondIndex': pondIndex,
        'ph': ph,
        'doLevel': doLevel,
        'salinity': salinity,
        'temperature': temperature,
        'ammonia': ammonia,
        'feedKg': feedKg,
      };
}

class TeluguVoiceNLUService {
  const TeluguVoiceNLUService();

  /// Parses voice transcripts containing mixed English/Telugu telemetry.
  ParsedTelemetry parseVoiceInput(String transcript) {
    if (transcript.trim().isEmpty) {
      return const ParsedTelemetry();
    }

    final lower = transcript.toLowerCase();

    // 1. Pond Index
    int? pondIndex;
    final pondMatch = RegExp(r'(?:pond|చెరువు|cheruvu)\s*[:=]?\s*(\d+)').firstMatch(lower);
    if (pondMatch != null) {
      pondIndex = int.tryParse(pondMatch.group(1)!);
    }

    // 2. Dissolved Oxygen (DO)
    double? doLevel;
    final doMatch = RegExp(r'\bdo\s*[:=]?\s*([0-9]+\.?[0-9]*)').firstMatch(lower);
    if (doMatch != null) {
      doLevel = double.tryParse(doMatch.group(1)!);
    }

    // 3. pH Level
    double? ph;
    final phMatch = RegExp(r'\bph\s*[:=]?\s*([0-9]+\.?[0-9]*)').firstMatch(lower);
    if (phMatch != null) {
      ph = double.tryParse(phMatch.group(1)!);
    }

    // 4. Salinity
    double? salinity;
    final salMatch = RegExp(r'\bsalinity\s*[:=]?\s*([0-9]+\.?[0-9]*)').firstMatch(lower);
    if (salMatch != null) {
      salinity = double.tryParse(salMatch.group(1)!);
    }

    // 5. Temperature
    double? temperature;
    final tempMatch = RegExp(r'\btemp(?:erature)?\s*[:=]?\s*([0-9]+\.?[0-9]*)').firstMatch(lower);
    if (tempMatch != null) {
      temperature = double.tryParse(tempMatch.group(1)!);
    }

    // 6. Ammonia
    double? ammonia;
    final nh3Match = RegExp(r'\bammonia\s*[:=]?\s*([0-9]+\.?[0-9]*)').firstMatch(lower);
    if (nh3Match != null) {
      ammonia = double.tryParse(nh3Match.group(1)!);
    }

    // 7. Feed Quantity (kg)
    double? feedKg;
    final feedMatch = RegExp(r'\bfeed\s*[:=]?\s*([0-9]+\.?[0-9]*)\s*(?:kg|కిలోలు)?').firstMatch(lower);
    if (feedMatch != null) {
      feedKg = double.tryParse(feedMatch.group(1)!);
    }

    return ParsedTelemetry(
      pondIndex: pondIndex,
      ph: ph,
      doLevel: doLevel,
      salinity: salinity,
      temperature: temperature,
      ammonia: ammonia,
      feedKg: feedKg,
    );
  }
}

// ---------------------------------------------------------------------------
// 4. PrawnDoc AI Disease Vision Diagnostic Simulator
// ---------------------------------------------------------------------------

enum ShrimpDisease {
  wssv, // White Spot Syndrome Virus
  ehp, // Enterocytozoon hepatopenaei
  rms, // Running Mortality Syndrome
  ahpnd, // Acute Hepatopancreatic Necrosis Disease / EMS
  blackGill, // Black Gill Disease
  wfs, // White Faeces Syndrome
  lss, // Loose Shell Syndrome
  cottonShrimp, // Cotton Shrimp Disease
  imnv, // Infectious Myonecrosis
  vibrioLuminescence, // Vibrio Luminescence
  larvalMycosis, // Larval Mycosis
  healthy, // Healthy Shrimp
}

class DiagnosticResult {
  final ShrimpDisease disease;
  final String diseaseName;
  final double confidence;
  final String description;
  final String immediateAction;
  final String teluguSummary;

  const DiagnosticResult({
    required this.disease,
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.immediateAction,
    required this.teluguSummary,
  });
}

class PrawnDocAIService {
  final SubscriptionService _subscriptionService;

  const PrawnDocAIService([this._subscriptionService = const SubscriptionService()]);

  DiagnosticResult diagnose({
    required ShrimpDisease detectedDisease,
    required double confidence,
    required int currentScansToday,
    required bool isPro,
  }) {
    // Quota validation gate
    if (!_subscriptionService.canPerformScan(
      currentScansToday: currentScansToday,
      isPro: isPro,
    )) {
      throw StateError(
        'Scan quota exceeded for Free tier. Max 3 scans/day. Upgrade to Pro for unlimited diagnostics.',
      );
    }

    switch (detectedDisease) {
      case ShrimpDisease.wssv:
        return const DiagnosticResult(
          disease: ShrimpDisease.wssv,
          diseaseName: 'White Spot Syndrome Virus (WSSV)',
          confidence: 0.96,
          description: 'White calcified spots observed on carapace and rostrum.',
          immediateAction: 'Emergency harvest or isolate pond immediately. Cease feed.',
          teluguSummary: 'వైట్ స్పాట్ వైరస్ వ్యాధి గుర్తించబడింది. చెరువును వేరుచేయండి.',
        );
      case ShrimpDisease.ehp:
        return const DiagnosticResult(
          disease: ShrimpDisease.ehp,
          diseaseName: 'Enterocytozoon hepatopenaei (EHP)',
          confidence: 0.92,
          description: 'Severe growth retardation, microsporidian spores in hepatopancreas.',
          immediateAction: 'Apply gut probiotics and organic acids in feed.',
          teluguSummary: 'EHP ఎదుగుదల లేమి వ్యాధి. గట్ ప్రొబయోటిక్స్ వాడండి.',
        );
      case ShrimpDisease.vibrioLuminescence:
        return const DiagnosticResult(
          disease: ShrimpDisease.vibrioLuminescence,
          diseaseName: 'Vibrio Luminescent Disease',
          confidence: 0.94,
          description: 'Bioluminescent green glow observed in body tissues at night.',
          immediateAction: 'Perform 20% water exchange and apply competitive Bacillus probiotics.',
          teluguSummary: 'వైబ్రియో వ్యాధి. నీటిని మార్చి ప్రొబయోటిక్స్ వేయండి.',
        );
      default:
        return const DiagnosticResult(
          disease: ShrimpDisease.healthy,
          diseaseName: 'Healthy Specimen',
          confidence: 0.98,
          description: 'No pathogenic lesions, transparent carapace and full gut.',
          immediateAction: 'Maintain current feeding and water quality routine.',
          teluguSummary: 'రొయ్యలు ఆరోగ్యంగా ఉన్నాయి. ప్రస్తుత నిర్వహణను కొనసాగించండి.',
        );
    }
  }
}

// ---------------------------------------------------------------------------
// 5. Test Repository Implementation for BaseRepository Pairwise Testing
// ---------------------------------------------------------------------------

class TestWaterLogRepository extends BaseRepository {
  TestWaterLogRepository([super.offlineSyncService]);

  Future<Map<String, dynamic>?> submitWaterLog({
    required String pondId,
    required double ph,
    required double dissolvedOxygen,
    required double ammonia,
    required Future<Map<String, dynamic>> Function() networkCaller,
  }) async {
    final offlinePayload = {
      'table': 'water_logs',
      'action': 'insert',
      'payload': {
        'pond_id': pondId,
        'ph': ph,
        'dissolved_oxygen': dissolvedOxygen,
        'ammonia': ammonia,
        'logged_at': DateTime.now().toUtc().toIso8601String(),
      },
    };

    return await safeMutate<Map<String, dynamic>>(
      networkAction: networkCaller,
      offlineMutation: offlinePayload,
      fallbackValue: {
        'status': 'queued_offline',
        'pond_id': pondId,
        'ph': ph,
      },
    );
  }
}
