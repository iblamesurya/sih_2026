import 'package:flutter/foundation.dart';

/// Parsed telemetry entity container returned by [TeluguVoiceNLUService].
@immutable
class ParsedTelemetry {
  /// 1-based index/number of the target pond (e.g. 1, 2, 3).
  final int? pondIndex;

  /// Water pH level (optimal 7.5 - 8.5).
  final double? ph;

  /// Dissolved Oxygen in mg/L (optimal > 4.0 mg/L).
  final double? doLevel;

  /// Salinity in ppt (optimal 10 - 25 ppt).
  final double? salinity;

  /// Water temperature in °C (optimal 26 - 32 °C).
  final double? temperature;

  /// Total Ammonia Nitrogen (TAN / NH3) in mg/L (optimal < 0.1 mg/L).
  final double? ammonia;

  /// Feed quantity in kilograms.
  final double? feedKg;

  /// Confidence score of the extraction (0.0 - 1.0).
  final double confidence;

  /// Raw voice transcript that was parsed.
  final String rawTranscript;

  const ParsedTelemetry({
    this.pondIndex,
    this.ph,
    this.doLevel,
    this.salinity,
    this.temperature,
    this.ammonia,
    this.feedKg,
    this.confidence = 1.0,
    this.rawTranscript = '',
  });

  /// True if no telemetry parameters or pond index were identified.
  bool get isEmpty =>
      pondIndex == null &&
      ph == null &&
      doLevel == null &&
      salinity == null &&
      temperature == null &&
      ammonia == null &&
      feedKg == null;

  /// True if at least one parameter or entity was identified.
  bool get isNotEmpty => !isEmpty;

  /// True if at least one water chemical/physical parameter was extracted.
  bool get hasAnyWaterParameter =>
      ph != null ||
      doLevel != null ||
      salinity != null ||
      temperature != null ||
      ammonia != null;

  Map<String, dynamic> toJson() => {
        'pondIndex': pondIndex,
        'ph': ph,
        'doLevel': doLevel,
        'salinity': salinity,
        'temperature': temperature,
        'ammonia': ammonia,
        'feedKg': feedKg,
        'confidence': confidence,
        'rawTranscript': rawTranscript,
        'isEmpty': isEmpty,
      };

  @override
  String toString() =>
      'ParsedTelemetry(Pond: $pondIndex, pH: $ph, DO: $doLevel, Salinity: $salinity, Temp: $temperature, NH3: $ammonia, Feed: $feedKg kg)';
}

/// Natural Language Understanding (NLU) Service for code-mixed Telugu, English, and transliterated speech.
///
/// Designed to parse on-device voice transcripts from farmers in coastal Andhra Pradesh,
/// extracting structured aquaculture parameters (pond number, DO, pH, salinity, temperature, ammonia, feed quantity).
class TeluguVoiceNLUService {
  const TeluguVoiceNLUService();

