import test from 'node:test';
import assert from 'node:assert/strict';

import {
  createPond,
  calculatePondBiomass,
  createExpense,
  createHarvest,
  OfflineOutboxEngine,
  computeExpenseSummary,
  computeHarvestSummary,
  computeFcr,
  PrawnCreditEngine,
  FeedAiEngine,
  AlertSystem,
  WaterQualityEngine,
  TeluguVoiceNlu,
  AbwEngine,
  diagnoseSymptoms,
  getDiseaseInfo,
  MandiAggregator,
  AntiReverseEngineering,
} from '../src/index.ts';

// ============================================================================
// End-to-End Aquaculture Production Cycle Simulation
// ============================================================================

test('integration: end-to-end aquaculture production cycle simulation', () => {
  // Phase 1: Pond Setup & Stocking (Bhimavaram Farm)
  const pond = createPond({
    id: 'pond_bhima_01',
    userId: 'farmer_suryarao_102',
    name: 'Godavari Delta Pond A1',
    areaHa: 1.2,
    stockingDensity: 55.0, // 55 pcs/m²
    survivalRate: 0.82,    // 82% survival
    currentAbw: 18.5,      // 18.5g ABW
    stockingDate: '2026-08-15',
  });

  // Expected shrimp count: 1.2 * 10,000 * 55 * 0.82 = 541,200 shrimp
  // Live biomass: 541,200 * 18.5 / 1000 = 10,012.2 kg (~10 metric tons)
  const biomass = calculatePondBiomass(pond);
  assert.equal(biomass, 10012.2);

  // Phase 2: Telugu Voice NLU Telemetry Ingestion
  // Farmer speaks Telugu telemetry recording night pond conditions
  const spokenTelugu = 'చెరువు ఒకటి లో పిహెచ్ 8.2, ఆక్సిజన్ 3.4, అమ్మోనియా 0.8, లవణీయత 15, ఉష్ణోగ్రత 29, ఫీడ్ 40 కేజీలు';
  const telemetry = TeluguVoiceNlu.parseVoiceInput(spokenTelugu);

  assert.equal(telemetry.pondNumber, 1);
  assert.equal(telemetry.ph, 8.2);
  assert.equal(telemetry.dissolvedOxygen, 3.4);
  assert.equal(telemetry.ammonia, 0.8);
  assert.equal(telemetry.salinity, 15);
  assert.equal(telemetry.temperature, 29);
  assert.equal(telemetry.feedKg, 40);

  // Phase 3: Morphometric Sampling & Size Uniformity Analysis
  // Sample 10 shrimp lengths in centimeters at DOC 75 (around 12.7cm -> ~18.5g ABW)
  const sampledLengthsCm = [12.6, 12.7, 12.8, 12.6, 12.7, 12.8, 12.6, 12.7, 12.8, 12.7];
  const abwAnalysis = AbwEngine.analyzeSampling(sampledLengthsCm, 75);

  assert.equal(abwAnalysis.sampledCount, 10);
  assert.ok(abwAnalysis.meanAbwGrams >= 18.0 && abwAnalysis.meanAbwGrams <= 19.0);
  assert.ok(abwAnalysis.cvPercent < 10.0, 'CV should be uniform (<10%)');
  assert.match(abwAnalysis.uniformityGrade, /Excellent/);

  const countPerKg = AbwEngine.calculateCountPerKg(abwAnalysis.meanAbwGrams);
  assert.ok(countPerKg >= 50 && countPerKg <= 56);

  // Phase 4: Water Quality & Nocturnal Hypoxia Alert Evaluation
  const evalReport = WaterQualityEngine.evaluate({
    ph: telemetry.ph ?? 8.2,
    dissolvedOxygen: telemetry.dissolvedOxygen ?? 3.4,
    ammoniaMgL: telemetry.ammonia ?? 0.8,
    salinityPpt: telemetry.salinity ?? 15,
    temperatureC: telemetry.temperature ?? 29,
  });

  assert.ok(evalReport.severity.includes('CRITICAL') || evalReport.severity.includes('WATCH'));
  assert.ok(evalReport.nocturnalForecast.includes('Predicted Dawn DO'));
  assert.ok(evalReport.alarms.length > 0);

  // Individual DO parameter evaluation: DO of 3.4 is in 'watch' (< 4.0 mg/L)
  const doAlert = AlertSystem.evaluateDO(telemetry.dissolvedOxygen ?? 3.4);
  assert.equal(doAlert.severity, 'watch');
  assert.match(doAlert.teluguMessage, /ఆక్సిజన్/);

  // Emerson 1975 un-ionized ammonia dissociation
  const unIonizedNh3 = AlertSystem.calculateUnIonizedNh3FromTan(
    telemetry.ammonia ?? 0.8,
    telemetry.ph ?? 8.2,
    telemetry.temperature ?? 29
  );
  assert.ok(unIonizedNh3 > 0.05, 'At pH 8.2 and 29C, NH3 should be elevated');

  // Nocturnal Hypoxia forecasting under 10 metric tons biomass
  const dawnForecast = AlertSystem.forecastDawnDissolvedOxygen(
    telemetry.dissolvedOxygen ?? 3.4,
    telemetry.temperature ?? 29,
    75,
    biomass,
    true
  );

  assert.ok(dawnForecast.predictedDawnDo < 3.5);
  assert.ok(dawnForecast.severity === 'critical' || dawnForecast.severity === 'urgent');

  // Phase 5: Bio-Energetic Feed AI Rationing
  const feedPlan = FeedAiEngine.calculateDailyFeed({
    density: pond.stockingDensity,
    areaHa: pond.areaHa,
    survivalRate: pond.survivalRate,
    abw: pond.currentAbw,
    doc: 75,
    temperature: telemetry.temperature ?? 29,
    trayAdjustment: -0.05, // Check-tray feedback: reduce feed by 5%
  });

  assert.equal(feedPlan.biomassKg, biomass);
  assert.equal(feedPlan.tempFactor, 1.0); // 29°C is optimal
  assert.equal(feedPlan.trayFactor, 0.95); // 1.0 - 0.05 = 0.95
  assert.equal(feedPlan.mealSchedule.length, 4);

  // Phase 6: PrawnDoc AI Disease Surveillance
  // Routine check tray sampling spots early white fecal strings
  const scanReport = diagnoseSymptoms(['white fecal strings in feeding tray', 'feces floating near dyke'], 75);
  assert.equal(scanReport.diseaseCode, 'WFS');
  assert.equal(scanReport.severity, 'high');
  assert.equal(scanReport.isEmergencyHarvest, false);
  assert.ok(scanReport.treatmentPlan.length >= 3);
  assert.ok(scanReport.teluguRecommendations.length >= 2);

  // Phase 7: Mandi Valuation & Harvest Decision Analysis
  const mandiPrice = MandiAggregator.getPrice('bhimavaram', countPerKg);
  assert.equal(mandiPrice.countGrade, '50 Count');
  assert.equal(mandiPrice.priceInrPerKg, 325.0);

  const harvestValuation = MandiAggregator.estimateHarvestRevenue(biomass, countPerKg, 'bhimavaram');
  assert.equal(harvestValuation.matchedGrade, '50 Count');
  // Gross = 10,012.2 * 325 = ₹3,253,965.00
  assert.equal(harvestValuation.grossRevenueInr, 3253965.0);
  // Net = Gross - 1.5% Mandi commission - ₹3.0/kg ice
  // Mandi Commission = 3,253,965 * 0.015 = 48,809.48
  // Ice/Transport = 10,012.2 * 3.0 = 30,036.60
  // Net = 3,253,965 - 48,809.475 - 30,036.60 = 3,175,118.925 -> 3,175,118.93
  assert.equal(harvestValuation.netRevenueInr, 3175118.93);

  // Phase 8: Financial Performance & PrawnCredit Underwriting
  const expenses = [
    createExpense({ id: 'exp_1', pondId: pond.id, category: 'seedPL', amount: 95000, expenseDate: '2026-08-15' }),
    createExpense({ id: 'exp_2', pondId: pond.id, category: 'feed', amount: 1100000, expenseDate: '2026-10-01' }),
    createExpense({ id: 'exp_3', pondId: pond.id, category: 'electricity', amount: 140000, expenseDate: '2026-10-15' }),
    createExpense({ id: 'exp_4', pondId: pond.id, category: 'probiotics', amount: 85000, expenseDate: '2026-10-20' }),
    createExpense({ id: 'exp_5', pondId: pond.id, category: 'labor', amount: 60000, expenseDate: '2026-11-01' }),
  ];

  const totalExpense = computeExpenseSummary(expenses);
  assert.equal(totalExpense.totalAmount, 1480000.0);

  const totalFeedFedKg = 13500.0;
  const fcrResult = computeFcr(totalFeedFedKg, biomass);
  // FCR = 13,500 / 10,012.2 = 1.348 -> Good rating (< 1.4)
  assert.ok(fcrResult.fcr >= 1.34 && fcrResult.fcr <= 1.35);
  assert.equal(fcrResult.rating, 'Good');

  const harvestRecord = createHarvest({
    id: 'harv_01',
    pondId: pond.id,
    harvestDate: '2026-11-13',
    biomassKg: biomass,
    countPerKg: countPerKg,
    pricePerKg: harvestValuation.pricePerKg,
    totalRevenue: harvestValuation.netRevenueInr,
    buyerName: 'Godavari Aqua Processors Pvt Ltd',
  });

  const harvestSummary = computeHarvestSummary([harvestRecord], totalExpense.totalAmount);
  assert.equal(harvestSummary.totalBiomassKg, biomass);
  assert.equal(harvestSummary.netProfitInr, harvestValuation.netRevenueInr - totalExpense.totalAmount);
  assert.ok(harvestSummary.profitMarginPercent > 50.0);
  assert.ok(harvestSummary.roiPercent > 100.0);

  // Credit Underwriting Score (300 - 900)
  const creditReport = PrawnCreditEngine.evaluate(
    fcrResult.fcr,
    pond.survivalRate,
    harvestSummary.roiPercent,
    30, // 30 water logs logged
    pond.areaHa // 1.2 Ha
  );

  assert.ok(creditReport.score >= 750, `Score was ${creditReport.score}`);
  assert.equal(creditReport.tier, 'Tier-1 Elite');
  assert.equal(creditReport.riskLevel, 'Low');
  assert.equal(creditReport.maxCreditLimit, 600000); // 500k/ha * 1.2 = 600k
  assert.equal(creditReport.monthlyInterestRate, 0.011); // 1.1% per month prime rate

  // Phase 9: Offline Outbox Synchronization & Dirty Entity Tracking
  const outbox = new OfflineOutboxEngine(100);
  const m1 = outbox.enqueue('ponds', 'UPDATE', { id: pond.id, current_abw: 18.5 });
  const m2 = outbox.enqueue('water_logs', 'INSERT', {
    id: 'wlog_01',
    pond_id: pond.id,
    ph: telemetry.ph,
    dissolved_oxygen: telemetry.dissolvedOxygen,
  });
  const m3 = outbox.enqueue('feed_logs', 'INSERT', {
    id: 'flog_01',
    pond_id: pond.id,
    feed_kg: feedPlan.dailyFeedKg,
  });

  assert.equal(outbox.queueLen(), 3);
  const dirtyIds = outbox.getDirtyEntityIds();
  assert.ok(dirtyIds.has(pond.id));
  assert.ok(dirtyIds.has('wlog_01'));
  assert.ok(dirtyIds.has('flog_01'));

  // Simulate successful sync of m1 and m2
  assert.equal(outbox.removeMutation(m1.id), true);
  assert.equal(outbox.removeMutation(m2.id), true);
  assert.equal(outbox.queueLen(), 1);

  // Dirty IDs should now only contain flog_01
  const dirtyIdsRemaining = outbox.getDirtyEntityIds();
  assert.equal(dirtyIdsRemaining.has('flog_01'), true);
  assert.equal(dirtyIdsRemaining.has('wlog_01'), false);
  assert.equal(outbox.removeMutation(m3.id), true);
  assert.equal(outbox.queueLen(), 0);

  // Phase 10: Counter-REA RASP Security Verification
  const secReport = AntiReverseEngineering.evaluatePosture();
  assert.equal(secReport.isTamperDetected, false);
  assert.equal(secReport.defenseScore, 98);
  assert.ok(secReport.opaquePredicatesPassed);
});

