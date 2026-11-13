import test from 'node:test';
import assert from 'node:assert/strict';

import {
  FeedAiEngine,
  BioFeedEngine,
} from '../src/feedAi.ts';

import {
  AlertSystem,
  WaterQualityEngine,
} from '../src/alertSystem.ts';

import {
  TeluguVoiceNlu,
  TeluguNluParser,
} from '../src/teluguNlu.ts';

import {
  AbwEngine,
  AllometricModel,
} from '../src/abw.ts';

// ============================================================================
// Feed AI Engine Tests
// ============================================================================

test('FeedAiEngine: calculateBiomass calculates accurate live biomass and handles zero/negative inputs safely', () => {
  // 50 pcs/m², 1.0 ha (10,000 m²), 85% survival, 16.5g ABW
  // Total pcs: 500,000 * 0.85 = 425,000 shrimp
  // Biomass = 425,000 * 16.5 / 1000 = 7012.5 kg
  const biomass = FeedAiEngine.calculateBiomass(50, 1.0, 0.85, 16.5);
  assert.equal(biomass, 7012.5);

  assert.equal(FeedAiEngine.calculateBiomass(0, 1.0, 0.85, 16.5), 0.0);
  assert.equal(FeedAiEngine.calculateBiomass(50, -1.0, 0.85, 16.5), 0.0);
  assert.equal(FeedAiEngine.calculateBiomass(50, 1.0, 0, 16.5), 0.0);
  assert.equal(FeedAiEngine.calculateBiomass(50, 1.0, 0.85, -5), 0.0);
});

test('FeedAiEngine: calculateFeedingRate strictly clamps between 0.03 and 0.08', () => {
  assert.equal(FeedAiEngine.calculateFeedingRate(0), 0.08);
  assert.equal(FeedAiEngine.calculateFeedingRate(40), 0.06);
  assert.equal(FeedAiEngine.calculateFeedingRate(100), 0.03);
  assert.equal(FeedAiEngine.calculateFeedingRate(150), 0.03);
  assert.equal(FeedAiEngine.calculateFeedingRate(-10), 0.08);
});

test('FeedAiEngine: calculateBioEnergeticFeedingRate tapers down for large shrimp (>22g)', () => {
  const rateSmall = FeedAiEngine.calculateBioEnergeticFeedingRate(60, 18.0);
  assert.equal(rateSmall, FeedAiEngine.calculateFeedingRate(60));

  const rateLarge = FeedAiEngine.calculateBioEnergeticFeedingRate(90, 30.0);
  assert.ok(rateLarge <= 0.03);
  assert.ok(rateLarge >= 0.018);
});

test('FeedAiEngine: calculateTempFactor implements temperature metabolic curve', () => {
  assert.equal(FeedAiEngine.calculateTempFactor(22.0), 0.85);
  assert.equal(FeedAiEngine.calculateTempFactor(23.9), 0.85);
  assert.equal(FeedAiEngine.calculateTempFactor(24.0), 1.0);
  assert.equal(FeedAiEngine.calculateTempFactor(28.0), 1.0);
  assert.equal(FeedAiEngine.calculateTempFactor(32.0), 1.0);
  assert.equal(FeedAiEngine.calculateTempFactor(32.1), 0.9);
  assert.equal(FeedAiEngine.calculateTempFactor(35.0), 0.9);
});

test('FeedAiEngine: calculateTrayFactor strictly clamps to [0.80, 1.10]', () => {
  assert.equal(FeedAiEngine.calculateTrayFactor(), 1.0);
  assert.equal(FeedAiEngine.calculateTrayFactor(0.0), 1.0);
  assert.equal(FeedAiEngine.calculateTrayFactor(0.1), 1.1);
  assert.equal(FeedAiEngine.calculateTrayFactor(0.25), 1.1); // Clamped at 1.10
  assert.equal(FeedAiEngine.calculateTrayFactor(-0.15), 0.85);
  assert.equal(FeedAiEngine.calculateTrayFactor(-0.35), 0.8); // Clamped at 0.80
});

