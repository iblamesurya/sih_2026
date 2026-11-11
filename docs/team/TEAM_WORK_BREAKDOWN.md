# PrawnGuard.ai — Production Work Breakdown & Team Assignment Document
**Smart India Hackathon (SIH 2026) | Enterprise Aquaculture Intelligence & FinTech Ecosystem**

---

| Metadata | Details |
|---|---|
| **Document Version** | 2.0.0 (Production Release Specification) |
| **Platform Target** | Mobile App (Flutter 3.x / Dart) & Web Admin Portal (React 19 / Vite 8 / Tailwind CSS v4) |
| **Backend Architecture** | Supabase BaaS (PostgreSQL 15 + RLS), Deno Edge Functions, SharedPreferences FIFO Queue |
| **Authoritative Lead** | Surya Tummala (`@iblamesurya` — Platform Lead & Principal Architect) |
| **Team Size** | 1 Platform Lead + 5 Modular Leaf Developers |
| **Repository Path** | `c:\Users\tummala surya\sih_2026` |
| **Target Distribution** | Android Play Store (AAB), Web Admin (Docker/Cloud Run), Supabase Managed Cloud |

---

## Table of Contents

1. [Executive Summary & Architectural Separation](#1-executive-summary--architectural-separation)
   - 1.1 [Aquaculture Domain Problem Statement](#11-aquaculture-domain-problem-statement)
   - 1.2 [Core Platform vs. Modular Leaf Component Architecture](#12-core-platform-vs-modular-leaf-component-architecture)
   - 1.3 [Core Platform Asset Inventory (Platform Lead Surya)](#13-core-platform-asset-inventory-platform-lead-surya)
   - 1.4 [Deep Ocean Matte Design System Tokens](#14-deep-ocean-matte-design-system-tokens)
2. [5-Developer Assignment & Functional Ownership Matrix](#2-5-developer-assignment--functional-ownership-matrix)
3. [Developer 1: Admin Dashboard Shell & Global KPIs (Varshith Reddy)](#3-developer-1-admin-dashboard-shell--global-kpis-varshith-reddy)
   - 3.1 [Task Boundaries & Deliverables](#31-task-boundaries--deliverables)
   - 3.2 [File Ownership Matrix](#32-file-ownership-matrix)
   - 3.3 [Multi-Language Data Contracts](#33-multi-language-data-contracts)
   - 3.4 [Mock vs. Live Execution Strategy](#34-mock-vs-live-execution-strategy)
   - 3.5 [Step-by-Step Developer Starting Guide](#35-step-by-step-developer-starting-guide)
4. [Developer 2: Ponds Management & Telemetry UI (Poojitha)](#4-developer-2-ponds-management--telemetry-ui-poojitha)
   - 4.1 [Task Boundaries & Deliverables](#41-task-boundaries--deliverables)
   - 4.2 [File Ownership Matrix](#42-file-ownership-matrix)
   - 4.3 [Multi-Language Data Contracts](#43-multi-language-data-contracts)
   - 4.4 [Mock vs. Live Execution Strategy](#44-mock-vs-live-execution-strategy)
   - 4.5 [Step-by-Step Developer Starting Guide](#45-step-by-step-developer-starting-guide)
5. [Developer 3: Admin Market Prices & Announcements (Pragna)](#5-developer-3-admin-market-prices--announcements-pragna)
   - 5.1 [Task Boundaries & Deliverables](#51-task-boundaries--deliverables)
   - 5.2 [File Ownership Matrix](#52-file-ownership-matrix)
   - 5.3 [Multi-Language Data Contracts](#53-multi-language-data-contracts)
   - 5.4 [Mock vs. Live Execution Strategy](#54-mock-vs-live-execution-strategy)
   - 5.5 [Step-by-Step Developer Starting Guide](#55-step-by-step-developer-starting-guide)
6. [Developer 4: More Hub, Profile Settings, i18n & Community (Thanush Reddy)](#6-developer-4-more-hub-profile-settings-i18n--community-thanush-reddy)
   - 6.1 [Task Boundaries & Deliverables](#61-task-boundaries--deliverables)
   - 6.2 [File Ownership Matrix](#62-file-ownership-matrix)
   - 6.3 [Multi-Language Data Contracts](#63-multi-language-data-contracts)
   - 6.4 [Mock vs. Live Execution Strategy](#64-mock-vs-live-execution-strategy)
   - 6.5 [Step-by-Step Developer Starting Guide](#65-step-by-step-developer-starting-guide)
7. [Developer 5: PrawnCredit & Farm Finance Ledger (Vishnu Nalluri)](#7-developer-5-prawncredit--farm-finance-ledger-vishnu-nalluri)
   - 7.1 [Task Boundaries & Deliverables](#71-task-boundaries--deliverables)
   - 7.2 [File Ownership Matrix](#72-file-ownership-matrix)
   - 7.3 [Multi-Language Data Contracts](#73-multi-language-data-contracts)
   - 7.4 [Mock vs. Live Execution Strategy](#74-mock-vs-live-execution-strategy)
   - 7.5 [Step-by-Step Developer Starting Guide](#75-step-by-step-developer-starting-guide)
8. [Dependency Boundaries, Branching & Integration Protocol](#8-dependency-boundaries-branching--integration-protocol)
   - 8.1 [Zero-Conflict Branching Strategy](#81-zero-conflict-branching-strategy)
   - 8.2 [Protected Core Rules](#82-protected-core-rules)
   - 8.3 [PR Merge Ordering & Integration Sequence](#83-pr-merge-ordering--integration-sequence)
   - 8.4 [CI/CD Quality Gate Enforcement](#84-cicd-quality-gate-enforcement)
9. [Verification & Testing Standards](#9-verification--testing-standards)
10. [Document Index & Cross-References](#10-document-index--cross-references)

---

## 1. Executive Summary & Architectural Separation

### 1.1 Aquaculture Domain Problem Statement

PrawnGuard.ai (AquaVerse) addresses critical systemic pain points faced by commercial shrimp farmers (*Litopenaeus vannamei* and *Penaeus monodon*) across coastal Andhra Pradesh (West Godavari, Krishna, Bapatla, Nellore) and greater India:

1. **Catastrophic Disease Collapses:** Outbreaks of White Spot Syndrome Virus (WSSV), White Gut (WFS), Enterocytozoon hepatopenaei (EHP), Running Mortality Syndrome (RMS), Black Gill, and Vibriosis decimate crops worth ₹15–18 Lakh per acre within 24–48 hours. Remote lab testing typically requires 48–72 hours.
2. **Feed Cost Bleed & Water Degradation:** Feed accounts for 60–70% of operational expenditure (~₹1.95 Lakh/ton). Inaccurate broadcast feeding produces ₹1.5 Lakhs in annual waste per pond, accumulating sludge and generating lethal unionized ammonia ($NH_3$).
3. **Nocturnal Hypoxia Mortalities:** Dissolved Oxygen (DO) crashes precipitously between 02:00 AM and 05:00 AM due to phytoplankton respiration and calm weather, leading to sudden morning die-offs without proactive aeration management.
4. **Connectivity & Literacy Obstacles:** Prawn ponds operate in remote coastal zones with frequent complete cellular dropouts. Farmers require offline-first persistence with automatic background sync and voice-first telemetry logging in spoken Telugu.
5. **Predatory Farm-Gate Price Exploitation:** Local middleman syndicates exploit information asymmetry regarding daily count prices (30c, 40c, 50c, 100c), depriving farmers of ₹1.0–1.25 Lakhs per harvest.

---

### 1.2 Core Platform vs. Modular Leaf Component Architecture

To guarantee **zero merge conflicts** and parallel engineering speed, the project employs **Approach A (Horizontal Layer Separation)**:

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   CORE PLATFORM & SHARED SERVICES                                  │
│                                  Lead Architect: Surya (@iblamesurya)                              │
│                                                                                                    │
│  ┌───────────────────────────────┐  ┌────────────────────────────────┐  ┌────────────────────────┐  │
│  │ Supabase BaaS                 │  │ 16 Singleton Core Services     │  │ Central State & Shell  │  │
│  │ • 15 Tables + RLS Policies    │  │ • OfflineSync FIFO Queue (100) │  │ • Riverpod Providers   │  │
│  │ • Atomic RPC Quota Functions  │  │ • AuthService (Phone OTP +91)  │  │ • GoRouter 5-Tab Shell │  │
│  │ • 2 Deno Edge Functions (AI)  │  │ • AlertSystem & Emergency Siren│  │ • Deep Ocean Matte UI  │  │
│  └───────────────────────────────┘  └────────────────────────────────┘  └────────────────────────┘  │
└──────────────────┬───────────────────┬───────────────────┬───────────────────┬─────────────────────┘
                   │                   │                   │                   │
                   ▼                   ▼                   ▼                   ▼
    ┌───────────────────────────┐ ┌───────────────┐ ┌───────────────────┐ ┌───────────────┐ ┌───────────────┐
    │        DEVELOPER 1        │ │  DEVELOPER 2  │ │    DEVELOPER 3    │ │  DEVELOPER 4  │ │  DEVELOPER 5  │
    │      Varshith Reddy       │ │   Poojitha    │ │      Pragna       │ │ Thanush Reddy │ │ Vishnu Nalluri│
    │ @2400031215-VarshithReddy │ │ @Poojitha8006 │ │   @TummaPragna    │ │@thanushreddy..│ │@VishnuNalluri │
    │                           │ │               │ │                   │ │               │ │               │
    │     feat/admin-shell      │ │ feat/ponds-ui │ │feat/market-annou..│ │feat/more-prof.│ │feat/finance-ui│
    │    React 19 + Vite 8      │ │ Flutter/Dart  │ │ React 19 + Vite 8 │ │ Flutter/Dart  │ │ Flutter/Dart  │
    │                           │ │               │ │                   │ │               │ │               │
    │ Admin Shell, Global KPIs, │ │ Ponds List &  │ │ Mandi Price Mgmt, │ │ More Hub,     │ │ PrawnCredit,  │
    │ Sparklines & Farm Map     │ │ Telemetry UI  │ │ Regional Advisory │ │ Profile & te  │ │ Farm Finance  │
    └───────────────────────────┘ └───────────────┘ └───────────────────┘ └───────────────┘ └───────────────┘
```

- **Platform Lead Surya (70% Heavy Lifting):** Owns database integrity, cloud security policies, background synchronizers, Deno AI compute, navigation shells, and master provider graphs.
- **5 Modular Leaf Developers (30% Parallel Feature Buildout):** Build self-contained user interface views and modals. Developers work exclusively on their assigned files with mock fallback data, isolated branches, and strictly read-only access to core services.

---

### 1.3 Core Platform Asset Inventory (Platform Lead Surya)

The following components are fully maintained and protected by the Platform Lead. **Leaf developers are strictly forbidden from modifying these files.**

#### 1. 15 Supabase Relational Database Tables (`supabase/schema.sql`)
1. `profiles`: User identities, Indian phone numbers (+91), subscription tier (`free` vs `pro`), daily scan counter, GPS coordinates, district.
2. `farms`: Registered farm holdings, total acreage, registered water intake sources, geolocation coordinates.
3. `ponds`: Active cultivation ponds (`pond_1`, `pond_2`), species (`L. vannamei` / `P. monodon`), water area, stocking density, DOC, survival rate.
4. `crop_cycles`: Stocking batches, hatchery origins, seed PL stages (PL10–PL15), target harvest dates, cycle status.
5. `water_logs`: High-frequency water quality telemetry records (pH, DO, salinity, temperature, ammonia, alkalinity, turbidity).
6. `feed_logs`: Meal-by-meal feed tracking, feed brand names, check-tray leftover feedback (-20% to +10%).
7. `disease_scans`: Diagnostic vision scans, MD5 image hash, pathology classification, confidence %, treatment advisories.
8. `growth_samples`: Periodic sampling measurements for Average Body Weight (ABW) and size distribution curves.
9. `abw_samples`: Cast-net camera sampling and AI vision size estimates.
10. `expenses`: Operational farm ledger records (feed, seed PL, electricity/diesel, probiotics/chemicals, labor).
11. `harvests`: Crop harvest records, total biomass (kg), count size, buyer/exporter details, price/kg, FCR.
12. `market_prices`: Regional Andhra Pradesh daily mandi procurement rates across count grades (30c–100c).
13. `admin_announcements`: High-priority biosecurity outbreak alerts, cyclone warnings, and government subsidy broadcasts.
14. `activity_events`: Audit trail for farmer actions and edge triggers.
15. `notification_preferences`: Multi-channel notification settings (push, SMS, emergency sirens).
- **Atomic Database Functions (RPC):** `increment_scan_count(p_user_id, p_scan_date)` for atomic quota tracking.

#### 2. Deno Serverless Edge Functions (`supabase/functions/`)
- `prawndoc-ai/index.ts`: Multimodal shrimp pathology diagnostics utilizing Google Gemini 1.5 Flash. Compresses images to 768px JPEG q75, computes MD5 hash for deduplication, injects real-time pond water telemetry RAG context (pH, DO, Ammonia), enforces prompt-injection sanitization, and extracts clean JSON.
- `weather-intelligence/index.ts`: 15-minute in-memory caching for OpenWeatherMap API, regional aquaculture weather conditions, and predictive nocturnal hypoxia risk modeling.

#### 3. 16 Dart Core Singleton Services (`lib/core/services/`)
- `SupabaseClientService` (`supabase_client.dart`): Supabase SDK client singleton.
- `AuthService` (`auth_service.dart`): E.164 phone normalization (+91, 10 digits) and mapping to `<phone>@prawnguard.app` for Supabase OTP.
- `OfflineSyncService` (`offline_sync_service.dart`): Thread-safe FIFO mutation queue (capacity: 100) in `SharedPreferences` with exponential backoff drain.
- `BaseRepository` (`base_repository.dart`): Safe network mutations (`safeMutate<T>`) diverting failed operations to `OfflineSyncService`.
- `FarmDataRepository` (`farm_data_repository.dart`): Repository for all Supabase tables with in-memory TTL caching and graceful offline fallback.
- `RealtimeService` (`realtime_service.dart`): Realtime WebSocket listeners for tables (`water_logs`, `feed_logs`, `disease_scans`).
- `DataHydrationService` (`data_hydration_service.dart`): Local snapshot serialization and remote hydration coordinator.
- `AlertSystem` (`alert_system.dart`): Scientific water parameter threshold evaluation (`optimal`, `watch`, `urgent`).
- `EmergencyAlarmService` (`emergency_alarm_service.dart`): Full-screen emergency sirens and haptic alerts for DO crashes (< 3.0 ppm) and ammonia surges (> 0.1 ppm).
- `FeedAIService` (`feed_ai_service.dart`): Bio-energetic biomass calculation, 4-meal daily schedule (06:00, 11:00, 16:00, 21:00), temperature multipliers, and check-tray feedback loops.
- `PrawnDocAIService` (`prawndoc_ai_service.dart`): Client-side image preprocessing, quota validation, edge function proxy, and fallback diagnostic knowledge base for 12 shrimp diseases.
- `TeluguVoiceNLUService` (`telugu_voice_nlu_service.dart`): Code-mixed Telugu/English regex parser for telemetry extraction (`DO`, `pH`, `ammonia`, `feedKg`).
- `WeatherService` (`weather_service.dart`): Weather intelligence client with offline fallback.
- `LocationService` (`location_service.dart`): Geolocation with fallback to primary aquaculture hubs (Bhimavaram, Nellore, Surat).
- `SubscriptionService` (`subscription_service.dart`): Free vs Pro tier quota rules (3 daily scans, 3 ponds max, 5 feed calcs/mo).
- `LoggerService` (`logger_service.dart`): Centralized structured telemetry logging.

#### 4. Navigation Shell, State Registry & Bootstrap
- `AppRouter` (`lib/core/router/app_router.dart`): GoRouter 14.x 5-tab `StatefulShellRoute` (`/home`, `/ponds`, `/feed`, `/prawndoc`, `/more`) and modal standalone routes (`/login`, `/onboarding`, `/quick-log`, `/finance`, `/weather`, `/reports`, `/upgrade`, `/admin`, `/community`, `/market-prices`, `/abw-sampling`, `/add-pond`, `/pond/:id`).
- `AppProviders` (`lib/core/providers/app_providers.dart`): Central Riverpod registry for services, session state (`currentUserProvider`, `currentFarmProvider`, `currentLocaleProvider`), entity lists (`pondListProvider`, `waterLogsProvider`, `expensesProvider`, `harvestsProvider`, `alertsProvider`), and the global `clearAllUserData(ref)` sign-out handler.
- `AppTheme` (`lib/core/theme/app_theme.dart`): Deep Ocean Matte styling tokens.
- `lib/main.dart`: Application bootstrap and error boundary setup.

---

### 1.4 Deep Ocean Matte Design System Tokens

All user interfaces across both Flutter mobile and React web must adhere strictly to the **Deep Ocean Matte** design system:

```
┌───────────────────────┬──────────────┬────────────────────────────────────────────────────────┐
│ Token Identifier      │ Hex / Value  │ Semantic Application                                   │
├───────────────────────┼──────────────┼────────────────────────────────────────────────────────┤
│ background            │ #0A0A0B      │ Primary canvas background (prevents glare on ponds)   │
│ backgroundSecondary   │ #0F0F0F      │ Secondary screen regions and card backdrops            │
│ surface               │ #171717      │ Component cards, dialogs, bottom sheets, navigation    │
│ surfaceLight          │ #222222      │ Nested list items, elevated containers, input fills    │
│ border                │ #2A2A2A      │ Subtle divider lines and structural borders            │
│ primary               │ #00E5FF      │ Electric Cyan accent: primary CTA, active states       │
│ secondary             │ #10B981      │ Emerald Green: optimal status, healthy metrics, profit │
│ alertUrgent           │ #E55C5C      │ Coral Red: critical alerts, DO crash, emergency sirens │
│ alertWatch            │ #E5B05C      │ Amber Yellow: watch warnings, caution thresholds       │
│ alertInfo             │ #5C9EE5      │ Sky Blue: informational banners, general notices       │
│ textPrimary           │ #FFFFFF      │ Primary headings, vital metrics, hero figures          │
│ textSecondary         │ #9E9E9E      │ Subtitles, field labels, metadata timestamps           │
│ textTertiary          │ #616161      │ Inactive icons, placeholder hints                      │
│ glassEffect           │ rgba(255,255,255,0.05) + blur(16px) │ Translucent overlay styling     │
│ typographyHeading     │ Space Grotesk│ Numerical values, KPI figures, screen titles           │
│ typographyBody        │ Outfit       │ Body prose, descriptions, form field labels            │
└───────────────────────┴──────────────┴────────────────────────────────────────────────────────┘
```

---

## 2. 5-Developer Assignment & Functional Ownership Matrix

| Developer | Role & GitHub Handle | Assigned Module | Platform / Stack | Branch Name | Primary Files Written |
|---|---|---|---|---|---|
| **Dev 1** | **Varshith Reddy**<br>(`@2400031215-VarshithReddy`) | Admin Dashboard Shell & Global Analytics | React 19 + Vite 8<br>Tailwind CSS v4<br>Recharts | `feat/admin-shell` | `admin-dashboard/src/pages/Dashboard.jsx`<br>`admin-dashboard/src/components/Layout.jsx`<br>`admin-dashboard/src/pages/FarmMap.jsx` |
| **Dev 2** | **Poojitha**<br>(`@Poojitha8006`) | Ponds Management & Telemetry UI | Flutter 3.x / Dart<br>Riverpod 2.x | `feat/ponds-ui` | `lib/features/ponds/presentation/pages/pond_list_page.dart`<br>`lib/features/ponds/presentation/pages/pond_detail_page.dart`<br>`lib/features/ponds/presentation/pages/add_pond_modal.dart`<br>`lib/features/ponds/presentation/pages/telemetry_logging_page.dart` |
| **Dev 3** | **Pragna**<br>(`@TummaPragna`) | Admin Market Prices & Announcements | React 19 + Vite 8<br>Tailwind CSS v4<br>Lucide React | `feat/market-announcements` | `admin-dashboard/src/pages/MarketPrices.jsx`<br>`admin-dashboard/src/pages/Announcements.jsx` |
| **Dev 4** | **Thanush Reddy**<br>(`@thanushreddyseelam`) | More Hub, Profile Settings, i18n & Community | Flutter 3.x / Dart<br>Riverpod 2.x<br>Bilingual JSON | `feat/more-profile-i18n` | `lib/features/more/presentation/pages/more_page.dart`<br>`lib/features/more/presentation/pages/profile_settings_page.dart`<br>`lib/l10n/en.json`<br>`lib/l10n/te.json`<br>`lib/features/community/presentation/pages/community_page.dart` |
| **Dev 5** | **Vishnu Nalluri**<br>(`@VishnuNalluri-27`) | PrawnCredit & Farm Finance Ledger | Flutter 3.x / Dart<br>Riverpod 2.x | `feat/finance-ui` | `lib/features/finance/PrawnCreditPage.dart`<br>`lib/features/finance/widgets/ExpenseForm.dart`<br>`lib/features/finance/widgets/HarvestCard.dart`<br>`lib/features/finance/models/finance_models.dart` |

---

## 3. Developer 1: Admin Dashboard Shell & Global KPIs (Varshith Reddy)

- **Assignee:** Varshith Reddy (`@2400031215-VarshithReddy`)
- **Assigned Feature Branch:** `feat/admin-shell`
- **Technology Stack:** React 19, Vite 8, Tailwind CSS v4, Lucide React, Recharts, Leaflet

### 3.1 Task Boundaries & Deliverables
1. **Administrative Shell Layout (`Layout.jsx`):**
   - Responsive sidebar with collapsible mobile drawer.
   - Deep Ocean Matte navigation styling with active route indicators in Electric Cyan (`#00E5FF`).
   - Top navigation bar showing admin profile avatar, system status badge, and network latency indicator.
2. **Global KPI Metric Cards (`Dashboard.jsx`):**
   - Render 4 primary KPI cards:
     - **Active Ponds:** Numerical metric with 7-day sparkline in `#00E5FF`.
     - **Registered Farmers:** Metric with 7-day sparkline in `#10B981`.
     - **Scans Today:** Metric with 7-day sparkline in `#5C9EE5`.
     - **Urgent Alarms:** Metric with 7-day sparkline in `#E55C5C`.
   - Mini `AreaChart` sparklines using Recharts with smooth gradients and zero axis clutter.
3. **Recent Disease Scans Feed:**
   - Table displaying recent farm scans with pathology name, Telugu subtitle, pond identifier, timestamp, and severity badge (`Urgent`, `Watch`, `Optimal`).
4. **Interactive Farm Geospatial Map (`FarmMap.jsx`):**
   - React-Leaflet component centered on Bhimavaram (`16.5449°N, 81.5212°E`).
   - Color-coded pond markers based on risk level.

### 3.2 File Ownership Matrix
- **Exclusive Write Access:**
  - `admin-dashboard/src/pages/Dashboard.jsx`
  - `admin-dashboard/src/components/Layout.jsx`
  - `admin-dashboard/src/pages/FarmMap.jsx`
- **Strictly Read-Only Access:**
  - `admin-dashboard/src/lib/supabase.js`
  - `admin-dashboard/src/pages/MarketPrices.jsx` (Dev 3)
  - `admin-dashboard/src/pages/Announcements.jsx` (Dev 3)
  - All files in `lib/**`, `supabase/**`

### 3.3 Multi-Language Data Contracts

#### TypeScript Interface (`admin-dashboard/src/types/dashboard.ts`)
```typescript
export interface SparklinePoint {
  val: number;
}

export type TrendChangeType = 'positive' | 'negative' | 'neutral' | 'neutral-positive';

export interface KPICardMetric {
  id: 'ponds' | 'farmers' | 'scans' | 'alerts';
  title: string;
  value: string;
  change: string;
  changeType: TrendChangeType;
  timeframe: string;
  accentColor: string;
  accentBg: string;
  data: SparklinePoint[];
  gradientId: string;
}

export interface RecentScanItem {
  id: string;
  disease: string;
  teluguName: string;
  severity: 'Urgent' | 'Watch' | 'Optimal';
  confidence: number;
  pond: string;
  location: string;
  time: string;
}

export interface AdminDashboardState {
  kpis: KPICardMetric[];
  recentScans: RecentScanItem[];
  systemHealth: {
    edgeStatus: 'operational' | 'degraded' | 'offline';
    dbLatencyMs: number;
    activeRealtimeSockets: number;
  };
}
```

#### Pydantic v2 Model (`models/pydantic/admin_dashboard.py`)
```python
from enum import Enum
from typing import List, Literal
from pydantic import BaseModel, Field

class TrendChangeType(str, Enum):
    POSITIVE = "positive"
    NEGATIVE = "negative"
    NEUTRAL = "neutral"
    NEUTRAL_POSITIVE = "neutral-positive"

class SparklinePoint(BaseModel):
    val: float = Field(..., ge=0.0, description="Metric value point")

class KPICardMetric(BaseModel):
    id: Literal["ponds", "farmers", "scans", "alerts"]
    title: str = Field(..., min_length=1)
    value: str = Field(..., min_length=1)
    change: str
    change_type: TrendChangeType = Field(alias="changeType")
    timeframe: str
    accent_color: str = Field(alias="accentColor", pattern="^#([A-Fa-f0-9]{6})$")
    accent_bg: str = Field(alias="accentBg")
    data: List[SparklinePoint]
    gradient_id: str = Field(alias="gradientId")

class RecentScanItem(BaseModel):
    id: str
    disease: str
    telugu_name: str = Field(alias="teluguName")
    severity: Literal["Urgent", "Watch", "Optimal"]
    confidence: float = Field(..., ge=0.0, le=1.0)
    pond: str
    location: str
    time: str

class AdminDashboardPayload(BaseModel):
    kpis: List[KPICardMetric]
    recent_scans: List[RecentScanItem] = Field(alias="recentScans")
```

#### JSON Schema (Draft 2020-12) (`schemas/admin_dashboard.json`)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://prawnguard.app/schemas/admin_dashboard.json",
  "title": "AdminDashboardMetrics",
  "type": "object",
  "required": ["kpis", "recentScans"],
  "properties": {
    "kpis": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "title", "value", "change", "changeType", "accentColor", "data"],
        "properties": {
          "id": { "type": "string", "enum": ["ponds", "farmers", "scans", "alerts"] },
          "title": { "type": "string" },
          "value": { "type": "string" },
          "change": { "type": "string" },
          "changeType": { "type": "string", "enum": ["positive", "negative", "neutral", "neutral-positive"] },
          "timeframe": { "type": "string" },
          "accentColor": { "type": "string", "pattern": "^#([A-Fa-f0-9]{6})$" },
          "data": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["val"],
              "properties": { "val": { "type": "number", "minimum": 0 } }
            }
          }
        }
      }
    },
    "recentScans": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "disease", "severity", "confidence", "pond"],
        "properties": {
          "id": { "type": "string" },
          "disease": { "type": "string" },
          "teluguName": { "type": "string" },
          "severity": { "type": "string", "enum": ["Urgent", "Watch", "Optimal"] },
          "confidence": { "type": "number", "minimum": 0, "maximum": 1 },
          "pond": { "type": "string" },
          "location": { "type": "string" },
          "time": { "type": "string" }
        }
      }
    }
  }
}
```

#### Dart Riverpod State Contract
```dart
// Dart equivalence for mobile admin preview:
class AdminKpiState {
  final int activePonds;
  final int registeredFarmers;
  final int scansToday;
  final int urgentAlarms;

  const AdminKpiState({
    required this.activePonds,
    required this.registeredFarmers,
    required this.scansToday,
    required this.urgentAlarms,
  });
}
```

### 3.4 Mock vs. Live Execution Strategy
- **Mock Mode Strategy:**
  - `admin-dashboard/src/pages/Dashboard.jsx` embeds self-contained mock constants (`pondsSparkline`, `farmersSparkline`, `scansSparkline`, `alertsSparkline`, `RECENT_SCANS`).
  - When `VITE_SUPABASE_URL` is unconfigured, `Dashboard.jsx` immediately renders the static mock data. Zero network errors are thrown; all sparklines and layout views mount cleanly.
- **Live Mode Strategy:**
  - When configured, queries `admin-dashboard/src/lib/supabase.js`:
    ```javascript
    const { count: pondsCount } = await supabase.from('ponds').select('*', { count: 'exact', head: true });
    const { count: farmersCount } = await supabase.from('profiles').select('*', { count: 'exact', head: true });
    const { data: recentScans } = await supabase.from('disease_scans').select('*').order('created_at', { ascending: false }).limit(10);
    ```
  - Subscribes to Realtime Postgres Changes on the `disease_scans` table to update alert indicators without page refresh.

### 3.5 Step-by-Step Developer Starting Guide
```bash
# 1. Clone repository and checkout feature branch
git clone https://github.com/iblamesurya/sih_2026.git
cd sih_2026
git checkout feat/admin-shell

# 2. Navigate to admin dashboard and install dependencies
cd admin-dashboard
npm install

# 3. Run in mock mode (isolation)
npm run dev
# Browser opens http://localhost:5173

# 4. (Optional) Run with live Supabase credentials
# Create admin-dashboard/.env with:
# VITE_SUPABASE_URL=https://your-project.supabase.co
# VITE_SUPABASE_ANON_KEY=your-anon-public-key
npm run dev

# 5. Verify production build
npm run build

# 6. Push and create PR
git add src/pages/Dashboard.jsx src/components/Layout.jsx src/pages/FarmMap.jsx
git commit -m "feat(admin-shell): implement responsive layout, KPI sparklines and farm map"
git push origin feat/admin-shell
gh pr create --draft --title "[feat/admin-shell] Admin Dashboard Shell & Global KPIs" --reviewer iblamesurya
```

---

## 4. Developer 2: Ponds Management & Telemetry UI (Poojitha)

- **Assignee:** Poojitha (`@Poojitha8006`)
- **Assigned Feature Branch:** `feat/ponds-ui`
- **Technology Stack:** Flutter 3.x, Dart 3.x, Riverpod 2.x, GoRouter, Deep Ocean Matte Tokens

### 4.1 Task Boundaries & Deliverables
1. **Pond Overview Screen (`pond_list_page.dart`):**
   - Renders active pond cards showing pond name, area in hectares (`ha`), stocking density, DOC counter, and color-coded status badge (`Optimal`, `Watch`, `Urgent`).
   - Floating Action Button (+) opening the Add Pond modal sheet.
2. **Pond Telemetry & Historical Trends (`pond_detail_page.dart`):**
   - High-contrast parameter gauges for Dissolved Oxygen (`DO`), pH, Salinity, Temperature, Ammonia, and Alkalinity.
   - Historical line graph displaying parameter oscillations over the last 24 hours.
3. **Add Pond Modal Bottom Sheet (`add_pond_modal.dart`):**
   - Modal form with strict input validation: Pond Name (required), Area in ha (> 0), Stocking Count (> 0), Seed DOC (≥ 0), Species selector (`L. vannamei` / `P. monodon`).
   - Subscription quota check: Warns if Free Tier quota (max 3 ponds) is exceeded.
4. **Water Telemetry Logging Screen (`telemetry_logging_page.dart`):**
   - Numeric input fields for DO (ppm), pH, Salinity (ppt), Temperature (°C), Ammonia (ppm), Alkalinity (ppm).
   - Telugu voice logging microphone button connecting to `teluguVoiceNluProvider`.

### 4.2 File Ownership Matrix
- **Exclusive Write Access:**
  - `lib/features/ponds/presentation/pages/pond_list_page.dart`
  - `lib/features/ponds/presentation/pages/pond_detail_page.dart`
  - `lib/features/ponds/presentation/pages/add_pond_modal.dart`
  - `lib/features/ponds/presentation/pages/telemetry_logging_page.dart`
  - `lib/features/ponds/presentation/pages/abw_camera_sampling_page.dart`
- **Strictly Read-Only Access:**
  - `lib/core/providers/app_providers.dart`
  - `lib/core/services/*`
  - `supabase/*`
  - All other feature directories (`lib/features/finance/*`, `lib/features/more/*`)

### 4.3 Multi-Language Data Contracts

#### TypeScript Interface (`types/ponds.ts`)
```typescript
export interface PondEntity {
  id: string; // e.g. "pond_1725000000"
  userId?: string;
  farmId?: string;
  name: string; // e.g. "Pond 1 (North Field)"
  species: 'Litopenaeus vannamei' | 'Penaeus monodon';
  areaHa: number; // e.g. 1.2
  stockingDensity: number; // post-larvae per m2 (e.g. 50)
  doc: number; // Days of Culture (e.g. 45)
  stockingDate: string; // ISO 8601
  initialAbw: number; // in grams (e.g. 0.02)
  currentAbw?: number; // in grams (e.g. 14.5)
  survivalRate?: number; // 0.0 to 1.0 (default 0.85)
  status: 'Optimal' | 'Watch' | 'Urgent' | 'Harvested' | 'Fallow';
  latitude?: number;
  longitude?: number;
  locationName?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface WaterLogEntity {
  id: string;
  pondId: string;
  ph: number; // 0.0 to 14.0
  dissolvedOxygen: number; // mg/L (optimal > 4.0, critical < 3.0)
  salinity: number; // ppt
  temperature: number; // Celsius
  ammonia: number; // ppm (optimal < 0.05, critical > 0.1)
  alkalinity: number; // ppm (optimal 100 - 150)
  turbidityCm?: number;
  overallSeverity: 'optimal' | 'watch' | 'urgent';
  source: 'manual' | 'voice_nlu' | 'iot_sensor';
  recordedAt: string; // ISO 8601
}
```

#### Pydantic v2 Model (`models/pydantic/ponds.py`)
```python
from enum import Enum
from typing import Optional, Literal
from pydantic import BaseModel, Field

class PondStatus(str, Enum):
    OPTIMAL = "Optimal"
    WATCH = "Watch"
    URGENT = "Urgent"
    HARVESTED = "Harvested"
    FALLOW = "Fallow"

class WaterLogSeverity(str, Enum):
    OPTIMAL = "optimal"
    WATCH = "watch"
    URGENT = "urgent"

class PondModel(BaseModel):
    id: str = Field(..., pattern=r"^(pond_|\d+)")
    user_id: Optional[str] = None
    farm_id: Optional[str] = None
    name: str = Field(..., min_length=2, max_length=100)
    species: str = Field(default="Litopenaeus vannamei")
    area_ha: float = Field(..., gt=0.0, description="Area in hectares")
    stocking_density: float = Field(..., ge=0.0, description="PL count per m2")
    doc: int = Field(..., ge=0, description="Days of culture")
    stocking_date: Optional[str] = None
    initial_abw: float = Field(default=0.02, ge=0.0)
    current_abw: Optional[float] = Field(default=None, ge=0.0)
    survival_rate: float = Field(default=0.85, ge=0.0, le=1.0)
    status: PondStatus = PondStatus.OPTIMAL
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location_name: Optional[str] = None
    created_at: str

class WaterLogModel(BaseModel):
    id: str = Field(..., pattern=r"^(wlog_|log_)")
    pond_id: str
    ph: float = Field(..., ge=0.0, le=14.0)
    dissolved_oxygen: float = Field(..., ge=0.0, le=30.0, alias="dissolvedOxygen")
    salinity: float = Field(..., ge=0.0, le=60.0)
    temperature: float = Field(..., ge=0.0, le=50.0)
    ammonia: float = Field(..., ge=0.0, le=20.0)
    alkalinity: float = Field(..., ge=0.0, le=500.0)
    turbidity_cm: Optional[float] = Field(default=None, ge=0.0, alias="turbidityCm")
    overall_severity: WaterLogSeverity = Field(default=WaterLogSeverity.OPTIMAL, alias="overallSeverity")
    source: Literal["manual", "voice_nlu", "iot_sensor"] = "manual"
    recorded_at: str = Field(alias="recordedAt")
```

#### JSON Schema (Draft 2020-12) (`schemas/ponds.json`)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://prawnguard.app/schemas/ponds.json",
  "title": "PondAndWaterTelemetry",
  "type": "object",
  "definitions": {
    "Pond": {
      "type": "object",
      "required": ["id", "name", "areaHa", "stockingDensity", "doc", "status"],
      "properties": {
        "id": { "type": "string" },
        "name": { "type": "string", "minLength": 2 },
        "species": { "type": "string" },
        "areaHa": { "type": "number", "exclusiveMinimum": 0 },
        "stockingDensity": { "type": "number", "minimum": 0 },
        "doc": { "type": "integer", "minimum": 0 },
        "status": { "type": "string", "enum": ["Optimal", "Watch", "Urgent", "Harvested", "Fallow"] }
      }
    },
    "WaterLog": {
      "type": "object",
      "required": ["id", "pondId", "ph", "dissolvedOxygen", "salinity", "temperature", "ammonia"],
      "properties": {
        "id": { "type": "string" },
        "pondId": { "type": "string" },
        "ph": { "type": "number", "minimum": 0, "maximum": 14 },
        "dissolvedOxygen": { "type": "number", "minimum": 0, "maximum": 30 },
        "salinity": { "type": "number", "minimum": 0, "maximum": 60 },
        "temperature": { "type": "number", "minimum": 0, "maximum": 50 },
        "ammonia": { "type": "number", "minimum": 0, "maximum": 20 },
        "alkalinity": { "type": "number", "minimum": 0, "maximum": 500 }
      }
    }
  }
}
```

#### Dart Riverpod Provider Contracts (`lib/features/ponds/data_contracts.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provided by lib/core/providers/app_providers.dart:
// final pondListProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);
// final waterLogsProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);
// final alertsProvider = StateProvider<List<WaterAlert>>((ref) => []);
// final offlineSyncProvider = Provider<OfflineSyncService>((ref) => ...);

Map<String, dynamic> createPondMap({
  required String id,
  required String name,
  required double areaHa,
  required int stockingDensity,
  required int doc,
  required String species,
  required double initialAbw,
  required double latitude,
  required double longitude,
  required String locationName,
  String status = 'Optimal',
}) => {
  'id': id,
  'name': name,
  'areaHa': areaHa,
  'stockingDensity': stockingDensity,
  'doc': doc,
  'species': species,
  'initialAbw': initialAbw,
  'latitude': latitude,
  'longitude': longitude,
  'locationName': locationName,
  'status': status,
  'created_at': DateTime.now().toIso8601String(),
};
```

### 4.4 Mock vs. Live Execution Strategy
- **Mock Mode Strategy:**
  - `PondListPage` includes an auto-seeding handler (`_loadDemoPonds(WidgetRef ref)`) initializing `pondListProvider` with 2 realistic demo ponds (North Field, South Field) and baseline water logs.
  - Adding a pond updates `ref.read(pondListProvider.notifier).state = [...state, newPond]` in memory.
  - Form validation, UI navigation, and charts execute locally with zero network calls.
- **Live Mode Strategy:**
  - Submitting `AddPondModal` enqueues the mutation to the offline sync manager:
    ```dart
    ref.read(offlineSyncProvider).enqueue({
      'table': 'ponds',
      'action': 'insert',
      'payload': newPond,
    });
    ```
  - If network connectivity is active, `OfflineSyncService` executes the POST request to Supabase REST immediately; if offline, it persists safely in the FIFO queue (capacity: 100).

### 4.5 Step-by-Step Developer Starting Guide
```bash
# 1. Clone repository and checkout feature branch
git clone https://github.com/iblamesurya/sih_2026.git
cd sih_2026
git checkout feat/ponds-ui

# 2. Fetch Flutter dependencies
flutter pub get

# 3. Run in mock mode (isolation)
flutter run -d chrome
# or: flutter run -d <connected-android-device>

# 4. Verify Ponds UI flow
# - Navigate to Ponds Tab
# - Verify demo ponds auto-populate
# - Tap "+" button and create a new pond
# - Inspect pond details and historical telemetry graph

# 5. Run test verification suite
flutter test test/core/providers/app_providers_test.dart
flutter test test/e2e/tier1_feature_coverage_test.dart

# 6. Push and create PR
git add lib/features/ponds/
git commit -m "feat(ponds-ui): implement pond list, telemetry graphs and add pond modal"
git push origin feat/ponds-ui
gh pr create --draft --title "[feat/ponds-ui] Ponds Management & Telemetry UI" --reviewer iblamesurya
```

---

## 5. Developer 3: Admin Market Prices & Announcements (Pragna)

- **Assignee:** Pragna (`@TummaPragna`)
- **Assigned Feature Branch:** `feat/market-announcements`
- **Technology Stack:** React 19, Vite 8, Tailwind CSS v4, Lucide React, Recharts, Supabase JS Client

### 5.1 Task Boundaries & Deliverables
1. **Mandi Market Prices Management (`MarketPrices.jsx`):**
   - Regional hub filter dropdown covering major Andhra Pradesh aquaculture trading hubs: Bhimavaram, Nellore, Kakinada, Machilipatnam, and Surat (Gujarat).
   - Price table listing count sizes (30c, 40c, 50c, 60c, 80c, 100c), buying rate in ₹/kg, 24-hour price change indicator, and demand badge (`Low`, `Moderate`, `Stable`, `High`, `Very High`).
   - 7-day historical price trend multi-line chart (Recharts) for 30 count, 40 count, and 50 count shrimp.
   - "Update Price" modal dialog with numerical input validation.
2. **Regional Announcements Broadcast Center (`Announcements.jsx`):**
   - Advisory list displaying active alerts with English & Telugu titles, target district, priority badge (`Critical`, `High`, `Normal`), and category icon (`Weather Advisory`, `Disease Warning`, `Scheme & Subsidy`, `Market Update`).
   - "New Broadcast" modal form capturing bilingual title/body, target district filter, priority, and category.
   - Delete/Archive action with feedback toasts.

### 5.2 File Ownership Matrix
- **Exclusive Write Access:**
  - `admin-dashboard/src/pages/MarketPrices.jsx`
  - `admin-dashboard/src/pages/Announcements.jsx`
- **Strictly Read-Only Access:**
  - `admin-dashboard/src/lib/supabase.js`
  - `admin-dashboard/src/pages/Dashboard.jsx` (Dev 1)
  - `admin-dashboard/src/components/Layout.jsx` (Dev 1)
  - All files in `lib/**`, `supabase/**`

### 5.3 Multi-Language Data Contracts

#### TypeScript Interface (`admin-dashboard/src/types/market.ts`)
```typescript
export interface MarketPriceEntity {
  id: string;
  hubName: string; // e.g. "Bhimavaram (West Godavari, AP)"
  species: 'L. vannamei' | 'P. monodon';
  countGrade: string; // e.g. "30 Count"
  countPerKg: number; // e.g. 30
  priceInrPerKg: number; // e.g. 420.0
  priceChangeInr: number; // e.g. +15.0
  demandLevel: 'Low' | 'Moderate' | 'Stable' | 'High' | 'Very High';
  buyerName?: string;
  effectiveDate: string; // YYYY-MM-DD
  updatedAt: string; // ISO 8601
}

export type AnnouncementCategory =
  | 'Weather Advisory'
  | 'Disease Warning'
  | 'Scheme & Subsidy'
  | 'Market Update'
  | 'General';

export type AnnouncementPriority = 'Normal' | 'High' | 'Critical';

export interface AdminAnnouncementEntity {
  id: string;
  title: string;
  teluguTitle?: string;
  body: string;
  teluguBody?: string;
  category: AnnouncementCategory;
  priority: AnnouncementPriority;
  targetRegion: string; // e.g. "West Godavari"
  author: string;
  recipientCount: number;
  status: 'Active' | 'Archived' | 'Draft';
  createdAt: string;
}

export interface CreateAnnouncementPayload {
  title: string;
  teluguTitle: string;
  body: string;
  category: AnnouncementCategory;
  priority: AnnouncementPriority;
  targetRegion: string;
}
```

#### Pydantic v2 Model (`models/pydantic/market_announcements.py`)
```python
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field

class DemandLevel(str, Enum):
    LOW = "Low"
    MODERATE = "Moderate"
    STABLE = "Stable"
    HIGH = "High"
    VERY_HIGH = "Very High"

class AnnouncementCategory(str, Enum):
    WEATHER = "Weather Advisory"
    DISEASE = "Disease Warning"
    SUBSIDY = "Scheme & Subsidy"
    MARKET = "Market Update"
    GENERAL = "General"

class AnnouncementPriority(str, Enum):
    NORMAL = "Normal"
    HIGH = "High"
    CRITICAL = "Critical"

class MarketPriceModel(BaseModel):
    id: Optional[str] = None
    hub_name: str = Field(..., alias="hubName")
    species: str = "L. vannamei"
    count_grade: str = Field(..., alias="countGrade")
    count_per_kg: int = Field(..., gt=0, alias="countPerKg")
    price_inr_per_kg: float = Field(..., gt=0.0, alias="priceInrPerKg")
    price_change_inr: float = Field(default=0.0, alias="priceChangeInr")
    demand_level: DemandLevel = Field(default=DemandLevel.HIGH, alias="demandLevel")
    effective_date: str = Field(alias="effectiveDate")

class AdminAnnouncementModel(BaseModel):
    id: str
    title: str = Field(..., min_length=3)
    telugu_title: Optional[str] = Field(default=None, alias="teluguTitle")
    body: str = Field(..., min_length=10)
    category: AnnouncementCategory
    priority: AnnouncementPriority
    target_region: str = Field(..., alias="targetRegion")
    recipient_count: int = Field(default=0, ge=0, alias="recipientCount")
    status: str = "Active"
    created_at: str = Field(alias="createdAt")
```

#### JSON Schema (Draft 2020-12) (`schemas/market_announcements.json`)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://prawnguard.app/schemas/market_announcements.json",
  "title": "MarketAndAnnouncements",
  "type": "object",
  "definitions": {
    "MarketPrice": {
      "type": "object",
      "required": ["hubName", "countGrade", "countPerKg", "priceInrPerKg", "demandLevel"],
      "properties": {
        "id": { "type": "string" },
        "hubName": { "type": "string" },
        "species": { "type": "string" },
        "countGrade": { "type": "string" },
        "countPerKg": { "type": "integer", "minimum": 1 },
        "priceInrPerKg": { "type": "number", "minimum": 0 },
        "priceChangeInr": { "type": "number" },
        "demandLevel": { "type": "string", "enum": ["Low", "Moderate", "Stable", "High", "Very High"] }
      }
    },
    "Announcement": {
      "type": "object",
      "required": ["title", "body", "category", "priority", "targetRegion"],
      "properties": {
        "id": { "type": "string" },
        "title": { "type": "string", "minLength": 3 },
        "teluguTitle": { "type": "string" },
        "body": { "type": "string", "minLength": 10 },
        "category": { "type": "string", "enum": ["Weather Advisory", "Disease Warning", "Scheme & Subsidy", "Market Update", "General"] },
        "priority": { "type": "string", "enum": ["Normal", "High", "Critical"] },
        "targetRegion": { "type": "string" },
        "recipientCount": { "type": "integer", "minimum": 0 },
        "status": { "type": "string", "enum": ["Active", "Archived", "Draft"] }
      }
    }
  }
}
```

#### Dart Riverpod State Contract
```dart
// Dart equivalence for mobile market view:
class MarketPriceItem {
  final String hub;
  final int countGrade;
  final double pricePerKg;
  final double change24h;

  const MarketPriceItem({
    required this.hub,
    required this.countGrade,
    required this.pricePerKg,
    required this.change24h,
  });
}
```

### 5.4 Mock vs. Live Execution Strategy
- **Mock Mode Strategy:**
  - `MarketPrices.jsx` contains `INITIAL_PRICES` (6 count sizes for Bhimavaram) and `HISTORICAL_TRENDS` (7 dates).
  - `Announcements.jsx` contains `INITIAL_ANNOUNCEMENTS` (3 realistic advisories: Cyclone Warning, WSSV Outbreak Alert, PMMSY Solar Subsidy).
  - Creating or modifying records updates local React state (`setPrices([...])`, `setAnnouncements([...])`) with instant UI feedback.
- **Live Mode Strategy:**
  - On component mount, executes:
    ```javascript
    const { data: livePrices } = await supabase.from('market_prices').select('*').eq('district', selectedHub);
    const { data: liveAnnouncements } = await supabase.from('admin_announcements').select('*').order('created_at', { ascending: false });
    ```
  - Submitting an announcement persists to `public.admin_announcements` with user authorization check.

### 5.5 Step-by-Step Developer Starting Guide
```bash
# 1. Clone repository and checkout feature branch
git clone https://github.com/iblamesurya/sih_2026.git
cd sih_2026
git checkout feat/market-announcements

# 2. Install dependencies
cd admin-dashboard
npm install

# 3. Run in mock mode (isolation)
npm run dev

# 4. Verify features:
# - Open http://localhost:5173/market-prices: Test hub selection, price editing, and Recharts historical trends
# - Open http://localhost:5173/announcements: Test category filtering, bilingual advisory modal, and submit broadcast

# 5. Verify production build
npm run build

# 6. Push and create PR
git add src/pages/MarketPrices.jsx src/pages/Announcements.jsx
git commit -m "feat(market-announcements): implement mandi prices and regional announcements"
git push origin feat/market-announcements
gh pr create --draft --title "[feat/market-announcements] Admin Market Prices & Announcements" --reviewer iblamesurya
```

---

## 6. Developer 4: More Hub, Profile Settings, i18n & Community (Thanush Reddy)

- **Assignee:** Thanush Reddy (`@thanushreddyseelam`)
- **Assigned Feature Branch:** `feat/more-profile-i18n`
- **Technology Stack:** Flutter 3.x, Dart 3.x, Riverpod 2.x, JSON Localization (`en.json`, `te.json`), GoRouter

### 6.1 Task Boundaries & Deliverables
1. **More Hub Navigation Screen (`more_page.dart`):**
   - Farmer profile summary header showing name, phone number (+91), farm name, and Pro subscription badge.
   - Bilingual language switch toggle (`English / తెలుగు`) updating `currentLocaleProvider` instantaneously.
   - Navigation tiles linking to: Farm Profile, Mandi Market Rates, Weather Advisory, Export PDF Reports, Offline Sync Queue Status, and Community Forum.
   - Sign-Out action triggering `clearAllUserData(ref)` and redirecting to `/login`.
2. **Profile Settings Screen (`profile_settings_page.dart`):**
   - Editable fields: Farmer Full Name, Farm Name, District (West Godavari, Krishna, Bapatla, Nellore), Water Intake Source.
   - GPS coordinate refresh button querying `locationServiceProvider`.
3. **Bilingual Localization Dictionaries (`en.json` & `te.json`):**
   - Synchronize all UI strings across English and authentic colloquial Telugu.
   - Ensure zero missing keys between `lib/l10n/en.json` and `lib/l10n/te.json`.
4. **Community Knowledge Forum (`community_page.dart`):**
   - Regional biosecurity broadcast banner (e.g., "WSSV outbreak reported within 15 km of Bhimavaram").
   - Category filter chips: Biosecurity, Feed Management, Water Quality, Market Rates.
   - Discussion card list with title, author, time, reply count, and Telugu subtitles.
   - "Ask Aqua Community" modal bottom sheet.

### 6.2 File Ownership Matrix
- **Exclusive Write Access:**
  - `lib/features/more/presentation/pages/more_page.dart`
  - `lib/features/more/presentation/pages/profile_settings_page.dart`
  - `lib/features/community/presentation/pages/community_page.dart`
  - `lib/l10n/en.json`
  - `lib/l10n/te.json`
- **Strictly Read-Only Access:**
  - `lib/core/providers/app_providers.dart`
  - `lib/core/services/*`
  - `supabase/*`
  - All other feature directories (`lib/features/ponds/*`, `lib/features/finance/*`)

### 6.3 Multi-Language Data Contracts

#### TypeScript Interface (`types/user_profile.ts`)
```typescript
export interface FarmerProfileEntity {
  id: string; // Auth UUID
  phone: string; // E.164 (e.g. "+919876543210")
  email?: string;
  fullName: string;
  preferredLocale: 'en' | 'te';
  role: 'farmer' | 'admin' | 'technician';
  subscriptionTier: 'free' | 'pro';
  dailyScanCount: number;
  district: string;
  state: string;
  lastGpsLat?: number;
  lastGpsLng?: number;
  createdAt: string;
}

export interface CommunityPostItem {
  id: string;
  title: string;
  authorName: string;
  district: string;
  likes: number;
  repliesCount: number;
  tag: string;
  createdAt: string;
}

export interface I18nDictionary {
  [key: string]: string;
}
```

#### Pydantic v2 Model (`models/pydantic/profile_i18n.py`)
```python
from enum import Enum
from typing import Optional, Literal
from pydantic import BaseModel, Field

class LocaleEnum(str, Enum):
    EN = "en"
    TE = "te"

class SubscriptionTier(str, Enum):
    FREE = "free"
    PRO = "pro"

class FarmerProfileModel(BaseModel):
    id: str
    phone: str = Field(..., pattern=r"^\+91[0-9]{10}$")
    email: Optional[str] = None
    full_name: str = Field(default="Farmer", alias="fullName")
    preferred_locale: LocaleEnum = Field(default=LocaleEnum.TE, alias="preferredLocale")
    role: Literal["farmer", "admin", "technician"] = "farmer"
    subscription_tier: SubscriptionTier = Field(default=SubscriptionTier.FREE, alias="subscriptionTier")
    daily_scan_count: int = Field(default=0, ge=0, alias="dailyScanCount")
    district: str = "West Godavari"
    state: str = "Andhra Pradesh"
    last_gps_lat: Optional[float] = Field(default=None, alias="lastGpsLat")
    last_gps_lng: Optional[float] = Field(default=None, alias="lastGpsLng")
```

#### JSON Schema (Draft 2020-12) (`schemas/profile_i18n.json`)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://prawnguard.app/schemas/profile_i18n.json",
  "title": "FarmerProfileAndLocalization",
  "type": "object",
  "properties": {
    "profile": {
      "type": "object",
      "required": ["id", "phone", "fullName", "preferredLocale", "subscriptionTier"],
      "properties": {
        "id": { "type": "string" },
        "phone": { "type": "string", "pattern": "^\\+91[0-9]{10}$" },
        "fullName": { "type": "string" },
        "preferredLocale": { "type": "string", "enum": ["en", "te"] },
        "subscriptionTier": { "type": "string", "enum": ["free", "pro"] },
        "district": { "type": "string" }
      }
    }
  }
}
```

#### Dart Riverpod Provider Contracts (`lib/features/more/data_contracts.dart`)
```dart
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provided by lib/core/providers/app_providers.dart:
// final currentUserProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
// final currentFarmProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
// final currentLocaleProvider = StateProvider<Locale>((ref) => const Locale('en'));
// final currentSubscriptionTierProvider = StateProvider<SubscriptionTier>((ref) => SubscriptionTier.free);
// final pendingSyncCountProvider = StateProvider<int>((ref) => 0);

void toggleLocale(WidgetRef ref) {
  final current = ref.read(currentLocaleProvider);
  final updated = current.languageCode == 'te' ? const Locale('en') : const Locale('te');
  ref.read(currentLocaleProvider.notifier).state = updated;
}
```

### 6.4 Mock vs. Live Execution Strategy
- **Mock Mode Strategy:**
  - `MorePage.dart` / `more_page.dart` embeds default mock profile data (`"Surya Tummala"`, `"+91 98765 43210"`, `"Bhimavaram Farm #1"`).
  - Language toggle operates synchronously on `currentLocaleProvider` without requiring app reload.
  - JSON strings are loaded directly from local asset bundles.
- **Live Mode Strategy:**
  - Watches `ref.watch(currentUserProvider)` and `ref.watch(currentFarmProvider)` populated during phone OTP verification.
  - Profile modifications dispatch updates to `profiles` and `farms` tables via `OfflineSyncService`.

### 6.5 Step-by-Step Developer Starting Guide
```bash
# 1. Clone repository and checkout feature branch
git clone https://github.com/iblamesurya/sih_2026.git
cd sih_2026
git checkout feat/more-profile-i18n

# 2. Fetch dependencies
flutter pub get

# 3. Run in mock mode (isolation)
flutter run -d chrome

# 4. Verify features:
# - Navigate to More Tab
# - Toggle language switch (English / Telugu) and verify immediate UI translation
# - Open Farm Profile and test editing fields
# - Open Community Hub and verify discussion cards

# 5. Verify JSON localization validity (PowerShell):
Get-Content lib/l10n/en.json | ConvertFrom-Json
Get-Content lib/l10n/te.json | ConvertFrom-Json

# 6. Run test verification suite
flutter test test/core/services/subscription_service_test.dart
flutter test test/core/router/app_router_test.dart

# 7. Push and create PR
git add lib/features/more/ lib/features/community/ lib/l10n/
git commit -m "feat(more-profile-i18n): implement more hub, bilingual i18n dictionaries and community forum"
git push origin feat/more-profile-i18n
gh pr create --draft --title "[feat/more-profile-i18n] More Hub, Profile Settings, i18n & Community" --reviewer iblamesurya
```

---

## 7. Developer 5: PrawnCredit & Farm Finance Ledger (Vishnu Nalluri)

- **Assignee:** Vishnu Nalluri (`@VishnuNalluri-27`)
- **Assigned Feature Branch:** `feat/finance-ui`
- **Technology Stack:** Flutter 3.x, Dart 3.x, Riverpod 2.x, `intl` NumberFormat, Deep Ocean Matte Tokens

### 7.1 Task Boundaries & Deliverables
1. **Financial Overview & P&L Dashboard (`PrawnCreditPage.dart`):**
   - Header summary banner showing Total Revenue, Total Incurred Expenses, and Net Profit formatted in Indian Rupees (`₹`).
   - 3-tab segmented navigation: **Expenses**, **Harvests**, and **PrawnCredit Score**.
2. **Farm Expenses Ledger (`PrawnCreditPage.dart` & `ExpenseForm.dart`):**
   - Categorized expense list (`feed`, `seedPL`, `powerFuel`, `probioticsChemicals`, `labor`, `equipment`, `other`) with semantic category icons and pond association tags.
   - "+ Add Expense" modal bottom sheet with input validation (Category, Amount in ₹, Pond selector, Date, Supplier name, Notes).
3. **Harvest Records & FCR Tracking (`HarvestCard.dart`):**
   - Harvest cards displaying harvest date, pond name, total biomass (kg), count grade, price per kg (₹), auto-calculated total revenue, and Feed Conversion Ratio (FCR).
   - Export harvest receipt and WhatsApp sharing action.
4. **PrawnCredit AI Creditworthiness Meter (`PrawnCreditPage.dart`):**
   - Visual circular credit score meter (range: 300 to 900).
   - Risk rating tier badge: **Tier-1 Elite** (Score > 750), **Tier-2 Preferred** (650–750), **Tier-3 Standard** (< 650).
   - Pre-approved micro-loan credit limit display (e.g. ₹3,50,000 at 1.1% monthly interest).
   - "Apply for Working Capital Loan" action dialog.

### 7.2 File Ownership Matrix
- **Exclusive Write Access:**
  - `lib/features/finance/presentation/pages/prawn_credit_page.dart` (or legacy `PrawnCreditPage.dart`)
  - `lib/features/finance/presentation/pages/finance_page.dart`
  - `lib/features/finance/presentation/widgets/expense_form.dart` (or legacy `ExpenseForm.dart`)
  - `lib/features/finance/presentation/widgets/harvest_card.dart` (or legacy `HarvestCard.dart`)
  - `lib/features/finance/models/finance_models.dart`
- **Strictly Read-Only Access:**
  - `lib/core/providers/app_providers.dart`
  - `lib/core/services/*`
  - `supabase/*`
  - All other feature directories (`lib/features/ponds/*`, `lib/features/more/*`)

### 7.3 Multi-Language Data Contracts

#### TypeScript Interface (`types/finance.ts`)
```typescript
export type ExpenseCategory =
  | 'feed'
  | 'seedPL'
  | 'powerFuel'
  | 'probioticsChemicals'
  | 'labor'
  | 'equipment'
  | 'other';

export interface ExpenseEntity {
  id: string; // e.g. "exp_1725000000"
  category: ExpenseCategory;
  amount: number; // in INR
  date: string; // ISO 8601
  pondId: string;
  pondName: string;
  supplier?: string;
  notes?: string;
}

export type HarvestType = 'Partial' | 'Complete' | 'Emergency';

export interface HarvestRecordEntity {
  id: string; // e.g. "hrv_1725000000"
  date: string; // ISO 8601
  pondId: string;
  pondName: string;
  harvestType: HarvestType;
  biomassKg: number;
  countPerKg: number; // e.g. 40
  pricePerKg: number; // in INR (e.g. 350.0)
  totalRevenue: number; // biomassKg * pricePerKg
  fcr: number; // Feed Conversion Ratio (e.g. 1.35)
  buyerName?: string;
}

export interface PrawnCreditScoreEntity {
  score: number; // 300 to 900
  tier: 'Tier-1 Elite' | 'Tier-2 Preferred' | 'Tier-3 Standard';
  maxCreditLimit: number; // in INR
  monthlyInterestRate: number; // e.g. 1.1
  riskLevel: 'Low' | 'Moderate' | 'High';
}
```

#### Pydantic v2 Model (`models/pydantic/finance.py`)
```python
from enum import Enum
from typing import Optional, Literal
from pydantic import BaseModel, Field, computed_field

class ExpenseCategoryEnum(str, Enum):
    FEED = "feed"
    SEED_PL = "seedPL"
    POWER_FUEL = "powerFuel"
    PROBIOTICS = "probioticsChemicals"
    LABOR = "labor"
    EQUIPMENT = "equipment"
    OTHER = "other"

class ExpenseModel(BaseModel):
    id: str = Field(..., pattern=r"^(exp_|\d+)")
    category: ExpenseCategoryEnum
    amount: float = Field(..., gt=0.0, description="Amount in INR")
    date: str
    pond_id: str = Field(..., alias="pondId")
    pond_name: str = Field(..., alias="pondName")
    supplier: Optional[str] = None
    notes: Optional[str] = None

class HarvestRecordModel(BaseModel):
    id: str = Field(..., pattern=r"^(hrv_|\d+)")
    date: str
    pond_id: str = Field(..., alias="pondId")
    pond_name: str = Field(..., alias="pondName")
    harvest_type: Literal["Partial", "Complete", "Emergency"] = Field(default="Complete", alias="harvestType")
    biomass_kg: float = Field(..., gt=0.0, alias="biomassKg")
    count_per_kg: int = Field(..., gt=0, alias="countPerKg")
    price_per_kg: float = Field(..., gt=0.0, alias="pricePerKg")
    fcr: float = Field(default=1.35, ge=0.0)
    buyer_name: Optional[str] = Field(default=None, alias="buyerName")

    @computed_field
    @property
    def total_revenue(self) -> float:
        return self.biomass_kg * self.price_per_kg
```

#### JSON Schema (Draft 2020-12) (`schemas/finance.json`)
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://prawnguard.app/schemas/finance.json",
  "title": "FarmFinanceAndPrawnCredit",
  "type": "object",
  "definitions": {
    "Expense": {
      "type": "object",
      "required": ["id", "category", "amount", "date", "pondId", "pondName"],
      "properties": {
        "id": { "type": "string" },
        "category": { "type": "string", "enum": ["feed", "seedPL", "powerFuel", "probioticsChemicals", "labor", "equipment", "other"] },
        "amount": { "type": "number", "exclusiveMinimum": 0 },
        "date": { "type": "string" },
        "pondId": { "type": "string" },
        "pondName": { "type": "string" }
      }
    },
    "HarvestRecord": {
      "type": "object",
      "required": ["id", "date", "pondId", "biomassKg", "countPerKg", "pricePerKg"],
      "properties": {
        "id": { "type": "string" },
        "date": { "type": "string" },
        "pondId": { "type": "string" },
        "biomassKg": { "type": "number", "exclusiveMinimum": 0 },
        "countPerKg": { "type": "integer", "exclusiveMinimum": 0 },
        "pricePerKg": { "type": "number", "exclusiveMinimum": 0 },
        "fcr": { "type": "number", "minimum": 0 }
      }
    }
  }
}
```

#### Dart Riverpod Provider Contracts (`lib/features/finance/models/finance_models.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provided by lib/core/providers/app_providers.dart:
// final expensesProvider = StateProvider<List<Expense>>((ref) => []);
// final harvestsProvider = StateProvider<List<HarvestRecord>>((ref) => []);

// Verified domain models in lib/features/finance/models/finance_models.dart:
// - class Expense (includes toJson, fromJson, ExpenseCategory enum)
// - class HarvestRecord (includes computed totalRevenue getter)
// - class PrawnCreditScore (score computation logic)
```

### 7.4 Mock vs. Live Execution Strategy
- **Mock Mode Strategy:**
  - `PrawnCreditPage.dart` executes `_loadDemoFinanceData()` generating 4 realistic expenses (CP Feeds grow-out feed ₹145,000, Apex Hatcheries PL15 seed ₹68,000, APSPDCL power ₹32,000, AquaBio probiotics ₹18,500) and 2 harvest batches.
  - Dynamic score computation, revenue totals, and expense filtering run in memory.
- **Live Mode Strategy:**
  - Hydrated by `DataHydrationService` from `public.expenses` and `public.harvests`.
  - Adding an expense enqueues to `OfflineSyncService`:
    ```dart
    ref.read(offlineSyncProvider).enqueue({
      'table': 'expenses',
      'action': 'insert',
      'payload': newExpense.toJson(),
    });
    ```

### 7.5 Step-by-Step Developer Starting Guide
```bash
# 1. Clone repository and checkout feature branch
git clone https://github.com/iblamesurya/sih_2026.git
cd sih_2026
git checkout feat/finance-ui

# 2. Fetch dependencies
flutter pub get

# 3. Run in mock mode (isolation)
flutter run -d chrome

# 4. Verify finance features:
# - Open Finance screen (/finance)
# - Inspect Financial Summary banner (Revenue, Expenses, Net Profit)
# - Test adding an expense via ExpenseForm modal
# - Switch to Harvests tab and review harvest cards & FCR calculation
# - Switch to PrawnCredit tab and inspect dynamic credit meter

# 5. Run test verification suite
flutter test test/features/finance/finance_test.dart

# 6. Push and create PR
git add lib/features/finance/
git commit -m "feat(finance-ui): implement PrawnCredit ledger, expense form and harvest cards"
git push origin feat/finance-ui
gh pr create --draft --title "[feat/finance-ui] PrawnCredit & Farm Finance Ledger" --reviewer iblamesurya
```

---

## 8. Dependency Boundaries, Branching & Integration Protocol

### 8.1 Zero-Conflict Branching Strategy

To guarantee that 5 developers can work in parallel without code collisions or merge conflicts, each developer operates on an isolated feature branch branched directly from `main`:

```
main (Protected)
 ├── feat/core-platform         (@iblamesurya — Surya)
 ├── feat/admin-shell           (@2400031215-VarshithReddy — Varshith)
 ├── feat/ponds-ui              (@Poojitha8006 — Poojitha)
 ├── feat/market-announcements  (@TummaPragna — Pragna)
 ├── feat/more-profile-i18n     (@thanushreddyseelam — Thanush)
 └── feat/finance-ui            (@VishnuNalluri-27 — Vishnu)
```

```bash
# Standard branch creation command for each developer:
git checkout -b <assigned-branch-name> origin/main
```

---

### 8.2 Protected Core Rules

The following repository policies are strictly enforced:
1. **Never Modify Core Platform:** No leaf developer may edit files in `lib/core/services/*`, `lib/core/providers/*`, `lib/core/router/*`, `lib/core/theme/*`, or `supabase/*`.
2. **Never Direct-Push to `main`:** All code merges must happen via GitHub Pull Requests reviewed and approved by Platform Lead Surya (`@iblamesurya`).
3. **Mocks First:** Leaf features must be fully functional in offline mock mode before wiring into live Supabase endpoints.
4. **Token Compliance:** Every UI screen must use the Deep Ocean Matte tokens defined in Section 1.4. Hardcoded ad-hoc hex colors outside the palette are rejected during review.

---

### 8.3 PR Merge Ordering & Integration Sequence

To ensure stable integration, PR merges follow a strict sequential ordering:

```
┌────────────────────────────────────────────────────────────────────────┐
│ STAGE 1: Core Platform Foundation                                      │
│ Surya merges feat/core-platform and tags v0.1-base                     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ STAGE 2: Independent Leaf Feature PRs (Parallel Review)                │
│ Developers rebase on origin/main: git rebase origin/main               │
│ • PR #1 (feat/admin-shell)          — Varshith Reddy                   │
│ • PR #3 (feat/ponds-ui)             — Poojitha                         │
│ • PR #2 (feat/market-announcements) — Pragna                           │
│ • PR #5 (feat/more-profile-i18n)    — Thanush Reddy                    │
│ • PR #6 (feat/finance-ui)           — Vishnu Nalluri                   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ STAGE 3: Platform Integration & End-to-End Validation                  │
│ Surya wires live Supabase tables, runs full test suite & produces      │
│ production release builds (Play Store AAB + React Docker).             │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 8.4 CI/CD Quality Gate Enforcement

Every Pull Request must pass the automated GitHub Actions CI pipeline (`.github/workflows/ci.yml`):

1. **Static Analysis Gate:**
   - Flutter: `flutter analyze` must report **0 issues**.
   - React: `npm run lint` must pass with **0 errors**.
2. **Automated Unit & Widget Test Gate:**
   - Flutter: All 296 unit/widget/e2e tests across 22 test files must pass cleanly:
     ```bash
     flutter test
     ```
3. **Production Compilation Gate:**
   - Flutter: Release build check:
     ```bash
     flutter build apk --debug
     ```
   - React: Vite production compilation check:
     ```bash
     cd admin-dashboard && npm run build
     ```
4. **Pre-Launch Checklist Gate:**
   - Validation script `scripts/pre_launch_checklist.ps1` must score **19/19 (100%)**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File scripts\pre_launch_checklist.ps1
     ```

---

## 9. Verification & Testing Standards

Every developer is required to verify their deliverables using the test commands below prior to submitting their PR:

| Developer | Target Feature | Automated Verification Command | Expected Result |
|---|---|---|---|
| **Dev 1** | Admin Shell | `cd admin-dashboard && npm run build` | Clean Vite bundle in `dist/` with 0 syntax errors |
| **Dev 2** | Ponds UI | `flutter test test/core/providers/app_providers_test.dart` | All provider tests pass |
| **Dev 3** | Market & Announcements | `cd admin-dashboard && npm run build` | Clean Vite bundle in `dist/` with 0 syntax errors |
| **Dev 4** | More & i18n | `flutter test test/core/router/app_router_test.dart`<br>`flutter test test/core/services/subscription_service_test.dart` | All router and subscription tests pass |
| **Dev 5** | Finance UI | `flutter test test/features/finance/finance_test.dart` | All expense and harvest tests pass |
| **All** | Static Analysis | `flutter analyze` | "No issues found!" (0 warnings, 0 errors) |
| **All** | Full Test Suite | `flutter test` | 296 tests pass across 22 test suites |

---

## 10. Document Index & Cross-References

- **Quick Team Assignment Map:** [`TEAM_ASSIGNMENTS.md`](../../TEAM_ASSIGNMENTS.md) & [`docs/team/TEAM_ASSIGNMENTS.md`](TEAM_ASSIGNMENTS.md)
- **Architecture & AI Master Specification:** [`docs/architecture/APP_COMPLETE_GUIDE_FOR_AI_AGENT.md`](../architecture/APP_COMPLETE_GUIDE_FOR_AI_AGENT.md)
- **Database Schema & SQL Migration:** [`supabase/schema.sql`](../../supabase/schema.sql)
- **Pre-Launch Production Checklist:** [`scripts/pre_launch_checklist.ps1`](../../scripts/pre_launch_checklist.ps1)
- **Project Root Guide:** [`README.md`](../../README.md)

---
*Authored by Platform Lead & Principal Architect Surya Tummala (`@iblamesurya`) for Smart India Hackathon 2026.*
