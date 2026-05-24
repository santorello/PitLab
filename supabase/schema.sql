create extension if not exists pgcrypto;

create type public.app_role as enum ('user', 'shop_owner', 'track_organizer', 'admin');
create type public.track_status_kind as enum ('open', 'wet', 'closed', 'unknown');
create type public.arrival_status as enum ('coming', 'maybe', 'cancelled');
create type public.event_visibility as enum ('public', 'hidden');
create type public.event_rsvp_status as enum ('going', 'maybe', 'cancelled');
create type public.track_media_type as enum ('cover', 'logo', 'gallery');
create type public.organization_membership_role as enum ('owner', 'manager', 'editor', 'staff', 'viewer');
create type public.organization_membership_status as enum ('invited', 'active', 'disabled');
create type public.approval_status as enum ('draft', 'pending', 'approved', 'rejected', 'archived');
create type public.approval_entity_type as enum ('track', 'shop', 'spot');
create type public.notification_kind as enum ('approval_requested', 'approval_decided', 'ownership_assigned', 'system');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

revoke execute on function public.set_updated_at() from public, anon, authenticated;
grant execute on function public.set_updated_at() to service_role;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url text,
  preferred_language text not null default 'it' check (preferred_language in ('it', 'en')),
  role public.app_role not null default 'user',
  preferred_city text,
  onboarding_completed_at timestamptz,
  deletion_requested_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.tracks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  slug text not null unique,
  name text not null,
  short_description text,
  description text,
  address text,
  city text not null,
  country text not null default 'Italy',
  latitude double precision,
  longitude double precision,
  external_map_url text,
  approval_status public.approval_status not null default 'approved',
  submitted_by uuid references public.profiles (id) on delete set null,
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  review_notes text,
  published_at timestamptz,
  archived_at timestamptz,
  is_public boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.shops (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  slug text not null unique,
  name text not null,
  short_description text,
  subtitle text,
  organization_name text,
  description text,
  address text,
  city text not null,
  country text not null default 'Italy',
  latitude double precision,
  longitude double precision,
  external_map_url text,
  website_url text,
  phone text,
  image_url text,
  gallery_images text[] default '{}',
  service_labels text[] default '{}',
  hours text,
  contacts text,
  notes text,
  approval_status public.approval_status not null default 'approved',
  submitted_by uuid references public.profiles (id) on delete set null,
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  review_notes text,
  published_at timestamptz,
  archived_at timestamptz,
  is_public boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  legal_name text not null,
  display_name text not null,
  description text,
  logo_url text,
  website_url text,
  email text,
  phone text,
  address text,
  city text,
  country text not null default 'Italy',
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.organization_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.organization_membership_role not null default 'manager',
  status public.organization_membership_status not null default 'active',
  invited_by uuid references public.profiles (id) on delete set null,
  accepted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (organization_id, user_id)
);

create table public.track_categories (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label_it text not null,
  label_en text not null,
  sort_order integer not null default 0
);

create table public.track_category_links (
  track_id uuid not null references public.tracks (id) on delete cascade,
  category_id uuid not null references public.track_categories (id) on delete cascade,
  primary key (track_id, category_id)
);

