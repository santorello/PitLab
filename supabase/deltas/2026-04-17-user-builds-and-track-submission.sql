-- ────────────────────────────────────────────────────────────────────────────
-- 2026-04-17: user_builds + track organizer submission RLS
-- ────────────────────────────────────────────────────────────────────────────

-- ── user_builds ────────────────────────────────────────────────────────────
-- Ogni utente può avere più build/modelli nel suo "garage".
-- is_public=true  → visibile a chiunque nel profilo pubblico
-- is_public=false → visibile solo al proprietario (enforced da RLS)

create table public.user_builds (
  id          uuid        primary key default gen_random_uuid(),
  owner_id    uuid        not null references public.profiles(id) on delete cascade,
  title       text        not null,
  meta        text        not null default '',
  specs       text[]      not null default '{}',
  -- Solo URL (http/https o storage path). Data-URL base64 NON vengono persistiti qui.
  image_urls  text[]      not null default '{}',
  is_public   boolean     not null default false,
  created_at  timestamptz not null default timezone('utc', now()),
  updated_at  timestamptz not null default timezone('utc', now())
);

create index user_builds_owner_idx  on public.user_builds (owner_id);
create index user_builds_public_idx on public.user_builds (is_public) where is_public = true;

create trigger user_builds_updated_at
  before update on public.user_builds
  for each row execute function public.set_updated_at();

alter table public.user_builds enable row level security;

create policy "user_builds: owner reads all"
  on public.user_builds for select
  using (owner_id = auth.uid());

create policy "user_builds: public reads public"
  on public.user_builds for select
  using (is_public = true);

create policy "user_builds: owner inserts"
  on public.user_builds for insert
  with check (owner_id = auth.uid());

create policy "user_builds: owner updates"
  on public.user_builds for update
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "user_builds: owner deletes"
  on public.user_builds for delete
  using (owner_id = auth.uid());

-- ── Track submission da track_organizer ──────────────────────────────────
-- Permette a chi ha ruolo track_organizer di:
--  • INSERT una track propria con approval_status IN (draft, pending)
--  • SELECT le proprie track (qualsiasi stato: pending, rejected, approved)
--  • UPDATE le proprie track NON ancora approvate

create policy "tracks: organizer reads own"
  on public.tracks for select
  using (
    submitted_by = auth.uid()
    and exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('track_organizer', 'admin')
    )
  );

create policy "tracks: organizer inserts pending"
  on public.tracks for insert
  with check (
    submitted_by = auth.uid()
    and approval_status in ('draft', 'pending')
    and is_public = false
    and exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('track_organizer', 'admin')
    )
  );

create policy "tracks: organizer updates own draft"
  on public.tracks for update
  using (
    submitted_by = auth.uid()
    and approval_status in ('draft', 'pending')
    and exists (
      select 1 from public.profiles
      where id = auth.uid() and role in ('track_organizer', 'admin')
    )
  )
  with check (
    submitted_by = auth.uid()
    and approval_status in ('draft', 'pending')
    and is_public = false
  );
