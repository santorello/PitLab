create type public.organization_membership_role as enum ('owner', 'manager', 'editor', 'staff', 'viewer');
create type public.organization_membership_status as enum ('invited', 'active', 'disabled');
create type public.approval_status as enum ('draft', 'pending', 'approved', 'rejected', 'archived');
create type public.approval_entity_type as enum ('track', 'shop', 'spot');
create type public.notification_kind as enum ('approval_requested', 'approval_decided', 'ownership_assigned', 'system');

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

alter table public.tracks
  add column organization_id uuid references public.organizations (id) on delete set null,
  add column approval_status public.approval_status not null default 'approved',
  add column submitted_by uuid references public.profiles (id) on delete set null,
  add column reviewed_by uuid references public.profiles (id) on delete set null,
  add column reviewed_at timestamptz,
  add column review_notes text,
  add column published_at timestamptz,
  add column archived_at timestamptz;

alter table public.shops
  add column organization_id uuid references public.organizations (id) on delete set null,
  add column approval_status public.approval_status not null default 'approved',
  add column submitted_by uuid references public.profiles (id) on delete set null,
  add column reviewed_by uuid references public.profiles (id) on delete set null,
  add column reviewed_at timestamptz,
  add column review_notes text,
  add column published_at timestamptz,
  add column archived_at timestamptz;

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

create index tracks_approval_status_idx on public.tracks (approval_status);
create index shops_approval_status_idx on public.shops (approval_status);
create index organization_memberships_user_id_idx on public.organization_memberships (user_id);
create index approval_requests_status_idx on public.approval_requests (status);
create index approval_requests_entity_idx on public.approval_requests (entity_type, entity_id);
create index notification_recipients_user_id_idx on public.notification_recipients (user_id);

create trigger organizations_set_updated_at
before update on public.organizations
for each row execute function public.set_updated_at();

create trigger organization_memberships_set_updated_at
before update on public.organization_memberships
for each row execute function public.set_updated_at();

create trigger approval_requests_set_updated_at
before update on public.approval_requests
for each row execute function public.set_updated_at();

alter table public.organizations enable row level security;
alter table public.organization_memberships enable row level security;
alter table public.approval_requests enable row level security;
alter table public.notifications enable row level security;
alter table public.notification_recipients enable row level security;

drop policy if exists "public can read public tracks" on public.tracks;
create policy "public can read public tracks"
on public.tracks
for select
to anon, authenticated
using (is_public = true and approval_status = 'approved');

drop policy if exists "public can read public shops" on public.shops;
create policy "public can read public shops"
on public.shops
for select
to anon, authenticated
using (is_public = true and approval_status = 'approved');

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
