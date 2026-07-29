-- 2026-06-02 — Beta hardening: covering index sulle foreign key segnalate dal performance advisor
-- STATO: già applicato su pitlap-dev (migration: beta_add_missing_fk_indexes)
--
-- 17 FK senza indice di copertura -> JOIN e cascade lenti con dati reali.
-- CREATE INDEX semplice (non CONCURRENTLY) perché apply_migration gira in transazione;
-- IF NOT EXISTS rende lo script idempotente per il replay su prod.

CREATE INDEX IF NOT EXISTS idx_approval_requests_organization_id ON public.approval_requests (organization_id);
CREATE INDEX IF NOT EXISTS idx_approval_requests_reviewed_by      ON public.approval_requests (reviewed_by);
CREATE INDEX IF NOT EXISTS idx_approval_requests_submitted_by     ON public.approval_requests (submitted_by);
CREATE INDEX IF NOT EXISTS idx_events_created_by                  ON public.events (created_by);
CREATE INDEX IF NOT EXISTS idx_notifications_created_by           ON public.notifications (created_by);
CREATE INDEX IF NOT EXISTS idx_org_memberships_invited_by         ON public.organization_memberships (invited_by);
CREATE INDEX IF NOT EXISTS idx_shop_managers_granted_by           ON public.shop_managers (granted_by);
CREATE INDEX IF NOT EXISTS idx_shops_organization_id              ON public.shops (organization_id);
CREATE INDEX IF NOT EXISTS idx_shops_reviewed_by                  ON public.shops (reviewed_by);
CREATE INDEX IF NOT EXISTS idx_track_managers_granted_by          ON public.track_managers (granted_by);
CREATE INDEX IF NOT EXISTS idx_track_media_track_id               ON public.track_media (track_id);
CREATE INDEX IF NOT EXISTS idx_track_status_current_updated_by    ON public.track_status_current (updated_by);
CREATE INDEX IF NOT EXISTS idx_track_status_history_updated_by    ON public.track_status_history (updated_by);
CREATE INDEX IF NOT EXISTS idx_tracks_organization_id             ON public.tracks (organization_id);
CREATE INDEX IF NOT EXISTS idx_tracks_reviewed_by                 ON public.tracks (reviewed_by);
CREATE INDEX IF NOT EXISTS idx_tracks_submitted_by                ON public.tracks (submitted_by);
CREATE INDEX IF NOT EXISTS idx_weekly_featured_builds_owner_id    ON public.weekly_featured_builds (owner_id);
