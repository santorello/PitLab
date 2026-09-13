-- ============================================================================
-- CATCH-UP PROD — PARTE A di 2  (2026-09-12)
--
-- ESEGUIRE QUESTO FILE DA SOLO, PER PRIMO.
-- Contiene solo ALTER TYPE ... ADD VALUE, che non possono stare nella stessa
-- transazione in cui i nuovi valori vengono usati. Per questo sono isolati.
--
-- Estratto da: 2026-06-10-profile-follows-notifications.sql (Parte A)
-- Dopo questo file, eseguire 2026-09-12-catchup-B-resto.sql
-- ============================================================================

alter type public.notification_kind add value if not exists 'new_follower';
alter type public.notification_kind add value if not exists 'followed_activity';
alter type public.approval_entity_type add value if not exists 'profile';
alter type public.approval_entity_type add value if not exists 'user_build';
alter type public.approval_entity_type add value if not exists 'community_event';

-- Estratto da: 2026-07-29-operational-notifications.sql (Parte A)
alter type public.notification_kind add value if not exists 'track_status_changed';
alter type public.notification_kind add value if not exists 'comment_received';
