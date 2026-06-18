revoke update on table public.keepalive from anon;
grant update (checked_at) on table public.keepalive to anon;

drop policy if exists "Allow anonymous keepalive update" on public.keepalive;

create policy "Allow anonymous keepalive update"
on public.keepalive
for update
to anon
using (id = true)
with check (id = true);
