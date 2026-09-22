-- Eventi community: alla cancellazione dell'account l'evento RESTA e l'autore
-- viene anonimizzato (come tracks/shops/spots). Decisione di Giuseppe, 23/09/2026.
-- Prima: author_id NOT NULL + ON DELETE CASCADE (l'evento spariva con l'utente).
-- Dopo:  author_id nullable + ON DELETE SET NULL.
-- Effetti verificati su dev:
--   - RLS update/delete: author_id = auth.uid() con author_id NULL e' falso,
--     quindi un evento orfano lo modifica o cancella solo l'admin.
--   - Trigger PitCoin e notifiche follower sono solo AFTER INSERT: non toccati.
--   - Flutter legge author_id come String? (profile_hub_providers): nessuna modifica.
-- Idempotente.

alter table public.community_events alter column author_id drop not null;

alter table public.community_events drop constraint if exists community_events_author_id_fkey;
alter table public.community_events
  add constraint community_events_author_id_fkey
  foreign key (author_id) references public.profiles(id) on delete set null;

-- Controllo: deve restituire 'YES' e 'ON DELETE SET NULL'
select is_nullable,
       (select pg_get_constraintdef(oid) from pg_constraint
         where conname = 'community_events_author_id_fkey') as fk
from information_schema.columns
where table_schema = 'public' and table_name = 'community_events' and column_name = 'author_id';
