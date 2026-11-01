-- 2026-11-01 — Admin: elenco di TUTTI i commenti (anche nascosti), più recenti in alto.
-- Risolve titolo e indirizzo della scheda commentata (spot, pista, evento
-- ufficiale o community, build). Solo admin; sola lettura. Idempotente.
-- ponytail: tetto a p_limit righe (default 300); paginazione quando i commenti
-- saranno migliaia.

create or replace function public.admin_all_comments(p_limit int default 300)
returns jsonb language sql stable security definer set search_path = public as $$
  select case when not public.is_admin() then '[]'::jsonb else coalesce((
    select jsonb_agg(x order by ts desc) from (
      select jsonb_build_object(
        'id', c.id, 'body', c.body, 'entity_type', c.entity_type,
        'created_at', c.created_at, 'is_hidden', c.is_hidden,
        'reported_count', c.reported_count,
        'author', coalesce(p.display_name, 'Utente'),
        'entity_title', coalesce(s.title, t.name, e.title, ce.title, b.title),
        'route', case c.entity_type
          when 'spot' then '/spot/' || s.slug
          when 'track' then '/track/' || t.slug
          when 'event' then '/event/' || c.entity_id
          when 'user_build' then '/build/' || c.entity_id
        end) x, c.created_at ts
      from entity_comments c
      left join profiles p on p.id = c.author_id
      left join spots s on c.entity_type = 'spot' and s.id = c.entity_id
      left join tracks t on c.entity_type = 'track' and t.id = c.entity_id
      left join events e on c.entity_type = 'event' and e.id = c.entity_id
      left join community_events ce on c.entity_type = 'event' and ce.id = c.entity_id
      left join user_builds b on c.entity_type = 'user_build' and b.id = c.entity_id
      order by c.created_at desc
      limit greatest(p_limit, 1)
    ) r), '[]'::jsonb) end;
$$;

revoke execute on function public.admin_all_comments(int) from public, anon;
grant execute on function public.admin_all_comments(int) to authenticated;
