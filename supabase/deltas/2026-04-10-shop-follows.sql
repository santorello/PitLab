create table if not exists public.shop_follows (
  shop_id uuid not null references public.shops (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (shop_id, user_id)
);

create index if not exists shop_follows_user_id_idx
  on public.shop_follows (user_id);

alter table public.shop_follows enable row level security;

drop policy if exists "users can read own shop follows" on public.shop_follows;
create policy "users can read own shop follows"
on public.shop_follows
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "users can manage own shop follows" on public.shop_follows;
create policy "users can manage own shop follows"
on public.shop_follows
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
