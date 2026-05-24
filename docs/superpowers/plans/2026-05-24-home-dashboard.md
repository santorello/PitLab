# Home Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the PitLap home in the visual direction of `docs/mockups/home-vision-v2.html`, using only real database-backed contracts and explicit empty states.

**Architecture:** Supabase owns home aggregates through read-only views/RPC. Flutter consumes those contracts through a dedicated provider file and renders the home without mock/demo values. Sections with no reliable contract are hidden or marked as coming soon.

**Tech Stack:** Flutter, Riverpod, GoRouter, Supabase PostgREST/RPC, SQL views with RLS-aware contracts.

---

### Task 1: Home Database Contracts

**Files:**
- Create: `supabase/deltas/2026-05-24-home-dashboard-contracts.sql`

- [x] **Step 1: Add overview stats view**

Create `public.home_overview_stats` with counts for open tracks, upcoming public events, recent spots, public shops, geocoded shops, and public builds.

- [x] **Step 2: Add trending tracks view**

Create `public.home_trending_tracks` with a documented score based on current status, privacy-safe arrivals summary, upcoming events, follower count RPC, and recent status updates.

- [x] **Step 3: Add featured track contract**

Create `public.home_featured_track` as the top row from `home_trending_tracks`.

- [x] **Step 4: Add PitCoin public leaderboard**

Create `public.pitcoin_public_leaderboard` from `public_user_pitcoin`, exposing only public-profile leaderboard data.

- [x] **Step 5: Add owner streak RPC**

Create `public.get_my_pitcoin_streak()` as a security-invoker RPC using the authenticated user's own PitCoin transaction visibility.

### Task 2: Flutter Data Providers

**Files:**
- Create: `app/lib/features/community/application/home_dashboard_provider.dart`

- [x] **Step 1: Add typed models**

Add `HomeOverviewStats`, `HomeTrendingTrack`, and `PitcoinLeaderboardEntry`.

- [x] **Step 2: Add view-backed providers**

Add Riverpod providers for overview stats, featured track, trending tracks, public leaderboard, and authenticated streak.

- [x] **Step 3: Add fail-safe behavior**

Catch missing-contract errors and return empty data so the UI never fabricates values while migrations are pending.

### Task 3: Home UI

**Files:**
- Replace: `app/lib/features/community/presentation/community_home_screen.dart`

- [x] **Step 1: Render visual home shell**

Use warm background, compact mobile-first content width, brand top bar, greeting card, action chips, and card-based sections.

- [x] **Step 2: Render only real data**

Use DB-backed providers for PitCoin, KPI, featured track, trending, leaderboard, and activity feed.

- [x] **Step 3: Handle unavailable sections honestly**

Render "Arriva presto" for Live ai box, hide missing featured/trending sections, and show "Classifica in partenza" when leaderboard scores are all zero.

### Task 4: Verification

**Files:**
- Inspect: changed Dart and SQL files

- [x] **Step 1: Run lightweight source checks**

Check for stale mock/demo references and simple delimiter balance.

- [ ] **Step 2: Run full Flutter verification**

Run `flutter analyze` and relevant tests manually, per project preference.

- [ ] **Step 3: Apply Supabase delta**

Apply `supabase/deltas/2026-05-24-home-dashboard-contracts.sql` to the target project before expecting the new home sections to populate.
