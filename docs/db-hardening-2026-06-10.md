# DB hardening — audit sicurezza & performance (2026-06-10)

Audit eseguito con gli advisor Supabase su `pitlap-dev` (mqieterttnqdtdguaqoe) e relativi interventi. Delta applicati:

- `supabase/deltas/2026-06-10-prod-alignment.sql` — fix D01/D05/D10/D11 (solo scritto, **da applicare su prod manualmente**)
- `supabase/deltas/2026-06-10-rls-consolidation.sql` — applicato su dev (migration `rls_consolidation_and_fk_indexes`), da includere nel rollout prod

## Interventi fatti

### RLS consolidation (advisor: 108 lint `multiple_permissive_policies` → risolti i principali)

Le tabelle `spots`, `external_links`, `community_events`, `user_builds`, `profiles`, `track_category_links` avevano una policy admin `FOR ALL` sovrapposta alle policy owner/public su ogni azione: Postgres valutava 2-4 policy permissive per riga. Consolidate in una sola policy per comando con `OR is_admin()`. Semantica permessi invariata, verificata policy per policy.

`tracks` lasciata intatta di proposito: il flusso gestore/organizer è stato appena stabilizzato (delta prod-alignment) e i 4 lint residui valgono il rischio evitato. Da rivedere dopo il Gate Alpha.

### Indici FK (advisor: `unindexed_foreign_keys`)

Aggiunti: `event_rsvps_user_id_idx`, `track_category_links_category_id_idx`, `track_services_service_type_id_idx`.

## Decisioni documentate (nessun intervento)

### SECURITY DEFINER esposti ad anon — intenzionali

`is_admin()`, `is_track_manager(uuid)`, `is_shop_manager(uuid)`: servono dentro le RLS policy anche per query guest; ritornano solo boolean, nessun dato. `get_public_track_arrival_summary`, `get_track_follower_count`, `get_shop_follower_count`: espongono solo aggregati pubblici by design (privacy arrivals già verificata). `complete_onboarding`, `request_account_deletion`, `update_shop_rich_fields`: solo `authenticated`, tutte ancorate a `auth.uid()` o check manager interno.

### Indici inutilizzati (advisor: 32 lint `unused_index`) — censiti, NON rimossi

In pre-alpha il traffico non è rappresentativo: molti indici servono flussi non ancora esercitati (notifiche, organizzazioni, approvazioni). Rivalutare dopo 3 mesi di dato reale post-alpha. Elenco al 2026-06-10:

`user_build_votes_build_created_idx`, `user_build_votes_user_idx` (user_build_votes); `weekly_featured_builds_build_idx`, `idx_weekly_featured_builds_owner_id` (weekly_featured_builds); `profiles_home_location_idx`, `profiles_public_slug_idx` (profiles); `tracks_approval_status_idx`, `idx_tracks_organization_id`, `idx_tracks_reviewed_by` (tracks); `organization_memberships_user_id_idx`, `idx_org_memberships_invited_by` (organization_memberships); `approval_requests_status_idx`, `approval_requests_entity_idx`, `idx_approval_requests_organization_id`, `idx_approval_requests_reviewed_by`, `idx_approval_requests_submitted_by` (approval_requests); `notification_recipients_user_id_idx` (notification_recipients); `idx_shop_managers_granted_by` (shop_managers); `idx_shops_organization_id`, `idx_shops_reviewed_by` (shops); `idx_track_managers_granted_by` (track_managers); `spots_city_idx`, `spots_category_idx`, `spots_custom_idx` (spots); `community_events_starts_idx` (community_events); `idx_events_created_by` (events); `idx_notifications_created_by` (notifications); `idx_track_media_track_id` (track_media); `idx_track_status_current_updated_by` (track_status_current); `idx_track_status_history_updated_by` (track_status_history); `external_links_owner_idx`, `external_links_entity_idx` (external_links).

## Azioni manuali residue (Giuseppe)

1. Applicare su `pitlap-prod` i due delta, in quest'ordine: `2026-06-10-prod-alignment.sql`, poi `2026-06-10-rls-consolidation.sql`.
2. Dashboard Auth (dev e prod): abilitare **Leaked password protection**.
3. Dopo l'applicazione su prod, rilanciare gli advisor e verificare la sparizione dei lint corrispondenti.