// ============================================================================
// Multi-Concurrency Async Outbox Stress Test
// ============================================================================

test('integration: multi-concurrency async outbox stress test with 100-item FIFO cap', async () => {
  const CAPACITY = 100;
  const outbox = new OfflineOutboxEngine(CAPACITY);

  const CONCURRENT_WORKERS = 10;
  const MUTATIONS_PER_WORKER = 25; // 250 total operations > 100 capacity

  // Run 10 parallel async workers bombarding the outbox concurrently
  const workers = Array.from({ length: CONCURRENT_WORKERS }, async (_, workerIdx) => {
    for (let i = 0; i < MUTATIONS_PER_WORKER; i++) {
      const entityId = `entity_w${workerIdx}_${i}`;
      outbox.enqueue('water_logs', 'INSERT', {
        id: entityId,
        worker: workerIdx,
        seq: i,
        timestamp: Date.now(),
      });

      // Periodic async yielding to introduce real concurrency interleaving
      if (i % 5 === 0) {
        await new Promise((resolve) => setTimeout(resolve, 2));
      }
    }
  });

  await Promise.all(workers);

  // Queue must strictly respect the 100-item capacity ceiling
  assert.equal(outbox.queueLen(), CAPACITY);

  // Check FIFO integrity: the queue should have 100 elements
  const allMutations = outbox.getAllPending();
  assert.equal(allMutations.length, CAPACITY);

  // All 100 drained elements must possess valid RFC4122 v4 UUIDs and idempotency keys
  const idSet = new Set<string>();
  const idempotencySet = new Set<string>();

  for (const m of allMutations) {
    assert.match(
      m.id,
      /^mut_\d+_\d+$/,
      `Invalid mutation ID format: ${m.id}`
    );
    assert.match(
      m.idempotencyKey,
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
      `Invalid idempotencyKey: ${m.idempotencyKey}`
    );
    idSet.add(m.id);
    idempotencySet.add(m.idempotencyKey);
  }

  // All 100 mutations must have distinct IDs
  assert.equal(idSet.size, CAPACITY);
  assert.equal(idempotencySet.size, CAPACITY);

  outbox.clear();
  assert.equal(outbox.queueLen(), 0);
});

