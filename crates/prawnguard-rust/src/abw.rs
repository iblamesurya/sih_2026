use serde::{Deserialize, Serialize};

/// Comprehensive summary of an ABW camera or physical sampling event.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AbwSampleResult {
    /// Number of individual shrimp specimens measured.
    pub sampled_count: usize,
    /// Mean rostrum-to-telson body length in cm.
    pub mean_length_cm: f64,
    /// Average Body Weight (ABW) in grams derived from allometric formula.
    pub mean_abw_grams: f64,
    /// Commercial count per kilogram (1000 / ABW).
    pub count_per_kg: f64,
    /// Coefficient of variation (CV%) indicating size uniformity.
    pub cv_percent: f64,
    /// Uniformity category ("Excellent", "Good", "Moderate", "Poor").
    pub uniformity_grade: String,
    /// Days of Culture (DOC) during sampling.
    pub doc: i32,
    /// Industry benchmark target ABW for this DOC.
    pub benchmark_abw_grams: f64,
    /// Percentage deviation from benchmark (+% ahead, -% stunted).
    pub growth_deviation_percent: f64,
}

/// Allometric & Morphometric Shrimp ABW Engine for Litopenaeus vannamei.
pub struct AbwEngine;

/// Alias model providing direct length-to-weight and weight-to-count methods.
pub struct AllometricModel;

impl AllometricModel {
    pub fn length_to_weight(length_cm: f64) -> f64 {
        AbwEngine::calculate_weight_from_length_cm(length_cm)
    }

    pub fn weight_to_count(weight_grams: f64) -> u32 {
        AbwEngine::calculate_count_per_kg(weight_grams).round() as u32
    }
}

impl AbwEngine {
    /// Standard L. vannamei allometric length-to-weight formula:
    /// `W (g) = 0.0082 * L(cm)^3.04`
    pub fn calculate_weight_from_length_cm(length_cm: f64) -> f64 {
        let safe_l = length_cm.clamp(4.0, 22.0);
        let raw = 0.0082 * safe_l.powf(3.04);
        (raw * 100.0).round() / 100.0
    }

    /// Inverse allometric weight-to-length formula:
    /// `L (cm) = (W / 0.0082)^(1 / 3.04)`
    pub fn calculate_length_cm_from_weight(weight_grams: f64) -> f64 {
        let safe_w = weight_grams.clamp(1.0, 45.0);
        let raw_l = (safe_w / 0.0082).powf(1.0 / 3.04);
        let clamped = raw_l.clamp(6.0, 18.0);
        (clamped * 10.0).round() / 10.0
    }

    /// Commercial count per kg:
    /// `Count = 1000.0 / W (g)`
    pub fn calculate_count_per_kg(weight_grams: f64) -> f64 {
        if weight_grams <= 0.0 {
            return 0.0;
        }
        (1000.0 / weight_grams * 10.0).round() / 10.0
    }

    /// Interpolates industry benchmark target ABW (g) for a given DOC.
    pub fn benchmark_abw_for_doc(doc: i32) -> f64 {
        let d = doc.max(1) as f64;
        if d <= 30.0 {
            (3.5 * (d / 30.0) * 10.0).round() / 10.0
        } else if d <= 45.0 {
            let abw = 3.5 + ((d - 30.0) / 15.0) * (8.0 - 3.5);
            (abw * 10.0).round() / 10.0
        } else if d <= 60.0 {
            let abw = 8.0 + ((d - 45.0) / 15.0) * (14.5 - 8.0);
            (abw * 10.0).round() / 10.0
        } else if d <= 75.0 {
            let abw = 14.5 + ((d - 60.0) / 15.0) * (20.0 - 14.5);
            (abw * 10.0).round() / 10.0
        } else if d <= 90.0 {
            let abw = 20.0 + ((d - 75.0) / 15.0) * (26.0 - 20.0);
            (abw * 10.0).round() / 10.0
        } else {
            let excess = (d - 90.0).clamp(0.0, 30.0);
            let abw = 26.0 + (excess / 15.0) * 6.0;
            (abw * 10.0).round() / 10.0
        }
    }

    /// Evaluates uniformity classification from CV%:
    /// - CV < 8.0% -> "Excellent"
    /// - CV <= 12.0% -> "Good"
    /// - CV <= 18.0% -> "Moderate"
    /// - CV > 18.0% -> "Poor"
    pub fn uniformity_grade_from_cv(cv_percent: f64) -> String {
        if cv_percent < 8.0 {
            "Excellent (High Uniformity)".to_string()
        } else if cv_percent <= 12.0 {
            "Good (Normal Batch Uniformity)".to_string()
        } else if cv_percent <= 18.0 {
            "Moderate (Size Variation Detected)".to_string()
        } else {
            "Poor (High Disparity / Possible Stunting)".to_string()
        }
    }

