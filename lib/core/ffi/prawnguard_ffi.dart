import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// Native typedefs matching crates/prawnguard-rust/src/ffi.rs
typedef _VersionNative = Pointer<Utf8> Function();
typedef _VersionDart = Pointer<Utf8> Function();

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

typedef _DiagnoseSymptomsNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _DiagnoseSymptomsDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef _GetMandiPriceNative = Double Function(Pointer<Utf8>, Uint32);
typedef _GetMandiPriceDart = double Function(Pointer<Utf8>, int);

typedef _EstimateHarvestNative = Pointer<Utf8> Function(Pointer<Utf8>, Double, Uint32);
typedef _EstimateHarvestDart = Pointer<Utf8> Function(Pointer<Utf8>, double, int);

typedef _VerifySecurityNative = Pointer<Utf8> Function();
typedef _VerifySecurityDart = Pointer<Utf8> Function();

typedef _CalculateFeedNative = Pointer<Utf8> Function(
  Double, Double, Double, Double, Uint32, Double, Double, Uint8, Uint8,
);
typedef _CalculateFeedDart = Pointer<Utf8> Function(
  double, double, double, double, int, double, double, int, int,
);

typedef _EvaluateWaterQualityNative = Pointer<Utf8> Function(
  Double, Double, Double, Double, Double, Double,
);
typedef _EvaluateWaterQualityDart = Pointer<Utf8> Function(
  double, double, double, double, double, double,
);

typedef _ParseTeluguVoiceNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _ParseTeluguVoiceDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef _AnalyzeAbwNative = Pointer<Utf8> Function(Pointer<Utf8>, Uint32);
typedef _AnalyzeAbwDart = Pointer<Utf8> Function(Pointer<Utf8>, int);

typedef _EvaluateCreditScoreNative = Pointer<Utf8> Function(
  Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Double,
);
typedef _EvaluateCreditScoreDart = Pointer<Utf8> Function(
  Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, double,
);

/// High-Performance C-ABI FFI Bridge connecting Flutter Dart to the native
/// Rust aquaculture engine (`crates/prawnguard-rust`).
class PrawnGuardFfi {
  static PrawnGuardFfi? _instance;
  static PrawnGuardFfi get instance => _instance ??= PrawnGuardFfi._init();

  DynamicLibrary? _dylib;
  bool _isAvailable = false;

  late final _VersionDart _version;
  late final _FreeStringDart _freeString;
  late final _DiagnoseSymptomsDart _diagnoseSymptoms;
  late final _GetMandiPriceDart _getMandiPrice;
  late final _EstimateHarvestDart _estimateHarvest;
  late final _VerifySecurityDart _verifySecurity;
  late final _CalculateFeedDart _calculateFeed;
  late final _EvaluateWaterQualityDart _evaluateWaterQuality;
  late final _ParseTeluguVoiceDart _parseTeluguVoice;
  late final _AnalyzeAbwDart _analyzeAbw;
  late final _EvaluateCreditScoreDart _evaluateCreditScore;

  PrawnGuardFfi._init() {
    _loadLibrary();
  }

  bool get isAvailable => _isAvailable;

