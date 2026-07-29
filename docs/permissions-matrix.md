# Permissions Matrix

Matrice iniziale dei ruoli e dei permessi applicativi di PitLap.

Obiettivo:

- separare in modo chiaro lettura pubblica, autenticazione e ownership
- evitare ambiguita' tra ruolo globale e permesso su una singola entita'
- preparare il passaggio da gating UI a enforcement backend reale

## Stato

Data aggiornamento: `2026-07-29` (audit RLS su `pitlap-dev`)

Implementazione UI attuale:

- `guest`: menu pubblico senza `Garage`, `Profilo`, `Gestione`, `Admin`
- `shop owner`: puo' vedere `Modifica negozio` nel dettaglio negozio
- `shop owner`: l'edit del negozio dipende da `shop_managers`, non solo dal ruolo (attivo)
- `track organizer`: puo' accedere a `/manager` e vedere la voce `Gestione`
- `admin`: puo' vedere la voce `Admin` e accedere a `/admin`

Enforcement backend (verificato su dev 2026-07-29):

- enum `app_role` in uso reale: `user`, `admin`, `shop_owner`, `track_organizer`
- l'enforcement NON e' piu' solo gating UI: le tabelle 0.3.0 hanno RLS reale (vedi sotto)
- account "ibridi": il ruolo globale e' un'etichetta/capability, ma l'edit di piste/negozi e' ancorato alle tabelle di ownership per-entita' `track_managers`/`shop_managers`. Un utente puo' quindi gestire piste e negozi diversi a prescindere dal singolo `role`. Resta aperto solo il modo di *rappresentare* l'ibrido in UI (un solo ruolo mostrato), non la capability.

## Principi

- `guest` non e' un ruolo persistito, ma uno stato applicativo non autenticato
- `registered user` e' il ruolo base di chi usa PitLap come modellista
- `shop owner` e `track organizer` ereditano i permessi base dell'utente registrato
- un singolo account puo' dover combinare capability multiple (`shop_owner` + `track_organizer`) senza perdere ownership su entrambe le aree
- `admin` ha visibilita' e controllo completi su tutto il sistema
- i permessi sensibili si basano su due assi:
  - ruolo globale
  - ownership o relazione esplicita con negozio/pista

## Discovery pubblica

Principio di prodotto confermato:

- PitLap deve comportarsi come una web app "tipo Strava" per il modellismo
- un guest deve capire subito cosa esiste vicino a lui senza doversi registrare
- il confine di sicurezza non e' "togliere contenuto pubblico", ma:
  - limitare i campi sensibili
  - limitare le azioni dispositive
  - limitare la pubblicazione e l'editing a utenti autorizzati

Conseguenze operative:

- `tracks`, `shops`, `events`, `community_events`, `spots` e `profiles` pubblici restano consultabili dai guest, ma le tabelle larghe non devono necessariamente essere leggibili in ogni colonna
- per i client guest vanno preferite superfici pubbliche esplicite (view o select minimali) invece della lettura diretta di tabelle larghe
- i metadati di ownership, review o workflow non devono essere esposti solo per sostenere logiche UI

### Regola tecnica

- la UI guest deve usare contratti pubblici espliciti
- la UI autenticata puo' ottenere segnali di ownership calcolati, ma non deve ricevere piu' dati sensibili del necessario
- esempio adottato: per gli spot il client pubblico usa la view `public.public_spots`, che espone i dati di discovery e il flag `is_owned_by_current_user` senza esporre `owner_id`
- hardening applicato: `public.spots.owner_id` non e' selezionabile da `anon` o `authenticated`; l'insert autenticato puo' ancora valorizzarlo e le policy RLS continuano a proteggere creazione/modifica
- hardening grants applicato: `anon` non mantiene privilegi DML sulle tabelle `public`; `authenticated` non mantiene privilegi tecnici `TRIGGER`, `TRUNCATE`, `REFERENCES`

## Ruoli iniziali

### Guest

Puo':

- vedere piste pubbliche
- vedere eventi pubblici
- vedere negozi pubblici
- usare discovery `Vicino a te`
- aprire dettaglio pista, negozio, evento
- usare ricerca e filtri pubblici

Non puo':

- salvare preferiti
- creare eventi
- modificare profilo
- aprire garage o profili community
- gestire negozi o piste

### Registered user

Puo':

- tutto cio' che puo' il guest
- autenticarsi e mantenere una sessione
- impostare profilo base
- usare garage personale
- salvare preferiti
- segnare `Sto arrivando`
- creare eventi community se il modello dati finale lo confermera'

Non puo':

- modificare negozi non propri
- modificare piste non proprie
- usare pannello admin

### Shop owner

Puo':

- tutto cio' che puo' l'utente registrato
- creare e modificare il proprio negozio o i propri negozi
- aggiornare immagini, contatti, orari, note e profilo negozio
- collegare il negozio a una o piu' piste quando il modello ownership lo supportera'

Non puo':

- modificare piste non assegnate
- modificare negozi non assegnati
- usare funzioni admin globali

### Track organizer

Puo':

- tutto cio' che puo' l'utente registrato
- creare e modificare la propria pista o le proprie piste
- aggiornare stato pista, servizi, immagini, eventi e messaggi rapidi
- vedere presenze e dati operativi relativi alle piste assegnate
- modificare un negozio solo se esiste anche una ownership esplicita su `shop_managers`

Non puo':

- modificare piste non assegnate
- usare funzioni admin globali

### Admin

Puo':

- vedere tutto
- creare, modificare e disattivare utenti
- creare, modificare e disattivare negozi
- creare, modificare e disattivare piste
- gestire eventi, garage, profili, immagini e media
- assegnare ownership e ruoli
- gestire categorie hobby e label pista
- moderare submission, eventi, media e relazioni tra entita'
- usare dashboard di monitoraggio e pannello di controllo completo

