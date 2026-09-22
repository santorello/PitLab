-- Limiti di frequenza lato database (task 18, ondata 0).
-- Un trigger generico BEFORE INSERT conta le righe recenti dello stesso utente
-- e blocca oltre la soglia. Vale qualunque client usi l'utente.
--
-- Argomenti del trigger: (colonna_utente, max_righe, finestra)
--   colonna_utente = '*'  -> limite globale sulla tabella (per feedback, che
--                            arriva dalla Edge Function con service role).
-- Esenti: admin, e inserimenti senza utente autenticato (SQL da dashboard/MCP,
-- censimento, trigger di sistema), tranne che per i limiti globali.
-- Errore: SQLSTATE P0001, messaggio leggibile, HINT 'rate_limited'.
-- Idempotente.

create or replace function public.enforce_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_col      text     := tg_argv[0];
  v_max      integer  := tg_argv[1]::integer;
  v_window   interval := tg_argv[2]::interval;
  v_uid      uuid     := auth.uid();
  v_user     text;
  v_count    integer;
begin
  if v_col = '*' then
    execute format(
      'select count(*) from %I.%I where created_at > now() - $1',
      tg_table_schema, tg_table_name)
      into v_count using v_window;
  else
    if v_uid is null or public.is_admin() then
      return new;
    end if;
    v_user := to_jsonb(new) ->> v_col;
    if v_user is null then
      return new;
    end if;
    execute format(
      'select count(*) from %I.%I where %I = $1::uuid and created_at > now() - $2',
      tg_table_schema, tg_table_name, v_col)
      into v_count using v_user, v_window;
  end if;

  if v_count >= v_max then
    raise exception 'Troppe azioni in poco tempo: riprova tra qualche minuto.'
      using errcode = 'P0001', hint = 'rate_limited',
            detail = format('%s: max %s in %s', tg_table_name, v_max, v_window);
  end if;
  return new;
end;
$$;

revoke execute on function public.enforce_rate_limit() from public, anon, authenticated;

-- Commenti: raffica e volume giornaliero
drop trigger if exists trg_rate_comments_burst on public.entity_comments;
create trigger trg_rate_comments_burst before insert on public.entity_comments
  for each row execute function public.enforce_rate_limit('author_id', '5', '1 minute');
drop trigger if exists trg_rate_comments_day on public.entity_comments;
create trigger trg_rate_comments_day before insert on public.entity_comments
  for each row execute function public.enforce_rate_limit('author_id', '100', '1 day');

-- Like alle build
drop trigger if exists trg_rate_build_votes on public.user_build_votes;
create trigger trg_rate_build_votes before insert on public.user_build_votes
  for each row execute function public.enforce_rate_limit('user_id', '60', '10 minutes');

-- Segui profilo
drop trigger if exists trg_rate_profile_follows on public.profile_follows;
create trigger trg_rate_profile_follows before insert on public.profile_follows
  for each row execute function public.enforce_rate_limit('follower_id', '60', '1 hour');

-- Segnalazioni commenti
drop trigger if exists trg_rate_comment_reports on public.entity_comment_reports;
create trigger trg_rate_comment_reports before insert on public.entity_comment_reports
  for each row execute function public.enforce_rate_limit('reporter_id', '20', '1 day');

-- Nuovi contenuti: eventi, spot, piste, negozi
drop trigger if exists trg_rate_community_events on public.community_events;
create trigger trg_rate_community_events before insert on public.community_events
  for each row execute function public.enforce_rate_limit('author_id', '10', '1 day');
drop trigger if exists trg_rate_spots on public.spots;
create trigger trg_rate_spots before insert on public.spots
  for each row execute function public.enforce_rate_limit('owner_id', '10', '1 day');
drop trigger if exists trg_rate_tracks on public.tracks;
create trigger trg_rate_tracks before insert on public.tracks
  for each row execute function public.enforce_rate_limit('submitted_by', '5', '1 day');
drop trigger if exists trg_rate_shops on public.shops;
create trigger trg_rate_shops before insert on public.shops
  for each row execute function public.enforce_rate_limit('submitted_by', '5', '1 day');

-- Feedback (anche anonimo): tetto globale contro le raffiche di spam
drop trigger if exists trg_rate_feedback on public.feedback;
create trigger trg_rate_feedback before insert on public.feedback
  for each row execute function public.enforce_rate_limit('*', '30', '1 hour');