  void _loadLibrary() {
    if (kIsWeb) {
      _isAvailable = false;
      return;
    }

    try {
      if (Platform.isWindows) {
        // Attempt executable directory first, falling back to debug/release target paths
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final directDll = '$exeDir/prawnguard_rust.dll';
        const releaseDll = 'crates/prawnguard-rust/target/release/prawnguard_rust.dll';
        const debugDll = 'crates/prawnguard-rust/target/debug/prawnguard_rust.dll';

        if (File(directDll).existsSync()) {
          _dylib = DynamicLibrary.open(directDll);
        } else if (File(releaseDll).existsSync()) {
          _dylib = DynamicLibrary.open(releaseDll);
        } else if (File(debugDll).existsSync()) {
          _dylib = DynamicLibrary.open(debugDll);
        } else {
          _dylib = DynamicLibrary.open('prawnguard_rust.dll');
        }
      } else if (Platform.isAndroid) {
        _dylib = DynamicLibrary.open('libprawnguard_rust.so');
      } else if (Platform.isIOS || Platform.isMacOS) {
        _dylib = DynamicLibrary.process();
      } else if (Platform.isLinux) {
        _dylib = DynamicLibrary.open('libprawnguard_rust.so');
      }

      if (_dylib != null) {
        _version = _dylib!.lookupFunction<_VersionNative, _VersionDart>('prawnguard_version');
        _freeString = _dylib!.lookupFunction<_FreeStringNative, _FreeStringDart>('prawnguard_free_string');
        _diagnoseSymptoms = _dylib!.lookupFunction<_DiagnoseSymptomsNative, _DiagnoseSymptomsDart>('prawnguard_diagnose_symptoms');
        _getMandiPrice = _dylib!.lookupFunction<_GetMandiPriceNative, _GetMandiPriceDart>('prawnguard_get_mandi_price');
        _estimateHarvest = _dylib!.lookupFunction<_EstimateHarvestNative, _EstimateHarvestDart>('prawnguard_estimate_harvest');
        _verifySecurity = _dylib!.lookupFunction<_VerifySecurityNative, _VerifySecurityDart>('prawnguard_verify_security');
        _calculateFeed = _dylib!.lookupFunction<_CalculateFeedNative, _CalculateFeedDart>('prawnguard_calculate_feed');
        _evaluateWaterQuality = _dylib!.lookupFunction<_EvaluateWaterQualityNative, _EvaluateWaterQualityDart>('prawnguard_evaluate_water_quality');
        _parseTeluguVoice = _dylib!.lookupFunction<_ParseTeluguVoiceNative, _ParseTeluguVoiceDart>('prawnguard_parse_telugu_voice');
        _analyzeAbw = _dylib!.lookupFunction<_AnalyzeAbwNative, _AnalyzeAbwDart>('prawnguard_analyze_abw');
        _evaluateCreditScore = _dylib!.lookupFunction<_EvaluateCreditScoreNative, _EvaluateCreditScoreDart>('prawnguard_evaluate_credit_score');

        _isAvailable = true;
      }
    } catch (e) {
      debugPrint('[PrawnGuardFfi] Native library loading skipped/failed: $e');
      _isAvailable = false;
    }
  }

  /// Converts a native Rust heap-allocated Utf8 pointer to a Dart String,
  /// safely frees the Rust pointer in a finally block to prevent memory leaks,
  /// and returns parsed JSON.
  Map<String, dynamic> _consumeRustString(Pointer<Utf8> ptr) {
    if (ptr == nullptr) return {};
    try {
      final str = ptr.toDartString();
      if (str.isEmpty) return {};
      final decoded = jsonDecode(str);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } finally {
      _freeString(ptr);
    }
  }

  /// Returns native engine semver.
  String? getVersion() {
    if (!_isAvailable) return null;
    final ptr = _version();
    if (ptr == nullptr) return null;
    return ptr.toDartString();
  }

  /// 1. Diagnose shrimp symptoms using 12 ICAR-CIBA pathologies.
  Map<String, dynamic>? diagnoseSymptoms(List<String> symptoms) {
    if (!_isAvailable) return null;
    final csv = symptoms.join(',').toNativeUtf8();
    try {
      final resPtr = _diagnoseSymptoms(csv);
      return _consumeRustString(resPtr);
    } finally {
      malloc.free(csv);
    }
  }

  /// 2. Get Mandi price for a given regional AP hub and count per kg.
  double? getMandiPrice(String hub, int countPerKg) {
    if (!_isAvailable) return null;
    final hubUtf8 = hub.toNativeUtf8();
    try {
      final price = _getMandiPrice(hubUtf8, countPerKg);
      return price >= 0 ? price : null;
    } finally {
      malloc.free(hubUtf8);
    }
  }

