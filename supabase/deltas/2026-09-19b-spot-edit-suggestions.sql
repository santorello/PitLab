-- Delta: 2026-09-19 — Proposte di modifica spot (fix "Segnala aggiornamento")
-- Prima: chi non e' owner/admin finiva su un form vuoto e creava un doppione.
-- Ora: la stessa schermata, precompilata, salva una proposta che l'admin approva o rifiuta.
-- Idempotente. Eseguire su dev e poi su prod.

create table if not exists public.spot_edit_suggestions (
  id           uuid        primary key default gen_random_uuid(),
  spot_id      uuid        not null references public.spots(id) on delete cascade,
  submitted_by uuid        not null references public.profiles(id) on delete cascade,
  payload      jsonb       not null,
  status       text        not null default 'pending',
  review_notes text,
  reviewed_by  uuid        references public.profiles(id) on delete set null,
  reviewed_at  timestamptz,
  created_at   timestamptz not null default timezone('utc', now())
);

alter table public.spot_edit_suggestions drop constraint if exists spot_edit_suggestions_status_check;
alter table public.spot_edit_suggestions add constraint spot_edit_suggestions_status_check
  check (status in ('pending', 'approved', 'rejected'));

create index if not exists spot_edit_suggestions_pending_idx
  on public.spot_edit_suggestions (created_at desc) where status = 'pending';
create index if not exists spot_edit_suggestions_spot_idx
  on public.spot_edit_suggestions (spot_id);

-- ponytail: una sola proposta pending per utente e per spot, cosi' la coda non si riempie di rinvii.
create unique index if not exists spot_edit_suggestions_one_pending_idx
  on public.spot_edit_suggestions (spot_id, submitted_by) where status = 'pending';

alter table public.spot_edit_suggestions enable row level security;

drop policy if exists "spot_suggestions: author inserts"  on public.spot_edit_suggestions;
drop policy if exists "spot_suggestions: author reads"    on public.spot_edit_suggestions;
drop policy if exists "spot_suggestions: admins manage"   on public.spot_edit_suggestions;

create policy "spot_suggestions: author inserts" on public.spot_edit_suggestions
  for insert to authenticated
  with check (submitted_by = (select auth.uid()) and status = 'pending');

create policy "spot_suggestions: author reads" on public.spot_edit_suggestions
  for select to authenticated
  using (submitted_by = (select auth.uid()));

create policy "spot_suggestions: admins manage" on public.spot_edit_suggestions
  for all to authenticated
  using (exists (select 1 from public.profiles p
                 where p.id = (select auth.uid()) and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p
                      where p.id = (select auth.uid()) and p.role = 'admin'));

grant select, insert on public.spot_edit_suggestions to authenticated;
grant update (status, review_notes, reviewed_by, reviewed_at) on public.spot_edit_suggestions to authenticated;

-- Coda admin: proposte pending con il nome dello spot e di chi l'ha mandata.
create or replace view public.admin_spot_suggestions with (security_invoker = true) as
select s.id, s.spot_id, sp.slug as spot_slug, sp.title as spot_title,
       s.submitted_by, pr.display_name as submitted_by_name,
       s.payload, s.status, s.created_at
from public.spot_edit_suggestions s
join public.spots sp on sp.id = s.spot_id
left join public.profiles pr on pr.id = s.submitted_by
where s.status = 'pending';

grant select on public.admin_spot_suggestions to authenticated;

-- Approvazione: applica solo le chiavi presenti nel payload, poi marca la proposta.
create or replace function public.admin_review_spot_suggestion(
  p_id uuid, p_approve boolean, p_notes text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare v_payload jsonb; v_spot uuid;
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'admin') then
    raise exception 'solo admin';
  end if;

  select payload, spot_id into v_payload, v_spot
  from public.spot_edit_suggestions where id = p_id and status = 'pending';
  if not found then raise exception 'proposta non trovata o gia trattata'; end if;

  if p_approve then
    update public.spots set
      title         = coalesce(v_payload->>'title', title),
      city          = coalesce(v_payload->>'city', city),
      note          = coalesce(v_payload->>'note', note),
      address       = coalesce(v_payload->>'address', address),
      latitude      = coalesce((v_payload->>'latitude')::double precision, latitude),
      longitude     = coalesce((v_payload->>'longitude')::double precision, longitude),
      video_url     = coalesce(v_payload->>'video_url', video_url),
      best_for_tags = coalesce(
        (select array_agg(value::text) from jsonb_array_elements_text(v_payload->'best_for_tags')),
        best_for_tags),
      surface_tags  = coalesce(
        (select array_agg(value::text) from jsonb_array_elements_text(v_payload->'surface_tags')),
        surface_tags),
      access_type   = coalesce(v_payload->>'access_type', access_type),
      best_season   = coalesce(v_payload->>'best_season', best_season)
    where id = v_spot;
  end if;

  update public.spot_edit_suggestions
     set status = case when p_approve then 'approved' else 'rejected' end,
         review_notes = p_notes, reviewed_by = auth.uid(), reviewed_at = now()
   where id = p_id;
end $$;

revoke all on function public.admin_review_spot_suggestion(uuid, boolean, text) from public, anon;
grant execute on function public.admin_review_spot_suggestion(uuid, boolean, text) to authenticated;

-- Verifica (atteso: 1 tabella, 1 vista, 1 funzione)
select
  (select count(*) from information_schema.tables  where table_schema='public' and table_name='spot_edit_suggestions') as tabella,
  (select count(*) from information_schema.views   where table_schema='public' and table_name='admin_spot_suggestions') as vista,
  (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='admin_review_spot_suggestion') as funzione;
