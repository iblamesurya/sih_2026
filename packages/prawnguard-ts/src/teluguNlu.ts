/**
 * Parsed telemetry entity container returned by TeluguVoiceNlu.
 */
export interface ParsedTelemetry {
  pondIndex?: number;
  /** Alias for pondIndex for CLI compatibility. */
  pondNumber?: number;
  ph?: number;
  doLevel?: number;
  /** Alias for doLevel for CLI compatibility. */
  dissolvedOxygen?: number;
  salinity?: number;
  temperature?: number;
  ammonia?: number;
  alkalinity?: number;
  feedKg?: number;
  confidence: number;
  rawTranscript: string;
  isEmpty: boolean;
  hasAnyWaterParameter: boolean;
}

/**
 * Natural Language Understanding (NLU) Service for code-mixed Telugu, English, and transliterated speech.
 */
export class TeluguVoiceNlu {
  /**
   * Normalizes common spoken Telugu number words into digits.
   */
  static normalizeTeluguNumberWords(input: string): string {
    let s = input;
    const wordMap: [RegExp, string][] = [
      [/ఒకటిలో|ఒకటవ|ఒకటి|okati|okatava/gi, '1'],
      [/రెండులో|రెండవ|రెండో|రెండు|rendu|rendava/gi, '2'],
      [/మూడులో|మూడవ|మూడో|మూడు|moodu|mudu/gi, '3'],
      [/నాలుగులో|నాలుగవ|నాలుగో|నాలుగు|naalugu|nalugu/gi, '4'],
      [/ఐదులో|ఐదవ|ఐదో|ఐదు|aidu|ayidu/gi, '5'],
      [/ఆరులో|ఆరవ|ఆరు|aaru/gi, '6'],
      [/ఏడులో|ఏడవ|ఏడు|edu|yedu/gi, '7'],
      [/ఎనిమిదిలో|ఎనిమిదవ|ఎనిమిది|enimidi/gi, '8'],
      [/తొమ్మిదిలో|తొమ్మిదవ|తొమ్మిది|thommidi/gi, '9'],
      [/పదిలో|పదవ|పది|padi/gi, '10'],
      [/సున్నా|సున్న|sunna|\bzero\b/gi, '0'],
    ];

    for (const [pattern, digit] of wordMap) {
      s = s.replace(pattern, digit);
    }
    return s;
  }

  /**
   * Parses voice transcripts containing mixed English, Telugu script, and transliterated Telugu telemetry.
   */
  static parseVoiceInput(transcript: string): ParsedTelemetry {
    if (!transcript || transcript.trim().length === 0) {
      return {
        confidence: 0.0,
        rawTranscript: transcript || '',
        isEmpty: true,
        hasAnyWaterParameter: false,
      };
    }

    const normalized = this.normalizeTeluguNumberWords(transcript);
    const lower = normalized.toLowerCase();

    // 1. Pond Index
    let pondIndex: number | undefined;
    const pondPattern =
      /(?:pond|tank|చెరువు|పాండ్|ట్యాంక్|cheruvu|ceruvu)\s*[:=]?\s*(\d+)|(\d+)\s*(?:వ|va|vadi)?\s*(?:చెరువు|cheruvu|pond|tank)/i;
    const pondMatch = lower.match(pondPattern);
    if (pondMatch) {
      const matchedVal = pondMatch[1] || pondMatch[2];
      if (matchedVal) {
        pondIndex = parseInt(matchedVal, 10);
      }
    }

    // 2. Dissolved Oxygen (DO)
    let doLevel: number | undefined;
    const doPattern =
      /(?:\bdo\b|\bd\.o\.|\bdissolved\s+oxygen\b|ఆక్సిజన్|డివో|డి\.వో|oxygen|oxigen|aaksijan|aksijan)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)/i;
    const doMatch = lower.match(doPattern);
    if (doMatch && doMatch[1]) {
      doLevel = parseFloat(doMatch[1]);
    }