create table public.track_status_current (
  track_id uuid primary key references public.tracks (id) on delete cascade,
  status public.track_status_kind not null default 'unknown',
  message text,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.track_status_history (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks (id) on delete cascade,
  status public.track_status_kind not null,
  message text,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.service_types (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label_it text not null,
  label_en text not null,
  icon_key text,
  sort_order integer not null default 0
);

create table public.track_services (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks (id) on delete cascade,
  service_type_id uuid not null references public.service_types (id) on delete cascade,
  is_available boolean not null default false,
  notes text,
  updated_at timestamptz not null default timezone('utc', now()),
  unique (track_id, service_type_id)
);

create table public.arrivals (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  arrival_date date not null,
  status public.arrival_status not null default 'coming',
  note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (track_id, user_id, arrival_date)
);

create table public.track_follows (
  track_id uuid not null references public.tracks (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (track_id, user_id)
);

create table public.shop_follows (
  shop_id uuid not null references public.shops (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (shop_id, user_id)
);

create table public.user_consents (
  user_id uuid not null references public.profiles (id) on delete cascade,
  consent_type text not null check (
    consent_type in (
      'terms_accepted',
      'privacy_notice_seen',
      'marketing_email_opt_in'
    )
  ),
  accepted boolean not null default false,
  document_version text not null,
  source text not null default 'web_magic_link',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, consent_type)
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks (id) on delete cascade,
  title text not null,
  description text,
  start_at timestamptz not null,
  end_at timestamptz,
  visibility public.event_visibility not null default 'public',
  rsvp_enabled boolean not null default true,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (end_at is null or end_at >= start_at)
);

create table public.event_rsvps (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  status public.event_rsvp_status not null default 'going',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (event_id, user_id)
);

create table public.track_managers (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  granted_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (track_id, user_id)
);

create table public.shop_managers (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  granted_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (shop_id, user_id)
);

create table public.spots (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  city text not null,
  category text not null default '',
  best_for text not null default '',
  surface text not null default '',
  note text not null default '',
  image_accent bigint not null default 4278190080,
  photo_count integer not null default 0,
  address text,
  latitude double precision,
  longitude double precision,
  image_urls text[] not null default '{}',
  video_url text,
  is_custom boolean not null default false,
  owner_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index spots_city_idx on public.spots (city);
create index spots_category_idx on public.spots (category);
create index spots_custom_idx on public.spots (owner_id) where is_custom = true;

create trigger spots_updated_at
before update on public.spots
for each row execute function public.set_updated_at();

alter table public.spots enable row level security;

create policy "spots: public reads all"
on public.spots for select
using (true);

create policy "spots: owner inserts custom"
on public.spots for insert
with check (is_custom = true and owner_id = auth.uid() and auth.uid() is not null);

create policy "spots: owner updates custom"
on public.spots for update
using (is_custom = true and owner_id = auth.uid())
with check (is_custom = true and owner_id = auth.uid());

create policy "spots: owner deletes custom"
on public.spots for delete
using (is_custom = true and owner_id = auth.uid());

create policy "spots: admins manage all"
on public.spots for all
using (
  exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  )
);

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated, service_role;

create or replace function private.is_spot_owned_by_current_user(target_spot_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.spots s
      where s.id = target_spot_id
        and s.owner_id = auth.uid()
    );
$$;

revoke execute on function private.is_spot_owned_by_current_user(uuid) from public;
grant execute on function private.is_spot_owned_by_current_user(uuid)
to anon, authenticated, service_role;

create view public.public_spots
with (security_invoker = true)
as
select
  s.id,
  s.slug,
  s.title,
  s.city,
  s.category,
  s.best_for,
  s.surface,
  s.note,
  s.image_accent,
  s.photo_count,
  s.address,
  s.latitude,
  s.longitude,
  s.image_urls,
  s.video_url,
  s.is_custom,
  s.created_at,
  private.is_spot_owned_by_current_user(s.id) as is_owned_by_current_user
from public.spots s;

revoke all on public.public_spots from public;
revoke all on public.public_spots from anon;
revoke all on public.public_spots from authenticated;
revoke all on public.public_spots from service_role;
grant select on public.public_spots to anon, authenticated, service_role;

revoke all on public.spots from public, anon, authenticated;
grant select (
  id, slug, title, city, category, best_for, surface, note, image_accent,
  photo_count, address, latitude, longitude, image_urls, video_url,
  is_custom, created_at, updated_at
) on public.spots to anon, authenticated;
grant insert (
  slug, title, city, category, best_for, surface, note, image_accent,
  photo_count, address, latitude, longitude, image_urls, video_url,
  is_custom, owner_id
) on public.spots to authenticated;
grant update (
  title, city, category, best_for, surface, note, image_accent,
  photo_count, address, latitude, longitude, image_urls, video_url
) on public.spots to authenticated;
grant delete on public.spots to authenticated;

create view public.activity_feed
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

create table public.track_media (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks (id) on delete cascade,
  storage_path text not null,
  media_type public.track_media_type not null default 'cover',
  alt_it text,
  alt_en text,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.tracks
  add constraint tracks_organization_id_fkey
  foreign key (organization_id) references public.organizations (id) on delete set null;

alter table public.shops
  add constraint shops_organization_id_fkey
  foreign key (organization_id) references public.organizations (id) on delete set null;

create table public.approval_requests (
  id uuid primary key default gen_random_uuid(),
  entity_type public.approval_entity_type not null,
  entity_id uuid,
  organization_id uuid references public.organizations (id) on delete set null,
  submitted_by uuid references public.profiles (id) on delete set null,
  status public.approval_status not null default 'pending',
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  review_notes text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  kind public.notification_kind not null default 'system',
  entity_type public.approval_entity_type,
  entity_id uuid,
  title text not null,
  body text,
  payload jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now())
);

create table public.notification_recipients (
  notification_id uuid not null references public.notifications (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  read_at timestamptz,
  archived_at timestamptz,
  primary key (notification_id, user_id)
);

-- SECURITY DEFINER obbligatorio: queste funzioni vengono chiamate dalle policy RLS
-- delle stesse tabelle che leggono. Senza security definer si genera ricorsione infinita.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.is_track_manager(target_track_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.track_managers
    where track_id = target_track_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.is_shop_manager(target_shop_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.shop_managers
    where shop_id = target_shop_id
      and user_id = auth.uid()
  );
$$;

revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_track_manager(uuid) from public, anon;
revoke execute on function public.is_shop_manager(uuid) from public, anon;
grant execute on function public.is_admin() to authenticated, service_role;
grant execute on function public.is_track_manager(uuid) to authenticated, service_role;
grant execute on function public.is_shop_manager(uuid) to authenticated, service_role;

create or replace function public.auto_link_shop_manager_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.submitted_by is not null then
    insert into public.shop_managers (shop_id, user_id, granted_by)
    values (new.id, new.submitted_by, new.submitted_by)
    on conflict (shop_id, user_id) do nothing;
  end if;

  return new;
end;
$$;

create or replace function public.get_public_track_arrival_summary(
  track_uuid uuid,
  target_date date default current_date
)
returns table (
  coming_count bigint,
  maybe_count bigint,
  cancelled_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    count(*) filter (where arrivals.status = 'coming') as coming_count,
    count(*) filter (where arrivals.status = 'maybe') as maybe_count,
    count(*) filter (where arrivals.status = 'cancelled') as cancelled_count
  from public.arrivals
  where arrivals.track_id = track_uuid
    and arrivals.arrival_date = target_date
    and exists (
      select 1
      from public.tracks
      where tracks.id = track_uuid
        and tracks.is_public = true
    );
$$;

-- Conteggio follower pista (bypassa RLS — restituisce solo aggregato)
create or replace function public.get_track_follower_count(track_uuid uuid)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*) from public.track_follows where track_id = track_uuid;
$$;

-- Conteggio follower negozio
create or replace function public.get_shop_follower_count(shop_uuid uuid)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*) from public.shop_follows where shop_id = shop_uuid;
$$;

grant execute on function public.get_track_follower_count(uuid) to anon, authenticated;
grant execute on function public.get_shop_follower_count(uuid)  to anon, authenticated;

create index tracks_is_public_idx on public.tracks (is_public);
create index tracks_approval_status_idx on public.tracks (approval_status);
create index shops_is_public_idx on public.shops (is_public);
create index shops_approval_status_idx on public.shops (approval_status);
create index arrivals_track_id_idx on public.arrivals (track_id);
create index arrivals_user_id_idx on public.arrivals (user_id);
create index arrivals_arrival_date_idx on public.arrivals (arrival_date);
create index track_follows_user_id_idx on public.track_follows (user_id);
create index shop_follows_user_id_idx on public.shop_follows (user_id);
create index user_consents_user_id_idx on public.user_consents (user_id);
create index events_track_id_idx on public.events (track_id);
create index events_start_at_idx on public.events (start_at);
create index track_managers_track_id_idx on public.track_managers (track_id);
create index track_managers_user_id_idx on public.track_managers (user_id);
create index shop_managers_shop_id_idx on public.shop_managers (shop_id);
create index shop_managers_user_id_idx on public.shop_managers (user_id);
create index shops_submitted_by_idx on public.shops (submitted_by);
create index community_events_author_id_idx on public.community_events (author_id);
create index external_links_owner_entity_idx on public.external_links (
  owner_id,
  entity_type,
  entity_id,
  sort_order
);
create index track_status_history_track_id_idx on public.track_status_history (track_id);
create index organization_memberships_user_id_idx on public.organization_memberships (user_id);
create index approval_requests_status_idx on public.approval_requests (status);
create index approval_requests_entity_idx on public.approval_requests (entity_type, entity_id);
create index notification_recipients_user_id_idx on public.notification_recipients (user_id);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger tracks_set_updated_at
before update on public.tracks
for each row execute function public.set_updated_at();

create trigger shops_set_updated_at
before update on public.shops
for each row execute function public.set_updated_at();

drop trigger if exists shops_auto_link_manager_on_insert on public.shops;
create trigger shops_auto_link_manager_on_insert
after insert on public.shops
for each row execute function public.auto_link_shop_manager_on_insert();

create trigger organizations_set_updated_at
before update on public.organizations
for each row execute function public.set_updated_at();

create trigger organization_memberships_set_updated_at
before update on public.organization_memberships
for each row execute function public.set_updated_at();

create trigger track_services_set_updated_at
before update on public.track_services
for each row execute function public.set_updated_at();

create trigger arrivals_set_updated_at
before update on public.arrivals
for each row execute function public.set_updated_at();

create trigger user_consents_set_updated_at
before update on public.user_consents
for each row execute function public.set_updated_at();

create trigger events_set_updated_at
before update on public.events
for each row execute function public.set_updated_at();

create trigger approval_requests_set_updated_at
before update on public.approval_requests
for each row execute function public.set_updated_at();

create trigger event_rsvps_set_updated_at
before update on public.event_rsvps
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

grant execute on function public.get_public_track_arrival_summary(uuid, date)
to anon, authenticated;

alter table public.profiles enable row level security;
alter table public.tracks enable row level security;
alter table public.shops enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.track_categories enable row level security;
alter table public.track_category_links enable row level security;
alter table public.track_status_current enable row level security;
alter table public.track_status_history enable row level security;
alter table public.service_types enable row level security;
alter table public.track_services enable row level security;
alter table public.arrivals enable row level security;
alter table public.track_follows enable row level security;
alter table public.shop_follows enable row level security;
alter table public.user_consents enable row level security;
alter table public.events enable row level security;
alter table public.event_rsvps enable row level security;
alter table public.track_managers enable row level security;
alter table public.shop_managers enable row level security;
alter table public.track_media enable row level security;
alter table public.approval_requests enable row level security;
alter table public.notifications enable row level security;
alter table public.notification_recipients enable row level security;

create policy "profiles are readable by signed in users"
on public.profiles
for select
to authenticated
using (true);

create policy "users manage own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "admins can manage profiles"
on public.profiles
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "public can read public tracks"
on public.tracks
for select
to anon, authenticated
using (is_public = true and approval_status = 'approved');

create policy "admins can manage tracks"
on public.tracks
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "public can read public shops"
on public.shops
for select
to anon, authenticated
using (is_public = true and approval_status = 'approved');

create policy "shop submitters can insert own shops"
on public.shops
for insert
to authenticated
with check (
  auth.uid() = submitted_by
  and is_public = false
  and approval_status in ('draft', 'pending')
);

create policy "organizations visible to active members and admins"
on public.organizations
for select
to authenticated
using (
  public.is_admin()
  or exists (
    select 1
    from public.organization_memberships
    where organization_memberships.organization_id = organizations.id
      and organization_memberships.user_id = auth.uid()
      and organization_memberships.status = 'active'
  )
);

create policy "admins can manage organizations"
on public.organizations
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "memberships visible to related users and admins"
on public.organization_memberships
for select
to authenticated
using (
  public.is_admin()
  or user_id = auth.uid()
  or exists (
    select 1
    from public.organization_memberships current_membership
    where current_membership.organization_id = organization_memberships.organization_id
      and current_membership.user_id = auth.uid()
      and current_membership.status = 'active'
  )
);

create policy "admins can manage memberships"
on public.organization_memberships
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "shop managers can manage shops"
on public.shops
for all
to authenticated
using (public.is_shop_manager(id) or public.is_admin())
with check (public.is_shop_manager(id) or public.is_admin());

create policy "admins manage approval requests"
on public.approval_requests
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "submitters can read approval requests"
on public.approval_requests
for select
to authenticated
using (submitted_by = auth.uid() or public.is_admin());

create policy "admins manage notifications"
on public.notifications
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "users read own notification inbox"
on public.notification_recipients
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy "admins manage notification inbox"
on public.notification_recipients
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "public can read categories"
on public.track_categories
for select
to anon, authenticated
using (true);

create policy "admins can manage categories"
on public.track_categories
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "public can read track category links"
on public.track_category_links
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.tracks
    where tracks.id = track_category_links.track_id
      and tracks.is_public = true
  )
);

create policy "admins can manage track category links"
on public.track_category_links
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "public can read current track status"
on public.track_status_current
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.tracks
    where tracks.id = track_status_current.track_id
      and tracks.is_public = true
      and tracks.approval_status = 'approved'
  )
);

