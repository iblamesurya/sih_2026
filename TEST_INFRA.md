# PrawnGuard.ai — Comprehensive Test Infrastructure (TEST_INFRA)

## 1. Overview & Architecture
PrawnGuard.ai utilizes a rigorous **4-Tier Testing Architecture** designed to guarantee end-to-end correctness, high availability, offline resilience, and domain precision across the entire enterprise aquaculture intelligence platform.

```
+----------------------------------------------------------------------------------------------------+
|                                  4-TIER E2E TESTING ARCHITECTURE                                   |
+----------------------------------------------------------------------------------------------------+
|                                                                                                    |
|  [ TIER 1: Feature Coverage ]                                                                      |
|  - Unit and isolated happy-path behavioral verification (>=5 test cases per feature).              |
|  - Validates Theme tokens, L10n bilingual parity, Auth mapping, Offline FIFO, AlertSystem,         |
|    Feed AI biomass & 4-meal splits, Telugu Voice NLU, Subscription quotas.                         |
|                                                                                                    |
|  [ TIER 2: Boundary & Corner Cases ]                                                               |
|  - Stress conditions, mathematical extremes, malformed inputs (>=5 test cases per feature).       |
|  - FIFO 100-queue overflow & oldest eviction, exact pH/DO/Ammonia thresholds, DOC & temp          |
|    clamping, mixed-script NLU strings, international & invalid phone rejection.                    |
|                                                                                                    |
|  [ TIER 3: Cross-Feature Pairwise Interactions ]                                                   |
|  - Subsystem integrations across 2+ coupled domains.                                               |
|  - OfflineSync + BaseRepository network failure queuing & drain, Voice NLU telemetry ->            |
|    AlertSystem evaluation, Feed AI calculations -> Feed log mutations, Subscription quota         |
|    decrement -> PrawnDoc scan gating.                                                              |
|                                                                                                    |
|  [ TIER 4: Real-World Application Workloads ]                                                      |
|  - End-to-end full farm lifecycle simulation.                                                      |
|  - Farmer day-in-the-life: 06:00 voice telemetry -> Alert triage -> Feed AI 4-meal plan ->         |
|    PrawnDoc scan -> Afternoon check-tray adjustment -> Evening expense log -> Harvest              |
|    cashflow & PrawnCredit scoring -> Offline reconnection sync drain.                              |
|                                                                                                    |
+----------------------------------------------------------------------------------------------------+
```

---

## 2. Feature Inventory Test Matrix

| Feature ID | Module & Component | Specification Source | Target Test Suite | Acceptance Criteria |
|---|---|---|---|---|
| **F-01** | Deep Ocean Matte Theme & Typography | `lib/core/theme/app_theme.dart` | Tier 1, Tier 4 | Colors (`#0A0A0B`, `#171717`, `#00E5FF`, `#10B981`, `#E55C5C`, `#E5B05C`, `#5C9EE5`), card border `0x14FFFFFF`, Space Grotesk + Outfit text styles |
| **F-02** | Bilingual Localization Subsystem | `lib/l10n/en.json`, `lib/l10n/te.json` | Tier 1 | 100% key parity between `en.json` and `te.json`, valid JSON syntax, Telugu UTF-8 characters |
| **F-03** | AuthService Phone Mapping | `lib/core/services/auth_service.dart` | Tier 1, Tier 2 | Indian phone normalization (`+91`, `0`, spaces, hyphens) -> 10 digits -> `<phone>@prawnguard.app`, strict error on invalid |
| **F-04** | OfflineSyncService FIFO Engine | `lib/core/services/offline_sync_service.dart` | Tier 1, Tier 2, Tier 3, Tier 4 | Max 100 items in `offline_queue`, strict FIFO eviction of oldest items upon overflow, sequential drain with backoff |
| **F-05** | BaseRepository SafeMutate | `lib/core/services/base_repository.dart` | Tier 3, Tier 4 | Intercepts `SocketException`, `TimeoutException`, `ClientException` -> enqueues mutation into `OfflineSyncService` |
| **F-06** | AlertSystem Threshold Engine | `lib/core/services/alert_system.dart` | Tier 1, Tier 2, Tier 3, Tier 4 | pH (7.0/7.5/8.5/9.0), DO (3.0/4.0), NH3 (0.05/0.10), Alkalinity (100/150) categorization into urgent, watch, optimal |
| **F-07** | FeedAIService Bio-Energetics | `lib/core/services/feed_ai_service.dart` | Tier 1, Tier 2, Tier 3, Tier 4 | Biomass calculation, DOC rate clamp (0.03-0.08), Temp scaling (<24°C, 24-32°C, >32°C), Tray adjustments (-20% to +10%), 4-meal split (20/30/30/20) |
| **F-08** | TeluguVoiceNLUService Engine | `lib/core/services/telugu_voice_nlu_service.dart` | Tier 1, Tier 2, Tier 3, Tier 4 | Code-mixed regex extraction for pond, DO, pH, salinity, temp, ammonia, feedKg across English & Telugu scripts |
| **F-09** | SubscriptionService Quota Gates | `lib/core/services/subscription_service.dart` | Tier 1, Tier 2, Tier 3, Tier 4 | Free tier limits (3 scans/day, 3 ponds, 5 feed calcs/mo, 3 reports/mo), Pro tier unlimited, upgrade prompts |
| **F-10** | Finance & PrawnCredit Ledger | `lib/features/finance/models/` | Tier 4 | Expense tracking, harvest revenue calculation, net profit formula (`Revenue - Expenses`), PrawnCredit tier scoring |

---

## 3. Test Suite Structure & File Organization

```
test/
├── core/
│   └── services/
│       ├── alert_system_test.dart
│       ├── auth_service_test.dart
│       ├── offline_sync_test.dart
│       └── subscription_service_test.dart
├── features/
│   └── finance/
│       └── finance_test.dart
└── e2e/
    ├── test_helpers.dart                     # Shared mock fixtures, data generators & simulators
    ├── tier1_feature_coverage_test.dart      # Tier 1: >=5 isolated tests per feature
    ├── tier2_boundary_corner_test.dart       # Tier 2: >=5 boundary/stress tests per feature
    ├── tier3_cross_feature_pairwise_test.dart # Tier 3: Pairwise subsystem integrations
    └── tier4_real_world_application_test.dart # Tier 4: Farm lifecycle day-in-the-life workload
```

---

## 4. Execution & Verification Protocol

### Test Runner Command
```powershell
flutter test test/e2e/
```

### Full Test Suite Command
```powershell
flutter test
```

### Static Analysis Command
```powershell
flutter analyze
```

### Pass / Fail Criteria
- **Pass**: 100% of all test assertions pass with 0 failures, 0 errors, and 0 warnings.
- **Fail**: Any assertion failure, unresolved compilation error, uncaught exception, or timeout.
