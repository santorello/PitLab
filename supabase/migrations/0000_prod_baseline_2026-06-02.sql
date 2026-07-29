-- ============================================================
-- PROD BASELINE 2026-06-02
-- Schema replica from DEV (mqieterttnqdtdguaqoe) to PROD (klfjvyytubiorqzfisdu)
-- NO DATA - structure only
-- ============================================================

-- ============================================================
-- SECTION 1: EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA extensions;
-- pg_stat_statements already default in new projects, skip

-- ============================================================
-- SECTION 2: CUSTOM SCHEMAS
-- ============================================================
CREATE SCHEMA IF NOT EXISTS private;

-- ============================================================
-- SECTION 3: ENUM TYPES
-- ============================================================
CREATE TYPE public.app_role AS ENUM ('user','admin','shop_owner','track_organizer');
CREATE TYPE public.approval_entity_type AS ENUM ('track','shop','spot');
CREATE TYPE public.approval_status AS ENUM ('draft','pending','approved','rejected','archived');
CREATE TYPE public.arrival_status AS ENUM ('coming','maybe','cancelled');
CREATE TYPE public.event_rsvp_status AS ENUM ('going','maybe','cancelled');
CREATE TYPE public.event_visibility AS ENUM ('public','hidden');
CREATE TYPE public.notification_kind AS ENUM ('approval_requested','approval_decided','ownership_assigned','system');
CREATE TYPE public.organization_membership_role AS ENUM ('owner','manager','editor','staff','viewer');
CREATE TYPE public.organization_membership_status AS ENUM ('invited','active','disabled');
CREATE TYPE public.track_media_type AS ENUM ('cover','logo','gallery');
CREATE TYPE public.track_status_kind AS ENUM ('open','wet','closed','unknown','info','limited','coming');

-- ============================================================
-- SECTION 4: TABLES (no FK yet)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid NOT NULL,
  display_name text,
  avatar_url text,
  preferred_language text NOT NULL DEFAULT 'it'::text,
  role public.app_role NOT NULL DEFAULT 'user'::app_role,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  preferred_city text,
  onboarding_completed_at timestamptz,
  deletion_requested_at timestamptz,
  public_slug text,
  is_public boolean NOT NULL DEFAULT false,
  user_interests text[] NOT NULL DEFAULT '{}'::text[],
  onboarding_completed boolean NOT NULL DEFAULT false,
  home_city text,
  home_country text,
  home_latitude double precision,
  home_longitude double precision,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_public_slug_key UNIQUE (public_slug),
  CONSTRAINT profiles_preferred_language_check CHECK (preferred_language = ANY (ARRAY['it'::text, 'en'::text]))
);

CREATE TABLE IF NOT EXISTS public.organizations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  slug text NOT NULL,
  legal_name text NOT NULL,
  display_name text NOT NULL,
  description text,
  logo_url text,
  website_url text,
  email text,
  phone text,
  address text,
  city text,
  country text NOT NULL DEFAULT 'Italy'::text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT organizations_pkey PRIMARY KEY (id),
  CONSTRAINT organizations_slug_key UNIQUE (slug)
);

