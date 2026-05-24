# PitCoin & Badge System — Specifica

> Stato: bozza per approvazione, 2026-05-23
> Versione progetto: 0.1.20 (pre-alpha)
> Riferimento roadmap: `docs/roadmap.md` sezione "Idea futura — Sistema crediti, medaglie e bonus per attivita'"

---

## 1. Premessa

PitCoin nasce come sistema di **reputation/activity score** integrato in PitLap. Non e' una moneta spendibile nella prima iterazione: e' una metrica che identifica quanto un utente e' attivo e utile alla community. Eventuali premi materiali (sconti negozi partner, badge cosmetici premium, accessi anticipati) restano un'opzione futura non MVP.

Il sistema e' composto da due livelli complementari:

- **PitCoin** — punteggio continuo, somma cumulativa di tutti i micro-contributi
- **Badge** — milestone discrete sbloccate al raggiungimento di soglie significative

I due livelli si rinforzano: PitCoin senza badge resta un numero astratto; badge senza PitCoin perdono il sottostante quantitativo.

## 2. Principi guida

1. **Zero modifiche alle logiche esistenti** — l'implementazione passa esclusivamente da trigger Postgres su tabelle gia' presenti. Il codice Flutter/Riverpod non deve essere toccato per generare punti; legge solo il balance e lo storico.
2. **Single source of truth** — il ledger `pitcoin_transactions` e' append-only e idempotente. Tutte le altre tabelle derivano da li'.
3. **Configurabilita' admin** — valori, cap, cooldown e criteri vivono in tabelle, non in codice. L'economia si calibra senza migrazioni.
4. **Privacy by default** — il balance puo' essere pubblico sul profilo opt-in, ma lo storico transazioni resta privato all'owner. I badge sono pubblici come "trofei".
5. **Anti-gaming** — cap giornalieri, cooldown, dedup su entita'. Gli admin non accumulano per non viziare le metriche.
6. **Backfill al deploy** — le azioni gia' compiute nella pre-alpha vengono riconosciute retroattivamente.

## 3. Architettura dati

Quattro nuove tabelle nello schema `public`.

### 3.1 `pitcoin_action_definitions`

Catalogo delle azioni che generano PitCoin. Modificabile da admin tramite il pannello.

```sql
create table public.pitcoin_action_definitions (
  action_key            text primary key,
  name_it               text not null,
  name_en               text not null,
  description_it        text,
  description_en        text,
  category              text not null,  -- identity | garage | catalog | operations | events | engagement
  base_points           int  not null,
  daily_cap             int,             -- max accreditamenti/giorno per stessa action_key
  per_entity_cap        int,             -- max accreditamenti per entita' (source_id)
  lifetime_cap          int,             -- max accreditamenti totali nella vita utente
  cooldown_seconds      int,             -- secondi minimi tra due accreditamenti consecutivi
  requires_approval     boolean default false,
  enabled               boolean default true,
  created_at            timestamptz default now(),
  updated_at            timestamptz default now()
);
```

### 3.2 `pitcoin_transactions`

Ledger append-only. Ogni accreditamento e' una riga; eventuali revoche future si scrivono come delta negativi.

```sql
create table public.pitcoin_transactions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  action_key    text not null references public.pitcoin_action_definitions(action_key),
  points        int  not null,
  source_table  text,
  source_id     uuid,
  metadata      jsonb not null default '{}'::jsonb,
  awarded_at    timestamptz not null default now(),
  unique (user_id, action_key, source_table, source_id)
);

create index pitcoin_transactions_user_idx
  on public.pitcoin_transactions(user_id, awarded_at desc);

create index pitcoin_transactions_action_idx
  on public.pitcoin_transactions(action_key, awarded_at desc);
```

La **unique constraint** `(user_id, action_key, source_table, source_id)` e' il cuore dell'idempotenza: un trigger ripetuto, una replica replicata, un retry idempotente non possono creare doppi accrediti.

### 3.3 `user_pitcoin_balances`

Rollup mantenuto da trigger sul ledger. Letto dal client per il badge profilo.

```sql
create table public.user_pitcoin_balances (
  user_id           uuid primary key references public.profiles(id) on delete cascade,
  total_points      int not null default 0,
  lifetime_earned   int not null default 0,    -- somma delle sole transazioni positive
  last_action_at    timestamptz,
  updated_at        timestamptz default now()
);
```

