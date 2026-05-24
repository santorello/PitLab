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
  jsonb_build_object('status', h.status, 'message', h.message, 'slug', t.slug) as payload,
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
    'slug', t.slug
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
    'badge', ce.badge
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
    'surface', s.surface
  ) as payload,
  s.created_at
from public.public_spots s
order by created_at desc;

revoke all on public.activity_feed from public;
revoke all on public.activity_feed from anon;
revoke all on public.activity_feed from authenticated;
revoke all on public.activity_feed from service_role;
grant select on public.activity_feed to anon, authenticated, service_role;

revoke execute on function public.complete_onboarding(text) from public, anon;
revoke execute on function public.complete_onboarding(text, text[]) from public, anon;
grant execute on function public.complete_onboarding(text) to authenticated, service_role;
grant execute on function public.complete_onboarding(text, text[]) to authenticated, service_role;

create or replace function public.complete_onboarding(
  p_preferred_city text default ''::text,
  p_user_interests text[] default '{}'::text[]
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  update public.profiles
  set
    preferred_city = coalesce(nullif(trim(p_preferred_city), ''), preferred_city),
    user_interests = case
      when array_length(p_user_interests, 1) > 0 then p_user_interests
      else user_interests
    end,
    onboarding_completed = true,
    onboarding_completed_at = coalesce(onboarding_completed_at, now()),
    updated_at = now()
  where id = auth.uid();
end;
$$;

revoke execute on function public.complete_onboarding(text, text[]) from public, anon;
grant execute on function public.complete_onboarding(text, text[]) to authenticated, service_role;

revoke execute on function public.request_account_deletion() from public, anon;
grant execute on function public.request_account_deletion() to authenticated, service_role;

revoke execute on function public.update_shop_rich_fields(uuid, text, text, text[], text, text, text, text[]) from public, anon;
grant execute on function public.update_shop_rich_fields(uuid, text, text, text[], text, text, text, text[]) to authenticated, service_role;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function public.set_updated_at() from public, anon, authenticated;
grant execute on function public.set_updated_at() to service_role;