CREATE TABLE IF NOT EXISTS public.organization_memberships (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role public.organization_membership_role NOT NULL DEFAULT 'manager'::organization_membership_role,
  status public.organization_membership_status NOT NULL DEFAULT 'active'::organization_membership_status,
  invited_by uuid,
  accepted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT organization_memberships_pkey PRIMARY KEY (id),
  CONSTRAINT organization_memberships_organization_id_user_id_key UNIQUE (organization_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.tracks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  slug text NOT NULL,
  name text NOT NULL,
  short_description text,
  description text,
  address text,
  city text NOT NULL,
  country text NOT NULL DEFAULT 'Italy'::text,
  latitude double precision,
  longitude double precision,
  external_map_url text,
  is_public boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  organization_id uuid,
  approval_status public.approval_status NOT NULL DEFAULT 'approved'::approval_status,
  submitted_by uuid,
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_notes text,
  published_at timestamptz,
  archived_at timestamptz,
  image_url text,
  contact_email text,
  phone text,
  organization_name text,
  CONSTRAINT tracks_pkey PRIMARY KEY (id),
  CONSTRAINT tracks_slug_key UNIQUE (slug)
);

CREATE TABLE IF NOT EXISTS public.shops (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  slug text NOT NULL,
  name text NOT NULL,
  short_description text,
  description text,
  address text,
  city text NOT NULL,
  country text NOT NULL DEFAULT 'Italy'::text,
  latitude double precision,
  longitude double precision,
  external_map_url text,
  website_url text,
  phone text,
  is_public boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  organization_id uuid,
  approval_status public.approval_status NOT NULL DEFAULT 'approved'::approval_status,
  submitted_by uuid,
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_notes text,
  published_at timestamptz,
  archived_at timestamptz,
  image_url text,
  subtitle text,
  organization_name text,
  service_labels text[] DEFAULT '{}'::text[],
  hours text,
  contacts text,
  notes text,
  gallery_images text[] DEFAULT '{}'::text[],
  CONSTRAINT shops_pkey PRIMARY KEY (id),
  CONSTRAINT shops_slug_key UNIQUE (slug)
);

CREATE TABLE IF NOT EXISTS public.spots (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  slug text NOT NULL,
  title text NOT NULL,
  city text NOT NULL,
  category text NOT NULL DEFAULT ''::text,
  best_for text NOT NULL DEFAULT ''::text,
  surface text NOT NULL DEFAULT ''::text,
  note text NOT NULL DEFAULT ''::text,
  image_accent bigint NOT NULL DEFAULT '4278190080'::bigint,
  photo_count integer NOT NULL DEFAULT 0,
  address text,
  latitude double precision,
  longitude double precision,
  image_urls text[] NOT NULL DEFAULT '{}'::text[],
  video_url text,
  is_custom boolean NOT NULL DEFAULT false,
  owner_id uuid,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT spots_pkey PRIMARY KEY (id),
  CONSTRAINT spots_slug_key UNIQUE (slug)
);

CREATE TABLE IF NOT EXISTS public.approval_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  entity_type public.approval_entity_type NOT NULL,
  entity_id uuid,
  organization_id uuid,
  submitted_by uuid,
  status public.approval_status NOT NULL DEFAULT 'pending'::approval_status,
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_notes text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT approval_requests_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.arrivals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  track_id uuid NOT NULL,
  user_id uuid NOT NULL,
  arrival_date date NOT NULL,
  status public.arrival_status NOT NULL DEFAULT 'coming'::arrival_status,
  note text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT arrivals_pkey PRIMARY KEY (id),
  CONSTRAINT arrivals_track_id_user_id_arrival_date_key UNIQUE (track_id, user_id, arrival_date)
);

