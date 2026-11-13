/**
 * PrawnGuard.ai TypeScript Core Models
 * Domain entities for ponds, telemetry logs, feedings, pathology scans, expenses, harvests, and mandi prices.
 */

export interface Pond {
  id: string;
  userId: string;
  farmerId?: string | null;
  farmId?: string | null;
  name: string;
  species: string;
  areaHa: number;
  stockingDensity: number;
  doc: number;
  stockingDate: string;
  initialAbw: number;
  currentAbw: number;
  survivalRate: number;
  status: string;
  version: number;
  createdAt?: string | null;
  updatedAt?: string | null;
}

export function createPond(params: Partial<Pond> & { id: string; userId: string; name: string; stockingDate: string }): Pond {
  return {
    id: params.id,
    userId: params.userId,
    farmerId: params.farmerId ?? null,
    farmId: params.farmId ?? null,
    name: params.name,
    species: params.species ?? "L. vannamei",
    areaHa: params.areaHa ?? 1.0,
    stockingDensity: params.stockingDensity ?? 50.0,
    doc: params.doc ?? 1,
    stockingDate: params.stockingDate,
    initialAbw: params.initialAbw ?? 0.02,
    currentAbw: params.currentAbw ?? 15.0,
    survivalRate: params.survivalRate ?? 0.85,
    status: params.status ?? "Active",
    version: params.version ?? 1,
    createdAt: params.createdAt ?? null,
    updatedAt: params.updatedAt ?? null,
  };
}

/**
 * Computes estimated total biomass in kg:
 * Biomass (kg) = areaHa * 10,000 * stockingDensity * survivalRate * (currentAbw / 1000.0)
 */
export function calculatePondBiomass(pond: Pond): number {
  const totalShrimp = pond.areaHa * 10000.0 * pond.stockingDensity * pond.survivalRate;
  return (totalShrimp * pond.currentAbw) / 1000.0;
}

export interface WaterLog {
  id: string;
  userId?: string | null;
  pondId: string;
  ph?: number | null;
  dissolvedOxygen?: number | null;
  salinity?: number | null;
  temperature?: number | null;
  ammonia?: number | null;
  alkalinity?: number | null;
  turbidityCm?: number | null;
  overallSeverity: string;
  source: string;
  idempotencyKey?: string | null;
  recordedAt: string;
}

export function createWaterLog(params: Partial<WaterLog> & { id: string; pondId: string; recordedAt: string }): WaterLog {
  return {
    id: params.id,
    userId: params.userId ?? null,
    pondId: params.pondId,
    ph: params.ph ?? null,
    dissolvedOxygen: params.dissolvedOxygen ?? null,
    salinity: params.salinity ?? null,
    temperature: params.temperature ?? null,
    ammonia: params.ammonia ?? null,
    alkalinity: params.alkalinity ?? null,
    turbidityCm: params.turbidityCm ?? null,
    overallSeverity: params.overallSeverity ?? "optimal",
    source: params.source ?? "manual",
    idempotencyKey: params.idempotencyKey ?? null,
    recordedAt: params.recordedAt,
  };
}

export interface FeedLog {
  id: string;
  userId?: string | null;
  pondId: string;
  doc: number;
  biomassKg: number;
  feedingRate: number;
  dailyFeedKg: number;
  mealNumber?: number | null;
  scheduledTime?: string | null;
  feedKg?: number | null;
  percentShare?: number | null;
  meal1Kg: number;
  meal2Kg: number;
  meal3Kg: number;
  meal4Kg: number;
  meal1Completed: boolean;
  meal2Completed: boolean;
  meal3Completed: boolean;
  meal4Completed: boolean;
  checkTrayStatus: string;
  trayAdjustment: number;
  temperatureC: number;
  idempotencyKey?: string | null;
  fedAt: string;
}

export function createFeedLog(params: Partial<FeedLog> & { id: string; pondId: string; fedAt: string }): FeedLog {
  return {
    id: params.id,
    userId: params.userId ?? null,
    pondId: params.pondId,
    doc: params.doc ?? 1,
    biomassKg: params.biomassKg ?? 0.0,
    feedingRate: params.feedingRate ?? 0.0,
    dailyFeedKg: params.dailyFeedKg ?? 0.0,
    mealNumber: params.mealNumber ?? null,
    scheduledTime: params.scheduledTime ?? null,
    feedKg: params.feedKg ?? null,
    percentShare: params.percentShare ?? null,
    meal1Kg: params.meal1Kg ?? 0.0,
    meal2Kg: params.meal2Kg ?? 0.0,
    meal3Kg: params.meal3Kg ?? 0.0,
    meal4Kg: params.meal4Kg ?? 0.0,
    meal1Completed: params.meal1Completed ?? false,
    meal2Completed: params.meal2Completed ?? false,
    meal3Completed: params.meal3Completed ?? false,
    meal4Completed: params.meal4Completed ?? false,
    checkTrayStatus: params.checkTrayStatus ?? "normal",
    trayAdjustment: params.trayAdjustment ?? 0.0,
    temperatureC: params.temperatureC ?? 28.5,
    idempotencyKey: params.idempotencyKey ?? null,
    fedAt: params.fedAt,
  };
}