create policy "track managers can update current track status"
on public.track_status_current
for update
to authenticated
using (public.is_track_manager(track_id) or public.is_admin())
with check (public.is_track_manager(track_id) or public.is_admin());

create policy "track managers can insert current track status"
on public.track_status_current
for insert
to authenticated
with check (public.is_track_manager(track_id) or public.is_admin());

create policy "public can read track status history"
on public.track_status_history
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.tracks
    where tracks.id = track_status_history.track_id
      and tracks.is_public = true
      and tracks.approval_status = 'approved'
  )
);

create policy "track managers can insert track status history"
on public.track_status_history
for insert
to authenticated
with check (public.is_track_manager(track_id) or public.is_admin());

create policy "admins can manage track status history"
on public.track_status_history
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "public can read service types"
on public.service_types
for select
to anon, authenticated
using (true);

create policy "admins can manage service types"
on public.service_types
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "public can read track services"
on public.track_services
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.tracks
    where tracks.id = track_services.track_id
      and tracks.is_public = true
  )
);

create policy "track managers can manage track services"
on public.track_services
for all
to authenticated
using (public.is_track_manager(track_id) or public.is_admin())
with check (public.is_track_manager(track_id) or public.is_admin());

create policy "users can manage own arrivals"
on public.arrivals
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can read own track follows"
on public.track_follows
for select
to authenticated
using (auth.uid() = user_id);

