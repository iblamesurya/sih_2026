use regex::Regex;
use serde::{Deserialize, Serialize};

/// Parsed telemetry entity container returned by [TeluguVoiceNlu].
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ParsedTelemetry {
    pub pond_index: Option<i32>,
    /// Alias for pond_index for CLI compatibility.
    pub pond_number: Option<i32>,
    pub ph: Option<f64>,
    pub do_level: Option<f64>,
    /// Alias for do_level for CLI compatibility.
    pub dissolved_oxygen: Option<f64>,
    pub salinity: Option<f64>,
    pub temperature: Option<f64>,
    pub ammonia: Option<f64>,
    pub alkalinity: Option<f64>,
    pub feed_kg: Option<f64>,
    pub confidence: f64,
    pub raw_transcript: String,
}

impl ParsedTelemetry {
    pub fn empty(raw_transcript: String) -> Self {
        Self {
            pond_index: None,
            pond_number: None,
            ph: None,
            do_level: None,
            dissolved_oxygen: None,
            salinity: None,
            temperature: None,
            ammonia: None,
            alkalinity: None,
            feed_kg: None,
            confidence: 0.0,
            raw_transcript,
        }
    }

    pub fn is_empty(&self) -> bool {
        self.pond_index.is_none()
            && self.ph.is_none()
            && self.do_level.is_none()
            && self.salinity.is_none()
            && self.temperature.is_none()
            && self.ammonia.is_none()
            && self.alkalinity.is_none()
            && self.feed_kg.is_none()
    }

    pub fn is_not_empty(&self) -> bool {
        !self.is_empty()
    }

    pub fn has_any_water_parameter(&self) -> bool {
        self.ph.is_some()
            || self.do_level.is_some()
            || self.salinity.is_some()
            || self.temperature.is_some()
            || self.ammonia.is_some()
            || self.alkalinity.is_some()
    }
}

/// Natural Language Understanding (NLU) Service for code-mixed Telugu, English, and transliterated speech.
pub struct TeluguVoiceNlu;

impl TeluguVoiceNlu {
    /// Normalizes common spoken Telugu number words into digits.
    pub fn normalize_telugu_number_words(input: &str) -> String {
        let mut s = input.to_string();
        let replacements = [
            (r"(?i)ఒకటిలో|ఒకటవ|ఒకటి|okati|okatava", "1"),
            (r"(?i)రెండులో|రెండవ|రెండో|రెండు|rendu|rendava", "2"),
            (r"(?i)మూడులో|మూడవ|మూడో|మూడు|moodu|mudu", "3"),
            (r"(?i)నాలుగులో|నాలుగవ|నాలుగో|నాలుగు|naalugu|nalugu", "4"),
            (r"(?i)ఐదులో|ఐదవ|ఐదో|ఐదు|aidu|ayidu", "5"),
            (r"(?i)ఆరులో|ఆరవ|ఆరు|aaru", "6"),
            (r"(?i)ఏడులో|ఏడవ|ఏడు|edu|yedu", "7"),
            (r"(?i)ఎనిమిదిలో|ఎనిమిదవ|ఎనిమిది|enimidi", "8"),
            (r"(?i)తొమ్మిదిలో|తొమ్మిదవ|తొమ్మిది|thommidi", "9"),
            (r"(?i)పదిలో|పదవ|పది|padi", "10"),
            (r"(?i)సున్నా|సున్న|sunna|\bzero\b", "0"),
        ];

        for (pattern, digit) in replacements {
            if let Ok(re) = Regex::new(pattern) {
                s = re.replace_all(&s, digit).to_string();
            }
        }
        s
    }

