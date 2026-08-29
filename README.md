# PrawnGuard.ai — Prawn Guard (SIH 2026)

Enterprise Aquaculture Intelligence & Pond Management Platform

- **Mobile:** Flutter 3.x + Riverpod 3.x + GoRouter 14.x + Supabase + Firebase
- **BaaS:** Supabase (Postgres + RLS + Edge Functions + Realtime + Storage + pg_cron)
- **Admin:** React 19 + Vite 8 + Tailwind + Leaflet + Recharts
- **AI:** Gemini Flash Multimodal (PrawnDoc) + Bio-Energetic Feed AI + Telugu Voice NLU

> See `docs/superpowers/specs/2026-08-29-prawnguard-work-split-design.md` for work-split & branch strategy.

## Team
- `iblamesurya` (Surya) — Platform Lead (70%)
- `2400031215-VarshithReddy` — Admin Dashboard Shell
- `Poojitha8006` — Ponds UI
- `TummaPragna` — Market & Announcements
- `thanushreddyseelam` — More/Profile/i18n
- `VishnuNalluri-27` — Finance/PrawnCredit

## Quick Start (after Platform Base lands)
```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
