import test from 'node:test';
import assert from 'node:assert/strict';

import * as PrawnGuard from '../src/index.ts';

// ============================================================================
// Module Re-export (Barrel) Verification
// ============================================================================

test('index: all 10 core subsystems are cleanly exported from the root barrel', () => {
  // 1. Models
  assert.equal(typeof PrawnGuard.createPond, 'function');
  assert.equal(typeof PrawnGuard.calculatePondBiomass, 'function');

  // 2. Outbox
  assert.equal(typeof PrawnGuard.OfflineOutboxEngine, 'function');

  // 3. Finance
  assert.equal(typeof PrawnGuard.PrawnCreditEngine, 'function');
  assert.equal(typeof PrawnGuard.computeFcr, 'function');

  // 4. Feed AI
  assert.equal(typeof PrawnGuard.FeedAiEngine, 'function');
  assert.equal(typeof PrawnGuard.BioFeedEngine, 'function');

  // 5. Alert System
  assert.equal(typeof PrawnGuard.AlertSystem, 'function');
  assert.equal(typeof PrawnGuard.WaterQualityEngine, 'function');

  // 6. Telugu NLU
  assert.equal(typeof PrawnGuard.TeluguVoiceNlu, 'function');
  assert.equal(typeof PrawnGuard.TeluguNluParser, 'function');

  // 7. ABW
  assert.equal(typeof PrawnGuard.AbwEngine, 'function');
  assert.equal(typeof PrawnGuard.AllometricModel, 'function');

  // 8. PrawnDoc
  assert.equal(typeof PrawnGuard.diagnoseSymptoms, 'function');
  assert.equal(typeof PrawnGuard.getDiseaseInfo, 'function');
  assert.equal(typeof PrawnGuard.getAllDiseases, 'function');

  // 9. Mandi
  assert.equal(typeof PrawnGuard.MandiAggregator, 'function');
  assert.ok(PrawnGuard.REGIONAL_HUBS);
  assert.ok(PrawnGuard.COUNT_GRADES);

  // 10. Security
  assert.equal(typeof PrawnGuard.AntiReverseEngineering, 'function');
  assert.ok(PrawnGuard.DECOY_ADMIN_TOKEN);
});

// ============================================================================
// PrawnDoc AI Disease Pathology Tests
// ============================================================================

test('PrawnDoc: getAllDiseases returns complete ICAR-CIBA catalog with Telugu translations', () => {
  const diseases = PrawnGuard.getAllDiseases();
  assert.equal(diseases.length, 12);

  for (const info of diseases) {
    assert.ok(info.code.length > 0);
    assert.ok(info.name.length > 0);
    assert.ok(info.scientificName.length > 0);
    assert.ok(info.teluguName.length > 0);
    assert.ok(info.treatment.immediateActions.length > 0);
    assert.ok(info.treatment.teluguSummary.length > 0);
    assert.ok(info.treatment.teluguRecommendations.length > 0);
  }

  const wssv = PrawnGuard.getDiseaseInfo('wssv');
  assert.equal(wssv.code, 'WSSV');
  assert.equal(wssv.severity, 'critical');
  assert.equal(wssv.isEmergencyHarvest, true);
  assert.match(wssv.teluguName, /తెల్ల మచ్చల/);

  const healthy = PrawnGuard.getDiseaseInfo('healthy');
  assert.equal(healthy.code, 'HEALTHY');
  assert.equal(healthy.severity, 'none');
  assert.equal(healthy.isEmergencyHarvest, false);
});

test('PrawnDoc: diagnoseSymptoms correctly diagnoses WSSV with emergency harvest trigger', () => {
  const report = PrawnGuard.diagnoseSymptoms(
    ['white spots on carapace', 'lethargic surface swimming', 'rapid mortality'],
    65,
    3.2
  );

  assert.equal(report.diseaseCode, 'WSSV');
  assert.equal(report.isEmergencyHarvest, true);
  assert.equal(report.severity, 'critical');
  assert.ok(report.confidence >= 0.85);
  assert.ok(report.treatmentPlan.length > 0);
  assert.ok(report.teluguSummary.length > 0);
  assert.match(report.teluguAction, /నీటి మార్పిడిని వెంటనే నిలిపివేయండి/);
});

test('PrawnDoc: diagnoseSymptoms identifies Early Mortality Syndrome (AHPND)', () => {
  const report = PrawnGuard.diagnoseSymptoms(
    ['EMS outbreak', 'atrophied shrunken hepatopancreas', 'empty gut'],
    28,
    5.5
  );

  assert.equal(report.diseaseCode, 'AHPND');
  assert.equal(report.isEmergencyHarvest, false);
  assert.equal(report.severity, 'critical');
  assert.ok(report.confidence >= 0.85);
});

