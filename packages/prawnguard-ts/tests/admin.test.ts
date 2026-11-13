import test from 'node:test';
import assert from 'node:assert/strict';

import {
  diagnoseSymptoms,
  getAllDiseases,
  getDiseaseInfo,
} from '../src/prawnDoc.ts';

import {
  MandiAggregator,
  REGIONAL_HUBS,
  COUNT_GRADES,
} from '../src/mandi.ts';

import {
  AntiReverseEngineering,
  DECOY_ADMIN_TOKEN,
  DECOY_PAYMENT_SECRET,
  DECOY_SUPABASE_SERVICE_KEY,
} from '../src/security.ts';

// ============================================================================
// PrawnDoc Pathology Tests (12 ICAR-CIBA Shrimp Diseases)
// ============================================================================

test('PrawnDoc: all 12 ICAR-CIBA diseases defined with bilingual treatments', () => {
  const diseases = getAllDiseases();
  assert.equal(diseases.length, 12, 'Must contain all 12 ICAR-CIBA shrimp disease profiles');

  for (const d of diseases) {
    assert.ok(d.name.length > 0, `Name must not be empty for ${d.code}`);
    assert.ok(d.teluguName.length > 0, `Telugu name must not be empty for ${d.code}`);
    assert.ok(d.treatment.teluguSummary.length > 0, `Telugu summary must not be empty for ${d.code}`);
    assert.ok(d.treatment.immediateActions.length > 0, `Immediate actions must not be empty for ${d.code}`);
  }
});

test('PrawnDoc: getDiseaseInfo returns specific protocol details', () => {
  const wssv = getDiseaseInfo('wssv');
  assert.equal(wssv.code, 'WSSV');
  assert.equal(wssv.severity, 'critical');
  assert.equal(wssv.isEmergencyHarvest, true);
  assert.ok(wssv.treatment.immediateActions[0]?.includes('Stop water exchange'));

  const healthy = getDiseaseInfo('healthy');
  assert.equal(healthy.code, 'HEALTHY');
  assert.equal(healthy.severity, 'none');
  assert.equal(healthy.isEmergencyHarvest, false);
});

test('PrawnDoc: diagnoseSymptoms correctly classifies WSSV outbreak', () => {
  const report = diagnoseSymptoms(['white spots on carapace', 'red body', 'rapid mortality'], undefined, 3.2);
  assert.equal(report.diseaseCode, 'WSSV');
  assert.equal(report.isEmergencyHarvest, true);
  assert.ok(report.confidence >= 0.80);
});

test('PrawnDoc: diagnoseSymptoms correctly classifies AHPND/EMS', () => {
  const report = diagnoseSymptoms(['atrophied pale hepatopancreas', 'empty gut line'], 25, undefined);
  assert.equal(report.diseaseCode, 'AHPND');
  assert.equal(report.severity, 'critical');
});

test('PrawnDoc: diagnoseSymptoms recognizes healthy specimens', () => {
  const report = diagnoseSymptoms(['clean glassy body', 'full dark gut line', 'active swimming']);
  assert.equal(report.diseaseCode, 'HEALTHY');
  assert.equal(report.severity, 'none');
  assert.ok(report.confidence >= 0.90);
});

// ============================================================================
// Mandi Price Aggregator Tests
// ============================================================================

test('MandiAggregator: regional hub price offsets evaluated accurately', () => {
  const bvlm30 = MandiAggregator.getPrice('bhimavaram', 30);
  const nlr30 = MandiAggregator.getPrice('nellore', 30);
  const kkl30 = MandiAggregator.getPrice('kaikaluru', 30);
  const kkd30 = MandiAggregator.getPrice('kakinada', 30);

  assert.equal(bvlm30.priceInrPerKg, 435.0, 'Bhimavaram baseline');
  assert.equal(nlr30.priceInrPerKg, 445.0, 'Nellore +₹10 export proximity');
  assert.equal(kkl30.priceInrPerKg, 430.0, 'Kaikaluru -₹5 freight offset');
  assert.equal(kkd30.priceInrPerKg, 440.0, 'Kakinada +₹5 seaport parity');
});

test('MandiAggregator: generates 28-entry daily price sheet', () => {
  const sheet = MandiAggregator.generateDailyPriceSheet();
  assert.equal(sheet.length, 28, '4 hubs * 7 grades = 28 price entries');
});

test('MandiAggregator: estimates harvest revenue and commission accurately', () => {
  const val = MandiAggregator.estimateHarvestRevenue(2000.0, 30, 'bhimavaram');
  assert.equal(val.biomassKg, 2000.0);
  assert.equal(val.pricePerKg, 435.0);
  assert.equal(val.grossRevenueInr, 870000.0);
  assert.equal(val.mandiCommissionInr, 13050.0); // 1.5% of 870,000
  assert.equal(val.packingTransportInr, 6000.0); // ₹3/kg for 2000kg
  assert.equal(val.netRevenueInr, 850950.0);
});

// ============================================================================
// Counter-REA Number-Theoretic Security Tests
// ============================================================================

test('Security: invariant mod 7 never satisfied for any integers', () => {
  for (let x = 0; x < 50; x++) {
    for (let y = 0; y < 50; y++) {
      assert.equal(
        AntiReverseEngineering.opaqueResidueMod7(x, y),
        false,
        `Invariant 1 violated at x=${x}, y=${y}`
      );
    }
  }
});

test('Security: invariant sum of squares mod 4 never equals 3', () => {
  for (let x = 0; x < 50; x++) {
    for (let y = 0; y < 50; y++) {
      assert.equal(
        AntiReverseEngineering.opaqueSumSquaresMod4(x, y),
        false,
        `Invariant 2 violated at x=${x}, y=${y}`
      );
    }
  }
});

test('Security: product of consecutive integers is never odd', () => {
  for (let k = 0; k < 200; k++) {
    assert.equal(
      AntiReverseEngineering.opaqueConsecutiveParity(k),
      false,
      `Consecutive parity violated at k=${k}`
    );
  }
});

test('Security: evaluatePosture verifies invariants and canary integrity', () => {
  const posture = AntiReverseEngineering.evaluatePosture(false);
  assert.equal(posture.isTamperDetected, false);
  assert.equal(posture.opaquePredicatesPassed, true);
  assert.equal(posture.canaryIntegrityIntact, true);
  assert.equal(posture.defenseScore, 98);
  assert.ok(posture.status.includes('SECURE'));
});