  /// Parses voice transcripts containing mixed English, Telugu script, and transliterated Telugu telemetry.
  ///
  /// Examples:
  /// - "Pond 2 lo pH 7.8, DO 5.2, feed 25 kg" -> `{pond: 2, ph: 7.8, do: 5.2, feed: 25.0}`
  /// - "చెరువు 2 లో pH 7.5, DO 4.2" -> `{pond: 2, ph: 7.5, do: 4.2}`
  /// - "pond 1 lo salinity 15 ppt ammonia 0.04" -> `{pond: 1, salinity: 15.0, ammonia: 0.04}`
  /// - "ఉదయం 3వ చెరువులో మేత 35 కిలోలు వేసాము" -> `{pond: 3, feed: 35.0}`
  /// - "morning pH 7.8 vachindi, DO 5.2 mg/l recorded" -> `{ph: 7.8, do: 5.2}`
  ParsedTelemetry parseVoiceInput(String transcript) {
    if (transcript.trim().isEmpty) {
      return const ParsedTelemetry();
    }

    final lower = transcript.toLowerCase();

    // 1. Pond Index extraction
    // English: "pond 2", "tank 1"
    // Telugu script: "చెరువు 2", "పాండ్ 2", "2వ చెరువు", "2 వ చెరువు"
    // Transliterated: "cheruvu 2", "ceruvu 2", "2 va cheruvu"
    int? pondIndex;
    final pondPattern = RegExp(
      r'(?:pond|tank|చెరువు|పాండ్|ట్యాంక్|cheruvu|ceruvu)\s*[:=]?\s*(\d+)|(\d+)\s*(?:వ|va|vadi)?\s*(?:చెరువు|cheruvu|pond|tank)',
      caseSensitive: false,
    );
    final pondMatch = pondPattern.firstMatch(lower);
    if (pondMatch != null) {
      final matchedVal = pondMatch.group(1) ?? pondMatch.group(2);
      if (matchedVal != null) {
        pondIndex = int.tryParse(matchedVal);
      }
    }

    // 2. Dissolved Oxygen (DO) extraction
    // English: "do 5.2", "do = 6.1", "dissolved oxygen 4.8", "d.o. 5"
    // Telugu script: "ఆక్సిజన్ 4.5", "డివో 5.2", "డి.వో 5.0"
    // Transliterated: "oxygen 5.2", "oxigen 4.8", "aaksijan 5", "aksijan 4.2"
    double? doLevel;
    final doPattern = RegExp(
      r'(?:\bdo\b|\bd\.o\.|\bdissolved\s+oxygen\b|ఆక్సిజన్|డివో|డి\.వో|oxygen|oxigen|aaksijan|aksijan)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final doMatch = doPattern.firstMatch(lower);
    if (doMatch != null) {
      doLevel = double.tryParse(doMatch.group(1)!);
    }

    // 3. pH Level extraction
    // English: "ph 7.8", "ph : 8.2", "p.h. 7.5"
    // Telugu script: "పిహెచ్ 7.5", "పి హెచ్ 8.2", "పి.హెచ్ 7.8"
    // Transliterated: "pihech 7.8", "pih 7.5"
    double? ph;
    final phPattern = RegExp(
      r'(?:\bph\b|\bp\.h\.\b|పిహెచ్|పి\.హెచ్|పి\s*హెచ్|pihech)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final phMatch = phPattern.firstMatch(lower);
    if (phMatch != null) {
      ph = double.tryParse(phMatch.group(1)!);
    }

    // 4. Salinity extraction
    // English: "salinity 15", "salinity 15 ppt", "salt 20"
    // Telugu script: "ఉప్పుదనం 15", "ఉప్పు శాతం 20", "సెలైనిటీ 18", "ఉప్పు 15"
    // Transliterated: "uppudanam 15", "saliniti 16", "uppu 15"
    double? salinity;
    final salPattern = RegExp(
      r'(?:\bsalinity\b|\bsalt\b|ఉప్పుదనం|ఉప్పు\s*శాతం|సెలైనిటీ|uppudanam|saliniti)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final salMatch = salPattern.firstMatch(lower);
    if (salMatch != null) {
      salinity = double.tryParse(salMatch.group(1)!);
    }

    // 5. Temperature extraction
    // English: "temp 29.5", "temperature 26.5"
    // Telugu script: "ఉష్ణోగ్రత 28.5", "టెంపరేచర్ 30", "టెంప్ 29"
    // Transliterated: "ushnogratha 29", "ushnograta 28", "temparature 30"
    double? temperature;
    final tempPattern = RegExp(
      r'(?:\btemp(?:erature)?\b|ఉష్ణోగ్రత|టెంపరేచర్|టెంప్|ushnogratha|ushnograta|temparature)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final tempMatch = tempPattern.firstMatch(lower);
    if (tempMatch != null) {
      temperature = double.tryParse(tempMatch.group(1)!);
    }

    // 6. Ammonia (NH3) extraction
    // English: "ammonia 0.2", "nh3 0.04", "nh-3 0.05"
    // Telugu script: "అమ్మోనియా 0.05", "అమోనియా 0.1"
    // Transliterated: "amoniya 0.08", "ammoniya 0.05"
    double? ammonia;
    final nh3Pattern = RegExp(
      r'(?:\bammonia\b|\bnh3\b|\bnh-3\b|అమ్మోనియా|అమోనియా|amoniya|ammoniya)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final nh3Match = nh3Pattern.firstMatch(lower);
    if (nh3Match != null) {
      ammonia = double.tryParse(nh3Match.group(1)!);
    }

    // 7. Feed Quantity in kg extraction
    // English: "feed 25 kg", "feed : 25", "morning feed 35 kg", "25 kg feed"
    // Telugu script: "మేత 25 కిలోలు", "మేత 25 kg", "ఫీడ్ 30 కేజీ", "ఆహారం 25 కిలోలు"
    // Transliterated: "metha 25 kg", "meetha 30 kg", "meta 25"
    double? feedKg;
    final feedPattern = RegExp(
      r'(?:\bfeed\b|\bfeeding\b|మేత|ఫీడ్|ఆహారం|metha|meetha|meta)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)\s*(?:kg|kgs|కిలోలు|కిలో|కేజీలు|కేజీ|kilo|kilolu|keji|kejilu)?|([0-9]+(?:\.[0-9]+)?)\s*(?:kg|kgs|కిలోలు|కిలో|కేజీలు|కేజీ)\s*(?:feed|feeding|మేత|ఫీడ్|metha)',
      caseSensitive: false,
    );
    final feedMatch = feedPattern.firstMatch(lower);
    if (feedMatch != null) {
      final val = feedMatch.group(1) ?? feedMatch.group(2);
      if (val != null) {
        feedKg = double.tryParse(val);
      }
    }

    // Compute extraction confidence based on recognized entities
    int recognizedCount = 0;
    if (pondIndex != null) recognizedCount++;
    if (ph != null) recognizedCount++;
    if (doLevel != null) recognizedCount++;
    if (salinity != null) recognizedCount++;
    if (temperature != null) recognizedCount++;
    if (ammonia != null) recognizedCount++;
    if (feedKg != null) recognizedCount++;

    final confidence = recognizedCount > 0 ? (0.85 + (recognizedCount * 0.03)).clamp(0.0, 0.99) : 0.0;

    return ParsedTelemetry(
      pondIndex: pondIndex,
      ph: ph,
      doLevel: doLevel,
      salinity: salinity,
      temperature: temperature,
      ammonia: ammonia,
      feedKg: feedKg,
      confidence: confidence,
      rawTranscript: transcript,
    );
  }
}