test('PrawnDoc: diagnoseSymptoms identifies EHP microsporidian stunting', () => {
  const report = PrawnGuard.diagnoseSymptoms(
    ['severe growth retardation', 'stunted growth with high FCR', 'size variation across check tray'],
    75
  );

  assert.equal(report.diseaseCode, 'EHP');
  assert.equal(report.severity, 'high');
  assert.equal(report.isEmergencyHarvest, false);
  assert.ok(report.confidence >= 0.80);
});

test('PrawnDoc: diagnoseSymptoms identifies White Feces Syndrome (WFS)', () => {
  const report = PrawnGuard.diagnoseSymptoms(
    ['white feces floating on pond surface', 'white fecal strings in feeding tray', 'drop in feed intake']
  );

  assert.equal(report.diseaseCode, 'WFS');
  assert.equal(report.severity, 'high');
  assert.ok(report.confidence >= 0.80);
});

test('PrawnDoc: diagnoseSymptoms identifies Black Gill and IMNV', () => {
  const bgReport = PrawnGuard.diagnoseSymptoms(
    ['black gill melanization', 'respiratory distress', 'aerator crowd']
  );
  assert.equal(bgReport.diseaseCode, 'BLACK_GILL');
  assert.equal(bgReport.severity, 'medium');

  const imnvReport = PrawnGuard.diagnoseSymptoms(
    ['cooked meat appearance in tail', 'myonecrosis opaque tail muscle', 'tail reddening']
  );
  assert.equal(imnvReport.diseaseCode, 'IMNV');
  assert.equal(imnvReport.severity, 'critical');
  assert.equal(imnvReport.isEmergencyHarvest, true);
});

test('PrawnDoc: diagnoseSymptoms identifies Luminescent Vibriosis, YHV, and Cotton Shrimp', () => {
  const vibrio = PrawnGuard.diagnoseSymptoms(['luminescent green glow in dark pond water', 'vibrio TCBS yellow green']);
  assert.equal(vibrio.diseaseCode, 'VIBRIOSIS');

  const yhv = PrawnGuard.diagnoseSymptoms(['yellowish cephalothorax', 'yellow head catastrophic death']);
  assert.equal(yhv.diseaseCode, 'YHV');
  assert.equal(yhv.isEmergencyHarvest, true);

  const cotton = PrawnGuard.diagnoseSymptoms(['cotton opaque white flesh', 'loss of elasticity rubbery muscle']);
  assert.equal(cotton.diseaseCode, 'COTTON_SHRIMP');
});

test('PrawnDoc: diagnoseSymptoms recognizes healthy state', () => {
  const report = PrawnGuard.diagnoseSymptoms(
    ['healthy active swimming', 'glassy transparent body', 'clean gills and full gut']
  );

  assert.equal(report.diseaseCode, 'HEALTHY');
  assert.equal(report.severity, 'none');
  assert.equal(report.isEmergencyHarvest, false);
  assert.ok(report.confidence >= 0.90);
});

// ============================================================================
// Mandi Price Aggregator & Revenue Realization Tests
// ============================================================================

test('MandiAggregator: resolveCountGrade accurately categorizes shrimp counts', () => {
  assert.equal(PrawnGuard.MandiAggregator.resolveCountGrade(18), 20);
  assert.equal(PrawnGuard.MandiAggregator.resolveCountGrade(25), 20);
  assert.equal(PrawnGuard.MandiAggregator.resolveCountGrade(30), 30);
  assert.equal(PrawnGuard.MandiAggregator.resolveCountGrade(35), 30);
  assert.equal(PrawnGuard.MandiAggregator.resolveCountGrade(40), 40);
  assert.equal(PrawnGuard.MandiAggregator.resolveCountGrade(52), 50);
  assert.equal(PrawnGuard.MandiAggregator.resolveCountGrade(65), 60);
  assert.equal(PrawnGuard.MandiAggregator.resolveCountGrade(85), 80);
  assert.equal(PrawnGuard.MandiAggregator.resolveCountGrade(110), 100);
});

test('MandiAggregator: resolveHubKey matches standard names and colloquial variants', () => {
  assert.equal(PrawnGuard.MandiAggregator.resolveHubKey('bhimavaram'), 'bhimavaram');
  assert.equal(PrawnGuard.MandiAggregator.resolveHubKey('Nellore Hub'), 'nellore');
  assert.equal(PrawnGuard.MandiAggregator.resolveHubKey('kaikaluru market'), 'kaikaluru');
  assert.equal(PrawnGuard.MandiAggregator.resolveHubKey('Kakinada Port'), 'kakinada');
  assert.equal(PrawnGuard.MandiAggregator.resolveHubKey('unknown location'), 'bhimavaram');
});

