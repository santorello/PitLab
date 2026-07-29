-- Advisor cleanup (2026-07-29)
-- Chiude i lint performance introdotti/rimasti dalle feature 0.3.0.

-- 1) Foreign key non indicizzate (advisor: unindexed_foreign_keys)
create index if not exists entity_comment_reports_reporter_id_idx
  on public.entity_comment_reports (reporter_id);
create index if not exists entity_comments_hidden_by_idx
  on public.entity_comments (hidden_by);

-- 2) Multiple permissive policies su track_follows / shop_follows
-- Prima: 3 policy sovrapposte (manage own ALL + read own SELECT + admins read SELECT)
-- → il SELECT veniva valutato da 2-3 policy per riga. Consolido in UNA policy per
-- tabella: owner gestisce le proprie, admin legge/elimina; nessuno puo' forgiare
-- follow altrui (with check ancorato a auth.uid()). Semantica invariata salvo che
-- l'admin ora puo' anche rimuovere un follow (prima solo lettura) — accettabile.
drop policy if exists "users can manage own track follows" on public.track_follows;
drop policy if exists "users can read own track follows" on public.track_follows;
drop policy if exists "admins can read all track follows" on public.track_follows;
create policy "track_follows owner and admin" on public.track_follows
  for all
  using (user_id = (select auth.uid()) or is_admin())
  with check (user_id = (select auth.uid()));

drop policy if exists "users can manage own shop follows" on public.shop_follows;
drop policy if exists "users can read own shop follows" on public.shop_follows;
drop policy if exists "admins can read all shop follows" on public.shop_follows;
create policy "shop_follows owner and admin" on public.shop_follows
  for all
  using (user_id = (select auth.uid()) or is_admin())
  with check (user_id = (select auth.uid()));