create policy "users can manage own track follows"
on public.track_follows
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can read own shop follows"
on public.shop_follows
for select
to authenticated
using (auth.uid() = user_id);

create policy "users can manage own shop follows"
on public.shop_follows
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can read own consents"
on public.user_consents
for select
to authenticated
using (auth.uid() = user_id);

create policy "users can manage own consents"
on public.user_consents
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "track managers can read arrivals on managed tracks"
on public.arrivals
for select
to authenticated
using (public.is_track_manager(track_id) or public.is_admin());

create policy "public can read public events"
on public.events
for select
to anon, authenticated
using (
  visibility = 'public'
  and exists (
    select 1
    from public.tracks
    where tracks.id = events.track_id
      and tracks.is_public = true
      and tracks.approval_status = 'approved'
  )
);

create policy "track managers can manage events"
on public.events
for all
to authenticated
using (public.is_track_manager(track_id) or public.is_admin())
with check (public.is_track_manager(track_id) or public.is_admin());

create policy "users can read own event rsvps"
on public.event_rsvps
for select
to authenticated
using (auth.uid() = user_id or public.is_admin());

create policy "users can manage own event rsvps"
on public.event_rsvps
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "track managers can read event rsvps for managed track events"
on public.event_rsvps
for select
to authenticated
using (
  exists (
    select 1
    from public.events
    where events.id = event_rsvps.event_id
      and (public.is_track_manager(events.track_id) or public.is_admin())
  )
);

