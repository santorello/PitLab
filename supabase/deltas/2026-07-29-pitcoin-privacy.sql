-- Privacy PitCoin (2026-07-29)
-- Regola di prodotto: i PitCoin di un utente NON sono visibili agli altri.
--
-- La view public.public_user_pitcoin esponeva total_points/lifetime_earned di
-- TUTTI i profili pubblici ad anon/authenticated (le view girano coi privilegi
-- del creatore e bypassano la RLS di user_pitcoin_balances). La ricreo così i
-- valori PitCoin tornano solo al proprietario (auth.uid()), 0 per gli altri.
-- La tabella base user_pitcoin_balances resta protetta da RLS (owner+admin).
--
-- Nota: pitcoin_public_leaderboard espone ancora nome+punti altrui by design;
-- decisione di prodotto separata (rimuovere / anonimizzare) prima del go-live.

create or replace view public.public_user_pitcoin as
select
  p.id as user_id,
  p.public_slug,
  p.display_name,
  p.avatar_url,
  case when p.id = (select auth.uid())
       then coalesce(b.total_points, 0) else 0 end as total_points,
  case when p.id = (select auth.uid())
       then coalesce(b.lifetime_earned, 0) else 0 end as lifetime_earned,
  case when p.id = (select auth.uid())
       then b.last_action_at else null end as last_action_at
from public.profiles p
left join public.user_pitcoin_balances b on b.user_id = p.id
where p.is_public = true and p.public_slug is not null;
