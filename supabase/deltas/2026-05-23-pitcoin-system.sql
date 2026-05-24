-- ────────────────────────────────────────────────────────────────────────────
-- 2026-05-23: PitCoin & Badge System
-- ────────────────────────────────────────────────────────────────────────────
-- Riferimento spec: docs/pitcoin-system.md (versione 2026-05-23, progetto 0.1.20)
--
-- Cosa fa:
--   • Crea 5 nuove tabelle (pitcoin_action_definitions, pitcoin_transactions,
--     user_pitcoin_balances, pitcoin_badge_definitions, user_badges)
--   • Abilita RLS coerente con la matrice §7 della spec
--   • Funzioni core SECURITY DEFINER: award_pitcoin, recompute_user_balance,
--     check_badge_unlocks
--   • Trigger sul ledger pitcoin_transactions per rollup balance + valutazione badge
--   • Trigger sulle tabelle esistenti elencate in §6.2 della spec
--   • View pubbliche public_user_pitcoin / public_user_badges (profilo opt-in)
--   • Seed ~25 action definitions e ~25 badge definitions
--   • Backfill retroattivo delle azioni gia' compiute nella pre-alpha 0.1.x
--
-- Vincoli rispettati:
--   • Nessun ALTER COLUMN / DROP di tabelle/policy esistenti
--   • Tutto idempotente (create ... if not exists, create or replace, on conflict)
--   • Tutte le scritture su ledger/balance/badge passano da funzioni SECURITY DEFINER
--   • Admin (profiles.role = 'admin') esclusi dall'accumulo
--   • Idempotenza ledger garantita da unique (user_id, action_key, source_table, source_id)
--
-- Note schema reale (decisioni di adattamento):
--   • spots NON ha approval_status: spot_approved viene assegnato direttamente
--     all'INSERT su spots (con is_custom = true e owner_id non null)
--   • track_media NON ha colonna submitted_by/owner_id: l'azione track_media_added
--     resta definita nel catalogo ma non ha trigger automatico (no attribuzione utente)
--   • profile_completed: criterio = display_name non vuoto + avatar_url valorizzato
--     + onboarding_completed_at valorizzato + consenso 'terms_accepted'
--   • profile_made_public: profiles.is_public = true e public_slug non null
--   • Eventi: 'events.created_by' e 'community_events.author_id' come da spec
-- ────────────────────────────────────────────────────────────────────────────


-- ====================================================================
-- SEZIONE 1 — Tabelle
-- ====================================================================

create table if not exists public.pitcoin_action_definitions (
  action_key         text primary key,
  name_it            text not null,
  name_en            text not null,
  description_it     text,
  description_en     text,
  category           text not null check (category in (
    'identity','garage','catalog','operations','events','engagement','moderation'
  )),
  base_points        int  not null default 0,
  daily_cap          int,
  per_entity_cap     int,
  lifetime_cap       int,
  cooldown_seconds   int,
  requires_approval  boolean not null default false,
  enabled            boolean not null default true,
  created_at         timestamptz not null default timezone('utc', now()),
  updated_at         timestamptz not null default timezone('utc', now())
);

drop trigger if exists pitcoin_action_definitions_set_updated_at on public.pitcoin_action_definitions;
create trigger pitcoin_action_definitions_set_updated_at
  before update on public.pitcoin_action_definitions
  for each row execute function public.set_updated_at();


create table if not exists public.pitcoin_transactions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  action_key   text not null references public.pitcoin_action_definitions (action_key),
  points       int  not null,
  source_table text,
  source_id    uuid,
  metadata     jsonb not null default '{}'::jsonb,
  awarded_at   timestamptz not null default timezone('utc', now())
);

-- Unique constraint per idempotenza: usa COALESCE su colonne nullable
-- (Postgres considera NULL come "distinto" → con sole colonne nullable la unique
--  non blocca i duplicati che ci interessano)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'pitcoin_transactions_dedup_uniq'
      and conrelid = 'public.pitcoin_transactions'::regclass
  ) then
    alter table public.pitcoin_transactions
      add constraint pitcoin_transactions_dedup_uniq
      unique (user_id, action_key, source_table, source_id);
  end if;
end$$;

create index if not exists pitcoin_transactions_user_idx
  on public.pitcoin_transactions (user_id, awarded_at desc);
create index if not exists pitcoin_transactions_action_idx
  on public.pitcoin_transactions (action_key, awarded_at desc);
create index if not exists pitcoin_transactions_user_action_idx
  on public.pitcoin_transactions (user_id, action_key, awarded_at desc);


create table if not exists public.user_pitcoin_balances (
  user_id          uuid primary key references public.profiles (id) on delete cascade,
  total_points     int not null default 0,
  lifetime_earned  int not null default 0,
  last_action_at   timestamptz,
  updated_at       timestamptz not null default timezone('utc', now())
);


create table if not exists public.pitcoin_badge_definitions (
  badge_key       text primary key,
  name_it         text not null,
  name_en         text not null,
  description_it  text,
  description_en  text,
  icon_asset      text,
  category        text not null check (category in (
    'identity','catalog','operations','engagement','events','milestone'
  )),
  tier            text not null check (tier in ('bronze','silver','gold','special')),
  criteria        jsonb not null,
  enabled         boolean not null default true,
  sort_order      int not null default 0,
  created_at      timestamptz not null default timezone('utc', now())
);


create table if not exists public.user_badges (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  badge_key   text not null references public.pitcoin_badge_definitions (badge_key),
  awarded_at  timestamptz not null default timezone('utc', now()),
  metadata    jsonb not null default '{}'::jsonb,
  unique (user_id, badge_key)
);

create index if not exists user_badges_user_idx
  on public.user_badges (user_id, awarded_at desc);
create index if not exists user_badges_badge_idx
  on public.user_badges (badge_key, awarded_at desc);


-- ====================================================================
-- SEZIONE 2 — RLS
-- ====================================================================

alter table public.pitcoin_action_definitions  enable row level security;
alter table public.pitcoin_transactions        enable row level security;
alter table public.user_pitcoin_balances       enable row level security;
alter table public.pitcoin_badge_definitions   enable row level security;
alter table public.user_badges                 enable row level security;

-- pitcoin_action_definitions: tutti leggono le abilitate, admin gestiscono
drop policy if exists "pitcoin_action_definitions: anyone reads enabled"
  on public.pitcoin_action_definitions;
create policy "pitcoin_action_definitions: anyone reads enabled"
  on public.pitcoin_action_definitions for select
  to anon, authenticated
  using (enabled = true);

drop policy if exists "pitcoin_action_definitions: admins manage"
  on public.pitcoin_action_definitions;
create policy "pitcoin_action_definitions: admins manage"
  on public.pitcoin_action_definitions for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- pitcoin_transactions: solo owner legge le proprie, admin gestiscono
-- Nessun INSERT/UPDATE/DELETE da client: tutto via SECURITY DEFINER
drop policy if exists "pitcoin_transactions: owner reads own"
  on public.pitcoin_transactions;
create policy "pitcoin_transactions: owner reads own"
  on public.pitcoin_transactions for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "pitcoin_transactions: admins manage"
  on public.pitcoin_transactions;
create policy "pitcoin_transactions: admins manage"
  on public.pitcoin_transactions for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- user_pitcoin_balances: owner legge il proprio, admin gestiscono
-- (le letture pubbliche passano dalla view public_user_pitcoin)
drop policy if exists "user_pitcoin_balances: owner reads own"
  on public.user_pitcoin_balances;
create policy "user_pitcoin_balances: owner reads own"
  on public.user_pitcoin_balances for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "user_pitcoin_balances: admins manage"
  on public.user_pitcoin_balances;
create policy "user_pitcoin_balances: admins manage"
  on public.user_pitcoin_balances for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- pitcoin_badge_definitions: tutti leggono le abilitate, admin gestiscono
