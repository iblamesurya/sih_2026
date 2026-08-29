# PrawnGuard.ai — Work-Split & Collaboration Design

**Date:** 2026-08-29
**Status:** Approved — Approach A (Horizontal Layers)
**Repo:** `iblamesurya/sih_2026`
**Team:** 6 members (5 teammates + Surya as Platform Lead)
**Branding:** Prawn Guard / `prawn_guard` / `@prawnguard.app` / Deep Ocean Matte

---

## 1. Goal & Constraints

Split the MASTER BUILD PROMPT (15 services, Flutter offline-first mobile, Supabase BaaS, React 19 admin, Gemini vision, Feed AI, Telugu Voice NLU) so that:

- `iblamesurya` (Surya) carries ~70% — all hard singletons, AI, offline queue, Edge Functions, RLS, Riverpod/GoRouter shell.
- 5 teammates get **simple, AI-generatable, isolated leaf tasks** — each is 1–3 files, no cross-service logic, no `core/services/*` edits, merge-conflict-free, completable by `Claude Code` in one prompt.
- Every teammate has exactly one GitHub Issue, one branch, one reviewer (Surya), clear acceptance checklist.

Empty repo (`main` has 0 commits) → first commit must scaffold stable base before teammates branch.

---

## 2. Architecture Decomposition (for assignment, not implementation)

```
PrawnGuard Platform
├── 0. Platform Base (Surya) — must land on main first
│   ├── Flutter scaffold: lib/main.dart, theme (Deep Ocean Matte tokens), Space Grotesk + Outfit, l10n en/te
│   ├── Supabase schema (all 14 tables + RLS + increment_scan_count RPC) + Storage buckets
│   ├── core/services: SupabaseClientService, AuthService, OfflineSyncService (FIFO 100), RealtimeService, NotificationService, AppLogger
│   ├── Riverpod app_providers.dart (authState, userProfile, currentFarm, ponds, families) + clearAllUserData
│   └── GoRouter shell: StatefulShellRoute 5 tabs + modal routes (/login, /onboarding, /quick-log, /finance, /weather, /reports, /upgrade, /admin)
├── 1. AI & Voice (Surya)
│   ├── PrawnDocAIService (image compress 768px q75, MD5 dedup, RAG prompt, _parseRobustJson)
│   ├── FeedAIService (DOC/biomass/ABW/temp → 4-meal split + tray logic)
│   ├── TeluguVoiceNLUService (STT code-mix regex)
│   ├── WeatherService (weather-intelligence edge + hypoxia advisories)
│   ├── AlertSystem (pH/DO/NH3/Alkalinity thresholds)
│   ├── SubscriptionService (free/pro gates)
│   └── Edge Functions: prawndoc-ai (Gemini Flash), weather-intelligence (OWM), + pg_cron
├── 2. Admin Dashboard Shell (Varshith — Flutter+Gemini strength, but simplest React task)
│   └── admin-dashboard/ Vite 8 + React 19 + Tailwind + Leaflet + Recharts, Dashboard.jsx KPI cards only
├── 3. Ponds UI (Poojitha) — leaf, no service edits
├── 4. Market & Announcements (Pragna) — leaf admin CRUD
├── 5. More/Profile/i18n/Community (Thanush) — leaf static + l10n
└── 6. Finance/PrawnCredit (Vishnu) — leaf tables/forms
```

**Rule:** Teammates NEVER edit `lib/core/services/*`, `lib/core/providers/*`, `supabase/*`, `supabase/functions/*`. They own only their assigned leaf files.

---

## 3. Assignment Matrix (GitHub Issues)