## Ownership e relazioni

### Profilo utente

- ownership: `profiles.id = auth.uid()`
- admin: accesso completo

### Negozio

- ownership tramite relazione esplicita `shop_managers`
- admin: accesso completo

### Pista

- ownership attuale via `track_managers`
- admin: accesso completo

### Garage

- ownership: utente creatore
- visibilita' pubblica separata da editabilita'
- admin: accesso completo

### Evento

- ownership da chiarire tra:
  - utente creatore
  - negozio proprietario
  - organizzatore pista
  - admin

Viste future da prevedere:

- storico eventi per singolo attore
- archivio eventi aperti/chiusi
- futura libreria digitale consultabile senza esporre azioni di edit a chi non ha ownership

## Matrice sintetica

| Funzione | Guest | Registered | Shop owner | Track organizer | Admin |
| --- | --- | --- | --- | --- | --- |
| Vedere piste pubbliche | Si | Si | Si | Si | Si |
| Vedere negozi pubblici | Si | Si | Si | Si | Si |
| Vedere eventi pubblici | Si | Si | Si | Si | Si |
| Salvare preferiti | No | Si | Si | Si | Si |
| Usare garage personale | No | Si | Si | Si | Si |
| Vedere profili/garage community | No | Si | Si | Si | Si |
| Creare eventi | No | Si* | Si* | Si* | Si |
| Editare il proprio negozio | No | No | Si | Si** | Si |
| Editare la propria pista | No | No | Si** | Si | Si |
| Gestire media pista/negozio | No | No | Si | Si | Si |
| Moderare contenuti | No | No | No | No | Si |
| Gestire categorie hobby/label | No | No | No | No | Si |
| Pannello controllo completo | No | No | No | No | Si |
| Commentare entita' pubbliche | No | Si | Si | Si | Si |
| Modificare/eliminare propri commenti | No | Si | Si | Si | Si |
| Nascondere/moderare commenti | No | No | No | No | Si |
| Seguire profili / piste / negozi | No | Si | Si | Si | Si |
| Ricevere notifiche in-app | No | Si | Si | Si | Si |
| Vedere PitCoin altrui sul profilo | No | No | No | No | No |

Note:

- `Si*`: da confermare quando la policy eventi passera' da prototipo locale a backend reale
- `Si**`: solo se l'account ha relazioni di ownership multiple esplicite
- il solo ruolo globale non e' sufficiente per editare entita' sensibili: servono relazioni reali su `track_managers` e `shop_managers` (attivo)

### Regole RLS verificate (0.3.0, dev 2026-07-29)

- **Commenti** (`entity_comments`): INSERT con `WITH CHECK author_id = auth.uid() AND is_hidden = false`; UPDATE/DELETE solo autore o admin; SELECT pubblica solo dei commenti non nascosti (autore/admin vedono anche i propri nascosti). Segnalazioni via RPC `report_comment`, non INSERT diretto.
- **Follow** (`profile_follows`, `track_follows`, `shop_follows`): owner-scoped su `auth.uid()`; il follow profilo consentito (WITH CHECK) solo verso profili `is_public = true`.
- **Notifiche** (`notifications`, `notification_recipients`): lettura/aggiornamento solo del destinatario o admin; nessuna forgiabilita'.
- **PitCoin**: saldo di un utente non visibile agli altri — view `public_user_pitcoin` owner-only. Eccezione voluta: la classifica pubblica in home (`pitcoin_public_leaderboard`) resta con nomi + punti.

## Enforcement raccomandato

Ordine corretto:

1. nascondere o disabilitare le azioni in UI
2. proteggere routing e schermate sensibili
3. applicare policy backend e RLS
4. validare ownership lato repository e API

## Enforcement gia' attivo

- routing protetto per `Garage`, `Profilo`, `Onboarding`
- routing protetto per `Admin` con redirect se non admin
- routing protetto per `Gestione` con redirect se non `track_organizer` o `admin`
- pulsante `Modifica negozio` visibile solo a `shop_owner` o `admin`
- fondazione `shop_managers` pronta per spostare l'edit negozio da ruolo globale a ownership reale per slug
- salvataggio stato pista previsto via `track_status_current`, `track_status_history` e `track_services` con enforcement su `track_managers`

## Dashboard admin

Blocco previsto:

- overview utenti
- overview piste e negozi
- eventi recenti e submission in attesa
- immagini e media orfani o da moderare
- categorie hobby e label pista
- attivita' recenti e alert operativi
- contatori follow su piste e negozi
- viste archivio per analizzare lo storico eventi dei diversi attori

## Da fare

- ~~allineare schema reale dei ruoli oltre `user/admin`~~ fatto: enum `app_role` = user/admin/shop_owner/track_organizer
- ~~decidere il modello ownership per negozi~~ fatto: `shop_managers` per-negozio, enforcement RLS attivo
- ~~implementare enforcement reale oltre il gating UI~~ fatto per le entita' 0.3.0 (vedi "Regole RLS verificate")
- rappresentare in UI gli account con capability multiple (oggi il profilo mostra un solo ruolo): la capability funziona gia' via `track_managers`/`shop_managers`, manca solo la resa
- trasformare il pannello `Gestione` in un hub unico per piste e negozi assegnati, non solo per le piste
- chiarire il modello definitivo degli eventi community (policy ancora da portare da prototipo a backend)
- pulizia advisor: policy permissive multiple su `track_follows`/`shop_follows` (ALL + SELECT sovrapposte) — vedi blocco QA advisor