CREATE TABLE IF NOT EXISTS public.events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  track_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  start_at timestamptz NOT NULL,
  end_at timestamptz,
  visibility public.event_visibility NOT NULL DEFAULT 'public'::event_visibility,
  rsvp_enabled boolean NOT NULL DEFAULT true,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT events_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.event_rsvps (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  user_id uuid NOT NULL,
  status public.event_rsvp_status NOT NULL DEFAULT 'going'::event_rsvp_status,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT event_rsvps_pkey PRIMARY KEY (id),
  CONSTRAINT event_rsvps_event_id_user_id_key UNIQUE (event_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.community_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  author_id uuid NOT NULL,
  title text NOT NULL,
  location text NOT NULL DEFAULT ''::text,
  venue text NOT NULL DEFAULT ''::text,
  note text NOT NULL DEFAULT ''::text,
  badge text NOT NULL DEFAULT ''::text,
  creator_label text NOT NULL DEFAULT ''::text,
  creator_role text NOT NULL DEFAULT 'user'::text,
  image_urls text[] NOT NULL DEFAULT '{}'::text[],
  starts_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  ends_at timestamptz,
  CONSTRAINT community_events_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.external_links (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  entity_type text NOT NULL,
  entity_id text NOT NULL,
  provider text NOT NULL DEFAULT 'website'::text,
  label text NOT NULL DEFAULT ''::text,
  url text NOT NULL,
  is_public boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT external_links_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  kind public.notification_kind NOT NULL DEFAULT 'system'::notification_kind,
  entity_type public.approval_entity_type,
  entity_id uuid,
  title text NOT NULL,
  body text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT notifications_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.notification_recipients (
  notification_id uuid NOT NULL,
  user_id uuid NOT NULL,
  read_at timestamptz,
  archived_at timestamptz,
  CONSTRAINT notification_recipients_pkey PRIMARY KEY (notification_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.service_types (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  key text NOT NULL,
  label_it text NOT NULL,
  label_en text NOT NULL,
  icon_key text,
  sort_order integer NOT NULL DEFAULT 0,
  CONSTRAINT service_types_pkey PRIMARY KEY (id),
  CONSTRAINT service_types_key_key UNIQUE (key)
);

CREATE TABLE IF NOT EXISTS public.shop_follows (
  shop_id uuid NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT shop_follows_pkey PRIMARY KEY (shop_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.shop_managers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  shop_id uuid NOT NULL,
  user_id uuid NOT NULL,
  granted_by uuid,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT shop_managers_pkey PRIMARY KEY (id),
  CONSTRAINT shop_managers_shop_id_user_id_key UNIQUE (shop_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.track_categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  key text NOT NULL,
  label_it text NOT NULL,
  label_en text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  CONSTRAINT track_categories_pkey PRIMARY KEY (id),
  CONSTRAINT track_categories_key_key UNIQUE (key)
);

CREATE TABLE IF NOT EXISTS public.track_category_links (
  track_id uuid NOT NULL,
  category_id uuid NOT NULL,
  CONSTRAINT track_category_links_pkey PRIMARY KEY (track_id, category_id)
);

CREATE TABLE IF NOT EXISTS public.track_follows (
  track_id uuid NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT track_follows_pkey PRIMARY KEY (track_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.track_managers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  track_id uuid NOT NULL,
  user_id uuid NOT NULL,
  granted_by uuid,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT track_managers_pkey PRIMARY KEY (id),
  CONSTRAINT track_managers_track_id_user_id_key UNIQUE (track_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.track_media (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  track_id uuid NOT NULL,
  storage_path text NOT NULL,
  media_type public.track_media_type NOT NULL DEFAULT 'cover'::track_media_type,
  alt_it text,
  alt_en text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT track_media_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.track_services (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  track_id uuid NOT NULL,
  service_type_id uuid NOT NULL,
  is_available boolean NOT NULL DEFAULT false,
  notes text,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT track_services_pkey PRIMARY KEY (id),
  CONSTRAINT track_services_track_id_service_type_id_key UNIQUE (track_id, service_type_id)
);

CREATE TABLE IF NOT EXISTS public.track_status_current (
  track_id uuid NOT NULL,
  status public.track_status_kind NOT NULL DEFAULT 'unknown'::track_status_kind,
  message text,
  updated_by uuid,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT track_status_current_pkey PRIMARY KEY (track_id)
);

CREATE TABLE IF NOT EXISTS public.track_status_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  track_id uuid NOT NULL,
  status public.track_status_kind NOT NULL,
  message text,
  updated_by uuid,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT track_status_history_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.pitcoin_action_definitions (
  action_key text NOT NULL,
  name_it text NOT NULL,
  name_en text NOT NULL,
  description_it text,
  description_en text,
  category text NOT NULL,
  base_points integer NOT NULL DEFAULT 0,
  daily_cap integer,
  per_entity_cap integer,
  lifetime_cap integer,
  cooldown_seconds integer,
  requires_approval boolean NOT NULL DEFAULT false,
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT pitcoin_action_definitions_pkey PRIMARY KEY (action_key)
);

CREATE TABLE IF NOT EXISTS public.pitcoin_badge_definitions (
  badge_key text NOT NULL,
  name_it text NOT NULL,
  name_en text NOT NULL,
  description_it text,
  description_en text,
  icon_asset text,
  category text NOT NULL,
  tier text NOT NULL,
  criteria jsonb NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT pitcoin_badge_definitions_pkey PRIMARY KEY (badge_key)
);

CREATE TABLE IF NOT EXISTS public.pitcoin_transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  action_key text NOT NULL,
  points integer NOT NULL,
  source_table text,
  source_id uuid,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  awarded_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT pitcoin_transactions_pkey PRIMARY KEY (id),
  CONSTRAINT pitcoin_transactions_dedup_uniq UNIQUE (user_id, action_key, source_table, source_id)
);

CREATE TABLE IF NOT EXISTS public.user_badges (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  badge_key text NOT NULL,
  awarded_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT user_badges_pkey PRIMARY KEY (id),
  CONSTRAINT user_badges_user_id_badge_key_key UNIQUE (user_id, badge_key)
);

CREATE TABLE IF NOT EXISTS public.user_pitcoin_balances (
  user_id uuid NOT NULL,
  total_points integer NOT NULL DEFAULT 0,
  lifetime_earned integer NOT NULL DEFAULT 0,
  last_action_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT user_pitcoin_balances_pkey PRIMARY KEY (user_id)
);

CREATE TABLE IF NOT EXISTS public.user_builds (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  title text NOT NULL,
  meta text NOT NULL DEFAULT ''::text,
  specs text[] NOT NULL DEFAULT '{}'::text[],
  image_urls text[] NOT NULL DEFAULT '{}'::text[],
  is_public boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT user_builds_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.user_build_votes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  build_id uuid NOT NULL,
  user_id uuid NOT NULL,
  value integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT user_build_votes_pkey PRIMARY KEY (id),
  CONSTRAINT user_build_votes_build_id_user_id_key UNIQUE (build_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.user_consents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  consent_type text NOT NULL,
  accepted boolean NOT NULL DEFAULT false,
  document_version text NOT NULL,
  source text NOT NULL DEFAULT 'web_magic_link'::text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT user_consents_pkey PRIMARY KEY (id),
  CONSTRAINT user_consents_user_type_unique UNIQUE (user_id, consent_type)
);

CREATE TABLE IF NOT EXISTS public.weekly_featured_builds (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  week_start date NOT NULL,
  build_id uuid NOT NULL,
  owner_id uuid NOT NULL,
  weekly_votes integer NOT NULL DEFAULT 0,
  awarded_points integer NOT NULL DEFAULT 75,
  selected_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT weekly_featured_builds_pkey PRIMARY KEY (id),
  CONSTRAINT weekly_featured_builds_week_start_key UNIQUE (week_start)
);

-- ============================================================
-- SECTION 5: FOREIGN KEYS
-- ============================================================
ALTER TABLE public.profiles ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.organization_memberships ADD CONSTRAINT organization_memberships_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE public.organization_memberships ADD CONSTRAINT organization_memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.organization_memberships ADD CONSTRAINT organization_memberships_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.tracks ADD CONSTRAINT tracks_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE public.tracks ADD CONSTRAINT tracks_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.tracks ADD CONSTRAINT tracks_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.shops ADD CONSTRAINT shops_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE public.shops ADD CONSTRAINT shops_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.shops ADD CONSTRAINT shops_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.spots ADD CONSTRAINT spots_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.approval_requests ADD CONSTRAINT approval_requests_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE public.approval_requests ADD CONSTRAINT approval_requests_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.approval_requests ADD CONSTRAINT approval_requests_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.arrivals ADD CONSTRAINT arrivals_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON DELETE CASCADE;
ALTER TABLE public.arrivals ADD CONSTRAINT arrivals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.events ADD CONSTRAINT events_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON DELETE CASCADE;
ALTER TABLE public.events ADD CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.event_rsvps ADD CONSTRAINT event_rsvps_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;
ALTER TABLE public.event_rsvps ADD CONSTRAINT event_rsvps_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.community_events ADD CONSTRAINT community_events_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.external_links ADD CONSTRAINT external_links_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.notifications ADD CONSTRAINT notifications_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.notification_recipients ADD CONSTRAINT notification_recipients_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE CASCADE;
ALTER TABLE public.notification_recipients ADD CONSTRAINT notification_recipients_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.shop_follows ADD CONSTRAINT shop_follows_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES public.shops(id) ON DELETE CASCADE;
ALTER TABLE public.shop_follows ADD CONSTRAINT shop_follows_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.shop_managers ADD CONSTRAINT shop_managers_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES public.shops(id) ON DELETE CASCADE;
ALTER TABLE public.shop_managers ADD CONSTRAINT shop_managers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.shop_managers ADD CONSTRAINT shop_managers_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.track_category_links ADD CONSTRAINT track_category_links_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON DELETE CASCADE;
ALTER TABLE public.track_category_links ADD CONSTRAINT track_category_links_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.track_categories(id) ON DELETE CASCADE;

ALTER TABLE public.track_follows ADD CONSTRAINT track_follows_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON DELETE CASCADE;
ALTER TABLE public.track_follows ADD CONSTRAINT track_follows_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.track_managers ADD CONSTRAINT track_managers_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON DELETE CASCADE;
ALTER TABLE public.track_managers ADD CONSTRAINT track_managers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.track_managers ADD CONSTRAINT track_managers_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.track_media ADD CONSTRAINT track_media_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON DELETE CASCADE;

ALTER TABLE public.track_services ADD CONSTRAINT track_services_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON DELETE CASCADE;
ALTER TABLE public.track_services ADD CONSTRAINT track_services_service_type_id_fkey FOREIGN KEY (service_type_id) REFERENCES public.service_types(id) ON DELETE CASCADE;

ALTER TABLE public.track_status_current ADD CONSTRAINT track_status_current_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON DELETE CASCADE;
ALTER TABLE public.track_status_current ADD CONSTRAINT track_status_current_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.track_status_history ADD CONSTRAINT track_status_history_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON DELETE CASCADE;
ALTER TABLE public.track_status_history ADD CONSTRAINT track_status_history_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.pitcoin_transactions ADD CONSTRAINT pitcoin_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.pitcoin_transactions ADD CONSTRAINT pitcoin_transactions_action_key_fkey FOREIGN KEY (action_key) REFERENCES public.pitcoin_action_definitions(action_key);

ALTER TABLE public.user_badges ADD CONSTRAINT user_badges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.user_badges ADD CONSTRAINT user_badges_badge_key_fkey FOREIGN KEY (badge_key) REFERENCES public.pitcoin_badge_definitions(badge_key);

ALTER TABLE public.user_pitcoin_balances ADD CONSTRAINT user_pitcoin_balances_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.user_builds ADD CONSTRAINT user_builds_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.user_build_votes ADD CONSTRAINT user_build_votes_build_id_fkey FOREIGN KEY (build_id) REFERENCES public.user_builds(id) ON DELETE CASCADE;
ALTER TABLE public.user_build_votes ADD CONSTRAINT user_build_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.user_consents ADD CONSTRAINT user_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.weekly_featured_builds ADD CONSTRAINT weekly_featured_builds_build_id_fkey FOREIGN KEY (build_id) REFERENCES public.user_builds(id) ON DELETE CASCADE;
ALTER TABLE public.weekly_featured_builds ADD CONSTRAINT weekly_featured_builds_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


-- ============================================================
-- 08 — GRANTS FULL SYNC (aggiunto 2026-06-02 dopo verifica advisor prod)
-- Il passo 07 aveva replicato solo i revoke su trg_pitcoin*/is_*; le altre
-- funzioni SECURITY DEFINER erano nate con default PUBLIC EXECUTE.
-- Questo blocco allinea prod allo stato AUTOREVOLE di dev:
--   anon executable = 3 (get_public_track_arrival_summary, get_shop/track_follower_count)
--   authenticated executable = 9 (le 3 guest + complete_onboarding x3, get_my_pitcoin_streak,
--                                 request_account_deletion, update_shop_rich_fields)
--   tutto il resto: revocato da PUBLIC/anon/authenticated.
-- (Vedi migration applicata: prod_baseline_08_grants_full_sync)
-- ============================================================
