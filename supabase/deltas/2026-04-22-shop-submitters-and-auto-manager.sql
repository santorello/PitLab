create or replace function public.auto_link_shop_manager_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.submitted_by is not null then
    insert into public.shop_managers (shop_id, user_id, granted_by)
    values (new.id, new.submitted_by, new.submitted_by)
    on conflict (shop_id, user_id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists shops_auto_link_manager_on_insert on public.shops;

create trigger shops_auto_link_manager_on_insert
after insert on public.shops
for each row
execute function public.auto_link_shop_manager_on_insert();

insert into public.shop_managers (shop_id, user_id, granted_by)
select shops.id, shops.submitted_by, shops.submitted_by
from public.shops
where shops.submitted_by is not null
on conflict (shop_id, user_id) do nothing;

drop policy if exists "shop submitters can insert own shops" on public.shops;
create policy "shop submitters can insert own shops"
on public.shops
for insert
to authenticated
with check (
  auth.uid() = submitted_by
  and is_public = false
  and approval_status in ('draft', 'pending')
);