    // 3. pH Level
    let ph: number | undefined;
    const phPattern =
      /(?:\bph\b|\bp\.h\.\b|పీహెచ్|పిహెచ్|పీ\.హెచ్|పి\.హెచ్|పీ\s*హెచ్|పి\s*హెచ్|pihech)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)/i;
    const phMatch = lower.match(phPattern);
    if (phMatch && phMatch[1]) {
      ph = parseFloat(phMatch[1]);
    }

    // 4. Salinity
    let salinity: number | undefined;
    const salPattern =
      /(?:\bsalinity\b|\bsalt\b|ఉప్పుదనం|ఉప్పు\s*శాతం|ఉప్పు|లవణీయత|సెలైనిటీ|uppudanam|lavaneeyatha|saliniti|uppu)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)/i;
    const salMatch = lower.match(salPattern);
    if (salMatch && salMatch[1]) {
      salinity = parseFloat(salMatch[1]);
    }

    // 5. Temperature
    let temperature: number | undefined;
    const tempPattern =
      /(?:\btemp(?:erature)?\b|ఉష్ణోగ్రత|టెంపరేచర్|టెంప్|ushnogratha|ushnograta|temparature)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)/i;
    const tempMatch = lower.match(tempPattern);
    if (tempMatch && tempMatch[1]) {
      temperature = parseFloat(tempMatch[1]);
    }

    // 6. Ammonia (NH3)
    let ammonia: number | undefined;
    const nh3Pattern =
      /(?:\bammonia\b|\bnh3\b|\bnh-3\b|అమ్మోనియా|అమోనియా|amoniya|ammoniya)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)/i;
    const nh3Match = lower.match(nh3Pattern);
    if (nh3Match && nh3Match[1]) {
      ammonia = parseFloat(nh3Match[1]);
    }

    // 7. Alkalinity
    let alkalinity: number | undefined;
    const alkPattern =
      /(?:\balkalinity\b|ఆల్కలినిటీ|అల్కలినిటీ|క్షారత్వం|alkaliniti|ksharatvam)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)/i;
    const alkMatch = lower.match(alkPattern);
    if (alkMatch && alkMatch[1]) {
      alkalinity = parseFloat(alkMatch[1]);
    }

    // 8. Feed Quantity in kg
    let feedKg: number | undefined;
    const feedPattern =
      /(?:\bfeed\b|\bfeeding\b|మేత|ఫీడ్|ఆహారం|metha|meetha|meta)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)\s*(?:kg|kgs|కిలోలు|కిలో|కేజీలు|కేజీ|kilo|kilolu|keji|kejilu)?|([0-9]+(?:\.[0-9]+)?)\s*(?:kg|kgs|కిలోలు|కిలో|కేజీలు|కేజీ)\s*(?:feed|feeding|మేత|ఫీడ్|metha)/i;
    const feedMatch = lower.match(feedPattern);
    if (feedMatch) {
      const val = feedMatch[1] || feedMatch[2];
      if (val) {
        feedKg = parseFloat(val);
      }
    }

    let recognizedCount = 0;
    if (pondIndex !== undefined) recognizedCount++;
    if (ph !== undefined) recognizedCount++;
    if (doLevel !== undefined) recognizedCount++;
    if (salinity !== undefined) recognizedCount++;
    if (temperature !== undefined) recognizedCount++;
    if (ammonia !== undefined) recognizedCount++;
    if (alkalinity !== undefined) recognizedCount++;
    if (feedKg !== undefined) recognizedCount++;

    const confidence =
      recognizedCount > 0
        ? Math.min(Math.max(0.85 + recognizedCount * 0.03, 0.0), 0.99)
        : 0.0;

    const isEmpty = recognizedCount === 0;
    const hasAnyWaterParameter =
      ph !== undefined ||
      doLevel !== undefined ||
      salinity !== undefined ||
      temperature !== undefined ||
      ammonia !== undefined ||
      alkalinity !== undefined;

    return {
      pondIndex,
      pondNumber: pondIndex,
      ph,
      doLevel,
      dissolvedOxygen: doLevel,
      salinity,
      temperature,
      ammonia,
      alkalinity,
      feedKg,
      confidence: Math.round(confidence * 100) / 100,
      rawTranscript: transcript,
      isEmpty,
      hasAnyWaterParameter,
    };
  }
}

/**
 * Adapter for CLI and external service calls.
 */
export class TeluguNluParser {
  static parse(transcript: string): ParsedTelemetry {
    return TeluguVoiceNlu.parseVoiceInput(transcript);
  }
}
