-- ============================================================================
-- PitLap — Tabella keepalive (2026-09-12)
--
-- PERCHE' ESISTE QUESTO DELTA: la tabella `public.keepalive` era stata creata
-- a mano su dev e non era descritta da nessun delta. Il delta
-- 2026-06-18-enable-keepalive-timestamp-update.sql la presuppone gia'
-- esistente, quindi su un'istanza pulita (prod) fallirebbe con
-- "relation public.keepalive does not exist".
-- Questo file ricostruisce lo stato osservato su dev e va eseguito PRIMA
-- del delta del 2026-06-18.
--
-- A cosa serve: la GitHub Action di keepalive aggiorna `checked_at` a
-- intervalli regolari usando la anon key, cosi' il progetto free-tier non
-- viene auto-pausato per inattivita'. Esattamente cio' che e' successo a
-- pitlap-prod, rimasto INACTIVE fino al 2026-09-12.
--
-- Idempotente.
-- ============================================================================

begin;

-- Riga singola: il primary key booleano con default true impedisce per
-- costruzione l'inserimento di piu' di una riga.
create table if not exists public.keepalive (
  id boolean primary key default true,
  checked_at timestamptz not null default now()
);

insert into public.keepalive (id, checked_at)
values (true, now())
on conflict (id) do nothing;

alter table public.keepalive enable row level security;

-- Lettura anonima: serve alla Action per verificare l'esito dell'update.
drop policy if exists "Allow anonymous keepalive read" on public.keepalive;
create policy "Allow anonymous keepalive read"
  on public.keepalive
  for select
  to anon
  using (id = true);

commit;

-- ----------------------------------------------------------------------------
-- La policy e il grant di UPDATE (solo colonna checked_at) sono nel delta
-- 2026-06-18-enable-keepalive-timestamp-update.sql, da eseguire subito dopo.
-- ----------------------------------------------------------------------------