  /// 3. Estimate harvest realization and net revenue.
  Map<String, dynamic>? estimateHarvest(String hub, double biomassKg, int countPerKg) {
    if (!_isAvailable) return null;
    final hubUtf8 = hub.toNativeUtf8();
    try {
      final resPtr = _estimateHarvest(hubUtf8, biomassKg, countPerKg);
      return _consumeRustString(resPtr);
    } finally {
      malloc.free(hubUtf8);
    }
  }

  /// 4. Verify Counter-REA RASP number-theoretic invariants.
  Map<String, dynamic>? verifySecurity() {
    if (!_isAvailable) return null;
    final resPtr = _verifySecurity();
    return _consumeRustString(resPtr);
  }

  /// 5. Bio-energetic feed ration planning.
  Map<String, dynamic>? calculateFeed({
    required double stockingDensityPerM2,
    required double areaHa,
    required double survivalRate,
    required double currentAbwG,
    required int doc,
    required double waterTempC,
    double prevTrayLeftoverPct = 0.0,
    bool criticalWaterAlert = false,
    bool highAmmoniaAlert = false,
  }) {
    if (!_isAvailable) return null;
    final resPtr = _calculateFeed(
      stockingDensityPerM2,
      areaHa,
      survivalRate,
      currentAbwG,
      doc,
      waterTempC,
      prevTrayLeftoverPct,
      criticalWaterAlert ? 1 : 0,
      highAmmoniaAlert ? 1 : 0,
    );
    return _consumeRustString(resPtr);
  }

  /// 6. Water quality telemetry evaluation against ICAR-CIBA thresholds.
  Map<String, dynamic>? evaluateWaterQuality({
    required double ph,
    required double doMgL,
    required double salinityPpt,
    required double tempC,
    required double ammoniaTanMgL,
    required double alkalinityPpm,
  }) {
    if (!_isAvailable) return null;
    final resPtr = _evaluateWaterQuality(
      ph,
      doMgL,
      salinityPpt,
      tempC,
      ammoniaTanMgL,
      alkalinityPpm,
    );
    return _consumeRustString(resPtr);
  }

  /// 7. Parse natural Telugu voice telemetry.
  Map<String, dynamic>? parseTeluguVoice(String transcript) {
    if (!_isAvailable) return null;
    final transcriptUtf8 = transcript.toNativeUtf8();
    try {
      final resPtr = _parseTeluguVoice(transcriptUtf8);
      return _consumeRustString(resPtr);
    } finally {
      malloc.free(transcriptUtf8);
    }
  }

  /// 8. Morphometric ABW allometric sampling analysis.
  Map<String, dynamic>? analyzeAbw(List<double> lengthsCm, int doc) {
    if (!_isAvailable) return null;
    final jsonStr = jsonEncode(lengthsCm);
    final jsonUtf8 = jsonStr.toNativeUtf8();
    try {
      final resPtr = _analyzeAbw(jsonUtf8, doc);
      return _consumeRustString(resPtr);
    } finally {
      malloc.free(jsonUtf8);
    }
  }

  /// 9. 5-Pillar PrawnCredit risk underwriting evaluation.
  Map<String, dynamic>? evaluateCreditScore({
    List<Map<String, dynamic>> ponds = const [],
    List<Map<String, dynamic>> waterLogs = const [],
    List<Map<String, dynamic>> expenses = const [],
    List<Map<String, dynamic>> harvests = const [],
    double totalFeedKg = 0.0,
  }) {
    if (!_isAvailable) return null;
    final pUtf8 = jsonEncode(ponds).toNativeUtf8();
    final wUtf8 = jsonEncode(waterLogs).toNativeUtf8();
    final eUtf8 = jsonEncode(expenses).toNativeUtf8();
    final hUtf8 = jsonEncode(harvests).toNativeUtf8();

    try {
      final resPtr = _evaluateCreditScore(pUtf8, wUtf8, eUtf8, hUtf8, totalFeedKg);
      return _consumeRustString(resPtr);
    } finally {
      malloc.free(pUtf8);
      malloc.free(wUtf8);
      malloc.free(eUtf8);
      malloc.free(hUtf8);
    }
  }
}
