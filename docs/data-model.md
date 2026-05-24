# Modello Dati

## Obiettivo

Definire un primo modello dati stabile abbastanza per partire con il backend, senza irrigidire troppo il progetto.

## Entita' principali

### User

Campi iniziali proposti:

- `id`
- `display_name`
- `email`
- `avatar_url`
- `preferred_language`
- `created_at`
- `role`

Note:

- `role` puo' essere `user`, `shop_owner`, `track_organizer`, `admin` (allineato a `supabase/schema.sql`; il ruolo `manager` generico citato in versioni precedenti e' stato sostituito dai due ruoli specifici e dall'ownership reale via tabelle `shop_managers` / `track_managers`)
- `preferred_language` iniziale puo' essere `it` oppure `en`

### Track

Campi iniziali proposti:

- `id`
- `name`
- `slug`
- `description`
- `category_tags`
- `address`
- `city`
- `country`
- `is_public`
- `created_at`
- `updated_at`

### TrackStatus

Campi iniziali proposti:

- `id`
- `track_id`
- `status`
- `message`
- `updated_by`
- `updated_at`

Valori iniziali suggeriti per `status`:

- `open`
- `wet`
- `closed`

### TrackService

Campi iniziali proposti:

- `id`
- `track_id`
- `service_key`
- `is_available`
- `notes`

Servizi iniziali suggeriti:

- `power_220v`
- `compressed_air`
- `tables`
- `chairs`
- `toilets`
- `food`

### Arrival

Campi iniziali proposti:

- `id`
- `track_id`
- `user_id`
- `arrival_date`
- `status`
- `note`
- `created_at`

Valori iniziali suggeriti per `status`:

- `coming`
- `maybe`
- `cancelled`

### Event

Campi iniziali proposti:

- `id`
- `track_id`
- `title`
- `description`
- `start_at`
- `end_at`
- `registration_enabled`
- `created_by`
- `created_at`

### EventRegistration

Campi iniziali proposti:

- `id`
- `event_id`
- `user_id`
- `status`
- `created_at`

Valori iniziali suggeriti per `status`:

- `registered`
- `waiting_list`
- `cancelled`

### MediaAsset

Campi iniziali proposti:

- `id`
- `owner_user_id`
- `entity_type`
- `entity_id`
- `bucket`
- `storage_path`
- `public_url`
- `thumb_url`
- `mime_type`
- `size_bytes`
- `width`
- `height`
- `sort_order`
- `visibility`
- `moderation_status`
- `created_at`
- `updated_at`
- `deleted_at`

Valori iniziali suggeriti per `entity_type`:

- `profile`
- `garage_build`
- `shop`
- `track`
- `event`

Valori iniziali suggeriti per `visibility`:

- `private`
- `public`

Valori iniziali suggeriti per `moderation_status`:

- `approved`
- `pending`
- `rejected`
- `removed`

Limiti prodotto iniziali:

- `shop`: massimo 10 immagini galleria + 1 cover
- `track`: massimo 10 immagini galleria + 1 cover
- `garage_build`: massimo 5 immagini
- `event`: massimo 5 immagini + 1 cover

### ExternalLink

Campi iniziali proposti:

- `id`
- `owner_user_id`
- `entity_type`
- `entity_id`
- `provider`
- `label`
- `url`
- `is_public`
- `sort_order`
- `created_at`
- `updated_at`

Valori iniziali suggeriti per `provider`:

- `website`
- `instagram`
- `facebook`
- `youtube`
- `tiktok`
- `whatsapp`
- `telegram`

### TrackManager

Campi iniziali proposti:

- `id`
- `track_id`
- `user_id`
- `granted_by`
- `created_at`

### TrackFollow

Campi proposti per una fase successiva:

- `id`
- `track_id`
- `user_id`
- `is_favorite`
- `notifications_enabled`
- `created_at`
- `updated_at`

Scopo:

