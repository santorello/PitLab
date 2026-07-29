-- ============================================================================
-- PitLap — Sistema commenti polimorfici + segnalazioni (2026-06-10)
-- Tabelle: entity_comments, entity_comment_reports
-- View: entity_comment_counts (security_invoker)
-- RPC: report_comment(uuid, text)
-- PitCoin: azione comment_posted (5 punti, daily_cap 50, cooldown 60s) + trigger
-- Moderazione: is_hidden/hidden_reason/hidden_by solo admin (guard trigger)
-- Applicato su dev (migration entity_comments_system). Da applicare su prod.
-- Idempotente.
-- ============================================================================

begin;

create table if not exists public.entity_comments (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in ('track','shop','event','community_event','spot','user_build')),
  entity_id uuid not null,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  is_hidden boolean not null default false,
  hidden_reason text,
  hidden_by uuid references public.profiles(id),
  reported_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists entity_comments_entity_idx on public.entity_comments (entity_type, entity_id, created_at desc);
create index if not exists entity_comments_author_idx on public.entity_comments (author_id);

alter table public.entity_comments enable row level security;

drop policy if exists "entity_comments select" on public.entity_comments;
create policy "entity_comments select" on public.entity_comments
  for select using (
    (is_hidden = false) or (author_id = (select auth.uid())) or is_admin()
  );

drop policy if exists "entity_comments insert" on public.entity_comments;
create policy "entity_comments insert" on public.entity_comments
  for insert to authenticated
  with check (author_id = (select auth.uid()) and is_hidden = false);

drop policy if exists "entity_comments update" on public.entity_comments;
create policy "entity_comments update" on public.entity_comments
  for update to authenticated
  using ((author_id = (select auth.uid())) or is_admin())
  with check ((author_id = (select auth.uid())) or is_admin());

drop policy if exists "entity_comments delete" on public.entity_comments;
create policy "entity_comments delete" on public.entity_comments
  for delete to authenticated
  using ((author_id = (select auth.uid())) or is_admin());

create or replace function public.guard_comment_moderation_columns()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.is_admin() then
    new.is_hidden := old.is_hidden;
    new.hidden_reason := old.hidden_reason;
    new.hidden_by := old.hidden_by;
    new.reported_count := old.reported_count;
    new.author_id := old.author_id;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function public.guard_comment_moderation_columns() from public, anon, authenticated;

drop trigger if exists trg_guard_comment_moderation on public.entity_comments;
create trigger trg_guard_comment_moderation
  before update on public.entity_comments
  for each row execute function public.guard_comment_moderation_columns();

create table if not exists public.entity_comment_reports (
  comment_id uuid not null references public.entity_comments(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  primary key (comment_id, reporter_id)
);

alter table public.entity_comment_reports enable row level security;

drop policy if exists "comment_reports select" on public.entity_comment_reports;
create policy "comment_reports select" on public.entity_comment_reports
  for select to authenticated
  using ((reporter_id = (select auth.uid())) or is_admin());

create or replace function public.report_comment(p_comment_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  insert into public.entity_comment_reports (comment_id, reporter_id, reason)
  values (p_comment_id, auth.uid(), nullif(trim(coalesce(p_reason,'')), ''))
  on conflict do nothing;
  update public.entity_comments c
  set reported_count = (select count(*) from public.entity_comment_reports r where r.comment_id = c.id)
  where c.id = p_comment_id;
end;
$$;

revoke execute on function public.report_comment(uuid, text) from public, anon;
grant execute on function public.report_comment(uuid, text) to authenticated;

create or replace view public.entity_comment_counts
with (security_invoker = true) as
select entity_type, entity_id, count(*)::integer as comment_count
from public.entity_comments
where is_hidden = false
group by entity_type, entity_id;

insert into public.pitcoin_action_definitions (action_key, name_it, name_en, description_it, description_en, category, base_points, daily_cap, per_entity_cap, lifetime_cap, cooldown_seconds, requires_approval, enabled)
values ('comment_posted', 'Commento pubblicato', 'Comment posted',
        'Hai commentato un contenuto della community.', 'You commented on a community item.',
        'engagement', 5, 50, null, null, 60, false, true)
on conflict (action_key) do nothing;

create or replace function public.trg_pitcoin_comment_after_insert()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  begin
    perform public.award_pitcoin(new.author_id, 'comment_posted', 'entity_comments', new.id, null);
  exception when others then
    null;
  end;
  return new;
end;
$$;

revoke execute on function public.trg_pitcoin_comment_after_insert() from public, anon, authenticated;

drop trigger if exists trg_pitcoin_comment_after_insert on public.entity_comments;
create trigger trg_pitcoin_comment_after_insert
  after insert on public.entity_comments
  for each row execute function public.trg_pitcoin_comment_after_insert();

commit;
