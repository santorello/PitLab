-- Delta: 2026-04-21 - Profilo pubblico: public_slug e is_public
-- is_public=false (default): profilo visibile solo al proprietario
-- is_public=true:  profilo visibile anche ai guest via /u/:public_slug

alter table public.profiles
  add column if not exists public_slug text unique,
  add column if not exists is_public boolean not null default false;

create index if not exists profiles_public_slug_idx
  on public.profiles (public_slug)
  where public_slug is not null;

create policy "profiles: guest reads public"
  on public.profiles for select
  using (is_public = true);

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles'
      and policyname = 'profiles: owner reads own'
  ) then
    execute $policy$
      create policy "profiles: owner reads own"
        on public.profiles for select using (id = auth.uid())
    $policy$;
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles'
      and policyname = 'profiles: owner updates own'
  ) then
    execute $policy$
      create policy "profiles: owner updates own"
        on public.profiles for update
        using (id = auth.uid()) with check (id = auth.uid())
    $policy$;
  end if;
end
$$;