create policy "admins can manage track managers"
on public.track_managers
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "track managers are visible to authenticated users"
on public.track_managers
for select
to authenticated
using (public.is_admin() or public.is_track_manager(track_id));

create policy "admins can manage shop managers"
on public.shop_managers
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "shop managers are visible to authenticated users"
on public.shop_managers
for select
to authenticated
using (public.is_admin() or public.is_shop_manager(shop_id));

create policy "public can read public track media"
on public.track_media
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.tracks
    where tracks.id = track_media.track_id
      and tracks.is_public = true
  )
);

create policy "track managers can manage track media"
on public.track_media
for all
to authenticated
using (public.is_track_manager(track_id) or public.is_admin())
with check (public.is_track_manager(track_id) or public.is_admin());

insert into public.track_categories (key, label_it, label_en, sort_order)
values
  ('buggy', 'Buggy', 'Buggy', 10),
  ('mini_z', 'Mini-Z', 'Mini-Z', 20),
  ('mini4wd', 'Mini4WD', 'Mini4WD', 30),
  ('scaler', 'Scaler', 'Scaler', 40),
  ('bashing', 'Bashing', 'Bashing', 50)
on conflict (key) do nothing;

insert into public.service_types (key, label_it, label_en, icon_key, sort_order)
values
  ('power_220v', '220V', '220V', 'bolt', 10),
  ('compressed_air', 'Aria compressa', 'Compressed air', 'wind', 20),
  ('tables', 'Tavoli', 'Tables', 'table', 30),
  ('chairs', 'Sedie', 'Chairs', 'chair', 40),
  ('toilets', 'Bagni', 'Toilets', 'wc', 50),
  ('food', 'Ristoro', 'Food', 'utensils', 60)