    /// Parses voice transcripts containing mixed English, Telugu script, and transliterated Telugu telemetry.
    pub fn parse_voice_input(transcript: &str) -> ParsedTelemetry {
        if transcript.trim().is_empty() {
            return ParsedTelemetry::empty(transcript.to_string());
        }

        let normalized = Self::normalize_telugu_number_words(transcript);
        let lower = normalized.to_lowercase();

        // 1. Pond Index
        let mut pond_index = None;
        if let Ok(pond_re) = Regex::new(
            r"(?i)(?:pond|tank|చెరువు|పాండ్|ట్యాంక్|cheruvu|ceruvu)\s*[:=]?\s*(\d+)|(\d+)\s*(?:వ|va|vadi)?\s*(?:చెరువు|cheruvu|pond|tank)",
        ) {
            if let Some(caps) = pond_re.captures(&lower) {
                let val_str = caps.get(1).or_else(|| caps.get(2)).map(|m| m.as_str());
                if let Some(s) = val_str {
                    pond_index = s.parse::<i32>().ok();
                }
            }
        }

        // 2. Dissolved Oxygen (DO)
        let mut do_level = None;
        if let Ok(do_re) = Regex::new(
            r"(?i)(?:\bdo\b|\bd\.o\.|\bdissolved\s+oxygen\b|ఆక్సిజన్|డివో|డి\.వో|oxygen|oxigen|aaksijan|aksijan)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)",
        ) {
            if let Some(caps) = do_re.captures(&lower) {
                if let Some(m) = caps.get(1) {
                    do_level = m.as_str().parse::<f64>().ok();
                }
            }
        }

        // 3. pH Level
        let mut ph = None;
        if let Ok(ph_re) = Regex::new(
            r"(?i)(?:\bph\b|\bp\.h\.\b|పీహెచ్|పిహెచ్|పీ\.హెచ్|పి\.హెచ్|పీ\s*హెచ్|పి\s*హెచ్|pihech)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)",
        ) {
            if let Some(caps) = ph_re.captures(&lower) {
                if let Some(m) = caps.get(1) {
                    ph = m.as_str().parse::<f64>().ok();
                }
            }
        }

        // 4. Salinity
        let mut salinity = None;
        if let Ok(sal_re) = Regex::new(
            r"(?i)(?:\bsalinity\b|\bsalt\b|ఉప్పుదనం|ఉప్పు\s*శాతం|ఉప్పు|సెలైనిటీ|uppudanam|saliniti|uppu)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)",
        ) {
            if let Some(caps) = sal_re.captures(&lower) {
                if let Some(m) = caps.get(1) {
                    salinity = m.as_str().parse::<f64>().ok();
                }
            }
        }

        // 5. Temperature
        let mut temperature = None;
        if let Ok(temp_re) = Regex::new(
            r"(?i)(?:\btemp(?:erature)?\b|ఉష్ణోగ్రత|టెంపరేచర్|టెంప్|ushnogratha|ushnograta|temparature)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)",
        ) {
            if let Some(caps) = temp_re.captures(&lower) {
                if let Some(m) = caps.get(1) {
                    temperature = m.as_str().parse::<f64>().ok();
                }
            }
        }

        // 6. Ammonia (NH3)
        let mut ammonia = None;
        if let Ok(nh3_re) = Regex::new(
            r"(?i)(?:\bammonia\b|\bnh3\b|\bnh-3\b|అమ్మోనియా|అమోనియా|amoniya|ammoniya)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)",
        ) {
            if let Some(caps) = nh3_re.captures(&lower) {
                if let Some(m) = caps.get(1) {
                    ammonia = m.as_str().parse::<f64>().ok();
                }
            }
        }

        // 7. Alkalinity
        let mut alkalinity = None;
        if let Ok(alk_re) = Regex::new(
            r"(?i)(?:\balkalinity\b|ఆల్కలినిటీ|అల్కలినిటీ|క్షారత్వం|alkaliniti|ksharatvam)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)",
        ) {
            if let Some(caps) = alk_re.captures(&lower) {
                if let Some(m) = caps.get(1) {
                    alkalinity = m.as_str().parse::<f64>().ok();
                }
            }
        }

        // 8. Feed Quantity in kg
        let mut feed_kg = None;
        if let Ok(feed_re) = Regex::new(
            r"(?i)(?:\bfeed\b|\bfeeding\b|మేత|ఫీడ్|ఆహారం|metha|meetha|meta)\s*[:=]?\s*([0-9]+(?:\.[0-9]+)?)\s*(?:kg|kgs|కిలోలు|కిలో|కేజీలు|కేజీ|kilo|kilolu|keji|kejilu)?|([0-9]+(?:\.[0-9]+)?)\s*(?:kg|kgs|కిలోలు|కిలో|కేజీలు|కేజీ)\s*(?:feed|feeding|మేత|ఫీడ్|metha)",
        ) {
            if let Some(caps) = feed_re.captures(&lower) {
                let val_str = caps.get(1).or_else(|| caps.get(2)).map(|m| m.as_str());
                if let Some(s) = val_str {
                    feed_kg = s.parse::<f64>().ok();
                }
            }
        }

        // Recognized parameter count
        let mut recognized_count = 0;
        if pond_index.is_some() { recognized_count += 1; }
        if ph.is_some() { recognized_count += 1; }
        if do_level.is_some() { recognized_count += 1; }
        if salinity.is_some() { recognized_count += 1; }
        if temperature.is_some() { recognized_count += 1; }
        if ammonia.is_some() { recognized_count += 1; }
        if alkalinity.is_some() { recognized_count += 1; }
        if feed_kg.is_some() { recognized_count += 1; }

        let confidence = if recognized_count > 0 {
            (0.85 + (recognized_count as f64 * 0.03)).clamp(0.0, 0.99)
        } else {
            0.0
        };

        ParsedTelemetry {
            pond_index,
            pond_number: pond_index,
            ph,
            do_level,
            dissolved_oxygen: do_level,
            salinity,
            temperature,
            ammonia,
            alkalinity,
            feed_kg,
            confidence,
            raw_transcript: transcript.to_string(),
        }
    }
}