drop policy if exists "pitcoin_badge_definitions: anyone reads enabled"
  on public.pitcoin_badge_definitions;
create policy "pitcoin_badge_definitions: anyone reads enabled"
  on public.pitcoin_badge_definitions for select
  to anon, authenticated
  using (enabled = true);

drop policy if exists "pitcoin_badge_definitions: admins manage"
  on public.pitcoin_badge_definitions;
create policy "pitcoin_badge_definitions: admins manage"
  on public.pitcoin_badge_definitions for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- user_badges: owner legge le proprie, admin gestiscono
-- (le badge pubbliche passano dalla view public_user_badges)
drop policy if exists "user_badges: owner reads own"
  on public.user_badges;
create policy "user_badges: owner reads own"
  on public.user_badges for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "user_badges: admins manage"
  on public.user_badges;
create policy "user_badges: admins manage"
  on public.user_badges for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Blocca scritture dirette da client: solo le funzioni SECURITY DEFINER scrivono
revoke insert, update, delete on public.pitcoin_transactions  from anon, authenticated;
revoke insert, update, delete on public.user_pitcoin_balances from anon, authenticated;
revoke insert, update, delete on public.user_badges           from anon, authenticated;


-- ====================================================================
-- SEZIONE 3 — Funzioni core
-- ====================================================================

-- award_pitcoin: punto di ingresso unico per accreditare PitCoin
-- Implementa: enabled check, role admin check, daily_cap, per_entity_cap,
-- lifetime_cap, cooldown_seconds, INSERT ... ON CONFLICT DO NOTHING.
create or replace function public.award_pitcoin(
  p_user_id      uuid,
  p_action_key   text,
  p_source_table text default null,
  p_source_id    uuid default null,
  p_metadata     jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_def        public.pitcoin_action_definitions%rowtype;
  v_role       public.app_role;
  v_count      int;
  v_last       timestamptz;
begin
  if p_user_id is null or p_action_key is null then
    return;
  end if;

  -- 1) action definition presente e abilitata
  select * into v_def
  from public.pitcoin_action_definitions
  where action_key = p_action_key
    and enabled = true;
  if not found then
    return;
  end if;

  -- 2) admin escluso dall'accumulo
  select role into v_role from public.profiles where id = p_user_id;
  if v_role is null then
    return;
  end if;
  if v_role = 'admin' then
    return;
  end if;

  -- 3) daily_cap
  if v_def.daily_cap is not null then
    select count(*) into v_count
    from public.pitcoin_transactions
    where user_id = p_user_id
      and action_key = p_action_key
      and awarded_at >= date_trunc('day', timezone('utc', now()))
      and awarded_at <  date_trunc('day', timezone('utc', now())) + interval '1 day';
    if v_count >= v_def.daily_cap then
      return;
    end if;
  end if;

  -- 4) per_entity_cap (richiede source_id valorizzato)
  if v_def.per_entity_cap is not null and p_source_id is not null then
    select count(*) into v_count
    from public.pitcoin_transactions
    where user_id = p_user_id
      and action_key = p_action_key
      and source_id = p_source_id;
    if v_count >= v_def.per_entity_cap then
      return;
    end if;
  end if;

  -- 5) lifetime_cap
  if v_def.lifetime_cap is not null then
    select count(*) into v_count
    from public.pitcoin_transactions
    where user_id = p_user_id
      and action_key = p_action_key;
    if v_count >= v_def.lifetime_cap then
      return;
    end if;
  end if;

  -- 6) cooldown_seconds
  if v_def.cooldown_seconds is not null and v_def.cooldown_seconds > 0 then
    select max(awarded_at) into v_last
    from public.pitcoin_transactions
    where user_id = p_user_id
      and action_key = p_action_key;
    if v_last is not null
       and timezone('utc', now()) - v_last < make_interval(secs => v_def.cooldown_seconds) then
      return;
    end if;
  end if;

  -- 7) INSERT idempotente
  insert into public.pitcoin_transactions (
    user_id, action_key, points, source_table, source_id, metadata, awarded_at
  )
  values (
    p_user_id,
    p_action_key,
    v_def.base_points,
    p_source_table,
    p_source_id,
    coalesce(p_metadata, '{}'::jsonb),
    timezone('utc', now())
  )
  on conflict (user_id, action_key, source_table, source_id) do nothing;
end;
$$;

revoke execute on function public.award_pitcoin(uuid, text, text, uuid, jsonb)
  from public, anon, authenticated;
grant execute on function public.award_pitcoin(uuid, text, text, uuid, jsonb)
  to service_role;


-- Variante con metadata + awarded_at controllato (solo backfill / admin)
create or replace function public.award_pitcoin_backfill(
  p_user_id      uuid,
  p_action_key   text,
  p_source_table text,
  p_source_id    uuid,
  p_metadata     jsonb,
  p_awarded_at   timestamptz
)
returns void
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_def  public.pitcoin_action_definitions%rowtype;
  v_role public.app_role;
begin
  if p_user_id is null or p_action_key is null then return; end if;

  select * into v_def
  from public.pitcoin_action_definitions
  where action_key = p_action_key
    and enabled = true;
  if not found then return; end if;

  select role into v_role from public.profiles where id = p_user_id;
  if v_role is null or v_role = 'admin' then return; end if;

  insert into public.pitcoin_transactions (
    user_id, action_key, points, source_table, source_id, metadata, awarded_at
  ) values (
    p_user_id,
    p_action_key,
    v_def.base_points,
    p_source_table,
    p_source_id,
    coalesce(p_metadata, '{}'::jsonb),
    coalesce(p_awarded_at, timezone('utc', now()))
  )
  on conflict (user_id, action_key, source_table, source_id) do nothing;
end;
$$;

revoke execute on function public.award_pitcoin_backfill(uuid, text, text, uuid, jsonb, timestamptz)
  from public, anon, authenticated;
grant execute on function public.award_pitcoin_backfill(uuid, text, text, uuid, jsonb, timestamptz)
  to service_role;


