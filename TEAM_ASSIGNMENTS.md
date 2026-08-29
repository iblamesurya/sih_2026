# PrawnGuard — Team Assignments (SIH 2026)

**Repo:** `iblamesurya/sih_2026` | **Spec:** `docs/superpowers/specs/2026-08-29-prawnguard-work-split-design.md`
**Strategy:** Approach A — Horizontal Layers. Surya = Platform Lead (70%), 5 teammates = simple isolated leaf tasks (AI-generatable).

## Quick Map

| # | Issue | Assignee | Branch | Stack | What they build | Labels |
|---|-------|----------|--------|-------|-----------------|--------|
| 4 | [#4 — EPIC Platform Base](https://github.com/iblamesurya/sih_2026/issues/4) | @iblamesurya (Surya) | `feat/core-platform` | Flutter + Supabase + Edge | All 15 core services, theme, router, providers, schema, Edge Functions + **Voice Agent** | `core` `priority:high` |
| 1 | [#1 — Admin Dashboard Shell](https://github.com/iblamesurya/sih_2026/issues/1) | @2400031215-VarshithReddy | `feat/admin-shell` | React 19 + Vite + Tailwind | Dashboard KPI cards + Layout sidebar | `good first issue` `admin` |
| 3 | [#3 — Ponds UI](https://github.com/iblamesurya/sih_2026/issues/3) | @Poojitha8006 | `feat/ponds-ui` | Flutter | Ponds list + detail + AddPondModal (mocked) | `good first issue` `flutter` |
| 2 | [#2 — Market & Announcements](https://github.com/iblamesurya/sih_2026/issues/2) | @TummaPragna | `feat/market-announcements` | React | MarketPrices + Announcements tables + modals | `good first issue` `admin` |
| 5 | [#5 — More/Profile/i18n](https://github.com/iblamesurya/sih_2026/issues/5) | @thanushreddyseelam | `feat/more-profile-i18n` | Flutter | MorePage + en/te.json + Community placeholder | `good first issue` `flutter` |
| 6 | [#6 — Finance/PrawnCredit](https://github.com/iblamesurya/sih_2026/issues/6) | @VishnuNalluri-27 | `feat/finance-ui` | Flutter | PrawnCredit tabs + ExpenseForm + HarvestCard | `good first issue` `flutter` |

## For Teammates — How to start (copy-paste)

Each teammate runs this in their Claude Code terminal on their branch:

```bash
git clone https://github.com/iblamesurya/sih_2026.git
cd sih_2026
git checkout <your-branch>   # e.g. feat/ponds-ui
# then in Claude Code, paste the "Claude Scaffold Prompt" from your Issue
```

**Rules:**
- Only edit files listed in YOUR issue. Never touch `lib/core/services/*`, `lib/core/providers/*`, `supabase/*`
- Keep data mocked (no Supabase writes yet) — Surya will wire real data after `v0.1-base`
- Push and open Draft PR: `gh pr create --draft --title "[<your-feature>] ..." --reviewer iblamesurya`
- Tag @iblamesurya in PR for review

## For Surya — Your heavy load (Issue #4)

1. Checkout `feat/core-platform` and scaffold in this order:
   - `supabase/schema.sql` + RLS + `increment_scan_count` (from MASTER prompt §4)
   - `lib/core/theme/app_theme.dart` (Deep Ocean Matte tokens)
   - `lib/core/services/*` (15 services — start with SupabaseClient → Auth → OfflineSync → Realtime)
   - `lib/core/providers/app_providers.dart` + `lib/core/router/app_router.dart` (5-tab shell)
   - `supabase/functions/prawndoc-ai` + `weather-intelligence` (Deno)
   - `scripts/build_release.ps1`
2. `git push origin feat/core-platform` → PR → merge to `main` → `git tag v0.1-base && git push origin v0.1-base`
3. Comment on issues #1,2,3,5,6: "Base is ready — rebase your branch: `git fetch origin && git rebase origin/main`"
4. **Voice Agent (extra):** After base, new branch `feat/voice-agent` → `lib/core/services/voice_agent_service.dart` (STT + TTS + Telugu NLU agent loop). Keep separate PR.

## Branches (already pushed)

```
origin/main
origin/feat/core-platform        → Surya
origin/feat/admin-shell          → Varshith
origin/feat/ponds-ui             → Poojitha
origin/feat/market-announcements → Pragna
origin/feat/more-profile-i18n    → Thanush
origin/feat/finance-ui           → Vishnu
```

## Design System — Deep Ocean Matte (all teammates use these)

- `background`: `#0A0A0B` / `#0F0F0F` | `surface`: `#171717` | `primary`: `#00E5FF` | `secondary`: `#10B981`
- `alertUrgent`: `#E55C5C` | `alertWatch`: `#E5B05C` | `alertInfo`: `#5C9EE5`
- Header font: **Space Grotesk** | Body: **Outfit** | `glass`: `rgba(255,255,255,0.05) + blur(16px)`

## Milestones

- **Week 1:** Surya lands `v0.1-base` on main
- **Week 2:** All 5 leaf PRs drafted (mocked UI)
- **Week 3:** Surya integrates PrawnDoc AI + Feed AI + Voice NLU; teammates add Telugu labels + wiring
- **Week 4:** E2E offline FIFO test + `build_release.ps1` + SIH PPT

---
Generated 2026-08-29 — Work-split Approach A approved by @iblamesurya
