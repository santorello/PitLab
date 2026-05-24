create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create index if not exists shops_submitted_by_idx on public.shops (submitted_by);
create index if not exists community_events_author_id_idx on public.community_events (author_id);
create index if not exists external_links_owner_entity_idx
on public.external_links (owner_id, entity_type, entity_id, sort_order);
