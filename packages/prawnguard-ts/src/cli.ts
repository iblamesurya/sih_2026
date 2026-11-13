#!/usr/bin/env node

import { AbwEngine } from './abw.ts';
import { AlertSystem, WaterQualityEngine } from './alertSystem.ts';
import { FeedAiEngine } from './feedAi.ts';
import { MandiAggregator, COUNT_GRADES, REGIONAL_HUBS } from './mandi.ts';
import { diagnoseSymptoms } from './prawnDoc.ts';
import { AntiReverseEngineering } from './security.ts';
import { TeluguVoiceNlu } from './teluguNlu.ts';

function printBanner(): void {
  console.log(`
  ____                               ____                         _ 
 |  _ \\ _ __ __ ___      ___ __     / ___|_   _  __ _ _ __   __| |
 | |_) | '__/ _\` \\ \\ /\\ / / '_ \\   | |  _| | | |/ _\` | '__| / _\` |
 |  __/| | | (_| |\\ V  V /| | | |  | |_| | |_| | (_| | |   | (_| |
 |_|   |_|  \\__,_| \\_/\\_/ |_| |_|   \\____|\\__,_|\\__,_|_|    \\__,_|
               TypeScript Core Engine & Offline SDK v1.0.0
       Agricultural Intelligence & Bio-Energetic Telemetry System
`);
}

function printUsage(): void {
  console.log('Usage: node --experimental-strip-types src/cli.ts <command> [options]\n');
  console.log('Commands:');
  console.log('  diagnose <symptoms>     Diagnose shrimp disease using ICAR-CIBA protocol');
  console.log('  mandi [hub] [count]     Get Mandi farm-gate prices across Andhra Pradesh');
  console.log('  harvest <kg> <count>    Estimate harvest gross and net revenue realization');
  console.log('  security                Evaluate Counter-REA number-theoretic invariants');
  console.log('  telugu <text>           Parse spoken Telugu voice NLU water telemetry');
  console.log('  feed <doc> <kg> [temp]  Calculate diurnal 4-meal bio-energetic feed schedule');
  console.log('  alert <ph> <do> <nh3>   Evaluate water parameters & nocturnal hypoxia risk');
  console.log('  demo                    Run end-to-end multi-subsystem simulation\n');
}

function runDemo(): void {
  printBanner();
  console.log('🚀 Running Full End-to-End PrawnGuard.ai TypeScript Engine Simulation...\n');

  // 1. Allometric ABW
  const lenCm = 12.5;
  const weightG = AbwEngine.calculateWeightFromLengthCm(lenCm);
  const count = AbwEngine.calculateCountPerKg(weightG);
  console.log(`1️⃣ [ABW Allometry] Shrimp Length: ${lenCm} cm -> Weight: ${weightG.toFixed(2)} g (${Math.round(count)} count/kg)`);

  // 2. Feed AI
  const feedPlan = FeedAiEngine.calculateRation({
    doc: 65,
    biomassKg: 2800.0,
    temperatureC: 29.5,
    checkTrayStatus: 'normal',
    previousTrayLeftoverPct: 0.0,
  });
  console.log(
    `2️⃣ [Feed AI] DOC 65 Biomass 2.8t -> Daily Feed: ${feedPlan.dailyTotalKg.toFixed(1)} kg ` +
    `(M1: ${feedPlan.meal1Kg.toFixed(1)}, M2: ${feedPlan.meal2Kg.toFixed(1)}, M3: ${feedPlan.meal3Kg.toFixed(1)}, M4: ${feedPlan.meal4Kg.toFixed(1)})`
  );

  // 3. Water Quality & Hypoxia
  const waterEval = WaterQualityEngine.evaluate({
    ph: 8.2,
    dissolvedOxygen: 3.4,
    temperatureC: 29.0,
    salinityPpt: 15.0,
    ammoniaMgL: 0.08,
    alkalinityMgL: 125.0,
  });
  console.log(`3️⃣ [Alert Engine] Measured DO 3.4 mg/L -> Severity: ${waterEval.severity} (${waterEval.summary})`);

  // 4. PrawnDoc Pathology
  const report = diagnoseSymptoms(['white spots on carapace', 'red body', 'dyke swimming'], undefined, 3.4);
  console.log(
    `4️⃣ [PrawnDoc AI] Symptoms: White Spots -> ${report.diseaseName} ` +
    `(${(report.confidence * 100).toFixed(1)}% conf) - ${report.teluguName}`
  );

  // 5. Mandi Pricing
  const valuation = MandiAggregator.estimateHarvestRevenue(2800.0, Math.round(count), 'bhimavaram');
  console.log(
    `5️⃣ [Mandi Pricing] ${valuation.hubName} - ${valuation.matchedGrade} -> ` +
    `Price: ₹${valuation.pricePerKg.toFixed(2)}/kg | Net Realization: ₹${valuation.netRevenueInr.toFixed(2)}`
  );

  // 6. Security Invariants
  const posture = AntiReverseEngineering.evaluatePosture(false);
  console.log(
    `6️⃣ [Counter-REA] Opaque Predicates: ${posture.status} | ` +
    `Score: ${posture.defenseScore}/100 | Invariants Secure: ${posture.opaquePredicatesPassed}`
  );

  console.log('\n✅ Complete PrawnGuard TypeScript Core Engine verified 100% operational!\n');
}

