-- Delta: 2026-09-19 — Filtro contenuti su testi inviati dagli utenti
-- Blocca l'inserimento (nessun record sporco entra nel DB) e alza un errore
-- codificato che l'app traduce in un messaggio leggibile.
--
-- Copertura: entity_comments.body, spots.title/note, profiles.display_name,
--            spot_edit_suggestions.payload (title, city, note).
--
-- LIMITE NOTO, non aggirabile con questa tecnica: il filtro riconosce PAROLE e
-- FRASI presenti in tabella. Non capisce il senso di un testo. Contenuti
-- sessuali allusivi o riferimenti a minori scritti senza i termini elencati
-- passano. Il presidio vero resta la segnalazione + is_hidden gia' in uso.
--
-- Idempotente. Eseguire su dev e poi su prod.

begin;

-- ── Normalizzazione ─────────────────────────────────────────────────────────
-- Minuscole, accenti via, leetspeak (0→o 1→i 3→e 4→a 5→s 7→t 8→b @→a $→s),
-- lettere ripetute compresse, separatori (c.a.z.z.o / c-a-z-z-o) rimossi.
create or replace function public.moderation_normalize(p_text text)
returns text language sql immutable as $$
  select regexp_replace(
           regexp_replace(
             regexp_replace(
               translate(
                 lower(coalesce(p_text, '')),
                 'àáâãäèéêëìíîïòóôõöùúûüçñ0134578@$',
                 'aaaaaeeeeiiiiooooouuuucnoieastbas'
               ),
               '[^a-z0-9 ]+', '', 'g'          -- punteggiatura via SENZA spezzare
                                               -- la parola: c.a.z.z.o -> cazzo
             ),
             '(.)\1{2,}', '\1\1', 'g'           -- caaaazzo → caazzo
           ),
           '\s+', ' ', 'g'
         )
$$;

