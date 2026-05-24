create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  short_description text,
  description text,
  address text,
  city text not null,
  country text not null default 'Italy',
  latitude double precision,
  longitude double precision,
  external_map_url text,
  website_url text,
  phone text,
  is_public boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.shop_managers (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  granted_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (shop_id, user_id)
);

create or replace function public.is_shop_manager(target_shop_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.shop_managers
    where shop_id = target_shop_id
      and user_id = auth.uid()
  );
$$;

create index if not exists shops_is_public_idx on public.shops (is_public);
create index if not exists shop_managers_shop_id_idx on public.shop_managers (shop_id);
create index if not exists shop_managers_user_id_idx on public.shop_managers (user_id);

drop trigger if exists shops_set_updated_at on public.shops;
create trigger shops_set_updated_at
before update on public.shops
for each row execute function public.set_updated_at();

alter table public.shops enable row level security;
alter table public.shop_managers enable row level security;

drop policy if exists "public can read public shops" on public.shops;
create policy "public can read public shops"
on public.shops
for select
to anon, authenticated
using (is_public = true);

drop policy if exists "shop managers can manage shops" on public.shops;
create policy "shop managers can manage shops"
on public.shops
for all
to authenticated
using (public.is_shop_manager(id) or public.is_admin())
with check (public.is_shop_manager(id) or public.is_admin());

drop policy if exists "admins can manage shop managers" on public.shop_managers;
create policy "admins can manage shop managers"
on public.shop_managers
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "shop managers are visible to authenticated users" on public.shop_managers;
create policy "shop managers are visible to authenticated users"
on public.shop_managers
for select
to authenticated
using (public.is_admin() or public.is_shop_manager(shop_id));

-- Esempio rapido di assegnazione ownership:
-- insert into public.shop_managers (shop_id, user_id, granted_by)
-- values ('<shop-id>', '<user-id>', auth.uid())
-- on conflict (shop_id, user_id) do nothing;