test('FeedAiEngine: calculateDailyFeed and BioFeedEngine diurnal 4-meal plan', () => {
  const plan = FeedAiEngine.calculateDailyFeed({
    density: 50,
    areaHa: 1.0,
    survivalRate: 0.85,
    abw: 16.5,
    doc: 60,
    temperature: 28.5,
    trayStatus: 'normal',
  });

  assert.equal(plan.biomassKg, 7012.5);
  assert.equal(plan.tempFactor, 1.0);
  assert.equal(plan.trayFactor, 1.0);
  assert.equal(plan.mealSchedule.length, 4);
  assert.equal(plan.mealSchedule[0].percentShare, 0.2);
  assert.equal(plan.mealSchedule[1].percentShare, 0.3);
  assert.equal(plan.mealSchedule[2].percentShare, 0.3);
  assert.equal(plan.mealSchedule[3].percentShare, 0.2);

  // BioFeedEngine adapter
  const ration = BioFeedEngine.calculateRation({
    doc: 60,
    biomassKg: 7012.5,
    temperatureC: 28.5,
    checkTrayStatus: 'normal',
  });
  assert.equal(ration.biomassKg, 7012.5);
  assert.equal(ration.mealSchedule.length, 4);
});

// ============================================================================
// Water Quality & Hypoxia Alert Engine Tests
// ============================================================================

test('AlertSystem: evaluatePh thresholds and severity categorization', () => {
  assert.equal(AlertSystem.evaluatePh(6.8).severity, 'urgent');
  assert.equal(AlertSystem.evaluatePh(7.2).severity, 'watch');
  assert.equal(AlertSystem.evaluatePh(7.8).severity, 'optimal');
  assert.equal(AlertSystem.evaluatePh(8.8).severity, 'watch');
  assert.equal(AlertSystem.evaluatePh(9.2).severity, 'urgent');
});

test('AlertSystem: evaluateDO thresholds and hypoxia sirens', () => {
  assert.equal(AlertSystem.evaluateDO(2.4).severity, 'urgent');
  assert.equal(AlertSystem.evaluateDO(3.6).severity, 'watch');
  assert.equal(AlertSystem.evaluateDO(5.2).severity, 'optimal');

  const alarms = AlertSystem.evaluateWaterLogForEmergency('p1', 'Pond 1', 2.5, 0.03);
  assert.equal(alarms.length, 1);
  assert.ok(alarms[0].title.includes('LETHAL HYPOXIA CRASH'));
  assert.ok(alarms[0].checklist.length > 0);
  assert.ok(alarms[0].teluguChecklist.length > 0);
});

test('AlertSystem: Emerson (1975) un-ionized ammonia dissociation calculation', () => {
  // At 29°C, pH 8.0, TAN 1.0 mg/L -> NH3 is ~0.06 - 0.08 mg/L
  const nh3 = AlertSystem.calculateUnIonizedNh3FromTan(1.0, 8.0, 29.0);
  assert.ok(nh3 > 0.04 && nh3 < 0.12);

  assert.equal(AlertSystem.calculateUnIonizedNh3FromTan(0, 8.0, 29.0), 0.0);
  assert.equal(AlertSystem.calculateUnIonizedNh3FromTan(-1, 8.0, 29.0), 0.0);
});

test('AlertSystem: forecastDawnDissolvedOxygen nocturnal crash forecasting', () => {
  // Without aerators: high biomass and temp crashes DO
  const { predictedDawnDo: noAirDo, severity: noAirSev } =
    AlertSystem.forecastDawnDissolvedOxygen(6.5, 30.0, 75, 6000.0, false);
  assert.ok(noAirDo < 3.5);
  assert.ok(noAirSev === 'urgent' || noAirSev === 'critical');

  // With aerators running: DO is sustained higher
  const { predictedDawnDo: withAirDo } =
    AlertSystem.forecastDawnDissolvedOxygen(6.5, 30.0, 75, 6000.0, true);
  assert.ok(withAirDo > noAirDo);
});

test('WaterQualityEngine: evaluate produces comprehensive evaluation report', () => {
  const evalReport = WaterQualityEngine.evaluate({
    ph: 8.2,
    dissolvedOxygen: 3.4,
    temperatureC: 29.0,
    salinityPpt: 15.0,
    ammoniaMgL: 0.08,
    alkalinityMgL: 125.0,
  });

  assert.ok(evalReport.severity.includes('WATCH') || evalReport.severity.includes('CAUTION'));
  assert.ok(evalReport.nocturnalForecast.includes('Predicted Dawn DO'));
});

// ============================================================================
// Telugu Voice NLU Regex Parser Tests
// ============================================================================

