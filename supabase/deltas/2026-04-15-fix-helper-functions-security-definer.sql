-- Le funzioni helper usate nelle policy RLS devono essere SECURITY DEFINER
-- per evitare ricorsione infinita quando leggono le stesse tabelle protette.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.is_track_manager(target_track_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.track_managers
    where track_id = target_track_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.is_shop_manager(target_shop_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.shop_managers
    where shop_id = target_shop_id
      and user_id = auth.uid()
  );
$$;
