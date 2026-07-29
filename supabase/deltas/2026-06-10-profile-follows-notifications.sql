-- ============================================================================
-- PitLap — Segui profilo + centro notifiche in-app (2026-06-10)
-- Applicato su dev in 2 migration: notification_enum_extensions,
-- profile_follows_and_notification_center. Da applicare su prod.
-- ATTENZIONE: gli ALTER TYPE ... ADD VALUE vanno eseguiti FUORI da transazione
-- (o in una esecuzione separata precedente al resto).
-- ============================================================================

-- ---- Parte A (eseguire da sola, senza begin/commit) ------------------------

alter type public.notification_kind add value if not exists 'new_follower';
alter type public.notification_kind add value if not exists 'followed_activity';
alter type public.approval_entity_type add value if not exists 'profile';
alter type public.approval_entity_type add value if not exists 'user_build';
alter type public.approval_entity_type add value if not exists 'community_event';

-- ---- Parte B ----------------------------------------------------------------

begin;

create table if not exists public.profile_follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followed_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followed_id),
  check (follower_id <> followed_id)
);

create index if not exists profile_follows_followed_idx on public.profile_follows (followed_id);

alter table public.profile_follows enable row level security;

drop policy if exists "profile_follows select" on public.profile_follows;
create policy "profile_follows select" on public.profile_follows
  for select to authenticated
  using (follower_id = (select auth.uid()) or followed_id = (select auth.uid()) or is_admin());

drop policy if exists "profile_follows insert" on public.profile_follows;
create policy "profile_follows insert" on public.profile_follows
  for insert to authenticated
  with check (
    follower_id = (select auth.uid())
    and exists (select 1 from public.profiles p where p.id = followed_id and p.is_public = true)
  );

drop policy if exists "profile_follows delete" on public.profile_follows;
create policy "profile_follows delete" on public.profile_follows
  for delete to authenticated
  using (follower_id = (select auth.uid()) or is_admin());

create or replace function public.get_profile_follower_count(profile_uuid uuid)
returns integer
language sql
security definer
set search_path to 'public'
as $$
  select count(*)::integer from public.profile_follows where followed_id = profile_uuid;
$$;

grant execute on function public.get_profile_follower_count(uuid) to authenticated, anon;

drop policy if exists "recipients read own notifications" on public.notifications;
create policy "recipients read own notifications" on public.notifications
  for select to authenticated
  using (
    exists (
      select 1 from public.notification_recipients r
      where r.notification_id = notifications.id and r.user_id = (select auth.uid())
    )
  );

drop policy if exists "users update own notification inbox" on public.notification_recipients;
create policy "users update own notification inbox" on public.notification_recipients
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create or replace function public.create_notification(
  p_kind public.notification_kind,
  p_entity_type public.approval_entity_type,
  p_entity_id uuid,
  p_title text,
  p_body text,
  p_payload jsonb,
  p_created_by uuid,
  p_recipients uuid[]
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_id uuid;
begin
  if p_recipients is null or array_length(p_recipients, 1) is null then
    return;
  end if;
  insert into public.notifications (kind, entity_type, entity_id, title, body, payload, created_by)
  values (p_kind, p_entity_type, p_entity_id, p_title, p_body, coalesce(p_payload, '{}'::jsonb), p_created_by)
  returning id into v_id;
  insert into public.notification_recipients (notification_id, user_id)
  select v_id, unnest(p_recipients)
  on conflict do nothing;
end;
$$;

revoke execute on function public.create_notification(public.notification_kind, public.approval_entity_type, uuid, text, text, jsonb, uuid, uuid[]) from public, anon, authenticated;

create or replace function public.trg_notify_new_follower()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_name text;
begin
  select coalesce(nullif(display_name,''), 'Un utente') into v_name from public.profiles where id = new.follower_id;
  perform public.create_notification(
    'new_follower'::public.notification_kind,
    'profile'::public.approval_entity_type,
    new.follower_id,
    v_name || ' ha iniziato a seguirti',
    null,
    jsonb_build_object('follower_id', new.follower_id),
    new.follower_id,
    array[new.followed_id]
  );
  return new;
end;
$$;

revoke execute on function public.trg_notify_new_follower() from public, anon, authenticated;

drop trigger if exists trg_notify_new_follower on public.profile_follows;
create trigger trg_notify_new_follower
  after insert on public.profile_follows
  for each row execute function public.trg_notify_new_follower();

create or replace function public.trg_notify_followers_build_published()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_name text;
  v_recipients uuid[];
begin
  if (tg_op = 'INSERT' and new.is_public)
     or (tg_op = 'UPDATE' and new.is_public and not coalesce(old.is_public, false)) then
    select array_agg(follower_id) into v_recipients from public.profile_follows where followed_id = new.owner_id;
    if v_recipients is not null then
      select coalesce(nullif(display_name,''), 'Un utente') into v_name from public.profiles where id = new.owner_id;
      perform public.create_notification(
        'followed_activity'::public.notification_kind,
        'user_build'::public.approval_entity_type,
        new.id,
        v_name || ' ha pubblicato una nuova build',
        new.title,
        jsonb_build_object('owner_id', new.owner_id, 'build_id', new.id),
        new.owner_id,
        v_recipients
      );
    end if;
  end if;
  return new;
end;
$$;

revoke execute on function public.trg_notify_followers_build_published() from public, anon, authenticated;

drop trigger if exists trg_notify_followers_build_published on public.user_builds;
create trigger trg_notify_followers_build_published
  after insert or update on public.user_builds
  for each row execute function public.trg_notify_followers_build_published();

create or replace function public.trg_notify_followers_event_created()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_name text;
  v_recipients uuid[];
begin
  select array_agg(follower_id) into v_recipients from public.profile_follows where followed_id = new.author_id;
  if v_recipients is not null then
    select coalesce(nullif(display_name,''), 'Un utente') into v_name from public.profiles where id = new.author_id;
    perform public.create_notification(
      'followed_activity'::public.notification_kind,
      'community_event'::public.approval_entity_type,
      new.id,
      v_name || ' ha creato un nuovo evento',
      new.title,
      jsonb_build_object('author_id', new.author_id, 'event_id', new.id),
      new.author_id,
      v_recipients
    );
  end if;
  return new;
end;
$$;

revoke execute on function public.trg_notify_followers_event_created() from public, anon, authenticated;

drop trigger if exists trg_notify_followers_event_created on public.community_events;
create trigger trg_notify_followers_event_created
  after insert on public.community_events
  for each row execute function public.trg_notify_followers_event_created();

insert into public.pitcoin_action_definitions (action_key, name_it, name_en, description_it, description_en, category, base_points, daily_cap, per_entity_cap, lifetime_cap, cooldown_seconds, requires_approval, enabled)
values ('profile_followed', 'Profilo seguito', 'Profile followed',
        'Hai iniziato a seguire un profilo della community.', 'You started following a community profile.',
        'engagement', 2, 20, 1, null, 0, false, true)
on conflict (action_key) do nothing;

create or replace function public.trg_pitcoin_profile_follow_after_insert()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  begin
    perform public.award_pitcoin(new.follower_id, 'profile_followed', 'profile_follows', new.followed_id, null);
  exception when others then
    null;
  end;
  return new;
end;
$$;

revoke execute on function public.trg_pitcoin_profile_follow_after_insert() from public, anon, authenticated;

drop trigger if exists trg_pitcoin_profile_follow_after_insert on public.profile_follows;
create trigger trg_pitcoin_profile_follow_after_insert
  after insert on public.profile_follows
  for each row execute function public.trg_pitcoin_profile_follow_after_insert();

commit;