test('TeluguVoiceNlu: parses mixed Telugu script, English, and transliterations', () => {
  const t1 = 'చెరువు 2 లో pH 7.8, DO 5.2, feed 25 kg';
  const p1 = TeluguVoiceNlu.parseVoiceInput(t1);
  assert.equal(p1.pondIndex, 2);
  assert.equal(p1.pondNumber, 2);
  assert.equal(p1.ph, 7.8);
  assert.equal(p1.doLevel, 5.2);
  assert.equal(p1.dissolvedOxygen, 5.2);
  assert.equal(p1.feedKg, 25.0);
  assert.ok(p1.confidence >= 0.85);
  assert.equal(p1.isEmpty, false);
});

test('TeluguVoiceNlu: spoken Telugu number words are correctly normalized', () => {
  const t2 = 'చెరువు ఒకటిలో పీహెచ్ 7.9 ఉంది, ఆక్సిజన్ 4.8, అమ్మోనియా సున్నా, మేత 30 కేజీలు';
  const p2 = TeluguVoiceNlu.parseVoiceInput(t2);
  assert.equal(p2.pondIndex, 1);
  assert.equal(p2.ph, 7.9);
  assert.equal(p2.doLevel, 4.8);
  assert.equal(p2.ammonia, 0.0);
  assert.equal(p2.feedKg, 30.0);
});

test('TeluguVoiceNlu: transliterated Telugu phrases are recognized', () => {
  const t3 = 'cheruvu 3 lo salinity 15 ppt ammonia 0.04 temp 29';
  const p3 = TeluguNluParser.parse(t3);
  assert.equal(p3.pondIndex, 3);
  assert.equal(p3.salinity, 15.0);
  assert.equal(p3.ammonia, 0.04);
  assert.equal(p3.temperature, 29.0);
});

test('TeluguVoiceNlu: empty or conversational transcripts return empty telemetry safely', () => {
  const empty = TeluguVoiceNlu.parseVoiceInput('');
  assert.equal(empty.isEmpty, true);
  assert.equal(empty.confidence, 0.0);

  const nonTelemetry = TeluguVoiceNlu.parseVoiceInput('బాగున్నారా అండి ఈరోజు వాతావరణం ఎలా ఉంది');
  assert.equal(nonTelemetry.isEmpty, true);
  assert.equal(nonTelemetry.confidence, 0.0);
});

// ============================================================================
// Morphometric Allometric ABW Sampling Tests
// ============================================================================

test('AbwEngine: allometric length-to-weight and inverse formulas', () => {
  // At 12.6 cm: W = 0.0082 * 12.6^3.04 ≈ 18.28 g
  const w = AbwEngine.calculateWeightFromLengthCm(12.6);
  assert.ok(w > 17.5 && w < 19.0);

  // Inverse formula returns original length
  const l = AbwEngine.calculateLengthCmFromWeight(w);
  assert.ok(Math.abs(l - 12.6) <= 0.2);

  // AllometricModel adapter
  assert.equal(AllometricModel.lengthToWeight(12.6), w);
});

test('AbwEngine: calculateCountPerKg and AllometricModel.weightToCount', () => {
  assert.equal(AbwEngine.calculateCountPerKg(20.0), 50.0);
  assert.equal(AbwEngine.calculateCountPerKg(25.0), 40.0);
  assert.equal(AbwEngine.calculateCountPerKg(33.33), 30.0);

  assert.equal(AllometricModel.weightToCount(20.0), 50);
});

test('AbwEngine: benchmarkAbwForDoc returns standard industry benchmarks', () => {
  assert.equal(AbwEngine.benchmarkAbwForDoc(30), 3.5);
  assert.equal(AbwEngine.benchmarkAbwForDoc(45), 8.0);
  assert.equal(AbwEngine.benchmarkAbwForDoc(60), 14.5);
  assert.equal(AbwEngine.benchmarkAbwForDoc(75), 20.0);
  assert.equal(AbwEngine.benchmarkAbwForDoc(90), 26.0);
});

test('AbwEngine: analyzeSampling calculates mean ABW, CV%, and uniformity grade', () => {
  const samples = [12.4, 12.6, 12.5, 12.7, 12.6, 12.5, 12.8, 12.4];
  const result = AbwEngine.analyzeSampling(samples, 60);

  assert.equal(result.sampledCount, 8);
  assert.ok(result.meanAbwGrams > 16.0);
  assert.ok(result.cvPercent < 8.0);
  assert.ok(result.uniformityGrade.includes('Excellent'));
  assert.equal(result.doc, 60);
  assert.equal(result.benchmarkAbwGrams, 14.5);
});
