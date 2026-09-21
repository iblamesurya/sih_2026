# Original User Request

## 2026-08-29T15:21:46Z

Build and complete the entire PrawnGuard.ai (SIH 2026) enterprise aquaculture intelligence platform end-to-end, delivering the Flutter offline-first mobile application, Supabase BaaS schema and Edge Functions, React 19 admin dashboard, and AI domain engines (PrawnDoc disease vision, Feed AI bio-energetics, and Telugu Voice NLU).

Working directory: c:/Users/tummala surya/sih_2026
Integrity mode: development

## Requirements

### R1. Platform Base & Core Architecture
- Configure Flutter project with pinned dependencies, Deep Ocean Matte design tokens (`#0A0A0B`, `#171717`, `#00E5FF`, `#10B981`, `#E55C5C`, `#E5B05C`, `#5C9EE5`), and typography (Space Grotesk headers + Outfit body).
- Implement full English and Telugu bilingual localization (`en.json` and `te.json`).
- Implement 5-tab `StatefulShellRoute` GoRouter navigation (Home, Ponds, Feed AI, PrawnDoc, More) plus modal routes (`/login`, `/onboarding`, `/profile-setup`, `/quick-log`, `/finance`, `/weather`, `/reports`, `/upgrade`, `/admin`).
- Centralize Riverpod state management in `lib/core/providers/app_providers.dart` with complete user data invalidation on sign-out (`clearAllUserData`).

### R2. BaaS Schema & Edge Functions
- Provide complete PostgreSQL `supabase/schema.sql` containing all 14 domain tables (`profiles`, `farms`, `ponds`, `crop_cycles`, `water_logs`, `feed_logs`, `disease_scans`, `growth_samples`, `abw_samples`, `expenses`, `harvests`, `market_prices`, `admin_announcements`, `activity_events`, `notification_preferences`), RLS policies, indexes, and atomic `increment_scan_count` RPC.
- Implement Supabase Deno Edge Functions for `prawndoc-ai` (Gemini Flash multimodal vision analysis for 12 shrimp diseases) and `weather-intelligence` (OpenWeatherMap data caching & hypoxia advisories).

### R3. Core Services & Offline-First Engine
- Implement `SupabaseClientService` singleton with compile-time `--dart-define` configuration.
- Implement `OfflineSyncService` with FIFO queue (max 100 mutations stored in local preferences, sequential drain with exponential backoff on reconnection).
- Implement `BaseRepository` with `safeMutate()` wrapper guaranteeing offline mutation queuing across all entities.
- Implement core domain services: `AuthService` (Indian phone number to `@prawnguard.app` auth mapping), `RealtimeService`, `AlertSystem` (pH, DO, NH3, Alkalinity threshold evaluation), `LocationService`, and `SubscriptionService` (Free vs Pro quotas).

### R4. Intelligent AI & Voice Engines
- Implement `PrawnDocAIService`: image compression (768px JPEG q75), EXIF stripping, MD5 hash deduplication, water parameter RAG context injection, prompt injection mitigation, and robust JSON parsing for 12 shrimp diseases.
- Implement `FeedAIService`: bio-energetic biomass calculation, 4-meal daily split (20% 6AM, 30% 11AM, 30% 4PM, 20% 9PM), temperature adjustment factors, and check-tray feedback adjustments (-20% to +10%).
- Implement `TeluguVoiceNLUService`: regex-based code-mixed Telugu/English natural language parser for pond telemetry (DO, pH, salinity, temp, ammonia, feed quantity).

### R5. Complete Mobile & Admin UI Modules
- Build Flutter presentation pages: Ponds UI (list, pond details, telemetry, add pond modal), Finance / PrawnCredit (expenses, harvests, cashflow summary), More / Profile & Settings with Telugu language switcher, and Community placeholder.
- Build React 19 + Vite 8 + Tailwind admin dashboard in `admin-dashboard/` with KPI metrics cards, Leaflet pond geo-map, Recharts analytics, Market Prices management, and Admin Announcements broadcast.
- Provide release build automation script `scripts/build_release.ps1`.

## Acceptance Criteria

### Automated Verification & Integrity
- [ ] `flutter analyze` or Dart static checks pass without unresolved imports or compile-breaking errors.
- [ ] Comprehensive unit test suite passes covering:
  - Theme tokens & Deep Ocean Matte styling
  - AuthService phone normalization & email mapping
  - OfflineSyncService FIFO queue limit (100 ops max) and payload structure
  - AlertSystem threshold evaluations (Urgent / Watch / Optimal)
  - FeedAIService 4-meal splits and tray adjustments
  - TeluguVoiceNLUService regex extraction from mixed Telugu/English phrases
  - GoRouter routing configuration
- [ ] `supabase/schema.sql` contains valid SQL definitions for all 14 tables, indexes, RLS policies, and the `increment_scan_count` function.
- [ ] Supabase Edge Functions (`prawndoc-ai` and `weather-intelligence`) contain complete TypeScript implementations with error and CORS handling.
- [ ] `admin-dashboard/` contains functional React components for Dashboard, Layout, Market Prices, and Announcements.

### Functional Guardrails
- [ ] No hardcoded Supabase credentials or API secrets in source files.
- [ ] Offline queue strictly preserves FIFO ordering and drops oldest entries when exceeding 100 ops.
- [ ] All user-visible strings support both English and Telugu localization keys.
- [ ] UI components strictly adhere to the Deep Ocean Matte color system.