    /// Analyzes an array of individual specimen length measurements (cm) taken from a check tray.
    pub fn analyze_sampling(lengths_cm: &[f64], doc: i32) -> AbwSampleResult {
        if lengths_cm.is_empty() {
            let benchmark = Self::benchmark_abw_for_doc(doc);
            let default_l = Self::calculate_length_cm_from_weight(benchmark);
            return AbwSampleResult {
                sampled_count: 0,
                mean_length_cm: default_l,
                mean_abw_grams: benchmark,
                count_per_kg: Self::calculate_count_per_kg(benchmark),
                cv_percent: 0.0,
                uniformity_grade: "No Samples".to_string(),
                doc,
                benchmark_abw_grams: benchmark,
                growth_deviation_percent: 0.0,
            };
        }

        let n = lengths_cm.len() as f64;
        let sum_len: f64 = lengths_cm.iter().sum();
        let mean_len = sum_len / n;

        // Convert individual lengths to weights
        let weights: Vec<f64> = lengths_cm
            .iter()
            .map(|&l| Self::calculate_weight_from_length_cm(l))
            .collect();

        let sum_w: f64 = weights.iter().sum();
        let mean_abw = sum_w / n;

        // Standard deviation of weight
        let variance: f64 = weights
            .iter()
            .map(|&w| (w - mean_abw).powi(2))
            .sum::<f64>()
            / n;
        let std_dev = variance.sqrt();
        let cv_pct = if mean_abw > 0.0 {
            (std_dev / mean_abw) * 100.0
        } else {
            0.0
        };

        let benchmark = Self::benchmark_abw_for_doc(doc);
        let growth_dev = if benchmark > 0.0 {
            ((mean_abw - benchmark) / benchmark) * 100.0
        } else {
            0.0
        };

        AbwSampleResult {
            sampled_count: lengths_cm.len(),
            mean_length_cm: (mean_len * 10.0).round() / 10.0,
            mean_abw_grams: (mean_abw * 100.0).round() / 100.0,
            count_per_kg: Self::calculate_count_per_kg(mean_abw),
            cv_percent: (cv_pct * 10.0).round() / 10.0,
            uniformity_grade: Self::uniformity_grade_from_cv(cv_pct),
            doc,
            benchmark_abw_grams: benchmark,
            growth_deviation_percent: (growth_dev * 10.0).round() / 10.0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_allometric_length_to_weight() {
        // At 12.6 cm: W = 0.0082 * 12.6^3.04 ≈ 18.28 g
        let w = AbwEngine::calculate_weight_from_length_cm(12.6);
        assert!(w > 17.5 && w < 19.0);

        // Inverse calculation: should match closely
        let l = AbwEngine::calculate_length_cm_from_weight(w);
        assert!((l - 12.6).abs() <= 0.2);
    }

    #[test]
    fn test_count_per_kg() {
        // At 20g -> 50 count
        assert_eq!(AbwEngine::calculate_count_per_kg(20.0), 50.0);
        // At 25g -> 40 count
        assert_eq!(AbwEngine::calculate_count_per_kg(25.0), 40.0);
        // At 33.3g -> 30 count
        assert_eq!(AbwEngine::calculate_count_per_kg(33.33), 30.0);
    }

    #[test]
    fn test_doc_benchmarks() {
        assert_eq!(AbwEngine::benchmark_abw_for_doc(30), 3.5);
        assert_eq!(AbwEngine::benchmark_abw_for_doc(45), 8.0);
        assert_eq!(AbwEngine::benchmark_abw_for_doc(60), 14.5);
        assert_eq!(AbwEngine::benchmark_abw_for_doc(75), 20.0);
        assert_eq!(AbwEngine::benchmark_abw_for_doc(90), 26.0);
    }

    #[test]
    fn test_sampling_analysis() {
        let samples = [12.4, 12.6, 12.5, 12.7, 12.6, 12.5, 12.8, 12.4];
        let result = AbwEngine::analyze_sampling(&samples, 60);

        assert_eq!(result.sampled_count, 8);
        assert!(result.mean_abw_grams > 16.0);
        assert!(result.cv_percent < 8.0);
        assert!(result.uniformity_grade.contains("Excellent"));
        assert_eq!(result.doc, 60);
        assert_eq!(result.benchmark_abw_grams, 14.5);
    }
}
