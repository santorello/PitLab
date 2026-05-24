-- Delta: 2026-04-22 - Tabella external_links
-- Link esterni (sito, Instagram, YouTube, ecc.) collegati a entità del catalogo.
-- entity_type: 'shop' | 'track' | 'profile' | altro futuro
-- entity_id:   slug o UUID dell'entità (coerente con il formato usato dall'app)

create table public.external_links (
  id          uuid        primary key default gen_random_uuid(),
  owner_id    uuid        not null references public.profiles(id) on delete cascade,
  entity_type text        not null,
  entity_id   text        not null,
  provider    text        not null default 'website',
  label       text        not null default '',
  url         text        not null,
  is_public   boolean     not null default true,
  sort_order  int         not null default 0,
  created_at  timestamptz not null default timezone('utc', now()),
  updated_at  timestamptz not null default timezone('utc', now())
);

create index external_links_owner_idx  on public.external_links (owner_id);
create index external_links_entity_idx on public.external_links (entity_type, entity_id);

create trigger external_links_updated_at
  before update on public.external_links
  for each row execute function public.set_updated_at();

alter table public.external_links enable row level security;

-- Lettura pubblica dei link marcati pubblici
create policy "external_links: public reads public"
  on public.external_links for select
  using (is_public = true);

-- Owner legge tutti i propri link (inclusi privati)
create policy "external_links: owner reads own"
  on public.external_links for select
  using (owner_id = auth.uid());

create policy "external_links: owner inserts"
  on public.external_links for insert
  with check (owner_id = auth.uid() and auth.uid() is not null);

create policy "external_links: owner updates"
  on public.external_links for update
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "external_links: owner deletes"
  on public.external_links for delete
  using (owner_id = auth.uid());

create policy "external_links: admins manage all"
  on public.external_links for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));
