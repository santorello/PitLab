# PitLap Admin Regression Browser Report - 2026-05-20

Scope: browser regression on `http://localhost:8080/` with real admin session observed for `g.santoro90@live.it`.

Evidence basis:
- Browser walkthrough on local app.
- Supabase MCP SQL checks on project data.
- Read-only source inspection of admin route, widgets, dialogs and providers.
- Dispositive actions were executed only on temporary QA fixtures, then cleaned up and verified removed.

## Executive Summary

Admin access is available and the `/admin` page renders for the real admin session. Dashboard counts match Supabase data. The approval queue correctly shows empty because the database has zero pending track/shop approvals.

The main regression finding is on admin impersonation: observing a non-admin user redirects the admin away from `/admin`; on Home the visible UI did not expose a stop-impersonation control, so the admin can be stranded outside the admin area until app state is reset. This is high-priority because it affects a privileged QA/admin workflow and can make regression testing unreliable.

During the dispositive DB-backed pass, a second real bug emerged: the admin Event visibility toggle used `private`, but the database enum accepts `public` and `hidden`. This was corrected locally in the admin screen.

## Findings

### P1 - Admin Impersonation Can Strand The Admin Outside Admin Area

Severity: High

Entity: Admin UI, impersonation flow, `effectiveUserRoleProvider`, `/admin` route guard.

Risk:
- An admin clicking `Osserva` on a normal `user` loses effective admin role.
- `/admin` becomes guarded away because `isAdminProvider` uses the effective role.
- The app redirects to Home.
- In the tested Home view, no visible stop-impersonation control was present, so the admin has no obvious way to restore admin mode from the UI.

Browser evidence:
- Started from `/admin` with admin sidebar visible.
- Users panel filtered by `user`.
- Clicked the eye icon on a user row.
- Browser navigated to `http://localhost:8080/`.
- Admin item disappeared from sidebar.
- No visible `Esci` / stop-impersonation banner was visible in the Home screenshot.

Code evidence:
- `app/lib/features/admin/presentation/admin_settings_screen.dart`: user row `onImpersonate` calls `impersonationProvider.notifier.impersonateUser(...)`.
- `app/lib/features/auth/application/auth_providers.dart`: `effectiveUserRoleProvider` returns impersonated role when impersonation is active.
- `app/lib/app/navigation/app_router.dart`: `/admin` requires `isAdminProvider`.
- `app/lib/core/widgets/content_scaffold_header.dart`: stop impersonation control exists in `ContentScaffoldHeader`, but the observed Home surface did not show it.

Recommended fix:
- Keep the real admin as admin for route authorization, and use impersonated role only for the pages/features where UI simulation is intended.
- Alternatively, render a global impersonation banner with `Esci` at `AppScaffold` level, not only inside `ContentScaffoldHeader`.
- Avoid `context.go('/admin')` from the impersonation banner while `effectiveUserRoleProvider` is non-admin, unless the stop action is executed first.

Applied local fix:
- Added a global impersonation banner in `app/lib/core/widgets/app_scaffold.dart` with `Esci`, visible from any route while impersonation is active.
- The action stops impersonation and routes back to `/admin`.

Verification status:
- Not yet browser-verified after rebuild because Flutter CLI verification was intentionally skipped for now and browser screenshot capture became unstable.

Regression after fix:
- From `/admin`, impersonate a `user`.
- Confirm visible global banner with impersonated identity and `Esci`.
- Click `Esci`.
- Confirm `/admin` is accessible again and Admin sidebar item returns.

### P1 - Event Visibility Toggle Used Invalid Enum Value

Severity: High

Entity: Admin Events panel, `events.visibility`.

Risk:
- Clicking visibility toggle on an official event would call an update with `private`.
- The database rejects this value because `event_visibility` enum is `public` / `hidden`.
- Admin receives an error instead of changing event visibility.

DB evidence:
```sql
select t.typname, e.enumlabel
from pg_type t
join pg_enum e on e.enumtypid = t.oid
where t.typname = 'event_visibility'
order by e.enumsortorder;
```

Observed enum values:
- `public`
- `hidden`

Failure reproduced:
```sql
update public.events
set visibility = 'private'
where title = 'QA Regression Event 20260520';
```

Result:
- `ERROR: invalid input value for enum event_visibility: "private"`

Applied local fix:
- `app/lib/features/admin/presentation/admin_settings_screen.dart`
- Changed toggle target from `private` to `hidden`.

Post-fix DB-equivalent verification:
- Fixture official event updated from `public` to `hidden`.
- Same fixture updated back from `hidden` to `public`.

Recommended follow-up:
- Rebuild/reload web app and click the actual admin Event visibility toggle via browser.

### P2 - Shop Can Have `approval_status = rejected` And `is_public = true`

