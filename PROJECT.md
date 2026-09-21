# Project: PrawnGuard.ai (SIH 2026) Enterprise Aquaculture Intelligence Platform

## Architecture
- **Client App**: Flutter 3.x (Offline-first, Riverpod 2.x, GoRouter 14.x, Deep Ocean Matte design tokens, Space Grotesk / Outfit typography, bilingual en/te).
- **Backend as a Service (BaaS)**: Supabase PostgreSQL (15 domain tables, RLS policies, 18 foreign key indexes, atomic increment_scan_count RPC).
- **Serverless Compute**: TypeScript Deno Edge Functions (prawndoc-ai Gemini Vision, weather-intelligence OpenWeatherMap caching & hypoxia alerts).
- **Admin Portal**: React 19 + Vite 8 + Tailwind CSS v4 (dmin-dashboard/ with Leaflet geo-map, Recharts analytics, Market Prices, Announcements broadcast).
- **AI Domain Engines**:
  - PrawnDocAIService: Multimodal vision diagnosis for 12 shrimp diseases, 768px JPEG q75 compression, EXIF stripping, MD5 hash deduplication, water parameter RAG context injection, prompt injection mitigation, robust JSON parsing.
  - FeedAIService: Bio-energetic biomass calculation, 4-meal daily split (20% 6AM, 30% 11AM, 30% 4PM, 20% 9PM), temperature adjustment factors, check-tray feedback adjustments (-20% to +10%).
  - TeluguVoiceNLUService: Regex-based code-mixed Telugu/English parser for pond telemetry (DO, pH, salinity, temp, ammonia, feed kg).