### 3.4 `pitcoin_badge_definitions`

Catalogo badge. Criteri espressi in jsonb per estensibilita' senza migrazioni.

```sql
create table public.pitcoin_badge_definitions (
  badge_key       text primary key,
  name_it         text not null,
  name_en         text not null,
  description_it  text,
  description_en  text,
  icon_asset      text,
  category        text not null,        -- identity | catalog | operations | engagement | events | milestone
  tier            text not null check (tier in ('bronze','silver','gold','special')),
  criteria        jsonb not null,        -- es. { "type": "action_count", "action_key": "spot_approved", "threshold": 5 }
  enabled         boolean default true,
  sort_order      int default 0,
  created_at      timestamptz default now()
);
```

### 3.5 `user_badges`

Badge ottenute dall'utente.

```sql
create table public.user_badges (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  badge_key   text not null references public.pitcoin_badge_definitions(badge_key),
  awarded_at  timestamptz not null default now(),
  metadata    jsonb not null default '{}'::jsonb,
  unique (user_id, badge_key)
);

create index user_badges_user_idx on public.user_badges(user_id, awarded_at desc);
```

## 4. Catalogo PitCoin — valori proposti

Valori indicativi di partenza. Tutti calibrabili senza migrazione tramite `pitcoin_action_definitions`.

### 4.1 Identita' e profilo (one-shot)

| action_key | Descrizione | base_points | lifetime_cap | Note |
| --- | --- | --- | --- | --- |
| `profile_completed` | Avatar + slug pubblico + lingua + consensi base | 50 | 1 | Trigger su transizione "profilo non completo" → "completo" |
| `profile_made_public` | Profilo opt-in pubblico (`profiles.public_slug` valorizzato + visibility public) | 20 | 1 | One-shot |
| `external_link_added` | Aggiunta link social/web a profilo o entita' propria | 5 | 10 | Cap 3/entita', anti-spam |

### 4.2 Garage (mix one-shot/ricorrenti)

| action_key | Descrizione | base_points | Cap | Note |
| --- | --- | --- | --- | --- |
| `build_created` | INSERT su `user_builds` | 30 | per_entity_cap 1 | Una sola volta per build |
| `build_published` | UPDATE `user_builds.is_public` da false a true | 50 | per_entity_cap 1 | Azione richiesta esplicitamente: la pubblicazione e' un atto di contributo alla community, distinto dalla creazione privata |
| `build_photo_added` | Foto aggiunta a build | 5 | daily_cap 5 | Anti-spam su flooding foto |

### 4.3 Contributi al catalogo (pattern submission/approvazione)

Il pattern e' a due fasi: la submission scrive una transazione segnaposto con `points=0` per garantire idempotenza; al momento dell'approvazione admin scatta il payout reale.

| action_key | Descrizione | base_points | Note |
| --- | --- | --- | --- |
| `spot_submitted` | Nuovo spot creato (`spots`) | 0 | Placeholder idempotente |
| `spot_approved` | Spot ha ricevuto approvazione admin | 30 | Payout reale |
| `track_submitted` | Submission pista (`tracks` con `approval_status` in [`draft`,`pending`]) | 0 | Placeholder |
| `track_approved` | Pista approvata (`approval_status = approved`) | 100 | Contributo "premium" al catalogo |
| `shop_submitted` | Submission negozio | 0 | Placeholder |
| `shop_approved` | Negozio approvato | 80 | Contributo "premium" |

### 4.4 Gestione operativa (track_manager / shop_owner, ricorrenti con cooldown)

| action_key | Descrizione | base_points | Cap | Cooldown |
| --- | --- | --- | --- | --- |
| `track_status_updated` | Update `track_status_current` | 5 | daily_cap 1 per pista | 4h |
| `track_services_updated` | Update `track_services` | 10 | daily_cap 1 per pista | 4h |
| `track_media_added` | Foto aggiunta a `track_media` | 5 | daily_cap 5 | nessuno |
| `shop_info_updated` | Update info shop | 5 | daily_cap 1 per shop | 6h |
| `shop_media_added` | Foto aggiunta a shop | 5 | daily_cap 5 | nessuno |