test('MandiAggregator: regional hub pricing incorporates regional differentials', () => {
  const bhimavaramPrice = PrawnGuard.MandiAggregator.getPrice('bhimavaram', 30);
  const nellorePrice = PrawnGuard.MandiAggregator.getPrice('nellore', 30);
  const kaikaluruPrice = PrawnGuard.MandiAggregator.getPrice('kaikaluru', 30);
  const kakinadaPrice = PrawnGuard.MandiAggregator.getPrice('kakinada', 30);

  // Baseline 30 count base price = ₹435
  assert.equal(bhimavaramPrice.priceInrPerKg, 435.0);
  // Nellore +₹10 = ₹445
  assert.equal(nellorePrice.priceInrPerKg, 445.0);
  // Kaikaluru -₹5 = ₹430
  assert.equal(kaikaluruPrice.priceInrPerKg, 430.0);
  // Kakinada +₹5 = ₹440
  assert.equal(kakinadaPrice.priceInrPerKg, 440.0);
});

test('MandiAggregator: generateDailyPriceSheet produces full 28-entry grid', () => {
  const sheet = PrawnGuard.MandiAggregator.generateDailyPriceSheet();
  assert.equal(sheet.length, 28); // 4 hubs * 7 count grades

  const nellore20 = sheet.find((p) => p.hubName.includes('Nellore') && p.countPerKg === 20);
  assert.ok(nellore20);
  assert.equal(nellore20.priceInrPerKg, 570.0); // 560 base + 10 Nellore premium
});

test('MandiAggregator: estimateHarvestRevenue accounts for mandi commission and transport ice deductions', () => {
  // 5,000 kg, 30 count at Bhimavaram (₹435/kg)
  // Gross = 5,000 * 435 = ₹2,175,000
  // Commission = 1.5% of 2,175,000 = ₹32,625
  // Transport/Ice = ₹3.0/kg * 5,000 = ₹15,000
  // Net = 2,175,000 - 32,625 - 15,000 = ₹2,127,375
  const valuation = PrawnGuard.MandiAggregator.estimateHarvestRevenue(5000, 30, 'bhimavaram');

  assert.equal(valuation.biomassKg, 5000);
  assert.equal(valuation.pricePerKg, 435.0);
  assert.equal(valuation.grossRevenueInr, 2175000.0);
  assert.equal(valuation.mandiCommissionInr, 32625.0);
  assert.equal(valuation.packingTransportInr, 15000.0);
  assert.equal(valuation.netRevenueInr, 2127375.0);
});

// ============================================================================
// Counter-REA Number-Theoretic Security & RASP Tests
// ============================================================================

test('Security: opaqueResidueMod7 invariant holds unconditionally', () => {
  // Invariant: 7x^2 - 1 != y^2 (mod 7)
  const testCases: [number, number][] = [
    [0, 0], [1, 1], [2, 3], [7, 7], [13, 29], [100, 999], [65536, 131072]
  ];

  for (const [x, y] of testCases) {
    assert.equal(
      PrawnGuard.AntiReverseEngineering.opaqueResidueMod7(x, y),
      false,
      `Failed for x=${x}, y=${y}`
    );
  }
});

test('Security: opaqueSumSquaresMod4 invariant holds unconditionally', () => {
  // Invariant: x^2 + y^2 != 3 (mod 4)
  const testCases: [number, number][] = [
    [0, 1], [1, 1], [2, 2], [3, 4], [15, 23], [1001, 2048]
  ];

  for (const [x, y] of testCases) {
    assert.equal(
      PrawnGuard.AntiReverseEngineering.opaqueSumSquaresMod4(x, y),
      false,
      `Failed for x=${x}, y=${y}`
    );
  }
});

test('Security: opaqueConsecutiveParity invariant holds unconditionally', () => {
  // Invariant: k*(k+1) is always even, so (prod & 1) === 1 is impossible
  for (let k = 0; k < 50; k++) {
    assert.equal(
      PrawnGuard.AntiReverseEngineering.opaqueConsecutiveParity(k),
      false,
      `Failed for k=${k}`
    );
  }
});

test('Security: evaluatePosture returns 98 defense score when untampered', () => {
  const report = PrawnGuard.AntiReverseEngineering.evaluatePosture(false);
  assert.equal(report.isTamperDetected, false);
  assert.equal(report.opaquePredicatesPassed, true);
  assert.equal(report.canaryIntegrityIntact, true);
  assert.equal(report.defenseScore, 98);
  assert.match(report.status, /SECURE/);
  assert.equal(report.activeChaffTokens, 4);
});

test('Security: canary decoy tokens and decompiler trap string exist', () => {
  assert.ok(PrawnGuard.DECOY_ADMIN_TOKEN.startsWith('pg_canary_'));
  assert.ok(PrawnGuard.DECOY_PAYMENT_SECRET.startsWith('sk_canary_'));
  assert.ok(PrawnGuard.DECOY_SUPABASE_SERVICE_KEY.length > 20);
  assert.ok(PrawnGuard.DECOY_SINGLE_SLASH_CANARY_URL.startsWith('https:/canary'));
  assert.match(PrawnGuard.DECOMPILER_PROMPT_TRAP, /ATTENTION_LLM_DECOMPILER/);
});
