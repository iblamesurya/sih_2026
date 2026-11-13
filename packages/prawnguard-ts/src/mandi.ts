import type { MarketPrice } from './models.ts';

export type RegionalHubKey = 'bhimavaram' | 'nellore' | 'kaikaluru' | 'kakinada';

export interface HubConfig {
  key: RegionalHubKey;
  name: string;
  code: string;
  priceOffsetInr: number;
}

export const REGIONAL_HUBS: Record<RegionalHubKey, HubConfig> = {
  bhimavaram: {
    key: 'bhimavaram',
    name: 'Bhimavaram (West Godavari, AP)',
    code: 'BVLM',
    priceOffsetInr: 0.0, // Baseline market
  },
  nellore: {
    key: 'nellore',
    name: 'Nellore (Andhra Pradesh)',
    code: 'NLR',
    priceOffsetInr: 10.0, // +₹10 export proximity to Chennai port
  },
  kaikaluru: {
    key: 'kaikaluru',
    name: 'Kaikaluru (Krishna, AP)',
    code: 'KKL',
    priceOffsetInr: -5.0, // -₹5 inland transit freight offset
  },
  kakinada: {
    key: 'kakinada',
    name: 'Kakinada (East Godavari, AP)',
    code: 'KKD',
    priceOffsetInr: 5.0, // +₹5 direct seaport terminal
  },
};

export type CountGradeNumber = 20 | 30 | 40 | 50 | 60 | 80 | 100;

export interface CountGradeConfig {
  count: CountGradeNumber;
  label: string;
  basePriceInr: number;
  dailyTrendInr: number;
  demand: string;
}

export const COUNT_GRADES: Record<CountGradeNumber, CountGradeConfig> = {
  20: {
    count: 20,
    label: '20 Count',
    basePriceInr: 560.0,
    dailyTrendInr: 15.0,
    demand: 'Very High (US/EU Export)',
  },
  30: {
    count: 30,
    label: '30 Count',
    basePriceInr: 435.0,
    dailyTrendInr: 10.0,
    demand: 'High (Export Prime)',
  },
  40: {
    count: 40,
    label: '40 Count',
    basePriceInr: 375.0,
    dailyTrendInr: 5.0,
    demand: 'High (Domestic/Export)',
  },
  50: {
    count: 50,
    label: '50 Count',
    basePriceInr: 325.0,
    dailyTrendInr: 0.0,
    demand: 'Moderate',
  },
  60: {
    count: 60,
    label: '60 Count',
    basePriceInr: 285.0,
    dailyTrendInr: -5.0,
    demand: 'Moderate',
  },
  80: {
    count: 80,
    label: '80 Count',
    basePriceInr: 235.0,
    dailyTrendInr: -5.0,
    demand: 'Normal',
  },
  100: {
    count: 100,
    label: '100 Count',
    basePriceInr: 195.0,
    dailyTrendInr: -10.0,
    demand: 'Low',
  },
};

export interface HarvestValuation {
  hubName: string;
  biomassKg: number;
  countPerKg: number;
  matchedGrade: string;
  pricePerKg: number;
  grossRevenueInr: number;
  netRevenueInr: number;
  packingTransportInr: number;
  mandiCommissionInr: number;
}

export class MandiAggregator {
  public static readonly ALL_HUBS: RegionalHubKey[] = [
    'bhimavaram',
    'nellore',
    'kaikaluru',
    'kakinada',
  ];

  public static readonly ALL_COUNTS: CountGradeNumber[] = [20, 30, 40, 50, 60, 80, 100];

  /**
   * Resolves nearest commercial count grade for a raw count per kg.
   */
  public static resolveCountGrade(count: number): CountGradeNumber {
    if (count <= 25) return 20;
    if (count <= 35) return 30;
    if (count <= 45) return 40;
    if (count <= 55) return 50;
    if (count <= 70) return 60;
    if (count <= 90) return 80;
    return 100;
  }

  /**
   * Parses hub name or substring to standard RegionalHubKey.
   */
  public static resolveHubKey(hubString: string): RegionalHubKey {
    const lower = hubString.toLowerCase();
    if (lower.includes('nellore')) return 'nellore';
    if (lower.includes('kaik')) return 'kaikaluru';
    if (lower.includes('kakinada')) return 'kakinada';
    return 'bhimavaram';
  }

  /**
   * Fetches market price object for a specific hub and count grade.
   */
  public static getPrice(hubKey: RegionalHubKey | string, count: number): MarketPrice {
    const resolvedHubKey = typeof hubKey === 'string' && !(hubKey in REGIONAL_HUBS)
      ? this.resolveHubKey(hubKey)
      : (hubKey as RegionalHubKey);

    const hub = REGIONAL_HUBS[resolvedHubKey] ?? REGIONAL_HUBS.bhimavaram;
    const gradeNum = this.resolveCountGrade(count);
    const grade = COUNT_GRADES[gradeNum];

    const priceInr = grade.basePriceInr + hub.priceOffsetInr;

    return {
      id: `mandi-${hub.code.toLowerCase()}-${grade.count}`,
      hubName: hub.name,
      species: 'L. vannamei',
      countGrade: grade.label,
      countPerKg: grade.count,
      priceInrPerKg: priceInr,
      priceChangeInr: grade.dailyTrendInr,
      demandLevel: grade.demand,
      effectiveDate: '2026-11-13',
    };
  }

  /**
   * Generates complete 28-entry price sheet across all 4 hubs and 7 count grades.
   */
  public static generateDailyPriceSheet(): MarketPrice[] {
    const sheet: MarketPrice[] = [];
    for (const hub of this.ALL_HUBS) {
      for (const count of this.ALL_COUNTS) {
        sheet.push(this.getPrice(hub, count));
      }
    }
    return sheet;
  }

  /**
   * Estimates net farmer revenue realization considering Mandi commission and ice transport.
   */
  public static estimateHarvestRevenue(
    biomassKg: number,
    countPerKg: number,
    hubKey: RegionalHubKey | string
  ): HarvestValuation {
    const resolvedHubKey = typeof hubKey === 'string' && !(hubKey in REGIONAL_HUBS)
      ? this.resolveHubKey(hubKey)
      : (hubKey as RegionalHubKey);

    const hub = REGIONAL_HUBS[resolvedHubKey] ?? REGIONAL_HUBS.bhimavaram;
    const gradeNum = this.resolveCountGrade(countPerKg);
    const grade = COUNT_GRADES[gradeNum];

    const pricePerKg = grade.basePriceInr + hub.priceOffsetInr;
    const gross = biomassKg * pricePerKg;

    // Standard 1.5% Mandi commission and ₹3.0/kg ice/packing/transport
    const mandiCommission = gross * 0.015;
    const packingTransport = biomassKg * 3.0;
    const net = gross - mandiCommission - packingTransport;

    return {
      hubName: hub.name,
      biomassKg,
      countPerKg,
      matchedGrade: grade.label,
      pricePerKg,
      grossRevenueInr: Math.round(gross * 100) / 100,
      netRevenueInr: Math.round(net * 100) / 100,
      packingTransportInr: Math.round(packingTransport * 100) / 100,
      mandiCommissionInr: Math.round(mandiCommission * 100) / 100,
    };
  }
}