Il cooldown evita che il gestore guadagni punti switchando lo stato pista avanti e indietro per gaming.

### 4.5 Eventi

| action_key | Descrizione | base_points | Note |
| --- | --- | --- | --- |
| `community_event_created` | INSERT su `community_events` | 25 | per_entity_cap 1 |
| `official_event_created` | INSERT su `events` da parte di track_manager | 40 | per_entity_cap 1 |
| `event_rsvp_received` | Un utente fa RSVP confermato a evento proprio | 3 | daily_cap 10 |

### 4.6 Engagement in pista

| action_key | Descrizione | base_points | Cap | Note |
| --- | --- | --- | --- | --- |
| `arrival_checkin` | Check-in "Sto arrivando" | 3 | daily_cap 3, per_entity_cap 1/giorno | 1 sola transazione/giorno/pista, max 3 piste diverse/giorno |
| `track_followed` | Primo follow di una pista | 2 | per_entity_cap 1, lifetime_cap 50 | One-shot per pista |
| `shop_followed` | Primo follow di un negozio | 2 | per_entity_cap 1, lifetime_cap 50 | One-shot per shop |
| `event_rsvp_sent` | Utente fa RSVP a un evento | 2 | daily_cap 5 | |

### 4.7 Moderazione (futuro, post AI moderation)

| action_key | Descrizione | base_points | Note |
| --- | --- | --- | --- |
| `moderation_report_helpful` | Segnalazione confermata utile da admin | 15 | Da abilitare quando partira' il sistema hide-pending |

### 4.8 Esempio di accumulo realistico

Un utente alpha tipo, prima settimana attiva:

- profilo completato + reso pubblico → 70
- prima build creata, resa pubblica, con 3 foto → 30 + 50 + 15 = 95
- 1 spot creato e approvato → 30
- 4 check-in (2 weekend, 2 piste diverse) → 12
- 2 piste seguite, 1 negozio seguito → 6

Totale settimana 1 ≈ **213 PitCoin**. Numeri leggibili, non inflazionati.

## 5. Catalogo Badge — proposta iniziale

Tier: bronze / silver / gold (progressione classica) o special (one-shot, non ripetibile, tipicamente milestone storiche).

### 5.1 Identita'

| badge_key | Nome IT | Tier | Criterio |
| --- | --- | --- | --- |
| `identity_profile_complete` | Profilo Completo | special | `profile_completed >= 1` |
| `garage_open` | Officina Aperta | bronze | `build_created >= 1` |
| `garage_showcase` | Vetrina | bronze | `build_published >= 1` |
| `garage_showroom` | Showroom | silver | `build_published >= 5` |
| `garage_master` | Maestro Costruttore | gold | `build_published >= 15` |

### 5.2 Contributo catalogo

| badge_key | Nome IT | Tier | Criterio |
| --- | --- | --- | --- |
| `explorer_bronze` | Esploratore | bronze | `spot_approved >= 1` |
| `explorer_silver` | Cartografo | silver | `spot_approved >= 5` |
| `explorer_gold` | Geografo | gold | `spot_approved >= 20` |
| `track_pioneer_bronze` | Pioniere Pista | bronze | `track_approved >= 1` |
| `track_pioneer_silver` | Costruttore di Mappe | silver | `track_approved >= 3` |
| `track_pioneer_gold` | Architetto di Reti | gold | `track_approved >= 10` |
| `shop_mapper_bronze` | Segnalibri di Negozi | bronze | `shop_approved >= 1` |
| `shop_mapper_silver` | Censore di Negozi | silver | `shop_approved >= 3` |
| `shop_mapper_gold` | Curatore Mercati | gold | `shop_approved >= 10` |

### 5.3 Gestione

| badge_key | Nome IT | Tier | Criterio |
| --- | --- | --- | --- |
| `track_guardian_bronze` | Custode di Pista | bronze | 7 giorni distinti di `track_status_updated` |
| `track_guardian_silver` | Padrone di Casa | silver | 30 giorni distinti |
| `track_guardian_gold` | Tutore di Pista | gold | 90 giorni distinti |

### 5.4 Engagement