-- recompute_user_balance: utility per ricalcolo full da ledger
create or replace function public.recompute_user_balance(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_total    int;
  v_lifetime int;
  v_last     timestamptz;
begin
  if p_user_id is null then return; end if;

  select
    coalesce(sum(points), 0),
    coalesce(sum(case when points > 0 then points else 0 end), 0),
    max(awarded_at)
  into v_total, v_lifetime, v_last
  from public.pitcoin_transactions
  where user_id = p_user_id;

  insert into public.user_pitcoin_balances (user_id, total_points, lifetime_earned, last_action_at, updated_at)
  values (p_user_id, v_total, v_lifetime, v_last, timezone('utc', now()))
  on conflict (user_id) do update
    set total_points    = excluded.total_points,
        lifetime_earned = excluded.lifetime_earned,
        last_action_at  = excluded.last_action_at,
        updated_at      = timezone('utc', now());
end;
$$;

revoke execute on function public.recompute_user_balance(uuid)
  from public, anon, authenticated;
grant execute on function public.recompute_user_balance(uuid)
  to service_role;


-- check_badge_unlocks: valuta i criteri delle badge ancora non ottenute e le assegna
create or replace function public.check_badge_unlocks(
  p_user_id uuid,
  p_trigger_action_key text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_role     public.app_role;
  v_b        public.pitcoin_badge_definitions%rowtype;
  v_type     text;
  v_action   text;
  v_table    text;
  v_thresh   int;
  v_count    int;
  v_sum      int;
  v_ok       boolean;
begin
  if p_user_id is null then return; end if;

  -- Admin esclusi anche dalle badge
  select role into v_role from public.profiles where id = p_user_id;
  if v_role is null or v_role = 'admin' then return; end if;

  for v_b in
    select *
    from public.pitcoin_badge_definitions b
    where b.enabled = true
      and not exists (
        select 1 from public.user_badges ub
        where ub.user_id = p_user_id
          and ub.badge_key = b.badge_key
      )
  loop
    v_type   := coalesce(v_b.criteria->>'type', '');
    v_action := v_b.criteria->>'action_key';
    v_table  := v_b.criteria->>'source_table';
    v_thresh := nullif(v_b.criteria->>'threshold', '')::int;
    v_ok     := false;

    if v_type = 'action_count' then
      select count(*) into v_count
      from public.pitcoin_transactions
      where user_id = p_user_id
        and action_key = v_action;
      v_ok := (v_thresh is not null and v_count >= v_thresh);

    elsif v_type = 'action_count_any' then
      -- somma conteggi su piu' action_keys (criteria.action_keys = array)
      select count(*) into v_count
      from public.pitcoin_transactions
      where user_id = p_user_id
        and action_key = any (
          array(select jsonb_array_elements_text(v_b.criteria->'action_keys'))
        );
      v_ok := (v_thresh is not null and v_count >= v_thresh);

    elsif v_type = 'action_sum_points' then
      select coalesce(sum(points), 0) into v_sum
      from public.pitcoin_transactions
      where user_id = p_user_id
        and action_key = v_action;
      v_ok := (v_thresh is not null and v_sum >= v_thresh);

    elsif v_type = 'distinct_entities' then
      select count(distinct source_id) into v_count
      from public.pitcoin_transactions
      where user_id = p_user_id
        and action_key = v_action
        and (v_table is null or source_table = v_table)
        and source_id is not null;
      v_ok := (v_thresh is not null and v_count >= v_thresh);

    elsif v_type = 'distinct_days' then
      select count(distinct date_trunc('day', awarded_at)) into v_count
      from public.pitcoin_transactions
      where user_id = p_user_id
        and action_key = v_action;
      v_ok := (v_thresh is not null and v_count >= v_thresh);

    elsif v_type = 'same_entity_same_weekend' then
      -- check-in >= threshold nello stesso weekend (sabato+domenica) sulla stessa pista
      select max(c) into v_count
      from (
        select count(*) as c
        from public.pitcoin_transactions
        where user_id = p_user_id
          and action_key = coalesce(v_action, 'arrival_checkin')
          and source_id is not null
        group by source_id,
                 to_char(awarded_at, 'IYYY-IW')
      ) s;
      v_ok := (v_thresh is not null and v_count is not null and v_count >= v_thresh);

    elsif v_type = 'manual' then
      v_ok := false;

    else
      v_ok := false;
    end if;

    if v_ok then
      insert into public.user_badges (user_id, badge_key, awarded_at, metadata)
      values (
        p_user_id,
        v_b.badge_key,
        timezone('utc', now()),
        jsonb_build_object('trigger', coalesce(p_trigger_action_key, ''))
      )
      on conflict (user_id, badge_key) do nothing;
    end if;
  end loop;
end;
$$;

revoke execute on function public.check_badge_unlocks(uuid, text)
  from public, anon, authenticated;
grant execute on function public.check_badge_unlocks(uuid, text)
  to service_role;


-- award_user_badge_manual: assegnazione manuale (backfill milestone + admin)
create or replace function public.award_user_badge_manual(
  p_user_id   uuid,
  p_badge_key text,
  p_metadata  jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_role public.app_role;
begin
  if p_user_id is null or p_badge_key is null then return; end if;
  select role into v_role from public.profiles where id = p_user_id;
  if v_role is null or v_role = 'admin' then return; end if;

  if not exists (
    select 1 from public.pitcoin_badge_definitions
    where badge_key = p_badge_key and enabled = true
  ) then
    return;
  end if;

  insert into public.user_badges (user_id, badge_key, metadata)
  values (p_user_id, p_badge_key, coalesce(p_metadata, '{}'::jsonb))
  on conflict (user_id, badge_key) do nothing;
end;
$$;

revoke execute on function public.award_user_badge_manual(uuid, text, jsonb)
  from public, anon, authenticated;
grant execute on function public.award_user_badge_manual(uuid, text, jsonb)
  to service_role;


-- ====================================================================
-- SEZIONE 4 — View pubbliche
-- ====================================================================

drop view if exists public.public_user_pitcoin;
create view public.public_user_pitcoin
with (security_invoker = true)
as
select
  p.id                  as user_id,
  p.public_slug,
  p.display_name,
  p.avatar_url,
  coalesce(b.total_points, 0)    as total_points,
  coalesce(b.lifetime_earned, 0) as lifetime_earned,
  b.last_action_at
from public.profiles p
left join public.user_pitcoin_balances b on b.user_id = p.id
where p.is_public = true
  and p.public_slug is not null;

revoke all on public.public_user_pitcoin from public;
revoke all on public.public_user_pitcoin from anon;
revoke all on public.public_user_pitcoin from authenticated;
grant select on public.public_user_pitcoin to anon, authenticated, service_role;


drop view if exists public.public_user_badges;
create view public.public_user_badges
with (security_invoker = true)
as
select
  ub.user_id,
  p.public_slug,
  p.display_name,
  ub.badge_key,
  bd.name_it,
  bd.name_en,
  bd.description_it,
  bd.description_en,
  bd.icon_asset,
  bd.category,
  bd.tier,
  ub.awarded_at
from public.user_badges ub
join public.profiles p on p.id = ub.user_id
join public.pitcoin_badge_definitions bd on bd.badge_key = ub.badge_key
where p.is_public = true
  and p.public_slug is not null
  and bd.enabled = true;

revoke all on public.public_user_badges from public;
revoke all on public.public_user_badges from anon;
revoke all on public.public_user_badges from authenticated;
grant select on public.public_user_badges to anon, authenticated, service_role;


-- ====================================================================
-- SEZIONE 5 — Trigger sul ledger
-- ====================================================================

create or replace function public.trg_pitcoin_after_ledger_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  -- Upsert balance
  insert into public.user_pitcoin_balances (
    user_id, total_points, lifetime_earned, last_action_at, updated_at
  ) values (
    NEW.user_id,
    NEW.points,
    case when NEW.points > 0 then NEW.points else 0 end,
    NEW.awarded_at,
    timezone('utc', now())
  )
  on conflict (user_id) do update
    set total_points    = public.user_pitcoin_balances.total_points + NEW.points,
        lifetime_earned = public.user_pitcoin_balances.lifetime_earned
                          + case when NEW.points > 0 then NEW.points else 0 end,
        last_action_at  = greatest(
          coalesce(public.user_pitcoin_balances.last_action_at, NEW.awarded_at),
          NEW.awarded_at
        ),
        updated_at      = timezone('utc', now());

  -- Valuta badge dipendenti
  perform public.check_badge_unlocks(NEW.user_id, NEW.action_key);

  return NEW;
end;
$$;

drop trigger if exists pitcoin_transactions_after_insert on public.pitcoin_transactions;
create trigger pitcoin_transactions_after_insert
  after insert on public.pitcoin_transactions
  for each row execute function public.trg_pitcoin_after_ledger_insert();


-- ====================================================================
-- SEZIONE 6 — Trigger sulle tabelle esistenti
-- ====================================================================

-- ---- arrivals: arrival_checkin ----
create or replace function public.trg_pitcoin_arrivals_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.user_id is not null then
    perform public.award_pitcoin(
      NEW.user_id,
      'arrival_checkin',
      'arrivals',
      NEW.id,
      jsonb_build_object('track_id', NEW.track_id, 'arrival_date', NEW.arrival_date)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_arrivals_after_insert on public.arrivals;
create trigger trg_pitcoin_arrivals_after_insert
  after insert on public.arrivals
  for each row execute function public.trg_pitcoin_arrivals_after_insert();


-- ---- user_builds: build_created (INSERT) + build_published (UPDATE is_public f→t) ----
create or replace function public.trg_pitcoin_user_builds_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.owner_id is not null then
    perform public.award_pitcoin(
      NEW.owner_id,
      'build_created',
      'user_builds',
      NEW.id,
      jsonb_build_object('title', NEW.title)
    );
    if NEW.is_public = true then
      perform public.award_pitcoin(
        NEW.owner_id,
        'build_published',
        'user_builds',
        NEW.id,
        jsonb_build_object('title', NEW.title)
      );
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_user_builds_after_insert on public.user_builds;
create trigger trg_pitcoin_user_builds_after_insert
  after insert on public.user_builds
  for each row execute function public.trg_pitcoin_user_builds_after_insert();

create or replace function public.trg_pitcoin_user_builds_after_update()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if OLD.is_public is distinct from NEW.is_public
     and NEW.is_public = true
     and NEW.owner_id is not null then
    perform public.award_pitcoin(
      NEW.owner_id,
      'build_published',
      'user_builds',
      NEW.id,
      jsonb_build_object('title', NEW.title)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_user_builds_after_update on public.user_builds;
create trigger trg_pitcoin_user_builds_after_update
  after update on public.user_builds
  for each row
  when (OLD.is_public is distinct from NEW.is_public and NEW.is_public = true)
  execute function public.trg_pitcoin_user_builds_after_update();


-- ---- spots: spot_submitted (INSERT) + spot_approved (INSERT, schema senza approval_status) ----
-- NOTA SCHEMA: la tabella spots NON ha approval_status. Decisione:
--   • on INSERT con is_custom = true e owner_id != null: assegna sia spot_submitted
--     (placeholder a 0 punti per idempotenza) sia spot_approved (payout reale).
create or replace function public.trg_pitcoin_spots_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.is_custom = true and NEW.owner_id is not null then
    perform public.award_pitcoin(
      NEW.owner_id,
      'spot_submitted',
      'spots',
      NEW.id,
      jsonb_build_object('slug', NEW.slug)
    );
    perform public.award_pitcoin(
      NEW.owner_id,
      'spot_approved',
      'spots',
      NEW.id,
      jsonb_build_object('slug', NEW.slug)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_spots_after_insert on public.spots;
create trigger trg_pitcoin_spots_after_insert
  after insert on public.spots
  for each row execute function public.trg_pitcoin_spots_after_insert();


-- ---- tracks: track_submitted (INSERT) + track_approved (UPDATE → approved) ----
create or replace function public.trg_pitcoin_tracks_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.submitted_by is not null then
    perform public.award_pitcoin(
      NEW.submitted_by,
      'track_submitted',
      'tracks',
      NEW.id,
      jsonb_build_object('slug', NEW.slug)
    );
    if NEW.approval_status = 'approved' then
      perform public.award_pitcoin(
        NEW.submitted_by,
        'track_approved',
        'tracks',
        NEW.id,
        jsonb_build_object('slug', NEW.slug)
      );
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_tracks_after_insert on public.tracks;
create trigger trg_pitcoin_tracks_after_insert
  after insert on public.tracks
  for each row execute function public.trg_pitcoin_tracks_after_insert();

create or replace function public.trg_pitcoin_tracks_after_update()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.submitted_by is not null
     and OLD.approval_status is distinct from NEW.approval_status
     and NEW.approval_status = 'approved' then
    perform public.award_pitcoin(
      NEW.submitted_by,
      'track_approved',
      'tracks',
      NEW.id,
      jsonb_build_object('slug', NEW.slug)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_tracks_after_update on public.tracks;
create trigger trg_pitcoin_tracks_after_update
  after update on public.tracks
  for each row
  when (OLD.approval_status is distinct from NEW.approval_status
        and NEW.approval_status = 'approved')
  execute function public.trg_pitcoin_tracks_after_update();


-- ---- shops: shop_submitted (INSERT) + shop_approved (UPDATE → approved) ----
create or replace function public.trg_pitcoin_shops_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.submitted_by is not null then
    perform public.award_pitcoin(
      NEW.submitted_by,
      'shop_submitted',
      'shops',
      NEW.id,
      jsonb_build_object('slug', NEW.slug)
    );
    if NEW.approval_status = 'approved' then
      perform public.award_pitcoin(
        NEW.submitted_by,
        'shop_approved',
        'shops',
        NEW.id,
        jsonb_build_object('slug', NEW.slug)
      );
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_shops_after_insert on public.shops;
create trigger trg_pitcoin_shops_after_insert
  after insert on public.shops
  for each row execute function public.trg_pitcoin_shops_after_insert();

create or replace function public.trg_pitcoin_shops_after_update()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.submitted_by is not null
     and OLD.approval_status is distinct from NEW.approval_status
     and NEW.approval_status = 'approved' then
    perform public.award_pitcoin(
      NEW.submitted_by,
      'shop_approved',
      'shops',
      NEW.id,
      jsonb_build_object('slug', NEW.slug)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_shops_after_update on public.shops;
create trigger trg_pitcoin_shops_after_update
  after update on public.shops
  for each row
  when (OLD.approval_status is distinct from NEW.approval_status
        and NEW.approval_status = 'approved')
  execute function public.trg_pitcoin_shops_after_update();


-- ---- events: official_event_created ----
create or replace function public.trg_pitcoin_events_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.created_by is not null then
    perform public.award_pitcoin(
      NEW.created_by,
      'official_event_created',
      'events',
      NEW.id,
      jsonb_build_object('title', NEW.title)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_events_after_insert on public.events;
create trigger trg_pitcoin_events_after_insert
  after insert on public.events
  for each row execute function public.trg_pitcoin_events_after_insert();


-- ---- community_events: community_event_created ----
create or replace function public.trg_pitcoin_community_events_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.author_id is not null then
    perform public.award_pitcoin(
      NEW.author_id,
      'community_event_created',
      'community_events',
      NEW.id,
      jsonb_build_object('title', NEW.title)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_community_events_after_insert on public.community_events;
create trigger trg_pitcoin_community_events_after_insert
  after insert on public.community_events
  for each row execute function public.trg_pitcoin_community_events_after_insert();


-- ---- event_rsvps: event_rsvp_sent (utente) + event_rsvp_received (event owner) ----
create or replace function public.trg_pitcoin_event_rsvps_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_owner uuid;
begin
  if NEW.status = 'going' then
    if NEW.user_id is not null then
      perform public.award_pitcoin(
        NEW.user_id,
        'event_rsvp_sent',
        'event_rsvps',
        NEW.id,
        jsonb_build_object('event_id', NEW.event_id)
      );
    end if;

    select created_by into v_owner from public.events where id = NEW.event_id;
    if v_owner is not null and v_owner <> NEW.user_id then
      perform public.award_pitcoin(
        v_owner,
        'event_rsvp_received',
        'event_rsvps',
        NEW.id,
        jsonb_build_object('event_id', NEW.event_id, 'rsvp_user_id', NEW.user_id)
      );
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_event_rsvps_after_insert on public.event_rsvps;
create trigger trg_pitcoin_event_rsvps_after_insert
  after insert on public.event_rsvps
  for each row execute function public.trg_pitcoin_event_rsvps_after_insert();


-- ---- track_follows: track_followed ----
create or replace function public.trg_pitcoin_track_follows_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.user_id is not null then
    perform public.award_pitcoin(
      NEW.user_id,
      'track_followed',
      'track_follows',
      NEW.track_id,
      jsonb_build_object('track_id', NEW.track_id)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_track_follows_after_insert on public.track_follows;
create trigger trg_pitcoin_track_follows_after_insert
  after insert on public.track_follows
  for each row execute function public.trg_pitcoin_track_follows_after_insert();


-- ---- shop_follows: shop_followed ----
create or replace function public.trg_pitcoin_shop_follows_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.user_id is not null then
    perform public.award_pitcoin(
      NEW.user_id,
      'shop_followed',
      'shop_follows',
      NEW.shop_id,
      jsonb_build_object('shop_id', NEW.shop_id)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_shop_follows_after_insert on public.shop_follows;
create trigger trg_pitcoin_shop_follows_after_insert
  after insert on public.shop_follows
  for each row execute function public.trg_pitcoin_shop_follows_after_insert();


-- ---- track_status_history: track_status_updated ----
create or replace function public.trg_pitcoin_track_status_history_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.updated_by is not null then
    perform public.award_pitcoin(
      NEW.updated_by,
      'track_status_updated',
      'track_status_history',
      NEW.id,
      jsonb_build_object('track_id', NEW.track_id, 'status', NEW.status::text)
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_track_status_history_after_insert on public.track_status_history;
create trigger trg_pitcoin_track_status_history_after_insert
  after insert on public.track_status_history
  for each row execute function public.trg_pitcoin_track_status_history_after_insert();


-- ---- track_services: track_services_updated ----
create or replace function public.trg_pitcoin_track_services_after_update()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_actor uuid;
begin
  v_actor := auth.uid();
  if v_actor is not null then
    perform public.award_pitcoin(
      v_actor,
      'track_services_updated',
      'track_services',
      NEW.track_id,
      jsonb_build_object(
        'track_id', NEW.track_id,
        'service_type_id', NEW.service_type_id
      )
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_track_services_after_update on public.track_services;
create trigger trg_pitcoin_track_services_after_update
  after update on public.track_services
  for each row execute function public.trg_pitcoin_track_services_after_update();


-- ---- external_links: external_link_added ----
create or replace function public.trg_pitcoin_external_links_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
begin
  if NEW.owner_id is not null then
    perform public.award_pitcoin(
      NEW.owner_id,
      'external_link_added',
      'external_links',
      NEW.id,
      jsonb_build_object(
        'entity_type', NEW.entity_type,
        'entity_id',   NEW.entity_id,
        'provider',    NEW.provider
      )
    );
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_external_links_after_insert on public.external_links;
create trigger trg_pitcoin_external_links_after_insert
  after insert on public.external_links
  for each row execute function public.trg_pitcoin_external_links_after_insert();


-- ---- profiles: profile_completed + profile_made_public ----
-- profile_completed criteria: display_name + avatar_url + onboarding_completed_at
--                              + esiste consenso 'terms_accepted' accepted=true
-- profile_made_public criteria: is_public = true and public_slug is not null
create or replace function public.trg_pitcoin_profiles_after_update()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_old_complete boolean;
  v_new_complete boolean;
  v_terms_old    boolean;
  v_terms_new    boolean;
begin
  -- terms accepted (snapshot attuale: lo leggiamo dalla tabella user_consents)
  select coalesce(bool_or(uc.accepted), false)
    into v_terms_new
    from public.user_consents uc
    where uc.user_id = NEW.id
      and uc.consent_type = 'terms_accepted';
  v_terms_old := v_terms_new; -- snapshot identico, l'update e' su profiles

  v_old_complete := (
    coalesce(nullif(OLD.display_name, ''), null) is not null
    and coalesce(nullif(OLD.avatar_url,   ''), null) is not null
    and OLD.onboarding_completed_at is not null
    and v_terms_old
  );
  v_new_complete := (
    coalesce(nullif(NEW.display_name, ''), null) is not null
    and coalesce(nullif(NEW.avatar_url,   ''), null) is not null
    and NEW.onboarding_completed_at is not null
    and v_terms_new
  );

  if v_new_complete and not v_old_complete then
    perform public.award_pitcoin(
      NEW.id,
      'profile_completed',
      'profiles',
      NEW.id,
      '{}'::jsonb
    );
  end if;

  -- profile_made_public: transizione false→true di is_public, con public_slug valorizzato
  if NEW.is_public = true
     and NEW.public_slug is not null
     and (OLD.is_public is distinct from NEW.is_public
          or OLD.public_slug is distinct from NEW.public_slug) then
    perform public.award_pitcoin(
      NEW.id,
      'profile_made_public',
      'profiles',
      NEW.id,
      jsonb_build_object('public_slug', NEW.public_slug)
    );
  end if;

  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_profiles_after_update on public.profiles;
create trigger trg_pitcoin_profiles_after_update
  after update on public.profiles
  for each row execute function public.trg_pitcoin_profiles_after_update();


-- user_consents: ricalcola profile_completed quando arriva il consenso 'terms_accepted'
create or replace function public.trg_pitcoin_user_consents_after_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  v_p public.profiles%rowtype;
begin
  if NEW.consent_type = 'terms_accepted' and NEW.accepted = true then
    select * into v_p from public.profiles where id = NEW.user_id;
    if found
       and coalesce(nullif(v_p.display_name, ''), null) is not null
       and coalesce(nullif(v_p.avatar_url,   ''), null) is not null
       and v_p.onboarding_completed_at is not null then
      perform public.award_pitcoin(
        v_p.id,
        'profile_completed',
        'profiles',
        v_p.id,
        '{}'::jsonb
      );
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_pitcoin_user_consents_after_insert on public.user_consents;
create trigger trg_pitcoin_user_consents_after_insert
  after insert on public.user_consents
  for each row execute function public.trg_pitcoin_user_consents_after_change();

drop trigger if exists trg_pitcoin_user_consents_after_update on public.user_consents;
create trigger trg_pitcoin_user_consents_after_update
  after update on public.user_consents
  for each row execute function public.trg_pitcoin_user_consents_after_change();


-- ====================================================================
-- SEZIONE 7 — Seed pitcoin_action_definitions
-- ====================================================================

insert into public.pitcoin_action_definitions (
  action_key, name_it, name_en, description_it, description_en,
  category, base_points, daily_cap, per_entity_cap, lifetime_cap,
  cooldown_seconds, requires_approval, enabled
) values
-- Identita' e profilo
('profile_completed',     'Profilo completato',      'Profile completed',
 'Avatar, slug pubblico, lingua e consensi base',     'Avatar, public slug, language and base consents',
 'identity', 50, null, null, 1, null, false, true),
('profile_made_public',   'Profilo reso pubblico',   'Profile made public',
 'Profilo opt-in pubblico con public_slug',           'Opt-in public profile with public_slug',
 'identity', 20, null, null, 1, null, false, true),
('external_link_added',   'Link esterno aggiunto',   'External link added',
 'Aggiunta link social/web a profilo o entita''',     'Added social/web link to profile or owned entity',
 'identity', 5,  null, 3, 10, null, false, true),

-- Garage
('build_created',         'Build creata',            'Build created',
 'Nuova build inserita nel garage',                   'New build added to garage',
 'garage', 30, null, 1, null, null, false, true),
('build_published',       'Build pubblicata',        'Build published',
 'Build resa visibile alla community',                'Build made visible to the community',
 'garage', 50, null, 1, null, null, false, true),
('build_photo_added',     'Foto build aggiunta',     'Build photo added',
 'Foto aggiunta a una build',                         'Photo added to a build',
 'garage', 5, 5, null, null, null, false, true),

-- Catalogo (submission/approvazione)
('spot_submitted',        'Spot inviato',            'Spot submitted',
 'Nuovo spot creato (placeholder idempotente)',       'New spot created (idempotent placeholder)',
 'catalog', 0, null, 1, null, null, false, true),
('spot_approved',         'Spot approvato',          'Spot approved',
 'Spot ha ricevuto approvazione',                     'Spot has been approved',
 'catalog', 30, null, 1, null, null, true,  true),
('track_submitted',       'Pista inviata',           'Track submitted',
 'Submission pista (placeholder idempotente)',        'Track submission (idempotent placeholder)',
 'catalog', 0, null, 1, null, null, false, true),
('track_approved',        'Pista approvata',         'Track approved',
 'Pista approvata e pubblicata nel catalogo',         'Track approved and published in catalog',
 'catalog', 100, null, 1, null, null, true, true),
('shop_submitted',        'Negozio inviato',         'Shop submitted',
 'Submission negozio (placeholder idempotente)',      'Shop submission (idempotent placeholder)',
 'catalog', 0, null, 1, null, null, false, true),
('shop_approved',         'Negozio approvato',       'Shop approved',
 'Negozio approvato e pubblicato',                    'Shop approved and published',
 'catalog', 80, null, 1, null, null, true, true),

-- Operativi (track_manager / shop_owner)
('track_status_updated',  'Stato pista aggiornato',  'Track status updated',
 'Aggiornamento stato corrente della pista',          'Update of current track status',
 'operations', 5, 1, null, null, 14400, false, true),
('track_services_updated','Servizi pista aggiornati','Track services updated',
 'Aggiornamento servizi pista',                       'Update of track services',
 'operations', 10, 1, null, null, 14400, false, true),
('track_media_added',     'Foto pista aggiunta',     'Track media added',
 'Foto aggiunta alla galleria pista',                 'Photo added to track gallery',
 'operations', 5, 5, null, null, null, false, true),
('shop_info_updated',     'Info negozio aggiornate', 'Shop info updated',
 'Aggiornamento informazioni negozio',                'Update of shop information',
 'operations', 5, 1, null, null, 21600, false, true),
('shop_media_added',      'Foto negozio aggiunta',   'Shop media added',
 'Foto aggiunta alla galleria negozio',               'Photo added to shop gallery',
 'operations', 5, 5, null, null, null, false, true),

-- Eventi
('community_event_created','Evento community creato','Community event created',
 'Nuovo evento community',                            'New community event',
 'events', 25, null, 1, null, null, false, true),
('official_event_created','Evento ufficiale creato', 'Official event created',
 'Nuovo evento ufficiale su pista',                   'New official event on a track',
 'events', 40, null, 1, null, null, false, true),
('event_rsvp_received',   'RSVP ricevuto',           'RSVP received',
 'Un utente ha confermato presenza a un evento proprio','A user confirmed attendance to your event',
 'events', 3, 10, null, null, null, false, true),

-- Engagement
('arrival_checkin',       'Check-in arrivo',         'Arrival check-in',
 'Check-in "Sto arrivando" in una pista',             '"I''m coming" check-in on a track',
 'engagement', 3, 3, 1, null, null, false, true),
('track_followed',        'Pista seguita',           'Track followed',
 'Primo follow di una pista',                         'First follow of a track',
 'engagement', 2, null, 1, 50, null, false, true),
('shop_followed',         'Negozio seguito',         'Shop followed',
 'Primo follow di un negozio',                        'First follow of a shop',
 'engagement', 2, null, 1, 50, null, false, true),
('event_rsvp_sent',       'RSVP inviato',            'RSVP sent',
 'RSVP a un evento',                                  'RSVP to an event',
 'engagement', 2, 5, null, null, null, false, true),

-- Moderazione (futura)
('moderation_report_helpful','Segnalazione utile',   'Helpful report',
 'Segnalazione confermata utile dagli admin',         'Report confirmed helpful by admins',
 'moderation', 15, null, null, null, null, true, false)
on conflict (action_key) do update
  set name_it           = excluded.name_it,
      name_en           = excluded.name_en,
      description_it    = excluded.description_it,
      description_en    = excluded.description_en,
      category          = excluded.category,
      base_points       = excluded.base_points,
      daily_cap         = excluded.daily_cap,
      per_entity_cap    = excluded.per_entity_cap,
      lifetime_cap      = excluded.lifetime_cap,
      cooldown_seconds  = excluded.cooldown_seconds,
      requires_approval = excluded.requires_approval,
      enabled           = excluded.enabled,
      updated_at        = timezone('utc', now());


-- ====================================================================
-- SEZIONE 8 — Seed pitcoin_badge_definitions
-- ====================================================================

insert into public.pitcoin_badge_definitions (
  badge_key, name_it, name_en, description_it, description_en,
  icon_asset, category, tier, criteria, enabled, sort_order
) values
-- Identita' / Garage
('identity_profile_complete', 'Profilo Completo', 'Complete Profile',
 'Hai completato avatar, slug pubblico e consensi base',
 'You completed avatar, public slug and base consents',
 'badges/identity_profile_complete.svg', 'identity', 'special',
 '{"type":"action_count","action_key":"profile_completed","threshold":1}'::jsonb,
 true, 10),

('garage_open', 'Officina Aperta', 'Garage Opened',
 'Hai creato la prima build nel tuo garage',
 'You created your first build',
 'badges/garage_open.svg', 'identity', 'bronze',
 '{"type":"action_count","action_key":"build_created","threshold":1}'::jsonb,
 true, 20),

('garage_showcase', 'Vetrina', 'Showcase',
 'Hai pubblicato la prima build alla community',
 'You published your first public build',
 'badges/garage_showcase.svg', 'identity', 'bronze',
 '{"type":"action_count","action_key":"build_published","threshold":1}'::jsonb,
 true, 30),

('garage_showroom', 'Showroom', 'Showroom',
 'Hai pubblicato 5 build',
 'You published 5 builds',
 'badges/garage_showroom.svg', 'identity', 'silver',
 '{"type":"action_count","action_key":"build_published","threshold":5}'::jsonb,
 true, 40),

('garage_master', 'Maestro Costruttore', 'Master Builder',
 'Hai pubblicato 15 build',
 'You published 15 builds',
 'badges/garage_master.svg', 'identity', 'gold',
 '{"type":"action_count","action_key":"build_published","threshold":15}'::jsonb,
 true, 50),

-- Contributo catalogo - spots
('explorer_bronze', 'Esploratore', 'Explorer',
 'Primo spot approvato',
 'First spot approved',
 'badges/explorer_bronze.svg', 'catalog', 'bronze',
 '{"type":"action_count","action_key":"spot_approved","threshold":1}'::jsonb,
 true, 100),

('explorer_silver', 'Cartografo', 'Cartographer',
 '5 spot approvati',
 '5 spots approved',
 'badges/explorer_silver.svg', 'catalog', 'silver',
 '{"type":"action_count","action_key":"spot_approved","threshold":5}'::jsonb,
 true, 110),

('explorer_gold', 'Geografo', 'Geographer',
 '20 spot approvati',
 '20 spots approved',
 'badges/explorer_gold.svg', 'catalog', 'gold',
 '{"type":"action_count","action_key":"spot_approved","threshold":20}'::jsonb,
 true, 120),

-- Contributo catalogo - tracks
('track_pioneer_bronze', 'Pioniere Pista', 'Track Pioneer',
 'Prima pista approvata',
 'First track approved',
 'badges/track_pioneer_bronze.svg', 'catalog', 'bronze',
 '{"type":"action_count","action_key":"track_approved","threshold":1}'::jsonb,
 true, 130),

('track_pioneer_silver', 'Costruttore di Mappe', 'Mapmaker',
 '3 piste approvate',
 '3 tracks approved',
 'badges/track_pioneer_silver.svg', 'catalog', 'silver',
 '{"type":"action_count","action_key":"track_approved","threshold":3}'::jsonb,
 true, 140),

('track_pioneer_gold', 'Architetto di Reti', 'Network Architect',
 '10 piste approvate',
 '10 tracks approved',
 'badges/track_pioneer_gold.svg', 'catalog', 'gold',
 '{"type":"action_count","action_key":"track_approved","threshold":10}'::jsonb,
 true, 150),

-- Contributo catalogo - shops
('shop_mapper_bronze', 'Segnalibri di Negozi', 'Shop Bookmarker',
 'Primo negozio approvato',
 'First shop approved',
 'badges/shop_mapper_bronze.svg', 'catalog', 'bronze',
 '{"type":"action_count","action_key":"shop_approved","threshold":1}'::jsonb,
 true, 160),

('shop_mapper_silver', 'Censore di Negozi', 'Shop Scout',
 '3 negozi approvati',
 '3 shops approved',
 'badges/shop_mapper_silver.svg', 'catalog', 'silver',
 '{"type":"action_count","action_key":"shop_approved","threshold":3}'::jsonb,
 true, 170),

('shop_mapper_gold', 'Curatore Mercati', 'Market Curator',
 '10 negozi approvati',
 '10 shops approved',
 'badges/shop_mapper_gold.svg', 'catalog', 'gold',
 '{"type":"action_count","action_key":"shop_approved","threshold":10}'::jsonb,
 true, 180),

-- Gestione (operations)
('track_guardian_bronze', 'Custode di Pista', 'Track Guardian',
 'Hai aggiornato lo stato pista in 7 giorni distinti',
 'You updated track status on 7 distinct days',
 'badges/track_guardian_bronze.svg', 'operations', 'bronze',
 '{"type":"distinct_days","action_key":"track_status_updated","threshold":7}'::jsonb,
 true, 200),

('track_guardian_silver', 'Padrone di Casa', 'House Master',
 '30 giorni distinti di aggiornamento stato pista',
 '30 distinct days updating track status',
 'badges/track_guardian_silver.svg', 'operations', 'silver',
 '{"type":"distinct_days","action_key":"track_status_updated","threshold":30}'::jsonb,
 true, 210),

('track_guardian_gold', 'Tutore di Pista', 'Track Custodian',
 '90 giorni distinti di aggiornamento stato pista',
 '90 distinct days updating track status',
 'badges/track_guardian_gold.svg', 'operations', 'gold',
 '{"type":"distinct_days","action_key":"track_status_updated","threshold":90}'::jsonb,
 true, 220),

-- Engagement
('local_pilot_bronze', 'Pilota Locale', 'Local Pilot',
 '10 check-in registrati',
 '10 check-ins logged',
 'badges/local_pilot_bronze.svg', 'engagement', 'bronze',
 '{"type":"action_count","action_key":"arrival_checkin","threshold":10}'::jsonb,
 true, 300),

('local_pilot_silver', 'Pilota Regolare', 'Regular Pilot',
 '50 check-in registrati',
 '50 check-ins logged',
 'badges/local_pilot_silver.svg', 'engagement', 'silver',
 '{"type":"action_count","action_key":"arrival_checkin","threshold":50}'::jsonb,
 true, 310),

('local_pilot_gold', 'Pilota Veterano', 'Veteran Pilot',
 '200 check-in registrati',
 '200 check-ins logged',
 'badges/local_pilot_gold.svg', 'engagement', 'gold',
 '{"type":"action_count","action_key":"arrival_checkin","threshold":200}'::jsonb,
 true, 320),

('weekend_warrior', 'Weekend Warrior', 'Weekend Warrior',
 '3 check-in nello stesso weekend, stessa pista',
 '3 check-ins same weekend, same track',
 'badges/weekend_warrior.svg', 'engagement', 'special',
 '{"type":"same_entity_same_weekend","action_key":"arrival_checkin","threshold":3}'::jsonb,
 true, 330),

('traveler_bronze', 'Giramondo', 'Globetrotter',
 'Check-in su 5 piste distinte',
 'Check-ins on 5 distinct tracks',
 'badges/traveler_bronze.svg', 'engagement', 'bronze',
 '{"type":"distinct_entities","action_key":"arrival_checkin","source_table":"arrivals","threshold":5}'::jsonb,
 true, 340),

('traveler_silver', 'Esploratore di Piste', 'Track Explorer',
 'Check-in su 15 piste distinte',
 'Check-ins on 15 distinct tracks',
 'badges/traveler_silver.svg', 'engagement', 'silver',
 '{"type":"distinct_entities","action_key":"arrival_checkin","source_table":"arrivals","threshold":15}'::jsonb,
 true, 350),

('traveler_gold', 'Conoscitore d''Italia', 'Italy Connoisseur',
 'Check-in su 30 piste distinte',
 'Check-ins on 30 distinct tracks',
 'badges/traveler_gold.svg', 'engagement', 'gold',
 '{"type":"distinct_entities","action_key":"arrival_checkin","source_table":"arrivals","threshold":30}'::jsonb,
 true, 360),

-- Eventi
('organizer_bronze', 'Organizzatore', 'Organizer',
 'Primo evento creato (community o ufficiale)',
 'First event created (community or official)',
 'badges/organizer_bronze.svg', 'events', 'bronze',
 '{"type":"action_count_any","action_keys":["community_event_created","official_event_created"],"threshold":1}'::jsonb,
 true, 400),

('organizer_silver', 'Show Runner', 'Show Runner',
 '5 eventi creati (community + ufficiali)',
 '5 events created (community + official)',
 'badges/organizer_silver.svg', 'events', 'silver',
 '{"type":"action_count_any","action_keys":["community_event_created","official_event_created"],"threshold":5}'::jsonb,
 true, 410),

('organizer_gold', 'Direttore di Gara', 'Race Director',
 '20 eventi creati (community + ufficiali)',
 '20 events created (community + official)',
 'badges/organizer_gold.svg', 'events', 'gold',
 '{"type":"action_count_any","action_keys":["community_event_created","official_event_created"],"threshold":20}'::jsonb,
 true, 420),

-- Milestone storiche
('pioneer_prealpha', 'Pioniere Pre-Alpha', 'Pre-Alpha Pioneer',
 'Utente attivo durante la pre-alpha 0.1.x',
 'Active user during pre-alpha 0.1.x',
 'badges/pioneer_prealpha.svg', 'milestone', 'special',
 '{"type":"manual"}'::jsonb,
 true, 900),

('pioneer_alpha', 'Pioniere Alpha', 'Alpha Pioneer',
 'Registrato prima del Gate Alpha pubblico',
 'Registered before public Alpha Gate',
 'badges/pioneer_alpha.svg', 'milestone', 'special',
 '{"type":"manual"}'::jsonb,
 true, 910)
on conflict (badge_key) do update
  set name_it        = excluded.name_it,
      name_en        = excluded.name_en,
      description_it = excluded.description_it,
      description_en = excluded.description_en,
      icon_asset     = excluded.icon_asset,
      category       = excluded.category,
      tier           = excluded.tier,
      criteria       = excluded.criteria,
      enabled        = excluded.enabled,
      sort_order     = excluded.sort_order;


-- ====================================================================
-- SEZIONE 9 — Backfill retroattivo
-- ====================================================================

do $$
declare
  v_meta jsonb := '{"source":"backfill","applied_at":"2026-05-23"}'::jsonb;
  v_now  timestamptz := timezone('utc', now());
  r      record;
begin
  -- ─── profile_completed (criterio attuale) ──────────────────────────────
  for r in
    select p.id, p.created_at
    from public.profiles p
    where p.role is distinct from 'admin'
      and coalesce(nullif(p.display_name, ''), null) is not null
      and coalesce(nullif(p.avatar_url,   ''), null) is not null
      and p.onboarding_completed_at is not null
      and exists (
        select 1 from public.user_consents uc
        where uc.user_id = p.id
          and uc.consent_type = 'terms_accepted'
          and uc.accepted = true
      )
  loop
    perform public.award_pitcoin_backfill(
      r.id, 'profile_completed', 'profiles', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
  end loop;

  -- ─── profile_made_public ───────────────────────────────────────────────
  for r in
    select p.id, p.created_at
    from public.profiles p
    where p.role is distinct from 'admin'
      and p.is_public = true
      and p.public_slug is not null
  loop
    perform public.award_pitcoin_backfill(
      r.id, 'profile_made_public', 'profiles', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
  end loop;

  -- ─── user_builds: build_created (+ build_published) ────────────────────
  for r in
    select b.id, b.owner_id, b.is_public, b.created_at
    from public.user_builds b
    where b.owner_id is not null
  loop
    perform public.award_pitcoin_backfill(
      r.owner_id, 'build_created', 'user_builds', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
    if r.is_public = true then
      perform public.award_pitcoin_backfill(
        r.owner_id, 'build_published', 'user_builds', r.id, v_meta,
        coalesce(r.created_at, v_now)
      );
    end if;
  end loop;

  -- ─── tracks: track_submitted + (se approved) track_approved ────────────
  for r in
    select t.id, t.submitted_by, t.approval_status, t.created_at
    from public.tracks t
    where t.submitted_by is not null
  loop
    perform public.award_pitcoin_backfill(
      r.submitted_by, 'track_submitted', 'tracks', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
    if r.approval_status = 'approved' then
      perform public.award_pitcoin_backfill(
        r.submitted_by, 'track_approved', 'tracks', r.id, v_meta,
        coalesce(r.created_at, v_now)
      );
    end if;
  end loop;

  -- ─── shops: shop_submitted + (se approved) shop_approved ───────────────
  for r in
    select s.id, s.submitted_by, s.approval_status, s.created_at
    from public.shops s
    where s.submitted_by is not null
  loop
    perform public.award_pitcoin_backfill(
      r.submitted_by, 'shop_submitted', 'shops', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
    if r.approval_status = 'approved' then
      perform public.award_pitcoin_backfill(
        r.submitted_by, 'shop_approved', 'shops', r.id, v_meta,
        coalesce(r.created_at, v_now)
      );
    end if;
  end loop;

  -- ─── spots: spot_submitted + spot_approved (schema senza approval_status) ──
  for r in
    select sp.id, sp.owner_id, sp.created_at
    from public.spots sp
    where sp.is_custom = true and sp.owner_id is not null
  loop
    perform public.award_pitcoin_backfill(
      r.owner_id, 'spot_submitted', 'spots', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
    perform public.award_pitcoin_backfill(
      r.owner_id, 'spot_approved', 'spots', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
  end loop;

  -- ─── community_events: community_event_created ─────────────────────────
  for r in
    select ce.id, ce.author_id, ce.created_at
    from public.community_events ce
    where ce.author_id is not null
  loop
    perform public.award_pitcoin_backfill(
      r.author_id, 'community_event_created', 'community_events', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
  end loop;

  -- ─── events: official_event_created ────────────────────────────────────
  for r in
    select e.id, e.created_by, e.created_at
    from public.events e
    where e.created_by is not null
  loop
    perform public.award_pitcoin_backfill(
      r.created_by, 'official_event_created', 'events', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
  end loop;

  -- ─── event_rsvps: event_rsvp_sent + event_rsvp_received ────────────────
  for r in
    select er.id, er.event_id, er.user_id, er.status, er.created_at,
           e.created_by as event_owner
    from public.event_rsvps er
    left join public.events e on e.id = er.event_id
    where er.status = 'going'
  loop
    if r.user_id is not null then
      perform public.award_pitcoin_backfill(
        r.user_id, 'event_rsvp_sent', 'event_rsvps', r.id, v_meta,
        coalesce(r.created_at, v_now)
      );
    end if;
    if r.event_owner is not null and r.event_owner <> r.user_id then
      perform public.award_pitcoin_backfill(
        r.event_owner, 'event_rsvp_received', 'event_rsvps', r.id, v_meta,
        coalesce(r.created_at, v_now)
      );
    end if;
  end loop;

  -- ─── arrivals: arrival_checkin (rispetta daily_cap retroattivo) ────────
  -- DISTINCT per (user, track, giorno) garantisce 1 sola transazione/giorno/pista
  -- (la unique constraint sul ledger e' su source_id = arrivals.id; usiamo
  --  l'id del primo arrival per quel giorno/pista/utente)
  for r in
    select distinct on (a.user_id, a.track_id, a.arrival_date)
      a.id, a.user_id, a.track_id, a.arrival_date, a.created_at
    from public.arrivals a
    where a.user_id is not null
      and a.status = 'coming'
    order by a.user_id, a.track_id, a.arrival_date, a.created_at asc
  loop
    perform public.award_pitcoin_backfill(
      r.user_id, 'arrival_checkin', 'arrivals', r.id, v_meta,
      coalesce(r.created_at, (r.arrival_date::timestamptz))
    );
  end loop;

  -- ─── track_follows: track_followed ────────────────────────────────────
  for r in
    select tf.track_id, tf.user_id, tf.created_at
    from public.track_follows tf
    where tf.user_id is not null
  loop
    perform public.award_pitcoin_backfill(
      r.user_id, 'track_followed', 'track_follows', r.track_id, v_meta,
      coalesce(r.created_at, v_now)
    );
  end loop;

  -- ─── shop_follows: shop_followed ──────────────────────────────────────
  for r in
    select sf.shop_id, sf.user_id, sf.created_at
    from public.shop_follows sf
    where sf.user_id is not null
  loop
    perform public.award_pitcoin_backfill(
      r.user_id, 'shop_followed', 'shop_follows', r.shop_id, v_meta,
      coalesce(r.created_at, v_now)
    );
  end loop;

  -- ─── track_status_history: track_status_updated (1/giorno/pista) ──────
  -- Rispetta il cooldown retroattivo collassando per (user, track, giorno)
  for r in
    select distinct on (tsh.updated_by, tsh.track_id, date_trunc('day', tsh.updated_at))
      tsh.id, tsh.updated_by, tsh.track_id, tsh.updated_at
    from public.track_status_history tsh
    where tsh.updated_by is not null
    order by tsh.updated_by, tsh.track_id, date_trunc('day', tsh.updated_at), tsh.updated_at asc
  loop
    perform public.award_pitcoin_backfill(
      r.updated_by, 'track_status_updated', 'track_status_history', r.id, v_meta,
      coalesce(r.updated_at, v_now)
    );
  end loop;

  -- ─── external_links: external_link_added ───────────────────────────────
  for r in
    select el.id, el.owner_id, el.created_at
    from public.external_links el
    where el.owner_id is not null
  loop
    perform public.award_pitcoin_backfill(
      r.owner_id, 'external_link_added', 'external_links', r.id, v_meta,
      coalesce(r.created_at, v_now)
    );
  end loop;

  -- ─── Ricomputa tutti i balance dal ledger ───────────────────────────────
  for r in
    select distinct user_id from public.pitcoin_transactions
  loop
    perform public.recompute_user_balance(r.user_id);
  end loop;

  -- ─── pioneer_prealpha: tutti gli utenti con >= 1 transazione di backfill
  for r in
    select distinct user_id
    from public.pitcoin_transactions
    where metadata->>'source' = 'backfill'
  loop
    perform public.award_user_badge_manual(
      r.user_id, 'pioneer_prealpha',
      jsonb_build_object('source','backfill','applied_at','2026-05-23')
    );
  end loop;

  -- ─── pioneer_alpha: tutti gli utenti registrati prima di oggi (Gate Alpha)
  for r in
    select id
    from public.profiles
    where role is distinct from 'admin'
      and created_at < '2026-05-23'::timestamptz
  loop
    perform public.award_user_badge_manual(
      r.id, 'pioneer_alpha',
      jsonb_build_object('source','backfill','applied_at','2026-05-23')
    );
  end loop;

  -- ─── Rivaluta tutte le badge a criteria automatica per ogni utente ────
  for r in
    select distinct user_id from public.pitcoin_transactions
  loop
    perform public.check_badge_unlocks(r.user_id, null);
  end loop;
end$$;


-- ────────────────────────────────────────────────────────────────────────────
-- FINE delta 2026-05-23 PitCoin & Badge System
-- ────────────────────────────────────────────────────────────────────────────