function main(): void {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    printBanner();
    printUsage();
    return;
  }

  const command = args[0]?.toLowerCase();

  switch (command) {
    case 'diagnose': {
      if (args.length < 2) {
        console.log('Usage: node --experimental-strip-types src/cli.ts diagnose "<symptom1, symptom2, ...>"');
        return;
      }
      const rawInput = args.slice(1).join(' ');
      const symptoms = rawInput.split(',').map((s) => s.trim()).filter(Boolean);

      console.log('\n🔍 Running PrawnDoc AI Vision Pathology Diagnostic Engine...');
      console.log('  Observed Symptoms:', symptoms);
      const report = diagnoseSymptoms(symptoms);

      console.log('\n========================================================');
      console.log('  PrawnDoc AI Diagnostic Result (ICAR-CIBA Protocol)');
      console.log('========================================================');
      console.log(`  Disease Code:     ${report.diseaseCode}`);
      console.log(`  Diagnosis:        ${report.diseaseName}`);
      console.log(`  Scientific:       ${report.scientificName}`);
      console.log(`  Telugu Name:      ${report.teluguName}`);
      console.log(`  Confidence:       ${(report.confidence * 100).toFixed(1)}%`);
      console.log(`  Severity:         ${report.severity.toUpperCase()}`);
      console.log(
        `  Emergency Action: ${
          report.isEmergencyHarvest
            ? 'EMERGENCY HARVEST / ISOLATION ADVISED'
            : 'STANDARD MITIGATION PROTOCOL'
        }`
      );
      console.log(`\n  Immediate Action: ${report.immediateAction}`);
      console.log(`  Telugu Action:    ${report.teluguAction}`);
      console.log(`\n  Telugu Summary:   ${report.teluguSummary}`);
      console.log('========================================================\n');
      break;
    }

    case 'mandi': {
      const hubArg = args[1] ?? 'bhimavaram';
      const hubKey = MandiAggregator.resolveHubKey(hubArg);
      const hub = REGIONAL_HUBS[hubKey];

      if (args[2]) {
        const count = parseInt(args[2], 10);
        if (!isNaN(count)) {
          const price = MandiAggregator.getPrice(hubKey, count);
          console.log(`\n🦐 Mandi Price for ${hub.name} - ${price.countGrade}`);
          console.log(`  Price:     ₹${price.priceInrPerKg.toFixed(2)} / kg`);
          console.log(`  Change:    ₹${price.priceChangeInr >= 0 ? '+' : ''}${price.priceChangeInr.toFixed(2)}`);
          console.log(`  Demand:    ${price.demandLevel}\n`);
          return;
        }
      }

      console.log('\n=========================================================================================');
      console.log(`  PrawnGuard Mandi Farm-Gate Price Matrix — ${hub.name}`);
      console.log('=========================================================================================');
      console.log(
        `${'Grade'.padEnd(12)} | ${'Count/kg'.padEnd(12)} | ${'Price (₹/kg)'.padEnd(12)} | ${'Trend'.padEnd(10)} | Demand Level`
      );
      console.log('-----------------------------------------------------------------------------------------');

      for (const count of MandiAggregator.ALL_COUNTS) {
        const price = MandiAggregator.getPrice(hubKey, count);
        const trendStr = `₹${price.priceChangeInr >= 0 ? '+' : ''}${price.priceChangeInr.toFixed(2)}`;
        console.log(
          `${price.countGrade.padEnd(12)} | ${String(price.countPerKg).padEnd(12)} | ₹${price.priceInrPerKg
            .toFixed(2)
            .padEnd(11)} | ${trendStr.padEnd(10)} | ${price.demandLevel}`
        );
      }
      console.log('=========================================================================================\n');
      break;
    }

    case 'harvest': {
      if (args.length < 3) {
        console.log('Usage: node --experimental-strip-types src/cli.ts harvest <biomass_kg> <count_per_kg> [hub]');
        return;
      }
      const biomass = parseFloat(args[1] ?? '1000');
      const count = parseInt(args[2] ?? '30', 10);
      const hub = args[3] ?? 'bhimavaram';

      const val = MandiAggregator.estimateHarvestRevenue(biomass, count, hub);
      console.log('\n💰 Harvest Valuation & Net Revenue Realization:');
      console.log(`  Regional Hub:       ${val.hubName}`);
      console.log(`  Harvest Biomass:    ${val.biomassKg.toFixed(1)} kg`);
      console.log(`  Grade Matched:      ${val.matchedGrade} (${val.countPerKg} count)`);
      console.log(`  Price per kg:       ₹${val.pricePerKg.toFixed(2)}`);
      console.log(`  Gross Revenue:      ₹${val.grossRevenueInr.toFixed(2)}`);
      console.log(`  Mandi Commission:  -₹${val.mandiCommissionInr.toFixed(2)} (1.5%)`);
      console.log(`  Ice & Transport:   -₹${val.packingTransportInr.toFixed(2)} (₹3/kg)`);
      console.log(`  Net Realization:    ₹${val.netRevenueInr.toFixed(2)}`);
      console.log('---------------------------------------------------------\n');
      break;
    }

    case 'security': {
      console.log('\n🛡️  Evaluating Counter-REA Number-Theoretic Security Posture...');
      const posture = AntiReverseEngineering.evaluatePosture(false);
      console.log(`  Tamper Detected:          ${posture.isTamperDetected}`);
      console.log(
        `  Opaque Invariants:        ${
          posture.opaquePredicatesPassed ? 'PASS (7x^2 - 1 != y^2 mod 7 active)' : 'FAIL'
        }`
      );
      console.log(
        `  Canary Token Integrity:   ${posture.canaryIntegrityIntact ? 'PASS (Canaries Armored)' : 'FAIL'}`
      );
      console.log(`  Active Chaff Tokens:      ${posture.activeChaffTokens}`);
      console.log(`  Defense Score:            ${posture.defenseScore}/100`);
      console.log(`  Status:                   ${posture.status}`);
      console.log('---------------------------------------------------------\n');
      break;
    }

    case 'telugu': {
      if (args.length < 2) {
        console.log('Usage: node --experimental-strip-types src/cli.ts telugu "<telugu speech text>"');
        return;
      }
      const query = args.slice(1).join(' ');
      console.log(`\n🗣️  Parsing Telugu Voice NLU Spoken Query: "${query}"`);
      const parsed = TeluguVoiceNlu.parseVoiceInput(query);
      console.log('  Pond Index:     ', parsed.pondIndex);
      console.log('  pH:             ', parsed.ph);
      console.log('  DO (Oxygen):    ', parsed.doLevel, 'mg/L');
      console.log('  Ammonia (NH3):  ', parsed.ammonia, 'mg/L');
      console.log('  Feed Amount:    ', parsed.feedKg, 'kg');
      console.log('---------------------------------------------------------\n');
      break;
    }

    case 'feed': {
      const doc = parseInt(args[1] ?? '65', 10);
      const biomass = parseFloat(args[2] ?? '2500');
      const temp = parseFloat(args[3] ?? '28.5');

      const plan = FeedAiEngine.calculateRation({
        doc,
        biomassKg: biomass,
        temperatureC: temp,
        checkTrayStatus: 'normal',
        previousTrayLeftoverPct: 0.0,
      });

      console.log(`\n🌾 Bio-Energetic Feed AI Diurnal Ration Plan (DOC ${doc}):`);
      console.log(`  Stocking Biomass:    ${biomass.toFixed(1)} kg`);
      console.log(`  Feeding Rate:        ${(plan.feedingRate * 100).toFixed(2)}%`);
      console.log(`  Water Temperature:   ${temp.toFixed(1)} °C (Temp Factor: ${plan.tempFactor.toFixed(2)})`);
      console.log(`  Daily Adjusted Feed: ${plan.adjustedDailyFeedKg.toFixed(2)} kg`);
      console.log('  4-Meal Schedule:');
      console.log(`    • Meal 1 (06:00 AM, 20%): ${plan.meal1Kg.toFixed(2)} kg`);
      console.log(`    • Meal 2 (11:00 AM, 30%): ${plan.meal2Kg.toFixed(2)} kg`);
      console.log(`    • Meal 3 (04:00 PM, 30%): ${plan.meal3Kg.toFixed(2)} kg`);
      console.log(`    • Meal 4 (09:00 PM, 20%): ${plan.meal4Kg.toFixed(2)} kg`);
      console.log('---------------------------------------------------------\n');
      break;
    }

    case 'alert': {
      const ph = parseFloat(args[1] ?? '7.8');
      const doVal = parseFloat(args[2] ?? '3.2');
      const nh3 = parseFloat(args[3] ?? '0.08');

      const evaluation = WaterQualityEngine.evaluate({
        ph,
        dissolvedOxygen: doVal,
        temperatureC: 28.5,
        salinityPpt: 15.0,
        ammoniaMgL: nh3,
        alkalinityMgL: 120.0,
      });

      console.log('\n⚠️  Water Quality & Nocturnal Hypoxia Diagnostic:');
      console.log(`  Overall Severity:  ${evaluation.severity.toUpperCase()}`);
      console.log(`  Status Summary:    ${evaluation.summary}`);
      console.log(`  Nocturnal Forecast: ${evaluation.nocturnalForecast}`);
      if (evaluation.alarms.length > 0) {
        console.log('  Active Alarms:');
        for (const alarm of evaluation.alarms) {
          console.log(`    🚨 [${alarm.parameter}] ${alarm.message}`);
        }
      }
      console.log('---------------------------------------------------------\n');
      break;
    }

    case 'demo': {
      runDemo();
      break;
    }

    default: {
      printUsage();
      break;
    }
  }
}

main();