export interface DiseaseScan {
  id: string;
  userId?: string | null;
  pondId: string;
  imageHash?: string | null;
  diseaseCode: string;
  diseaseName: string;
  teluguName?: string | null;
  confidence: number;
  severity: string;
  isEmergencyHarvest: boolean;
  immediateAction?: string | null;
  teluguAction?: string | null;
  treatmentPlan: string[];
  waterContext: Record<string, unknown>;
  farmerNotes?: string | null;
  idempotencyKey?: string | null;
  scannedAt: string;
}

export function createDiseaseScan(params: Partial<DiseaseScan> & {
  id: string;
  pondId: string;
  diseaseCode: string;
  diseaseName: string;
  confidence: number;
  scannedAt: string;
}): DiseaseScan {
  return {
    id: params.id,
    userId: params.userId ?? null,
    pondId: params.pondId,
    imageHash: params.imageHash ?? null,
    diseaseCode: params.diseaseCode,
    diseaseName: params.diseaseName,
    teluguName: params.teluguName ?? null,
    confidence: params.confidence,
    severity: params.severity ?? "optimal",
    isEmergencyHarvest: params.isEmergencyHarvest ?? false,
    immediateAction: params.immediateAction ?? null,
    teluguAction: params.teluguAction ?? null,
    treatmentPlan: params.treatmentPlan ?? [],
    waterContext: params.waterContext ?? {},
    farmerNotes: params.farmerNotes ?? null,
    idempotencyKey: params.idempotencyKey ?? null,
    scannedAt: params.scannedAt,
  };
}

export interface Expense {
  id: string;
  userId?: string | null;
  pondId: string;
  pondName: string;
  category: string;
  amount: number;
  supplier?: string | null;
  notes?: string | null;
  idempotencyKey?: string | null;
  expenseDate: string;
}

export function createExpense(params: Partial<Expense> & {
  id: string;
  pondId: string;
  category: string;
  amount: number;
  expenseDate: string;
}): Expense {
  return {
    id: params.id,
    userId: params.userId ?? null,
    pondId: params.pondId,
    pondName: params.pondName ?? "Pond 1",
    category: params.category,
    amount: params.amount,
    supplier: params.supplier ?? null,
    notes: params.notes ?? null,
    idempotencyKey: params.idempotencyKey ?? null,
    expenseDate: params.expenseDate,
  };
}

export interface Harvest {
  id: string;
  userId?: string | null;
  pondId: string;
  pondName: string;
  harvestType: string;
  biomassKg: number;
  countPerKg: number;
  pricePerKg: number;
  totalRevenue: number;
  fcr: number;
  buyerName?: string | null;
  idempotencyKey?: string | null;
  harvestDate: string;
}

export function createHarvest(params: Partial<Harvest> & {
  id: string;
  pondId: string;
  biomassKg: number;
  countPerKg: number;
  pricePerKg: number;
  totalRevenue: number;
  harvestDate: string;
}): Harvest {
  return {
    id: params.id,
    userId: params.userId ?? null,
    pondId: params.pondId,
    pondName: params.pondName ?? "Pond 1",
    harvestType: params.harvestType ?? "Partial",
    biomassKg: params.biomassKg,
    countPerKg: params.countPerKg,
    pricePerKg: params.pricePerKg,
    totalRevenue: params.totalRevenue,
    fcr: params.fcr ?? 1.3,
    buyerName: params.buyerName ?? null,
    idempotencyKey: params.idempotencyKey ?? null,
    harvestDate: params.harvestDate,
  };
}

export interface MarketPrice {
  id: string;
  hubName: string;
  species: string;
  countGrade: string;
  countPerKg: number;
  priceInrPerKg: number;
  priceChangeInr: number;
  demandLevel: string;
  effectiveDate: string;
}

export function createMarketPrice(params: Partial<MarketPrice> & {
  id: string;
  hubName: string;
  countGrade: string;
  countPerKg: number;
  priceInrPerKg: number;
  effectiveDate: string;
}): MarketPrice {
  return {
    id: params.id,
    hubName: params.hubName,
    species: params.species ?? "L. vannamei",
    countGrade: params.countGrade,
    countPerKg: params.countPerKg,
    priceInrPerKg: params.priceInrPerKg,
    priceChangeInr: params.priceChangeInr ?? 0.0,
    demandLevel: params.demandLevel ?? "High",
    effectiveDate: params.effectiveDate,
  };
}