| badge_key | Nome IT | Tier | Criterio |
| --- | --- | --- | --- |
| `local_pilot_bronze` | Pilota Locale | bronze | `arrival_checkin >= 10` |
| `local_pilot_silver` | Pilota Regolare | silver | `arrival_checkin >= 50` |
| `local_pilot_gold` | Pilota Veterano | gold | `arrival_checkin >= 200` |
| `weekend_warrior` | Weekend Warrior | special | 3 check-in nello stesso weekend stessa pista (ricalca la metrica Alpha primaria) |
| `traveler_bronze` | Giramondo | bronze | check-in su 5 piste distinte |
| `traveler_silver` | Esploratore di Piste | silver | check-in su 15 piste distinte |
| `traveler_gold` | Conoscitore d'Italia | gold | check-in su 30 piste distinte |

### 5.5 Eventi

| badge_key | Nome IT | Tier | Criterio |
| --- | --- | --- | --- |
| `organizer_bronze` | Organizzatore | bronze | `community_event_created + official_event_created >= 1` |
| `organizer_silver` | Show Runner | silver | `>= 5` |
| `organizer_gold` | Direttore di Gara | gold | `>= 20` |

### 5.6 Milestone storiche (backfill-only)

| badge_key | Nome IT | Tier | Criterio |
| --- | --- | --- | --- |
| `pioneer_prealpha` | Pioniere Pre-Alpha | special | Utente attivo durante 0.1.x (con almeno 1 transazione PitCoin retroattiva al backfill) |
| `pioneer_alpha` | Pioniere Alpha | special | Registrato prima del Gate Alpha pubblico |

### 5.7 Forme di criteria supportate (vocabolario jsonb)

Per non esplodere in N forme di logica:

- `{"type": "action_count", "action_key": "<x>", "threshold": N}` — conta transazioni di un'azione
- `{"type": "action_sum_points", "action_key": "<x>", "threshold": N}` — somma punti di un'azione
- `{"type": "distinct_entities", "action_key": "<x>", "source_table": "<t>", "threshold": N}` — entita' distinte
- `{"type": "distinct_days", "action_key": "<x>", "threshold": N}` — giorni distinti
- `{"type": "same_entity_same_weekend", "action_key": "arrival_checkin", "threshold": 3}` — caso speciale Weekend Warrior
- `{"type": "manual"}` — assegnazione manuale admin / backfill

Ogni forma e' una funzione SQL `check_badge_criterion(criteria_jsonb, user_id)` che ritorna boolean.

## 6. Trigger logic

### 6.1 Funzione centrale `award_pitcoin`

```
function award_pitcoin(
  p_user_id     uuid,
  p_action_key  text,
  p_source_table text,
  p_source_id    uuid,
  p_metadata     jsonb
) returns void as $$
  -- 1. SELECT * FROM pitcoin_action_definitions WHERE action_key = p_action_key AND enabled
  -- 2. Se requires_approval e source non e' "approved" stato: skip
  -- 3. Verifica daily_cap: count transazioni odierne user_id+action_key
  -- 4. Verifica per_entity_cap: count transazioni user_id+action_key+source_id
  -- 5. Verifica lifetime_cap
  -- 6. Verifica cooldown_seconds rispetto a MAX(awarded_at) per quella action_key
  -- 7. INSERT INTO pitcoin_transactions (...) ON CONFLICT DO NOTHING
  -- 8. (trigger sul ledger aggiorna user_pitcoin_balances e valuta badge)
$$ language plpgsql security definer;
```

### 6.2 Triggers sulle tabelle esistenti

| Tabella | Evento | Action key |
| --- | --- | --- |
| `arrivals` | AFTER INSERT | `arrival_checkin` |
| `user_builds` | AFTER INSERT | `build_created` |
| `user_builds` | AFTER UPDATE (is_public false→true) | `build_published` |
| `spots` | AFTER INSERT | `spot_submitted` |
| `spots` | AFTER UPDATE su approval_status (se gestita) | `spot_approved` |
| `tracks` | AFTER INSERT | `track_submitted` |
| `tracks` | AFTER UPDATE (approval_status → approved) | `track_approved` |
| `shops` | AFTER INSERT | `shop_submitted` |
| `shops` | AFTER UPDATE (approval_status → approved) | `shop_approved` |
| `events` | AFTER INSERT | `official_event_created` |
| `community_events` | AFTER INSERT | `community_event_created` |
| `event_rsvps` | AFTER INSERT | `event_rsvp_sent` + (su event owner) `event_rsvp_received` |
| `track_follows` | AFTER INSERT | `track_followed` |
| `shop_follows` | AFTER INSERT | `shop_followed` |
| `track_status_history` | AFTER INSERT | `track_status_updated` |
| `track_services` | AFTER UPDATE | `track_services_updated` |
| `external_links` | AFTER INSERT | `external_link_added` |
| `track_media` | AFTER INSERT | `track_media_added` |
| `profiles` | AFTER UPDATE (vari campi) | `profile_completed`, `profile_made_public` |