Severity: Medium

Entity: Admin Shops panel, `shops.approval_status`, `shops.is_public`.

Risk:
- Admin can toggle shop public visibility independently from approval status.
- A rejected shop can carry `is_public=true`, which is internally inconsistent.
- Current public shop fetch logic appears protected by requiring approved + public, so this did not expose the QA rejected shop publicly, but the data state is confusing and can regress if a future public query checks only `is_public`.

Evidence:
- QA shop was rejected.
- Visibility toggle set `is_public=true`.
- DB showed `approval_status='rejected' and is_public=true`.
- Public-equivalent filter `approval_status='approved' and is_public=true` returned zero for the QA shop.

Recommended fix:
- Disable `Pubblica` for non-approved shops, or make publish action set `approval_status='approved'` explicitly.
- Prefer conservative UI fix: show `Pubblica` only when `approval_status == approved`, and maybe show a disabled reason otherwise.

Applied local fix:
- `app/lib/features/admin/presentation/admin_settings_screen.dart`
- The shop row still displays `pub` / `hid`.
- The publish/hide action is only available when `approval_status == approved`.

### P3 - Admin Browser Automation Became Unstable After Impersonation

Severity: Medium

Entity: Local web runtime/browser session during admin QA.

Risk:
- After the impersonation flow and reload/new-tab attempts, the in-app browser rendered a black page while HTTP `/` still returned 200 and the standalone route audit was healthy.
- This may be a browser/runtime artifact, but it blocked further authenticated admin UI coverage in the same browser session.

Evidence:
- `Invoke-WebRequest http://localhost:8080/` returned `200`.
- Standalone audit script completed with `AUDIT_RESULTS=40`, `AUDIT_ERROR_ROUTES=0`.
- In-app browser reload/new tab showed black viewport after impersonation.
- Browser logs did not show a fresh app error; earlier logs only showed Supabase init/session refresh and a Noto font warning.

Recommended fix:
- First fix/globalize impersonation recovery.
- Add a targeted admin E2E script that starts from a known admin-authenticated storage state or a dedicated QA auth flow.
- For repeatable regression, avoid relying on an already-open manual browser session.

### P4 - Missing Noto Font Coverage Warning

Severity: Low

Entity: Flutter web font assets.

Risk:
- Emoji/icon-like glyphs in admin chips can render inconsistently.
- This is cosmetic, not currently blocking admin functionality.

Evidence:
- Browser warning: `Could not find a set of Noto fonts to display all missing characters`.
- Admin chips use emoji labels such as Dashboard/Approvazioni/Utenti/Piste/Negozi/Eventi.

Recommended fix:
- Prefer lucide/material icons instead of emoji in admin chips, or add the needed Noto font asset.

### P2 - Public Shop Follower Count RPC Called With Slug Instead Of UUID

Severity: Medium

Entity: Public Shops list/detail, `get_shop_follower_count(shop_uuid uuid)`.

Risk:
- `/shops` emitted HTTP 400 errors for `rest/v1/rpc/get_shop_follower_count`.
- The UI falls back to `0`, so the page remains usable, but console/API noise hides real regressions and follower counts are unreliable.

Evidence:
- Guest route audit returned `AUDIT_ERROR_ROUTES=2`.
- Both desktop and mobile `/shops` reported 400 on `get_shop_follower_count`.
- DB function signature is `get_shop_follower_count(shop_uuid uuid)`.
- Code passed `s.slug` / route slug into `shopFollowerCountProvider`.

Applied local fix:
- `app/lib/features/shops/presentation/shops_screen.dart`: `_ShopViewModel` now keeps both `id` and `slug`; follower count/follow state use UUID, navigation uses slug.
- `app/lib/features/shops/presentation/shop_detail_screen.dart`: follower count/follow state now use `shop.id`, while route/edit permissions continue to use slug.

Verification status:
- DB function works when called with a real shop UUID.
- Browser re-smoke after rebuild still pending; current running web server may not include local code edits until restarted.

## Confirmed Admin Coverage

### Access And Shell

Status: Covered by browser.

Observed:
- `/admin` loads with admin account.
- Sidebar shows Admin entry.
- Header shows active admin access for `g.santoro90@live.it`.
- Page title: `Admin`.
- Description: central panel for categories, users, tracks, shops and monitoring.

### Dashboard

Status: Covered by browser and SQL.

Observed browser values:
- Users: `9`
- Tracks: `11`
- Shops: `8`
- Events: `16`
- Track categories: `10`
- Pending approvals: `0`

SQL evidence:
```sql
select
  (select count(*) from public.profiles) as users,
  (select count(*) from public.tracks) as tracks,
  (select count(*) from public.shops) as shops,
  (select count(*) from public.events) + (select count(*) from public.community_events) as events,
  (select count(*) from public.track_categories) as track_categories,
  (select count(*) from public.tracks where approval_status='pending') + (select count(*) from public.shops where approval_status='pending') as pending_approvals;
```