/// NLU parser adapter for CLI and service integration.
pub struct TeluguNluParser;

impl TeluguNluParser {
    pub fn parse(transcript: &str) -> ParsedTelemetry {
        TeluguVoiceNlu::parse_voice_input(transcript)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mixed_telugu_english_telemetry_extraction() {
        // "చెరువు 2 లో pH 7.8, DO 5.2, feed 25 kg"
        let t1 = "చెరువు 2 లో pH 7.8, DO 5.2, feed 25 kg";
        let p1 = TeluguVoiceNlu::parse_voice_input(t1);
        assert_eq!(p1.pond_index, Some(2));
        assert_eq!(p1.ph, Some(7.8));
        assert_eq!(p1.do_level, Some(5.2));
        assert_eq!(p1.feed_kg, Some(25.0));
        assert!(p1.confidence >= 0.85);
    }

    #[test]
    fn test_spoken_telugu_number_words() {
        // "చెరువు ఒకటిలో పీహెచ్ 7.9 ఉంది, ఆక్సిజన్ 4.8, అమ్మోనియా సున్నా, మేత 30 కేజీలు"
        let t2 = "చెరువు ఒకటిలో పీహెచ్ 7.9 ఉంది, ఆక్సిజన్ 4.8, అమ్మోనియా సున్నా, మేత 30 కేజీలు";
        let p2 = TeluguVoiceNlu::parse_voice_input(t2);
        assert_eq!(p2.pond_index, Some(1));
        assert_eq!(p2.ph, Some(7.9));
        assert_eq!(p2.do_level, Some(4.8));
        assert_eq!(p2.ammonia, Some(0.0));
        assert_eq!(p2.feed_kg, Some(30.0));
    }

    #[test]
    fn test_transliterated_telugu_phrases() {
        let t3 = "cheruvu 3 lo salinity 15 ppt ammonia 0.04 temp 29";
        let p3 = TeluguVoiceNlu::parse_voice_input(t3);
        assert_eq!(p3.pond_index, Some(3));
        assert_eq!(p3.salinity, Some(15.0));
        assert_eq!(p3.ammonia, Some(0.04));
        assert_eq!(p3.temperature, Some(29.0));
    }

    #[test]
    fn test_empty_or_non_telemetry_conversation() {
        let empty = TeluguVoiceNlu::parse_voice_input("");
        assert!(empty.is_empty());
        assert_eq!(empty.confidence, 0.0);

        let non_telemetry = TeluguVoiceNlu::parse_voice_input("బాగున్నారా అండి ఈరోజు వాతావరణం ఎలా ఉంది");
        assert!(non_telemetry.is_empty());
        assert_eq!(non_telemetry.confidence, 0.0);
    }
}
