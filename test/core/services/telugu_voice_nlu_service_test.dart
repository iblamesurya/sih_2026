import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_guard/core/services/telugu_voice_nlu_service.dart';

void main() {
  group('TeluguVoiceNLUService — English & Transliterated Natural Phrases', () {
    const nluService = TeluguVoiceNLUService();

    test('extracts single pond index from English phrasing', () {
      final parsed = nluService.parseVoiceInput('Pond 2 lo telemetry log cheyyi');
      expect(parsed.pondIndex, 2);
      expect(parsed.isEmpty, isFalse);
    });

    test('extracts Dissolved Oxygen (DO) from English phrasing', () {
      final parsed = nluService.parseVoiceInput('DO 5.2 mg/l recorded');
      expect(parsed.doLevel, 5.2);
    });

    test('extracts pH level from English phrasing', () {
      final parsed = nluService.parseVoiceInput('morning pH 7.8 vachindi');
      expect(parsed.ph, 7.8);
    });

    test('extracts feed quantity in kg from English phrasing', () {
      final parsed = nluService.parseVoiceInput('evening feed 25 kg vesamu');
      expect(parsed.feedKg, 25.0);
    });

    test('extracts compound multi-parameter utterance in single English-Telugu sentence', () {
      final parsed = nluService.parseVoiceInput(
        'Pond 3 lo pH 8.1, DO 4.8, salinity 16, ammonia 0.04, feed 30 kg',
      );
      expect(parsed.pondIndex, 3);
      expect(parsed.ph, 8.1);
      expect(parsed.doLevel, 4.8);
      expect(parsed.salinity, 16.0);
      expect(parsed.ammonia, 0.04);
      expect(parsed.feedKg, 30.0);
      expect(parsed.confidence, greaterThan(0.90));
    });

    test('extracts temperature and salinity from transliterated Telugu phrases', () {
      final parsed = nluService.parseVoiceInput(
        'cheruvu 1 lo salinity 15 ppt, ushnogratha 29.5, amoniya 0.02',
      );
      expect(parsed.pondIndex, 1);
      expect(parsed.salinity, 15.0);
      expect(parsed.temperature, 29.5);
      expect(parsed.ammonia, 0.02);
    });

    test('extracts transliterated keywords: cheruvu, oxygen, metha', () {
      final parsed = nluService.parseVoiceInput(
        'cheruvu 4 lo oxygen 4.5, metha 35 kg vesamu',
      );
      expect(parsed.pondIndex, 4);
      expect(parsed.doLevel, 4.5);
      expect(parsed.feedKg, 35.0);
    });
  });

  group('TeluguVoiceNLUService — Native Telugu Script Phrases', () {
    const nluService = TeluguVoiceNLUService();

    test('extracts pond number and parameters from Telugu script (చెరువు 2 లో pH 7.5, DO 4.2)', () {
      final parsed = nluService.parseVoiceInput('చెరువు 2 లో pH 7.5, DO 4.2');
      expect(parsed.pondIndex, 2);
      expect(parsed.ph, 7.5);
      expect(parsed.doLevel, 4.2);
    });

    test('extracts Telugu script parameters (ఆక్సిజన్, పిహెచ్, ఉప్పుదనం, అమ్మోనియా)', () {
      final parsed = nluService.parseVoiceInput(
        'చెరువు 1 లో ఆక్సిజన్ 4.8, పిహెచ్ 7.9, ఉప్పుదనం 18, అమ్మోనియా 0.05',
      );
      expect(parsed.pondIndex, 1);
      expect(parsed.doLevel, 4.8);
      expect(parsed.ph, 7.9);
      expect(parsed.salinity, 18.0);
      expect(parsed.ammonia, 0.05);
    });

    test('extracts Telugu script feed quantity (మేత 30 కిలోలు / మేత 25 కేజీ)', () {
      final parsed1 = nluService.parseVoiceInput('3వ చెరువులో ఉదయం మేత 30 కిలోలు వేసాము');
      expect(parsed1.pondIndex, 3);
      expect(parsed1.feedKg, 30.0);

      final parsed2 = nluService.parseVoiceInput('చెరువు 5 లో మేత 25 కేజీ');
      expect(parsed2.pondIndex, 5);
      expect(parsed2.feedKg, 25.0);
    });

    test('extracts Telugu script temperature (ఉష్ణోగ్రత 28.5)', () {
      final parsed = nluService.parseVoiceInput('చెరువు 2 లో ఉష్ణోగ్రత 28.5 డిగ్రీలు ఉంది');
      expect(parsed.pondIndex, 2);
      expect(parsed.temperature, 28.5);
    });

    test('handles variations in Telugu script spacing (పి హెచ్, ఉప్పు శాతం, డివో)', () {
      final parsed = nluService.parseVoiceInput('పి హెచ్ 8.2 మరియు డివో 5.1, ఉప్పు శాతం 22');
      expect(parsed.ph, 8.2);
      expect(parsed.doLevel, 5.1);
      expect(parsed.salinity, 22.0);
    });
  });

  group('TeluguVoiceNLUService — Formatting Variations & Boundary Cases', () {
    const nluService = TeluguVoiceNLUService();

    test('handles irregular whitespace, colons, equal signs, and capitalization', () {
      final parsed = nluService.parseVoiceInput(
        '   POND   4   lo   ph   :   8.2   ,   DO   =  6.1  ',
      );
      expect(parsed.pondIndex, 4);
      expect(parsed.ph, 8.2);
      expect(parsed.doLevel, 6.1);
    });

    test('handles partial inputs gracefully with null for missing parameters', () {
      final onlyPond = nluService.parseVoiceInput('Pond 5 lo inspection');
      expect(onlyPond.pondIndex, 5);
      expect(onlyPond.ph, isNull);
      expect(onlyPond.doLevel, isNull);
      expect(onlyPond.salinity, isNull);
      expect(onlyPond.feedKg, isNull);

      final onlyFeed = nluService.parseVoiceInput('morning feed 40 kg given');
      expect(onlyFeed.pondIndex, isNull);
      expect(onlyFeed.feedKg, 40.0);

      final onlyDO = nluService.parseVoiceInput('DO 3.8');
      expect(onlyDO.doLevel, 3.8);
      expect(onlyDO.hasAnyWaterParameter, isTrue);
    });

    test('handles empty and whitespace-only inputs returning empty telemetry', () {
      final empty = nluService.parseVoiceInput('');
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);

      final whitespace = nluService.parseVoiceInput('    \t\n  ');
      expect(whitespace.isEmpty, isTrue);
    });

    test('returns empty telemetry for non-telemetry random speech', () {
      final chat = nluService.parseVoiceInput('namaskaram ela unnaru memu bagunnamu');
      expect(chat.isEmpty, isTrue);
      expect(chat.confidence, 0.0);
    });

    test('serializes ParsedTelemetry to JSON correctly', () {
      final parsed = nluService.parseVoiceInput('Pond 2 lo pH 7.8, DO 5.2, feed 25 kg');
      final json = parsed.toJson();

      expect(json['pondIndex'], 2);
      expect(json['ph'], 7.8);
      expect(json['doLevel'], 5.2);
      expect(json['feedKg'], 25.0);
      expect(json['rawTranscript'], contains('Pond 2'));
      expect(json['isEmpty'], isFalse);
    });
  });
}