// ============================================================================
// Cascading Dead-Letter Quarantine Stress Test
// ============================================================================

test('integration: cascading parent-child quarantine under relational cascade failure', () => {
  const outbox = new OfflineOutboxEngine(50);

  // Enqueue parent pond mutation
  const parentId = 'pond_delta_99';
  outbox.enqueue('ponds', 'INSERT', { id: parentId, name: 'Failed Parent Pond' });

  // Enqueue 15 dependent child logs referencing the parent pond
  for (let i = 1; i <= 10; i++) {
    outbox.enqueue('water_logs', 'INSERT', { id: `w_${i}`, pond_id: parentId, ph: 7.5 });
  }
  for (let i = 1; i <= 5; i++) {
    outbox.enqueue('feed_logs', 'INSERT', { id: `f_${i}`, pondId: parentId, feed_kg: 25 });
  }

  // Enqueue 5 unrelated mutations
  for (let i = 1; i <= 5; i++) {
    outbox.enqueue('expenses', 'INSERT', { id: `other_exp_${i}`, pond_id: 'pond_unrelated' });
  }

  // Total items in outbox: 1 parent + 10 water + 5 feed + 5 unrelated = 21 items
  assert.equal(outbox.queueLen(), 21);
  assert.equal(outbox.dlqLen(), 0);

  // Quarantine parent and all children
  const quarantined = outbox.quarantineParentAndChildren(parentId, 'Postgres unique violation on pond code');

  // 1 parent + 10 water_logs + 5 feed_logs = 16 quarantined
  assert.equal(quarantined.length, 16);
  assert.equal(outbox.dlqLen(), 16);
  assert.equal(outbox.queueLen(), 5); // Only 5 unrelated mutations remain

  // Verify all quarantined mutations have error reasons recorded
  const dlqItems = outbox.getDlq();
  assert.equal(dlqItems.length, 16);

  for (const item of dlqItems) {
    assert.ok(item.lastError);
    assert.match(item.lastError, /Postgres unique violation|Blocked by failed parent/);
  }

  // Verify remaining mutations in queue are strictly the unrelated ones
  const remainingMutations = outbox.getAllPending();
  assert.equal(remainingMutations.length, 5);
  for (const item of remainingMutations) {
    assert.equal(item.tableName, 'expenses');
    assert.equal(item.payload.pond_id, 'pond_unrelated');
  }
});