| # | Assignee | Branch | Issue Title | Scope (files to CREATE only) | Must NOT touch | Labels |
|---|----------|--------|-------------|------------------------------|----------------|--------|
| 0 | `iblamesurya` | `feat/core-platform` | Platform Base: Supabase + Theme + Router + Core Services + Edge Functions | All `core/*`, `supabase/*`, `lib/l10n/*`, `lib/core/theme/*`, `lib/core/providers/*`, `lib/core/router/*`, Edge Functions | — | `core` `priority:high` |
| 1 | `2400031215-VarshithReddy` | `feat/admin-shell` | Admin Dashboard Shell — KPI Cards + Layout | `admin-dashboard/src/pages/Dashboard.jsx`, `admin-dashboard/src/components/Layout.jsx`, `admin-dashboard/src/lib/supabase.js` (read-only) | `lib/**`, edge | `good first issue` `admin` |
| 2 | `Poojitha8006` | `feat/ponds-ui` | Ponds UI — List + Detail + Add Modal (forms only) | `lib/features/ponds/presentation/pages/PondsPage.dart`, `PondDetailsPage.dart`, `widgets/AddPondModal.dart` | `core/services/*`, providers | `good first issue` `flutter` |
| 3 | `TummaPragna` | `feat/market-announcements` | Admin: Market Prices & Announcements CRUD UI | `admin-dashboard/src/pages/MarketPrices.jsx`, `Announcements.jsx` | `lib/**` | `good first issue` `admin` |
| 4 | `thanushreddyseelam` | `feat/more-profile-i18n` | More Tab + Profile + l10n en/te JSON + Community placeholder | `lib/features/more/presentation/MorePage.dart`, `lib/l10n/en.json`, `te.json`, `lib/features/community/CommunityPage.dart` (placeholder) | `core/services/*` | `good first issue` `flutter` |
| 5 | `VishnuNalluri-27` | `feat/finance-ui` | PrawnCredit — Finance UI (expenses/harvests list + forms) | `lib/features/finance/PrawnCreditPage.dart`, `widgets/ExpenseForm.dart`, `widgets/HarvestCard.dart` | `core/services/*`, FeedAI | `good first issue` `flutter` |

All teammate issues contain: exact file paths, Deep Ocean Matte tokens, Space Grotesk/Outfit note, Telugu label placeholder, acceptance checklist, one-line Claude Code scaffold prompt.

---

## 4. Branch & Merge Strategy

- `main` is protected — only Surya merges via PR. Teammates never push to `main`.
- Each teammate: `git checkout -b <branch> origin/main` → commit → `gh pr create --draft` → request review from `iblamesurya`.
- No rebase of `core/*` — teammates rebase only if Surya announces new base tag (`v0.1-base`).
- Surya lands Platform Base first (`v0.1-base` tag), then teammates branch.

---

## 5. GitHub Issue Template (applied to each leaf issue)

Title, assignee, labels, body with:
- **Goal** (1 line)
- **Files to create** (exact paths)
- **Visual spec** — Deep Ocean Matte tokens (`#0A0A0B`, `#00E5FF`, `#10B981`, `#E55C5C` etc.)
- **Acceptance checklist** (checkboxes)
- **Claude scaffold prompt** — copy-paste for `Claude Code`
- **Do NOT touch** warning
- **Reviewer:** `@iblamesurya`

---

## 6. Milestones (SIH pacing, adjustable)

- **M1 (Week 1):** Surya lands Platform Base + Supabase schema on `main`, tags `v0.1-base`.
- **M2 (Week 2):** All 5 leaf PRs drafted (UI only, mocked data). Surya unblocks with dummy providers.
- **M3 (Week 3):** Surya integrates PrawnDoc AI + Feed AI + Voice NLU; teammates polish Telugu labels + Recharts/Leaflet wiring (read-only Supabase).
- **M4 (Week 4):** E2E demo, offline FIFO test, build_release.ps1, SIH PPT.

---

## 7. Automation (this spec's execution)

Workflow (ultracode) will:
1. Create 6 GitHub Issues (1 per teammate + 1 platform epic for Surya) via `gh issue create` + `gh issue edit --add-assignee`.
2. Create 6 branches via `git branch` + push empty commit as placeholder.
3. Post assignment summary comment on each issue tagging assignee.
4. Create `docs/superpowers/specs/*` commit on `main`.

Future: `gh project` board optional.

---

## 8. Self-Review Fixes

- [x] No TBD — all file paths concrete.
- [x] No contradictions — teammates never edit core.
- [x] Scope focused — this spec is only work-split, not full app spec (existing MASTER prompt is source of truth).
- [x] Telugu/Deep Ocean Matte constraints preserved.
- [x] Empty-repo bootstrapping accounted for.

---

## 9. Approval

Approved by `iblamesurya` on 2026-08-29 via chat: "yes create issues". Proceeding to GitHub automation.

Next step: `superpowers:writing-plans` is skipped per user intent (direct to execution); plan is this doc + GitHub Issues as executable tasks.
