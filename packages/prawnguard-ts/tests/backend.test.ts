import test from 'node:test';
import assert from 'node:assert/strict';
import { createPond, calculatePondBiomass, createWaterLog, createFeedLog, createDiseaseScan, createExpense, createHarvest, createMarketPrice } from '../src/models.ts';
import { OfflineOutboxEngine } from '../src/outbox.ts';
import { computeExpenseSummary, computeHarvestSummary, computeFcr, PrawnCreditEngine } from '../src/finance.ts';

test('models: pond biomass calculation', () => {
  const pond = createPond({
    id: 'pond_1',
    userId: 'user_1',
    name: 'Pond 1',
    areaHa: 1.0,
    stockingDensity: 50.0,
    survivalRate: 0.80,
    currentAbw: 16.0,
    stockingDate: '2026-08-01',
  });

  // Total shrimp: 1.0 * 10,000 * 50 * 0.80 = 400,000 shrimp
  // Biomass: 400,000 * 16g / 1000 = 6,400 kg
  assert.equal(calculatePondBiomass(pond), 6400.0);
});

test('outbox: fifo capacity and overflow head eviction', () => {
  const engine = new OfflineOutboxEngine(5);

  for (let i = 1; i <= 5; i++) {
    engine.enqueue('water_logs', 'INSERT', { id: `wlog_${i}` });
  }
  assert.equal(engine.queueLen(), 5);

  // Enqueue 6th mutation -> should evict wlog_1
  engine.enqueue('water_logs', 'INSERT', { id: 'wlog_6' });
  assert.equal(engine.queueLen(), 5);

  const head = engine.peekHead();
  assert.ok(head);
  assert.equal(head.payload.id, 'wlog_2');
});

test('outbox: atomic remove and dirty entity IDs', () => {
  const engine = new OfflineOutboxEngine(10);
  const m1 = engine.enqueue('ponds', 'INSERT', { id: 'pond_temp_1' });
  const _m2 = engine.enqueue('feed_logs', 'INSERT', { id: 'feed_1', pond_id: 'pond_temp_1' });

  const dirty = engine.getDirtyEntityIds();
  assert.ok(dirty.has('pond_temp_1'));
  assert.ok(dirty.has('feed_1'));

  assert.equal(engine.removeMutation(m1.id), true);
  assert.equal(engine.queueLen(), 1);

  const dirtyAfter = engine.getDirtyEntityIds();
  assert.equal(dirtyAfter.has('pond_temp_1'), false);
  assert.ok(dirtyAfter.has('feed_1'));
});

test('outbox: cascading parent-child quarantine', () => {
  const engine = new OfflineOutboxEngine(10);
  engine.enqueue('ponds', 'INSERT', { id: 'p_parent_failed' });
  engine.enqueue('water_logs', 'INSERT', { id: 'w1', pond_id: 'p_parent_failed' });
  engine.enqueue('feed_logs', 'INSERT', { id: 'f1', pondId: 'p_parent_failed' });
  const other = engine.enqueue('expenses', 'INSERT', { id: 'exp_other', pond_id: 'p_unrelated' });

  assert.equal(engine.queueLen(), 4);

  const quarantined = engine.quarantineParentAndChildren('p_parent_failed', 'Foreign key constraint failure');
  assert.equal(quarantined.length, 3);
  assert.equal(engine.queueLen(), 1);
  assert.equal(engine.dlqLen(), 3);

  const remaining = engine.peekHead();
  assert.ok(remaining);
  assert.equal(remaining.id, other.id);
});

test('finance: expense and harvest summaries', () => {
  const expenses = [
    createExpense({
      id: 'e1',
      pondId: 'p1',
      category: 'feed',
      amount: 70000.0,
      expenseDate: '2026-09-01',
    }),
    createExpense({
      id: 'e2',
      pondId: 'p1',
      category: 'seedPL',
      amount: 30000.0,
      expenseDate: '2026-09-02',
    }),
  ];

  const expSummary = computeExpenseSummary(expenses);
  assert.equal(expSummary.totalAmount, 100000.0);
  assert.equal(expSummary.categoryPercentages['feed'], 70.0);
  assert.equal(expSummary.categoryPercentages['seedPL'], 30.0);

  const harvests = [
    createHarvest({
      id: 'h1',
      pondId: 'p1',
      biomassKg: 1000.0,
      countPerKg: 40,
      pricePerKg: 350.0,
      totalRevenue: 350000.0,
      harvestDate: '2026-10-01',
    }),
  ];

  const hrvSummary = computeHarvestSummary(harvests, expSummary.totalAmount);
  assert.equal(hrvSummary.totalRevenueInr, 350000.0);
  assert.equal(hrvSummary.netProfitInr, 250000.0);
  assert.equal(hrvSummary.roiPercent, 250.0);
});

test('finance: fcr analysis rating', () => {
  const analysis = computeFcr(1300.0, 1000.0);
  assert.equal(analysis.fcr, 1.3);
  assert.equal(analysis.rating, 'Good');
});

test('finance: prawn credit score tier 1', () => {
  const credit = PrawnCreditEngine.evaluate(1.22, 0.88, 35.0, 60, 2.0);
  assert.ok(credit.score >= 750);
  assert.equal(credit.tier, 'Tier-1 Elite');
  assert.equal(credit.riskLevel, 'Low');
  assert.equal(credit.maxCreditLimit, 1000000.0); // 500k * 2 ha
});

test('outbox: async mutex lock serializes concurrent tasks', async () => {
  const engine = new OfflineOutboxEngine(20);
  const executionOrder: number[] = [];

  const task = async (id: number, delayMs: number) => {
    return engine.runLocked(async () => {
      executionOrder.push(id);
      await new Promise((resolve) => setTimeout(resolve, delayMs));
      executionOrder.push(id * 10);
      return id;
    });
  };

  await Promise.all([
    task(1, 15),
    task(2, 5),
    task(3, 1),
  ]);

  // Even though task 2 and 3 had shorter delays, task 1 acquired lock first,
  // so task 1 must start and finish before task 2 starts, etc.
  assert.deepEqual(executionOrder, [1, 10, 2, 20, 3, 30]);
});