### 6.3 Trigger sul ledger

```
trigger pitcoin_transactions_after_insert
on public.pitcoin_transactions
after insert
  -- aggiorna user_pitcoin_balances (upsert)
  -- richiama check_badge_unlocks(NEW.user_id, NEW.action_key)
```

### 6.4 Funzione `check_badge_unlocks`

```
function check_badge_unlocks(p_user_id uuid, p_trigger_action_key text) returns void as $$
  -- per ogni badge enabled non ancora ottenuta dall'utente
  -- valuta la criteria: se soddisfatta, INSERT INTO user_badges ON CONFLICT DO NOTHING
$$ language plpgsql security definer;
```

Ottimizzazione possibile: invece di valutare tutte le badge, filtrare solo quelle che dipendono da `p_trigger_action_key`. Si puo' fare aggiungendo una colonna `dependent_action_keys text[]` a `pitcoin_badge_definitions` derivata dalla criteria.

## 7. Visibilita' e RLS

Conferma la scelta presa: balance pubblico sul profilo opt-in, storico privato.

| Tabella | anon | authenticated (non owner) | owner | admin |
| --- | --- | --- | --- | --- |
| `pitcoin_action_definitions` | SELECT enabled=true | SELECT enabled=true | SELECT enabled=true | ALL |
| `pitcoin_transactions` | NO | NO | SELECT propri | ALL |
| `user_pitcoin_balances` | SELECT via view pubblica se profilo public | SELECT via view pubblica se public, propri sempre | SELECT propri | ALL |
| `pitcoin_badge_definitions` | SELECT enabled=true | SELECT enabled=true | SELECT enabled=true | ALL |
| `user_badges` | SELECT via view pubblica se profilo public | SELECT via view pubblica se public, propri sempre | SELECT propri | ALL |

Esponiamo due view pubbliche per il discovery, coerenti con il pattern `public_spots` gia' adottato:

- `public.public_user_pitcoin` — `user_id`, `public_slug`, `total_points` (solo se profilo public)
- `public.public_user_badges` — `user_id`, `public_slug`, `badge_key`, `awarded_at` (solo se profilo public)

Le INSERT su `pitcoin_transactions` e `user_badges` avvengono esclusivamente via funzioni `SECURITY DEFINER` invocate dai trigger. Nessun client puo' insertare direttamente.

## 8. Backfill al deploy

One-shot SQL eseguito subito dopo l'applicazione del delta. Pseudocodice:

```
-- per ogni profilo esistente
--   se profilo completo (criteri profile_completed) → award profile_completed
--   se profilo public → award profile_made_public

-- per ogni user_build esistente
--   award build_created con awarded_at = build.created_at
--   se is_public → award build_published

-- per ogni track approved → award track_submitted + track_approved al submitted_by
-- per ogni shop approved → award shop_submitted + shop_approved al submitted_by
-- per ogni spot esistente → award spot_submitted + (se approvato) spot_approved
-- per ogni community_event → award community_event_created
-- per ogni event → award official_event_created
-- per ogni arrival → award arrival_checkin (rispettando daily_cap retroattivo)
-- per ogni track_follow / shop_follow → award track_followed / shop_followed
-- per ogni track_status_history → award track_status_updated (con cooldown retroattivo)
-- per ogni external_link → award external_link_added

-- poi rivaluta tutte le badge per tutti gli utenti
-- assegna pioneer_prealpha agli utenti con almeno 1 transazione retroattiva
-- assegna pioneer_alpha agli utenti registrati prima della data Gate Alpha
```

Il backfill rispetta i cap/cooldown configurati per realismo. La metadata della transazione e' marcata `{"source":"backfill", "applied_at":"2026-05-XX"}`.