- distinguere l'interesse persistente verso una pista dalla presenza giornaliera
- abilitare in futuro preferiti, notifiche e personalizzazione discovery

### UserConsent

Campi iniziali proposti:

- `user_id`
- `consent_type`
- `accepted`
- `document_version`
- `source`
- `created_at`
- `updated_at`

Valori iniziali suggeriti per `consent_type`:

- `terms_accepted`
- `privacy_notice_seen`
- `marketing_email_opt_in`

Scopo:

- tracciare separatamente accettazione termini, presa visione privacy e consenso marketing
- mantenere distinta la parte necessaria al servizio da quella opzionale
- preparare versionamento dei documenti legali nel tempo

### UserBuild

Tabella `user_builds`. Garage personale dell'utente: modelli RC costruiti o in costruzione.

Campi:

- `id` (UUID)
- `owner_id` → `profiles.id`
- `title`
- `meta` (testo libero: marca, scala, ecc.)
- `specs` (testo libero: motore, ESC, ecc.)
- `image_urls` (array di URL http/https — le data-URL picker locali non vengono persistite)
- `is_public` (boolean — default false; visibilità controllata da RLS)
- `created_at`, `updated_at`

RLS: il proprietario può leggere/scrivere/cancellare i propri build. I build pubblici sono leggibili da chiunque.

### Track (flusso submission organizzatore)

Colonne aggiuntive su `tracks` per il flusso invio da organizzatore (delta aprile 2026):

- `image_url` — URL cover fornita dall'organizzatore
- `contact_email`
- `phone`
- `organization_name`
- `submitted_by` → `profiles.id`
- `approval_status` — enum: `draft | pending | approved | rejected | archived`
- `is_public` — false per tutte le submission in attesa

Flusso: l'organizzatore invia tramite `track_editor_screen` o `submit_place_screen` → INSERT con `approval_status = 'draft' | 'pending'` → admin vede la coda in `admin_settings_screen` → UPDATE con `approval_status = 'approved'` + `is_public = true`.

## Relazioni principali

- un `User` puo' avere molte `Arrival`
- una `Track` ha un solo stato corrente, ma molti aggiornamenti storici se vorremo estenderlo
- una `Track` ha molti `TrackService`
- una `Track` ha molti `Event`
- un `Event` ha molte `EventRegistration`
- una `Track` puo' avere uno o piu' `TrackManager`
- una `Track` puo' avere molti `TrackFollow`
- un `User` puo' avere molti `UserConsent`
- un `User`, una `Track`, uno `Shop`, un `Event` o una `GarageBuild` possono avere molti `MediaAsset`
- un profilo utente, una pista o un negozio possono avere molti `ExternalLink`

## Note di progettazione

- per l'MVP conviene tenere un modello semplice e leggibile
- lo storico degli stati pista puo' essere aggiunto dopo, senza complicare subito la scrittura
- i tag categoria possono partire come lista semplice o tabella dedicata in una fase successiva
- conviene usare `slug` per URL web leggibili
- la preferenza lingua utente puo' essere salvata nel profilo e usata come fallback rispetto alla lingua del device/browser
- conviene tenere `Arrival` e `TrackFollow` separati: il primo e' operativo/giornaliero, il secondo relazionale/persistente
- conviene tenere `UserConsent` separato dal profilo per avere tracciamento chiaro, versioni documento e futura revoca dei consensi opzionali
- conviene tenere `MediaAsset` separato dalle entita' principali per gestire storage, thumbnail, moderazione e pulizia immagini orfane
- conviene tenere `ExternalLink` separato per validare provider, ordinamento e visibilita' senza moltiplicare campi social sulle singole tabelle

## Domande aperte

- una pista puo' appartenere a piu' categorie contemporaneamente?
- la funzione "Sto arrivando" vale per una data specifica o come stato quasi real-time della giornata?
- gli eventi richiedono davvero registrazione nel primo rilascio o solo visualizzazione?
- `Preferiti` implica automaticamente notifiche o resta separato da `notifications_enabled`?
