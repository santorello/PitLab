-- Notifiche operative (2026-07-29)
-- Aggiunge notifiche per gli eventi che contano nel loop PitLap, oltre a
-- new_follower/followed_activity gia' esistenti:
--   1. cambio stato pista            -> follower della pista (track_follows)
--   2. commento su una tua entita'   -> proprietario (v1: pista/negozio via submitted_by)
--   3. esito approvazione            -> chi ha inviato la bozza (submitted_by)
--
-- Riusa public.create_notification(kind, entity_type, entity_id, title, body,
-- payload, created_by, recipients[]) gia' definita nel delta 2026-06-10.
-- Tutte le funzioni sono SECURITY DEFINER con EXECUTE revocato (chiamate solo da trigger).

-- Parte A: nuovi valori enum (fuori transazione rispetto all'uso).
alter type public.notification_kind add value if not exists 'track_status_changed';
alter type public.notification_kind add value if not exists 'comment_received';

-- Parte B: funzioni trigger + trigger.

-- 1) Cambio stato pista -> follower (escluso chi aggiorna).
create or replace function public.trg_notify_track_status_changed()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_track_name text;
  v_track_slug text;
  v_recipients uuid[];
begin
  -- Solo se lo stato cambia davvero (INSERT o UPDATE dello status).
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return new;
  end if;

  select name, slug into v_track_name, v_track_slug from public.tracks where id = new.track_id;

  select array_agg(user_id) into v_recipients
  from public.track_follows
  where track_id = new.track_id
    and user_id is distinct from new.updated_by;

  perform public.create_notification(
    'track_status_changed'::public.notification_kind,
    'track'::public.approval_entity_type,
    new.track_id,
    coalesce(v_track_name, 'Pista'),
    'Nuovo stato: ' || new.status::text
      || case when coalesce(new.message, '') <> '' then ' · ' || new.message else '' end,
    jsonb_build_object('status', new.status::text, 'slug', v_track_slug),
    new.updated_by,
    v_recipients
  );
  return new;
end;
$$;
revoke execute on function public.trg_notify_track_status_changed() from public, anon, authenticated;

drop trigger if exists trg_notify_track_status_changed on public.track_status_current;
create trigger trg_notify_track_status_changed
  after insert or update on public.track_status_current
  for each row execute function public.trg_notify_track_status_changed();

-- 2) Commento su una tua entita' -> proprietario (v1: track/shop).
-- ponytail: solo track/shop (submitted_by, colonne certe). spot/user_build/
-- community_event/event: aggiungere quando serve, risolvendo l'owner per tipo.
create or replace function public.trg_notify_comment_received()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_owner uuid;
  v_name text;
  v_slug text;
begin
  if new.entity_type = 'track' then
    select submitted_by, name, slug into v_owner, v_name, v_slug from public.tracks where id = new.entity_id;
  elsif new.entity_type = 'shop' then
    select submitted_by, name, slug into v_owner, v_name, v_slug from public.shops where id = new.entity_id;
  else
    return new; -- tipi non ancora gestiti
  end if;

  -- Niente notifica se non c'e' owner o se commenti sulla tua entita'.
  if v_owner is null or v_owner = new.author_id then
    return new;
  end if;

  perform public.create_notification(
    'comment_received'::public.notification_kind,
    new.entity_type::public.approval_entity_type,
    new.entity_id,
    coalesce(v_name, 'La tua scheda'),
    'Nuovo commento: ' || left(coalesce(new.body, ''), 120),
    jsonb_build_object('comment_id', new.id, 'slug', v_slug),
    new.author_id,
    array[v_owner]
  );
  return new;
end;
$$;
revoke execute on function public.trg_notify_comment_received() from public, anon, authenticated;

drop trigger if exists trg_notify_comment_received on public.entity_comments;
create trigger trg_notify_comment_received
  after insert on public.entity_comments
  for each row execute function public.trg_notify_comment_received();

-- 3) Esito approvazione (approvato/rifiutato) -> chi ha inviato la bozza.
-- Un'unica funzione per tracks e shops, distingue via TG_TABLE_NAME.
create or replace function public.trg_notify_approval_decided()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_kind_entity public.approval_entity_type;
begin
  if new.approval_status not in ('approved','rejected')
     or new.approval_status is not distinct from old.approval_status
     or new.submitted_by is null
     or new.submitted_by is not distinct from new.reviewed_by then
    return new;
  end if;

  v_kind_entity := case tg_table_name when 'shops' then 'shop' else 'track' end::public.approval_entity_type;

  perform public.create_notification(
    'approval_decided'::public.notification_kind,
    v_kind_entity,
    new.id,
    new.name,
    case new.approval_status::text
      when 'approved' then 'La tua richiesta è stata approvata.'
      else 'La tua richiesta non è stata approvata.'
        || case when coalesce(new.review_notes,'') <> '' then ' · ' || new.review_notes else '' end
    end,
    jsonb_build_object('approval_status', new.approval_status::text, 'slug', new.slug),
    new.reviewed_by,
    array[new.submitted_by]
  );
  return new;
end;
$$;
revoke execute on function public.trg_notify_approval_decided() from public, anon, authenticated;

drop trigger if exists trg_notify_approval_decided on public.tracks;
create trigger trg_notify_approval_decided
  after update of approval_status on public.tracks
  for each row execute function public.trg_notify_approval_decided();

drop trigger if exists trg_notify_approval_decided on public.shops;
create trigger trg_notify_approval_decided
  after update of approval_status on public.shops
  for each row execute function public.trg_notify_approval_decided();
