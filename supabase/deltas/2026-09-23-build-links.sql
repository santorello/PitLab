-- Ondata 2 "Luoghi vivi": una build puo' essere collegata a piste, negozi,
-- spot ed eventi. Ogni scheda luogo mostra le "Build viste qui".
-- Prima tabella nuova dopo la mail Supabase del 30/10/2026: GRANT esplicite.
-- Idempotente.

create table if not exists public.build_links (
  build_id    uuid        not null references public.user_builds(id) on delete cascade,
  entity_type text        not null check (entity_type in ('track', 'shop', 'spot', 'event')),
  entity_id   uuid        not null,
  created_at  timestamptz not null default now(),
  primary key (build_id, entity_type, entity_id)
);

create index if not exists build_links_entity_idx
  on public.build_links (entity_type, entity_id, created_at desc);

alter table public.build_links enable row level security;

-- Si vedono i collegamenti delle build pubbliche (e delle proprie).
drop policy if exists "build_links select" on public.build_links;
create policy "build_links select" on public.build_links
  for select using (
    exists (
      select 1 from public.user_builds b
      where b.id = build_links.build_id
        and (b.is_public or b.owner_id = (select auth.uid()))
    )
  );

-- Solo il proprietario della build collega e scollega.
drop policy if exists "build_links insert" on public.build_links;
create policy "build_links insert" on public.build_links
  for insert to authenticated
  with check (
    exists (
      select 1 from public.user_builds b
      where b.id = build_links.build_id and b.owner_id = (select auth.uid())
    )
  );

drop policy if exists "build_links delete" on public.build_links;
create policy "build_links delete" on public.build_links
  for delete to authenticated
  using (
    exists (
      select 1 from public.user_builds b
      where b.id = build_links.build_id and b.owner_id = (select auth.uid())
    )
  );

-- GRANT esplicite (regola 30/10/2026). Nessun update: si cancella e ricrea.
revoke all on public.build_links from anon, authenticated;
grant select on public.build_links to anon, authenticated;
grant insert, delete on public.build_links to authenticated;

-- Tetto: al massimo 8 luoghi per build, contro lo spam di collegamenti.
create or replace function public.build_links_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (select count(*) from public.build_links where build_id = new.build_id) >= 8 then
    raise exception 'Una build puo'' essere collegata al massimo a 8 luoghi.'
      using errcode = 'P0001', hint = 'build_links_limit';
  end if;
  return new;
end;
$$;
revoke execute on function public.build_links_limit() from public, anon, authenticated;

drop trigger if exists trg_build_links_limit on public.build_links;
create trigger trg_build_links_limit before insert on public.build_links
  for each row execute function public.build_links_limit();


-- Tutti i luoghi collegabili, con nome e citta', per la ricerca e le etichette.
-- security_invoker: valgono le RLS delle tabelle di origine (solo pubblici).
create or replace view public.link_targets
with (security_invoker = true) as
  select 'track'::text as entity_type, t.id as entity_id, t.slug, t.name, t.city
    from public.tracks t
   where t.is_public and t.approval_status = 'approved'
  union all
  select 'shop', s.id, s.slug, s.name, s.city
    from public.shops s
   where s.is_public and s.approval_status = 'approved'
  union all
  select 'spot', sp.id, sp.slug, sp.title, sp.city
    from public.spots sp
  union all
  select 'event', ce.id, null, ce.title, ce.location
    from public.community_events ce
  union all
  select 'event', e.id, null, e.title, coalesce(tr.city, '')
    from public.events e
    left join public.tracks tr on tr.id = e.track_id;

revoke all on public.link_targets from anon, authenticated;
grant select on public.link_targets to anon, authenticated;

-- Controllo
select (select count(*) from public.link_targets) as luoghi_collegabili;
