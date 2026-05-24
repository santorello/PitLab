-- Delta: 2026-05-24 - Immagini reali nel feed community
-- Espone nel payload della view activity_feed solo riferimenti media gia' pubblici
-- e disponibili nelle tabelle/view sorgenti.

create or replace view public.activity_feed
with (security_invoker = true)
as
select
  'track'::text as actor_type,
  t.id as actor_id,
  t.name as actor_name,
  t.slug as actor_slug,
  t.city as actor_city,
  'track_status'::text as event_type,
  case h.status
    when 'open'::public.track_status_kind then '🟢 Pista aperta'::text
    when 'wet'::public.track_status_kind then '🔵 Pista bagnata'::text
    when 'closed'::public.track_status_kind then '🔴 Pista chiusa'::text
    when 'limited'::public.track_status_kind then '🟡 Pista limitata'::text
    when 'coming'::public.track_status_kind then '🚗 Piloti in arrivo'::text
    when 'info'::public.track_status_kind then 'ℹ️ Aggiornamento scheda'::text
    else '⚪ Stato aggiornato'::text
  end as title,
  coalesce(h.message, t.name) as subtitle,
  jsonb_build_object(
    'status', h.status,
    'message', h.message,
    'slug', t.slug,
    'image_url', nullif(to_jsonb(t)->>'image_url', '')
  ) as payload,
  h.updated_at as created_at
from public.track_status_history h
join public.tracks t on t.id = h.track_id
where t.is_public = true
  and t.approval_status = 'approved'::public.approval_status

union all

select
  'track'::text as actor_type,
  t.id as actor_id,
  t.name as actor_name,
  t.slug as actor_slug,
  t.city as actor_city,
  'track_event'::text as event_type,
  '🏁 '::text || e.title as title,
  to_char((e.start_at at time zone 'Europe/Rome'), 'DD Mon YYYY HH24:MI') as subtitle,
  jsonb_build_object(
    'event_id', e.id,
    'start_at', e.start_at,
    'end_at', e.end_at,
    'description', e.description,
    'slug', t.slug,
    'image_url', nullif(to_jsonb(t)->>'image_url', '')
  ) as payload,
  e.created_at
from public.events e
join public.tracks t on t.id = e.track_id
where t.is_public = true
  and t.approval_status = 'approved'::public.approval_status
  and (e.visibility = 'public'::public.event_visibility or e.visibility is null)

union all

select
  'community'::text as actor_type,
  ce.id as actor_id,
  coalesce(ce.creator_label, 'Community'::text) as actor_name,
  null::text as actor_slug,
  ce.location as actor_city,
  'community_event'::text as event_type,
  '🎉 '::text || ce.title as title,
  (coalesce(ce.location, ''::text) || ' · '::text) || to_char((ce.starts_at at time zone 'Europe/Rome'), 'DD Mon YYYY') as subtitle,
  jsonb_build_object(
    'event_id', ce.id,
    'starts_at', ce.starts_at,
    'location', ce.location,
    'note', ce.note,
    'badge', ce.badge,
    'image_urls', ce.image_urls
  ) as payload,
  ce.created_at
from public.community_events ce

union all

select
  'spot'::text as actor_type,
  s.id as actor_id,
  s.title as actor_name,
  s.slug as actor_slug,
  s.city as actor_city,
  'new_spot'::text as event_type,
  '📍 Nuovo spot: '::text || s.title as title,
  (s.city || ' · '::text) || s.category as subtitle,
  jsonb_build_object(
    'slug', s.slug,
    'category', s.category,
    'best_for', s.best_for,
    'surface', s.surface,
    'image_urls', s.image_urls
  ) as payload,
  s.created_at
from public.public_spots s
order by created_at desc;

revoke all on public.activity_feed from public;
revoke all on public.activity_feed from anon;
revoke all on public.activity_feed from authenticated;
revoke all on public.activity_feed from service_role;
grant select on public.activity_feed to anon, authenticated, service_role;
