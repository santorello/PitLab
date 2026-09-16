-- 2026-09-16 — Card "build della settimana": la vista restituiva sempre autore NULL.
-- Nome sempre (build pubblica = firmata), slug solo se il profilo è pubblico.
-- security_invoker: gli ospiti vedono il nome solo dei profili pubblici (RLS anon). Idempotente.
create or replace view public.home_build_of_week with (security_invoker = on) as
select b.id, b.owner_id, b.title, b.meta, b.image_urls,
       p.display_name as author_display_name,
       case when p.is_public then p.public_slug end as author_public_slug,
       coalesce(w.weekly_votes, 0) as weekly_votes,
       0 as comment_count,
       coalesce(w.awarded_points, 0) as awarded_points,
       w.week_start, w.selected_at
from public.weekly_featured_builds w
join public.user_builds b on b.id = w.build_id
left join public.profiles p on p.id = b.owner_id
where b.is_public = true
order by w.week_start desc, w.selected_at desc
limit 1;

-- Verifica: autore valorizzato
select title, author_display_name, author_public_slug from public.home_build_of_week;