Result:
- `users=9`
- `tracks=11`
- `shops=8`
- `events=16`
- `track_categories=10`
- `pending_approvals=0`

### Approvals

Status: Covered for empty-state only.

Observed:
- Section renders.
- Message: `Nessun elemento in approvazione al momento.`
- SQL confirms `pending_approvals=0`.

Not covered:
- `Apri`, `Approva`, `Rifiuta` on real pending items because no pending items exist and no fixture was created.

### Users

Status: Partially covered by browser.

Covered:
- Search field `Cerca per nome...`.
- Search query `sant`.
- Role filter chips.
- Admin filter shows one admin profile.
- User filter shows one user profile.
- Change-role dialog opens and was cancelled.
- Rename dialog opens and was cancelled.
- Impersonation button was exercised and exposed finding P1.

Not covered destructively:
- Saving a role change.
- Saving a display-name change.
- Loading additional pages, because current filtered results did not require pagination.

### Piste, Negozi, Eventi, Categories, Spot & Garage

Status: Source-mapped and DB-equivalent dispositive actions covered on QA fixtures; not fully browser-clicked after impersonation/browser capture instability.

Expected admin surfaces from code:
- Piste: list all tracks, open detail, open editor, approve/reject, delete confirmation, track category add/delete.
- Negozi: list all shops, open detail, open editor, approve/reject, publish/hide, delete confirmation, local shop service labels.
- Eventi: list official/community events, toggle official event visibility, delete confirmation.
- Spot & Garage: informational banners only.

Recommended next browser pass:
- Start from clean admin session.
- Avoid impersonation until the end.
- Exercise non-destructive open/cancel flows first.
- Use dedicated QA fixtures before executing approve/reject/delete/toggle actions.

## Dispositive Fixture Pass

Temporary QA records created:
- `tracks.slug = qa-regression-track-20260520-01`
- `shops.slug = qa-regression-shop-20260520-01`
- `events.title = QA Regression Event 20260520`
- `community_events.title = QA Regression Community Event 20260520`
- `spots.slug = qa-regression-spot-20260520-01`
- `track_categories.key = qa_regression_20260520_01`

Actions executed and verified:
- Track pending fixture created with `approval_status=pending`, `is_public=false`.
- Shop pending fixture created with `approval_status=pending`, `is_public=false`.
- Public spot fixture visible from `public.public_spots`.
- Track approved: `approval_status=approved`, `is_public=true`.
- Shop rejected: `approval_status=rejected`.
- Event hidden: `visibility=hidden`.
- Event restored public: `visibility=public`.
- Shop visibility toggled public: exposed P2 inconsistency.
- Spot note updated and visible from `public.public_spots`.
- Track category deleted.
- Official event, community event, spot, shop and track fixtures deleted.

Cleanup verification:
- All QA fixture counts returned `0`.

## Suggested Regression Checklist

1. Admin entry is visible only for real admin.
2. `/admin` guard redirects guest to login and non-admin to Home.
3. Dashboard metrics match DB counts.
4. Empty approval queue matches pending count.
5. Pending approval fixture renders all fields and supports open/approve/reject.
6. User search filters by display name.
7. Role chips filter users correctly.
8. Change-role dialog opens, cancels, and saves only on confirmation.
9. Rename dialog opens, cancels, and saves only on confirmation.
10. Impersonation shows global stop banner and can be exited from every page.
11. Track list renders status/public fields and open/editor navigation works.
12. Track approve/reject updates `approval_status` and `is_public` as expected.
13. Track delete confirmation can be cancelled without data loss.
14. Track category add/delete works on a temporary QA category.
15. Shop list renders status/public fields and open/editor navigation works.
16. Shop approve/reject updates `approval_status`.
17. Shop publish/hide updates `is_public`.
18. Shop delete confirmation can be cancelled without data loss.
19. Shop service label add is local-only and does not claim persistence.
20. Official event visibility toggle updates only `events`.
21. Community events do not show visibility toggle.
22. Event delete confirmation can be cancelled without data loss.
23. Spot & Garage informational banners render without actions.
24. Console remains free of errors during the full pass.

## Notes For Future Automated Regression

- Flutter web semantics/DOM extraction is limited; screenshot plus targeted CUA/Playwright interactions are more reliable than DOM text scraping.
- For true repeatability, create a QA-only admin account and fixture set.
- Keep destructive actions behind temporary records named with a unique prefix such as `qa-regression-YYYYMMDD-HHMM`.
- Store screenshots and JSON logs under `qa-temp/admin-regression/`.