## 9. Anti-spam e gaming — sintesi

- Cap giornalieri su check-in, foto, update operativi.
- Cooldown su update operativi del gestore.
- Admin sono esclusi dall'accumulo (`profiles.role = 'admin'` → trigger esce subito).
- Impersonificazione admin: anche durante `effectiveUserIdProvider`, le scritture sono attribuite all'utente osservato, quindi i PitCoin restano in capo a lui — ma e' un caso minore, da monitorare.
- Submission rifiutata: nessuna revoca attiva (placeholder a 0 resta), e nessuna riassegnazione. Se l'utente reinvia, la unique constraint impedisce doppi accrediti.
- Build cancellate: nessuna revoca (al massimo `award_pitcoin_revoke` futuro per casi gravi).

## 10. UI Flutter da aggiungere (additive, no refactor)

Tre superfici nuove, tutte solo lettura, nessuna logica esistente toccata.

### 10.1 Badge balance nel profilo (autenticato)

In `profile_screen` (modulo Account gia' presente), card "PitCoin" con:

- icona moneta + numero totale
- delta ultime 7 giornate ("+45 questa settimana")
- link a "Storico attivita'"

### 10.2 Sezione "Storico attivita'" (autenticato)

Schermata `/profile/activity` o sub-route, lista paginata di `pitcoin_transactions` con:

- icona azione (da `pitcoin_action_definitions.category`)
- testo descrittivo localizzato
- punti accreditati
- data
- link all'entita' se ancora esistente (track/shop/event/spot/build)

### 10.3 Vetrina badge

Sezione "Trofei" nel profilo autenticato (mostra anche progress in corso, es. "Esploratore Silver 3/5") e sul profilo pubblico `/u/:publicSlug` (mostra solo le ottenute, come distintivi).

### 10.4 Risorse

- icone badge: asset SVG locali in `app/lib/assets/badges/` (16+ asset, primo set minimal). Categoria → simbolo coerente con design industrial-premium.
- localizzazione: estendere ARB con voci `badge.identity_profile_complete.name` / `.description`, etc.

## 11. Aperture & decisioni rimandate

Alcune scelte le sospendiamo esplicitamente fino a dato reale.

- **Scadenza punti**: per ora nessuna. Si rivaluta dopo Gate Alpha se emerge hoarding.
- **Leaderboard pubblica**: non ancora. Si rivaluta dopo il primo trimestre di dato.
- **Monetizzazione**: nessuna conversione in vantaggi materiali nella v1. Si rivaluta con partner commerciali.
- **Anti-frode geolocalizzato sui check-in**: rinviato. Per ora basta daily_cap.
- **Gating ruoli (shop_owner non guadagna come pilota)**: nella v1 tutti i ruoli accumulano allo stesso modo; si rivaluta se emerge distorsione metrica.

## 12. Piano di lavoro suggerito

Una volta approvato questo documento:

1. **Subagent SQL** scrive `supabase/deltas/2026-05-XX-pitcoin-system.sql`: tabelle, RLS, funzioni `SECURITY DEFINER`, trigger su tutte le tabelle elencate al §6.2, view pubbliche, backfill.
2. **Subagent Seed** scrive il seed iniziale di `pitcoin_action_definitions` e `pitcoin_badge_definitions` con i valori di questo documento.
3. **Subagent Flutter** aggiunge le tre superfici UI del §10 senza toccare provider esistenti, solo nuovi repository/provider/screen.
4. **Subagent QA** scrive script di verifica idempotenza (esegue insert duplicate, verifica zero doppi accrediti) e calcolo bilanci.
5. **VERSION.md** bump a 0.2.0 (minor: nuova capability rilevante).
6. **ROADMAP.md** sposta la sezione "Idea futura — Sistema crediti..." in changelog implementato.

## 13. Riferimenti incrociati

- `docs/roadmap.md` §"Idea futura — Sistema crediti, medaglie e bonus per attivita'" — origine della specifica
- `docs/data-model.md` — entita' coinvolte come source delle azioni
- `docs/permissions-matrix.md` — ruoli e ownership che governano chi puo' compiere quali azioni
- `docs/api-registry.md` — l'intera logica resta interna a Supabase, nessun nuovo provider esterno
- `supabase/schema.sql` — tabelle target dei trigger