-- ── Dizionario ──────────────────────────────────────────────────────────────
-- pattern = regex su testo NORMALIZZATO. \m \M sono i confini di parola di
-- Postgres: senza, "cazzuola" e "scopo" finirebbero bloccati.
create table if not exists public.moderation_terms (
  id         bigint generated always as identity primary key,
  pattern    text not null unique,
  category   text not null,
  note       text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.moderation_terms drop constraint if exists moderation_terms_category_check;
alter table public.moderation_terms add constraint moderation_terms_category_check
  check (category in ('volgare', 'bestemmia', 'sessuale', 'minori', 'odio'));

alter table public.moderation_terms enable row level security;
drop policy if exists "moderation_terms: admin only" on public.moderation_terms;
create policy "moderation_terms: admin only" on public.moderation_terms
  for all to authenticated
  using (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'));
grant select, insert, update, delete on public.moderation_terms to authenticated;

-- ── Verifica ────────────────────────────────────────────────────────────────
-- Ritorna la categoria del primo match, oppure null se il testo e' pulito.
-- security definer: le policy sopra chiudono la tabella agli utenti normali,
-- ma il trigger deve poterla leggere per chiunque.
create or replace function public.moderation_violation(p_text text)
returns text language sql stable security definer set search_path = public as $$
  select t.category
  from public.moderation_terms t
  where t.is_active
    and public.moderation_normalize(p_text) ~ t.pattern
  order by array_position(
    array['minori','odio','bestemmia','sessuale','volgare']::text[], t.category)
  limit 1
$$;

revoke all on function public.moderation_violation(text) from public, anon;
grant execute on function public.moderation_violation(text) to authenticated;

-- ── Trigger generico ────────────────────────────────────────────────────────
-- TG_ARGV = elenco dei campi da controllare sulla riga.
-- Il messaggio e' un codice: l'app lo traduce, l'utente non legge SQL.
create or replace function public.moderation_guard()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_field text;
  v_value text;
  v_hit   text;
begin
  foreach v_field in array tg_argv loop
    execute format('select ($1).%I::text', v_field) into v_value using new;
    v_hit := public.moderation_violation(v_value);
    if v_hit is not null then
      raise exception 'PITLAP_MODERATION:%:%', v_hit, v_field
        using errcode = 'P0001';
    end if;
  end loop;
  return new;
end $$;

-- ponytail: un solo trigger function riusata, niente una funzione per tabella.
drop trigger if exists entity_comments_moderation on public.entity_comments;
create trigger entity_comments_moderation
  before insert or update of body on public.entity_comments
  for each row execute function public.moderation_guard('body');

drop trigger if exists spots_moderation on public.spots;
create trigger spots_moderation
  before insert or update of title, note on public.spots
  for each row execute function public.moderation_guard('title', 'note');

drop trigger if exists profiles_moderation on public.profiles;
create trigger profiles_moderation
  before insert or update of display_name on public.profiles
  for each row execute function public.moderation_guard('display_name');

-- Le proposte hanno i testi dentro un jsonb: controllo mirato.
create or replace function public.moderation_guard_suggestion()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_hit text;
begin
  v_hit := public.moderation_violation(
    concat_ws(' ', new.payload->>'title', new.payload->>'city', new.payload->>'note'));
  if v_hit is not null then
    raise exception 'PITLAP_MODERATION:%:payload', v_hit using errcode = 'P0001';
  end if;
  return new;
end $$;

drop trigger if exists spot_suggestions_moderation on public.spot_edit_suggestions;
create trigger spot_suggestions_moderation
  before insert on public.spot_edit_suggestions
  for each row execute function public.moderation_guard_suggestion();

-- ── Dizionario iniziale ─────────────────────────────────────────────────────
-- Scritto a mano, non generato a runtime: PitLap non chiama nessun LLM.
-- Ampliabile dall'admin senza deploy (insert in moderation_terms).
-- Termini ambigui in contesto modellismo LASCIATI FUORI di proposito:
-- "pompa", "sega", "mazza", "fico", "scopo" — troppi falsi positivi.
insert into public.moderation_terms (pattern, category, note) values
  -- volgare
  ('\mca+zz(o|i|ata|ate|uto)\M',        'volgare',   'esclusa cazzuola'),
  ('\mstronz(o|a|i|e|ata|ate)\M',       'volgare',   null),
  ('\mvaffanculo\M|\mva fanculo\M|\mfanculo\M', 'volgare', null),
  ('\m(in|sul|nel)? ?culo\M',           'volgare',   null),
  ('\mcoglion(e|i|ata|ate)\M',          'volgare',   null),
  ('\mmerd(a|e|oso|osa)\M',             'volgare',   null),
  ('\mbastard(o|a|i|e)\M',              'volgare',   null),
  ('\mtroi(a|e)\M',                     'volgare',   null),
  ('\mputtan(a|e|ata|ate)\M',           'volgare',   null),
  ('\mzocc(ola|ole)\M',                 'volgare',   null),
  ('\mminchi(a|e|one)\M',               'volgare',   null),
  ('\mfrocio?\M|\mfroci\M',             'odio',      'omofobo'),
  ('\mnegr(o|a|i|e)\M',                 'odio',      null),
  ('\mricchion(e|i)\M',                 'odio',      null),
  -- bestemmia (forme piu' diffuse, incluse le storpiature comuni)
  ('\mdio (can|porc|boia|bestia|mer|lad|schif)',           'bestemmia', null),
  ('\mmadonna (puttan|troia|ladra|maial|porc|impestat)',   'bestemmia', null),
  ('\mporc(o|a) (dio|madonna|gesu|cristo|signore|mandria)','bestemmia', null),
  ('\mcristo (dio|santo|porco)\M',                         'bestemmia', null),
  ('\mdiocan|\mdioporco|\mdioboia|\mmadonnaputtana',       'bestemmia', 'tutto attaccato'),
  -- sessuale esplicito
  ('\mpompin(o|i|ara)\M',               'sessuale',  null),
  ('\mscopa(re|ta|te|ami|to)\M',        'sessuale',  null),
  ('\mtrombare\M|\mchiavare\M',         'sessuale',  null),
  ('\mfig(a|he)\M',                     'sessuale',  'esclusi fico/fichi'),
  ('\mtett(a|e|one)\M',                 'sessuale',  null),
  ('\mporno|\mhard ?core\M|\mxxx\M',    'sessuale',  null),
  ('\msborr|\msperma\M',                'sessuale',  null),
  ('\mmasturb',                         'sessuale',  null),
  ('\mescort\M|\msesso a pagamento\M',  'sessuale',  null),
  -- minori: combinazioni, non singole parole. L'ordine di priorita' nella
  -- funzione mette questa categoria per prima.
  ('\m(bambin|bimb|minoren|ragazzin|piccol|infant|lolit|preteen|cp)\w* '
   '(\w+ ){0,4}(sess|nud|porn|scopa|tocca|molest|abus|mutand|spogli)', 'minori', 'minore + sessuale'),
  ('\m(sess|porn|nud|scopa|molest|abus|spogli)\w* '
   '(\w+ ){0,4}(bambin|bimb|minoren|ragazzin|infant|lolit)',           'minori', 'sessuale + minore'),
  ('\mpedofil|\mpedoporno|\mchild ?porn|\mcsam\M',                     'minori', null),
  ('\mlolicon\M|\mshotacon\M|\mjailbait\M',                            'minori', null)
on conflict (pattern) do nothing;

commit;

-- ── Verifica: attesi 4 blocchi e 3 righe pulite ─────────────────────────────
select t.testo, public.moderation_violation(t.testo) as esito
from (values
  ('Bel giro, che spot fantastico!'),
  ('Il fondo dopo la pioggia diventa una merda'),
  ('C.A.Z.Z.O che salto'),
  ('caaaazzzo che bello'),
  ('Ho usato la cazzuola per livellare la rampa'),   -- deve passare
  ('Lo scopo del test era la trazione'),             -- deve passare
  ('porco dio che fango')
) as t(testo);

-- ============================================================================
-- Log dei blocchi (aggiunto 2026-09-19) — serve a TARARE i termini, non a
-- difendere: il blocco vero resta il trigger. La scrittura parte dal client
-- perche' il trigger alza un'eccezione e Postgres non ha transazioni
-- autonome: un insert dentro lo stesso statement verrebbe annullato.
-- ============================================================================

create table if not exists public.moderation_blocks (
  id         bigint generated always as identity primary key,
  user_id    uuid references public.profiles(id) on delete set null,
  category   text not null,
  source     text,
  field      text,
  sample     text,
  created_at timestamptz not null default now()
);
create index if not exists moderation_blocks_recent_idx on public.moderation_blocks (created_at desc);

alter table public.moderation_blocks enable row level security;
drop policy if exists "moderation_blocks: admin reads" on public.moderation_blocks;
create policy "moderation_blocks: admin reads" on public.moderation_blocks
  for select to authenticated
  using (exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin'));
grant select on public.moderation_blocks to authenticated;

-- Nessun grant di insert: si scrive solo da qui, cosi' nessuno inventa righe.
create or replace function public.log_moderation_block(
  p_category text, p_source text default null,
  p_field text default null, p_sample text default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_category not in ('volgare','bestemmia','sessuale','minori','odio') then
    return;
  end if;
  insert into public.moderation_blocks (user_id, category, source, field, sample)
  values (auth.uid(), p_category, left(p_source, 60), left(p_field, 60), left(p_sample, 300));
end $$;

revoke all on function public.log_moderation_block(text, text, text, text) from public, anon;
grant execute on function public.log_moderation_block(text, text, text, text) to authenticated;

-- Consultazione: quanto scatta e su cosa.
-- select category, count(*) from public.moderation_blocks group by 1 order by 2 desc;
-- select created_at, category, source, sample from public.moderation_blocks
--   order by created_at desc limit 30;

-- ── Retention del testo bloccato (90 giorni) ────────────────────────────────
-- La riga resta PER SEMPRE: serve la statistica, e l'etichetta di cosa era.
-- Il testo sparisce: e' contenuto sgradevole accanto a un user_id, quindi
-- dato personale. Dopo la pulizia restano categoria, origine, campo, autore
-- e data — abbastanza per tarare i termini e per ricostruire un episodio.

alter table public.moderation_blocks add column if not exists sample_purged_at timestamptz;

create or replace function public.purge_moderation_samples()
returns integer language plpgsql security definer set search_path = public as $$
declare v_count integer;
begin
  update public.moderation_blocks
     set sample = null, sample_purged_at = now()
   where sample is not null
     and created_at < now() - interval '90 days';
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- Nessuno la esegue dall'app: gira solo da cron.
revoke all on function public.purge_moderation_samples() from public, anon, authenticated;

-- ponytail: pg_cron invece di una Edge Function schedulata. Una riga, gira
-- dentro il database, non ha niente da tenere acceso.
create extension if not exists pg_cron;
select cron.unschedule(jobid) from cron.job where jobname = 'purge_moderation_samples';
select cron.schedule('purge_moderation_samples', '17 3 * * *',
                     $$select public.purge_moderation_samples()$$);

-- Consultazione quotidiana: mai il testo, solo le etichette.
create or replace view public.admin_moderation_stats with (security_invoker = true) as
select date_trunc('day', created_at)::date as giorno,
       category, source, count(*) as blocchi,
       count(*) filter (where sample is null) as testo_gia_cancellato
from public.moderation_blocks
group by 1, 2, 3
order by 1 desc, 4 desc;
grant select on public.admin_moderation_stats to authenticated;

-- Verifica cron (atteso: 1)
-- select count(*) from cron.job where jobname = 'purge_moderation_samples';