## Code Layout
- lib/core/theme/: pp_theme.dart, pp_text_styles.dart (Deep Ocean Matte tokens).
- lib/l10n/: en.json, 	e.json (bilingual localization dictionary).
- lib/core/services/: Core platform services (supabase_client.dart, uth_service.dart, offline_sync_service.dart, ase_repository.dart, ealtime_service.dart, lert_system.dart, location_service.dart, subscription_service.dart, prawndoc_ai_service.dart, eed_ai_service.dart, 	elugu_voice_nlu_service.dart, weather_service.dart).
- lib/core/router/: pp_router.dart (5-tab StatefulShellRoute + modal routes).
- lib/core/providers/: pp_providers.dart (central Riverpod state & clearAllUserData).
- lib/features/: Feature UI modules (Ponds, Finance/PrawnCredit, More/Profile/Settings, Community, Home, Feed AI, PrawnDoc).
- supabase/: schema.sql, unctions/prawndoc-ai/index.ts, unctions/weather-intelligence/index.ts.
- dmin-dashboard/: React 19 web admin dashboard (src/pages/, src/components/, src/lib/).
- 	est/: Comprehensive unit, widget, and E2E integration test suites.
- scripts/: uild_release.ps1 release automation script.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Deep Ocean Matte Theme & Tokens | Theme tokens (#0A0A0B, #171717, #00E5FF, #10B981, #E55C5C, #E5B05C, #5C9EE5) and typography | M1 | R1 |
| 2 | Bilingual Localization | English and Telugu dictionary (en.json, 	e.json) | M1 | R1 |
| 3 | Supabase Schema & RPC | 15 domain tables, RLS policies, indexes, increment_scan_count RPC | M1 | R2 |
| 4 | Edge Functions | prawndoc-ai and weather-intelligence Deno functions with CORS & error handling | M1 | R2 |
| 5 | OfflineSyncService & BaseRepository | FIFO max 100 mutations, SharedPreferences queue, backoff drain, safeMutate() | M1 | R3 |
| 6 | Core Auth & Domain Services | AuthService phone mapping, RealtimeService, AlertSystem, LocationService, SubscriptionService | M1 | R3 |
| 7 | PrawnDocAIService | 12 diseases vision, 768px compression, EXIF strip, MD5 deduplication, RAG injection, robust JSON parsing | M2 | R4 |
| 8 | FeedAIService | Bio-energetics biomass, 4-meal schedule (20/30/30/20), temperature factors, tray adjustments (-20% to +10%) | M2 | R4 |
| 9 | TeluguVoiceNLUService | Code-mixed Telugu/English regex parser for telemetry (DO, pH, salinity, temp, ammonia, feed) | M2 | R4 |
| 10 | GoRouter Navigation | 5-tab StatefulShellRoute + /login, /onboarding, /profile-setup, /quick-log, /finance, /weather, /reports, /upgrade, /admin | M3 | R1 |
| 11 | Riverpod State Management | Central pp_providers.dart with state providers and clearAllUserData sign-out invalidation | M3 | R1 |
| 12 | Mobile Presentation Pages | Ponds UI, Finance/PrawnCredit, More/Profile/Settings (Telugu switch), Community | M4 | R5 |
| 13 | Admin Web Dashboard | React 19 + Vite 8 + Tailwind, KPI cards, Recharts, Leaflet FarmMap, MarketPrices, Announcements | M4 | R5 |
| 14 | Release Automation Script | scripts/build_release.ps1 with .env loading, compile-time --dart-define, obfuscation | M4 | R5 |
| 15 | E2E Testing Suite (Tiers 1-4) | Comprehensive opaque-box test suite verifying all features against acceptance criteria | M5 | AC |
| 16 | Adversarial Hardening (Tier 5) | White-box stress testing, corner cases, and static analysis verification (lutter analyze 0 issues) | M5 | AC |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Core Services & BaaS Engine | OfflineSyncService FIFO 100, BaseRepository safeMutate, AuthService, RealtimeService, AlertSystem, LocationService, SubscriptionService, Edge Functions | None | PLANNED |
| M2 | AI & Voice Domain Engines | PrawnDocAIService (12 diseases vision), FeedAIService (bio-energetics & 4 meals), TeluguVoiceNLUService (code-mixed parser) | M1 | PLANNED |
| M3 | Router & State Management | GoRouter 5-tab shell + modal routes, Riverpod app_providers.dart with clearAllUserData | M1, M2 | PLANNED |
| M4 | Mobile Pages & Admin Dashboard | Ponds UI, Finance UI, More/Profile UI, Community, Admin FarmMap (Leaflet), MarketPrices, Announcements, build_release.ps1 | M3 | PLANNED |
| M5 | E2E Verification & Hardening | Pass 100% of E2E test suite (Tiers 1-4), Tier 5 adversarial hardening, static checks (0 analyze issues) | M4, TEST_READY.md | PLANNED |

## Interface Contracts
### AuthService
- signInWithOtp(String phone) -> Normalizes Indian phone (+91), maps to <phone>@prawnguard.app, triggers Supabase OTP.
- erifyOtp(String phone, String token) -> Authenticates session, loads profile, updates Riverpod user state.
- signOut() -> Clears session and calls clearAllUserData().

### OfflineSyncService & BaseRepository
- safeMutate<T>(Future<T> Function() networkAction, Map<String, dynamic> offlineMutation) -> Executes networkAction; on SocketException/TimeoutException, enqueues offlineMutation to offline_queue in SharedPreferences (FIFO, max 100 elements, dropping oldest if full).
- drainQueue() -> Iterates queued mutations sequentially, executing with exponential backoff on retryable errors.

### AlertSystem
- evaluateParameters({double? ph, double? dissolvedOxygen, double? ammonia, double? alkalinity}) -> Returns list of alerts with severities:
  - AlertSeverity.urgent (pH < 7.0 or > 9.0; DO < 3.0 mg/L; NH3 > 0.1 mg/L)
  - AlertSeverity.watch (pH 7.0-7.5 or 8.5-9.0; DO 3.0-4.0 mg/L; NH3 0.05-0.1 mg/L; Alkalinity < 100 mg/L)
  - AlertSeverity.optimal (pH 7.5-8.5; DO > 4.0 mg/L; NH3 < 0.05 mg/L; Alkalinity 100-150 mg/L)

### FeedAIService
- calculateDailyFeed({required double density, required double areaHa, required double survivalRate, required double abw, required int doc, required double temperature, double? trayLeftoverPercent})
  - Biomass = Density (pcs/m²) * Area (m²) * SurvivalRate * (ABW / 1000)
  - FeedingRate = clamp(0.08 - (DOC * 0.0005), 0.03, 0.08)
  - BaseDailyFeed = Biomass * FeedingRate
  - TempFactor = T < 24°C: 0.85; 24°C <= T <= 32°C: 1.00; T > 32°C: 0.90
  - TrayFactor = clamp(1.0 + (trayAdjustment), 0.80, 1.10)
  - AdjustedDailyFeed = BaseDailyFeed * TempFactor * TrayFactor
  - 4 Meals: Meal 1 (6 AM) 20%, Meal 2 (11 AM) 30%, Meal 3 (4 PM) 30%, Meal 4 (9 PM) 20%.

### TeluguVoiceNLUService
- parseVoiceInput(String transcript) -> Returns structured telemetry map with keys pondIndex, ph, doLevel, salinity, 	emperature, mmonia, eedKg parsed via regex supporting English, Telugu script, and transliterated Telugu.
