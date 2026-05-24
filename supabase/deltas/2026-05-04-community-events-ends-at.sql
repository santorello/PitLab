-- Add ends_at column to community_events for multi-day or timed events.
-- NULL means no explicit end date (open-ended / same day as starts_at).

alter table public.community_events
  add column if not exists ends_at timestamptz;
