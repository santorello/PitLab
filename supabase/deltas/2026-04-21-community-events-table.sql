-- Delta: 2026-04-21 - Tabella community_events
-- Eventi creati liberamente dagli utenti registrati (non legati a una pista ufficiale).
-- Distinti dalla tabella `events` che è riservata agli eventi ufficiali associati a tracks.

create table public.community_events (
  id            uuid        primary key default gen_random_uuid(),
  author_id     uuid        not null references public.profiles(id) on delete cascade,
  title         text        not null,
  location      text        not null default '',
  venue         text        not null default '',
  note          text        not null default '',
  badge         text        not null default '',
  creator_label text        not null default '',
  creator_role  text        not null default 'user',
  image_urls    text[]      not null default '{}',
  starts_at     timestamptz,
  created_at    timestamptz not null default timezone('utc', now()),
  updated_at    timestamptz not null default timezone('utc', now())
);

create index community_events_author_idx   on public.community_events (author_id);
create index community_events_starts_idx   on public.community_events (starts_at);

create trigger community_events_updated_at
  before update on public.community_events
  for each row execute function public.set_updated_at();

alter table public.community_events enable row level security;

-- Lettura: solo l'autore può vedere i propri eventi
create policy "community_events: author reads own"
  on public.community_events for select
  using (author_id = auth.uid());

-- Inserimento: l'utente autenticato può inserire solo i propri eventi
create policy "community_events: author inserts"
  on public.community_events for insert
  with check (author_id = auth.uid() and auth.uid() is not null);

-- Aggiornamento: solo l'autore può modificare i propri eventi
create policy "community_events: author updates"
  on public.community_events for update
  using (author_id = auth.uid())
  with check (author_id = auth.uid());

-- Eliminazione: solo l'autore può eliminare i propri eventi
create policy "community_events: author deletes"
  on public.community_events for delete
  using (author_id = auth.uid());

-- Admin: gestione completa
create policy "community_events: admins manage all"
  on public.community_events for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
