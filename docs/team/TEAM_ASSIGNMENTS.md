# PrawnGuard.ai — Team Assignments & Task Matrix (SIH 2026)

**Repository:** `iblamesurya/sih_2026`  
**Master Work Breakdown:** 👉 [**TEAM_WORK_BREAKDOWN.md**](TEAM_WORK_BREAKDOWN.md) (Complete architectural specs, multi-language contracts, mock/live workflows, and onboarding guides)  
**Strategy:** Approach A — Horizontal Separation. Platform Lead Surya (70% core platform), 5 Modular Leaf Developers (30% isolated UI components).

---

## 👥 5-Developer Quick Map & Assignments

| Role | Developer & GitHub Handle | Target Issue | Branch | Tech Stack | Functional Deliverables | Status |
|---|---|---|---|---|---|---|
| **Platform Lead** | **Surya Tummala**<br>(`@iblamesurya`) | [#4 — EPIC Platform Base](https://github.com/iblamesurya/sih_2026/issues/4) | `feat/core-platform` | Flutter 3.x + Dart<br>Supabase PostgreSQL<br>Deno TypeScript | 15 relational tables + RLS + RPCs, 16 core singleton services, Riverpod provider graph, GoRouter 5-tab shell, Deep Ocean Matte tokens, 2 Deno Edge Functions | **BASE STABLE** (`v0.1-base`) |
| **Dev 1** | **Varshith Reddy**<br>(`@2400031215-VarshithReddy`) | [#1 — Admin Dashboard Shell](https://github.com/iblamesurya/sih_2026/issues/1) | `feat/admin-shell` | React 19 + Vite 8<br>Tailwind CSS v4<br>Recharts | Dashboard KPI cards with 7-day sparklines, responsive sidebar shell, recent disease scan feed, interactive Leaflet farm map | Active / Ready for PR |
| **Dev 2** | **Poojitha**<br>(`@Poojitha8006`) | [#3 — Ponds UI & Telemetry](https://github.com/iblamesurya/sih_2026/issues/3) | `feat/ponds-ui` | Flutter 3.x / Dart<br>Riverpod 2.x | Ponds list with status badges, detailed telemetry graphs, Add Pond modal sheet with quota check, manual/voice water logging | Active / Ready for PR |
| **Dev 3** | **Pragna**<br>(`@TummaPragna`) | [#2 — Market & Announcements](https://github.com/iblamesurya/sih_2026/issues/2) | `feat/market-announcements` | React 19 + Vite 8<br>Tailwind CSS v4<br>Lucide React | Mandi market price table across AP hubs (30c–100c), historical price trend charts, regional announcements advisory broadcast modal | Active / Ready for PR |
| **Dev 4** | **Thanush Reddy**<br>(`@thanushreddyseelam`) | [#5 — More/Profile/i18n](https://github.com/iblamesurya/sih_2026/issues/5) | `feat/more-profile-i18n` | Flutter 3.x / Dart<br>Riverpod 2.x<br>Bilingual JSON | More Hub navigation screen, farmer profile settings, bilingual language toggle (`en` / `te`), synchronized i18n dictionaries, community forum | Active / Ready for PR |
| **Dev 5** | **Vishnu Nalluri**<br>(`@VishnuNalluri-27`) | [#6 — Finance/PrawnCredit](https://github.com/iblamesurya/sih_2026/issues/6) | `feat/finance-ui` | Flutter 3.x / Dart<br>Riverpod 2.x | P&L overview dashboard, categorized farm expense ledger, harvest cards with FCR calculation, PrawnCredit dynamic creditworthiness score gauge | Active / Ready for PR |

---

## 🚀 How to Start (Developer Quick-Start)

Every developer operates within their dedicated git branch:

```bash
# 1. Clone the repository
git clone https://github.com/iblamesurya/sih_2026.git
cd sih_2026

# 2. Checkout your assigned branch
git checkout <your-assigned-branch>   # e.g., feat/ponds-ui or feat/admin-shell

# 3. For Web Developers (Dev 1 & Dev 3):
cd admin-dashboard
npm install
npm run dev

# 3. For Mobile Developers (Dev 2, Dev 4 & Dev 5):
flutter pub get
flutter run -d chrome
```

---

## 🛡️ Collaboration & Code Rules

1. **Strict File Boundaries:** Only edit files assigned to your feature module. Never edit `lib/core/services/*`, `lib/core/providers/*`, `lib/core/router/*`, `lib/core/theme/*`, or `supabase/*`.
2. **Offline-First Mock Verification:** Ensure all screens render perfectly and validate interactions in offline mock mode prior to connecting live endpoints.
3. **Deep Ocean Matte Design System:** Strictly utilize design tokens (`#0A0A0B` background, `#171717` surface, `#00E5FF` primary, `#10B981` secondary, `#E55C5C` urgent alert).
4. **Draft PR Submission:**
   ```bash
   git add <your-changed-files>
   git commit -m "feat(<component>): implement leaf UI and data contracts"
   git push origin <your-assigned-branch>
   gh pr create --draft --title "[<branch-name>] Implementation" --reviewer iblamesurya
   ```

---

## 📖 Comprehensive Architectural & Contract Reference

For complete multi-language data contracts (TypeScript, Pydantic v2, JSON Schema 2020-12, Dart Riverpod), Mock vs. Live contracts, and detailed step-by-step setup guides, refer to:
👉 [**docs/team/TEAM_WORK_BREAKDOWN.md**](TEAM_WORK_BREAKDOWN.md)