on conflict (key) do nothing;

-- ── Delta 2026-04-17: user_builds + track submission columns ─────────────────
-- Colonne aggiuntive su tracks per il flusso di invio piste da organizzatore

alter table public.tracks
  add column if not exists image_url text,
  add column if not exists contact_email text,
  add column if not exists phone text,
  add column if not exists organization_name text;

-- RLS aggiuntive su tracks per il flusso organizzatore
-- (le policy globali admin sono già definite sopra)

create policy "organizers can insert own tracks"
on public.tracks
for insert
to authenticated
with check (
  auth.uid() = submitted_by
  and is_public = false
  and approval_status in ('draft', 'pending')
);

create policy "organizers can update own pending tracks"
on public.tracks
for update
to authenticated
using (
  auth.uid() = submitted_by
  and approval_status in ('draft', 'pending')
)
with check (
  auth.uid() = submitted_by
  and approval_status in ('draft', 'pending')
);

create policy "organizers can read own submitted tracks"
on public.tracks
for select
to authenticated
using (
  auth.uid() = submitted_by
  or is_public = true
  or public.is_admin()
);

-- Tabella user_builds: garage personale con RLS privacy

create table if not exists public.user_builds (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null default '',
  meta text not null default '',
  specs text not null default '',
  image_urls text[] not null default '{}',
  is_public boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.user_builds enable row level security;

create trigger user_builds_set_updated_at
before update on public.user_builds
for each row execute function public.set_updated_at();

create index if not exists user_builds_owner_id_idx on public.user_builds (owner_id);

create policy "owners can manage own builds"
on public.user_builds
for all
to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

create policy "public builds are readable by anyone"
on public.user_builds
for select
to anon, authenticated
using (is_public = true);

revoke insert, update, delete, truncate, references, trigger
on all tables in schema public
from anon;

revoke truncate, references, trigger
on all tables in schema public
from authenticated;
