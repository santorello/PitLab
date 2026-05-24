-- Delta: 2026-04-21 - Tabella spots
-- Spot: luoghi informali (bashing, scaler, droni) non legati a piste ufficiali.
-- is_custom=false → spot del catalogo ufficiale
-- is_custom=true  → spot aggiunto da utente (owner_id != null)

create table public.spots (
  id          uuid        primary key default gen_random_uuid(),
  slug        text        not null unique,
  title       text        not null,
  city        text        not null,
  category    text        not null default '',
  best_for    text        not null default '',
  surface     text        not null default '',
  note        text        not null default '',
  image_accent int        not null default 0xFFD97706,
  photo_count int         not null default 0,
  address     text,
  latitude    double precision,
  longitude   double precision,
  image_urls  text[]      not null default '{}',
  video_url   text,
  is_custom   boolean     not null default false,
  owner_id    uuid        references public.profiles(id) on delete set null,
  created_at  timestamptz not null default timezone('utc', now()),
  updated_at  timestamptz not null default timezone('utc', now())
);

create index spots_city_idx     on public.spots (city);
create index spots_category_idx on public.spots (category);
create index spots_custom_idx   on public.spots (owner_id) where is_custom = true;

create trigger spots_updated_at
  before update on public.spots
  for each row execute function public.set_updated_at();

alter table public.spots enable row level security;

create policy "spots: public reads all"   on public.spots for select using (true);
create policy "spots: owner inserts custom" on public.spots for insert
  with check (is_custom = true and owner_id = auth.uid() and auth.uid() is not null);
create policy "spots: owner updates custom" on public.spots for update
  using (is_custom = true and owner_id = auth.uid())
  with check (is_custom = true and owner_id = auth.uid());
create policy "spots: owner deletes custom" on public.spots for delete
  using (is_custom = true and owner_id = auth.uid());
create policy "spots: admins manage all" on public.spots for all
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- Seed default spots
insert into public.spots (slug, title, city, category, best_for, surface, note, image_accent, photo_count, latitude, longitude, is_custom)
values
  ('argine-del-taro', 'Argine del Taro', 'Parma', 'Bashing', 'Buggy 1/8, monster, short course', 'Terra battuta e sterrato aperto', 'Spazio largo, fondo variabile e buon margine per sessioni libere in compagnia.', -2571610, 3, 44.8015, 10.2402, false),
  ('cava-roveri-trail', 'Cava Roveri Trail', 'Modena', 'Scaler', 'Scaler, crawler, trail truck', 'Roccia leggera, ghiaia e salite tecniche', 'Spot adatto a uscite lente e tecniche, con punti fotogenici.', -14148093, 3, 44.6459, 10.9252, false),
  ('campo-volo-nord', 'Campo Volo Nord', 'Reggio Emilia', 'Droni', 'Freestyle, cinewhoop, micro FPV', 'Area aperta con prato e visuale ampia', 'Buona visibilità e spazio per voli tranquilli.', -16154521, 3, 44.7212, 10.6314, false)
on conflict (slug) do nothing;
