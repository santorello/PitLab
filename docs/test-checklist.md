# Test Checklist

Checklist operativa di test per PitLap.

Obiettivo:

- raccogliere i casi principali gia' verificabili sul prodotto attuale
- separare chiaramente precondizioni, azione e atteso
- facilitare test manuali regressivi e smoke test dopo ogni blocco rilevante

## Stato

Data aggiornamento: `2026-05-10`

## Convenzioni

- `Tipo`: smoke, regressione, UX, permessi, integrazione
- `Precondizioni`: stato minimo richiesto prima del test
- `Atteso`: risultato osservabile, non interpretazione generica

## Auth e sessione

### TC-001

- `Tipo`: smoke, integrazione
- `Titolo`: accesso guest alla home pubblica
- `Precondizioni`: sessione non autenticata
- `Passi`:
  - aprire la home
- `Atteso`:
  - menu pubblico visibile
  - `Garage` e `Profilo` non visibili

### TC-002

- `Tipo`: permessi
- `Titolo`: accesso diretto a profilo da guest
- `Precondizioni`: sessione non autenticata
- `Passi`:
  - aprire `/#/profile`
- `Atteso`:
  - redirect alla login

### TC-003

- `Tipo`: permessi
- `Titolo`: accesso diretto a garage da guest
- `Precondizioni`: sessione non autenticata
- `Passi`:
  - aprire `/#/garage`
- `Atteso`:
  - redirect alla login

### TC-004

- `Tipo`: integrazione
- `Titolo`: login via magic link con rientro sessione
- `Precondizioni`: email valida, Supabase raggiungibile
- `Passi`:
  - richiedere magic link
  - aprire il link
- `Atteso`:
  - sessione autenticata
  - stato `Accesso attivo` nel chrome globale

### TC-005

- `Tipo`: regressione, legale
- `Titolo`: persistenza consensi post-login
- `Precondizioni`: login da magic link con checkbox legali selezionati
- `Passi`:
  - completare il login
  - verificare `user_consents`
- `Atteso`:
  - righe coerenti per termini, privacy e marketing

### TC-006

- `Tipo`: smoke
- `Titolo`: logout
- `Precondizioni`: sessione autenticata
- `Passi`:
  - usare `Esci`
- `Atteso`:
  - ritorno a vista pubblica
  - `Garage` e `Profilo` rimossi dal menu

## Home piste

### TC-007

- `Tipo`: UX
- `Titolo`: click sul corpo card pista
- `Precondizioni`: home visibile
- `Passi`:
  - cliccare il corpo di una card pista
- `Atteso`:
  - apertura dettaglio pista corrispondente

### TC-008

- `Tipo`: permessi, UX
- `Titolo`: `Preferiti` da guest
- `Precondizioni`: sessione non autenticata
- `Passi`:
  - cliccare `Preferiti` su una card pista
- `Atteso`:
  - redirect al login

### TC-009

- `Tipo`: integrazione
- `Titolo`: `Preferiti` da utente autenticato
- `Precondizioni`: sessione autenticata
- `Passi`:
  - cliccare `Preferiti` su una pista
- `Atteso`:
  - stato della CTA aggiornato
  - conteggio `Piste salvate` coerente nel profilo

### TC-010

- `Tipo`: regressione
- `Titolo`: ricerca piste
- `Precondizioni`: home visibile
- `Passi`:
  - inserire testo nel campo ricerca
  - usare `clear`
- `Atteso`:
  - lista filtrata correttamente
  - reset completo della lista con `clear`

### TC-011

- `Tipo`: regressione
- `Titolo`: chip filtri piste
- `Precondizioni`: home visibile
- `Passi`:
  - selezionare e deselezionare chip filtro
- `Atteso`:
  - lista coerente con il filtro attivo

## Dettaglio pista e arrivi

### TC-012

- `Tipo`: integrazione
- `Titolo`: accesso al dettaglio pista
- `Precondizioni`: pista pubblica esistente
- `Passi`:
  - aprire `/#/track/<slug>`
- `Atteso`:
  - hero pista caricata
  - stato pista visibile

### TC-013

- `Tipo`: integrazione
- `Titolo`: `Sto arrivando`
- `Precondizioni`: sessione autenticata
- `Passi`:
  - aprire una pista
  - confermare arrivo
- `Atteso`:
  - CTA aggiornata
  - sezione `Oggi in pista` coerente

### TC-014

- `Tipo`: integrazione
- `Titolo`: stato `Forse`
- `Precondizioni`: sessione autenticata
- `Passi`:
  - usare il flusso presenza e selezionare `Forse`
- `Atteso`:
  - stato personale `maybe`

### TC-015

- `Tipo`: integrazione
- `Titolo`: annulla presenza
- `Precondizioni`: presenza gia' registrata
- `Passi`:
  - usare il flusso presenza e selezionare `Annulla`
- `Atteso`:
  - stato personale `cancelled`

### TC-016

- `Tipo`: UX
- `Titolo`: orario ultima registrazione in `Oggi in pista`
- `Precondizioni`: presenza registrata
- `Passi`:
  - osservare la sezione `Oggi in pista`
- `Atteso`:
  - orario di aggiornamento visibile

### TC-017

- `Tipo`: regressione
- `Titolo`: indipendenza stato su piste diverse
- `Precondizioni`: almeno due piste
- `Passi`:
  - impostare stati diversi su due piste
- `Atteso`:
  - ciascuna pista mantiene il proprio stato

## Meteo

### TC-018

- `Tipo`: integrazione
- `Titolo`: meteo live via Open-Meteo
- `Precondizioni`: pista con coordinate valide
- `Passi`:
  - aprire dettaglio pista
- `Atteso`:
  - badge `Meteo live`
  - forecast a 3 giorni coerente

### TC-019

- `Tipo`: regressione
- `Titolo`: fallback meteo locale
- `Precondizioni`: pista senza coordinate o provider non disponibile
- `Passi`:
  - aprire dettaglio pista
- `Atteso`:
  - fallback visibile
  - UI non rotta

### TC-020

- `Tipo`: legale, UX
- `Titolo`: attribuzione provider meteo
- `Precondizioni`: dettaglio pista aperto
- `Passi`:
  - verificare la sezione meteo
- `Atteso`:
  - nota `Dati meteo forniti da Open-Meteo`

## Vicino a te

### TC-021

- `Tipo`: UX
- `Titolo`: ricerca in `Vicino a te`
- `Precondizioni`: pagina aperta
- `Passi`:
  - cercare un elemento
  - usare `clear`
- `Atteso`:
  - lista filtrata e poi ripristinata

### TC-022

- `Tipo`: navigazione
- `Titolo`: click su pista in `Vicino a te`
- `Precondizioni`: pagina aperta
- `Passi`:
  - cliccare un item pista
- `Atteso`:
  - apertura dettaglio pista

### TC-023

- `Tipo`: navigazione
- `Titolo`: click su negozio in `Vicino a te`
- `Precondizioni`: pagina aperta
- `Passi`:
  - cliccare un item negozio
- `Atteso`:
  - apertura dettaglio negozio

## Eventi

### TC-024

- `Tipo`: permessi
- `Titolo`: `Crea evento` da guest
- `Precondizioni`: sessione non autenticata
- `Passi`:
  - cliccare `Crea evento`
- `Atteso`:
  - redirect al login

### TC-025

- `Tipo`: smoke
- `Titolo`: creazione evento da autenticato con luogo e immagine
- `Precondizioni`: sessione autenticata
- `Passi`:
  - creare un evento
  - compilare luogo e sede/impianto
  - caricare una foto locale
- `Atteso`:
  - card evento visibile in lista
  - immagine visibile nella card
  - creatore evento visibile
  - evento marcato come pubblico

### TC-025B

- `Tipo`: robustezza
- `Titolo`: immagine evento troppo pesante
- `Precondizioni`: sessione autenticata, immagine locale tra 1 MB e 5 MB disponibile
- `Passi`:
  - aprire `Crea evento`
  - provare a caricare l'immagine pesante
- `Atteso`:
  - immagine viene ridimensionata se entro il limite massimo di input
  - immagine non viene agganciata alla preview se supera il limite massimo di input di 5 MB
  - UI resta stabile senza errori CanvasKit/WASM

### TC-026

- `Tipo`: regressione
- `Titolo`: persistenza evento creato nella sessione
- `Precondizioni`: evento creato
- `Passi`:
  - cambiare pagina
  - tornare su `Eventi`
- `Atteso`:
  - evento ancora visibile

### TC-027

- `Tipo`: navigazione
- `Titolo`: dettaglio evento
- `Precondizioni`: evento presente
- `Passi`:
  - aprire la card evento
- `Atteso`:
  - dettaglio evento coerente
  - eventuale immagine caricata visibile
  - sede/impianto visibile se valorizzato

### TC-027B

- `Tipo`: UX, navigazione
- `Titolo`: condivisione evento
- `Precondizioni`: evento presente in lista o dettaglio
- `Passi`:
  - cliccare `Condividi`
  - incollare il contenuto copiato in un campo testo temporaneo
- `Atteso`:
  - link evento copiato negli appunti
  - snackbar di conferma visibile
  - link punta al dettaglio `/#/event/<id>`

### TC-027C

- `Tipo`: permessi, regressione
- `Titolo`: evento creato resta pubblico dopo logout
- `Precondizioni`: sessione autenticata, evento creato
- `Passi`:
  - eseguire logout
  - aprire `Eventi`
- `Atteso`:
  - evento creato ancora visibile nella lista pubblica eventi
  - `Crea evento` richiede nuovamente login

## Negozi

### TC-028

- `Tipo`: permessi
- `Titolo`: dettaglio negozio da guest
- `Precondizioni`: sessione non autenticata
- `Passi`:
  - aprire un negozio
- `Atteso`:
  - vista in sola lettura

### TC-029

- `Tipo`: permessi
- `Titolo`: modifica negozio da guest
- `Precondizioni`: sessione non autenticata
- `Passi`:
  - cliccare `Modifica negozio`
- `Atteso`:
  - redirect al login

### TC-030

- `Tipo`: smoke
- `Titolo`: modifica negozio da autenticato con cover e galleria
- `Precondizioni`: sessione autenticata
- `Passi`:
  - modificare campi principali
  - caricare una cover locale
  - caricare una o piu' immagini galleria
  - salvare
- `Atteso`:
  - draft locale aggiornato
  - cover visibile
  - galleria visibile nella scheda negozio

### TC-030B

- `Tipo`: robustezza
- `Titolo`: limite immagini galleria negozio
- `Precondizioni`: sessione autenticata come profilo negozio o admin impersonato
- `Passi`:
  - aprire modifica negozio
  - selezionare piu' di 3 immagini locali in una sola volta
- `Atteso`:
  - vengono agganciate al massimo 3 immagini
  - la galleria negozio non supera 10 immagini totali
  - immagini grandi vengono ridimensionate quando possibile
  - immagini oltre il limite massimo di input vengono ignorate
  - UI resta stabile

### TC-030C

- `Tipo`: smoke, UX
- `Titolo`: link esterni negozio
- `Precondizioni`: sessione autenticata come profilo negozio o admin impersonato
- `Passi`:
  - aprire dettaglio negozio
  - aggiungere un link sito web o YouTube
  - salvare
  - uscire e rientrare nella scheda negozio
- `Atteso`:
  - il link resta visibile nella sezione `Link e canali`
  - il chip apre il link esterno
  - il link e' rimuovibile solo da profilo autorizzato

## Profilo

### TC-031

- `Tipo`: smoke
- `Titolo`: modifica nome visibile
- `Precondizioni`: sessione autenticata
- `Passi`:
  - modificare nome visibile
  - salvare
- `Atteso`:
  - nome aggiornato in hero

### TC-032

- `Tipo`: integrazione
- `Titolo`: cambio lingua dal profilo
- `Precondizioni`: sessione autenticata
- `Passi`:
  - cambiare lingua
  - salvare
- `Atteso`:
  - lingua persistita e riletta

### TC-033

- `Tipo`: UX
- `Titolo`: URL immagine profilo valido
- `Precondizioni`: sessione autenticata
- `Passi`:
  - inserire URL immagine affidabile
- `Atteso`:
  - preview avatar visibile

### TC-034

- `Tipo`: robustezza
- `Titolo`: URL immagine profilo non caricabile
- `Precondizioni`: sessione autenticata
- `Passi`:
  - inserire URL da host che blocca il browser
- `Atteso`:
  - fallback avatar pulito
  - nessun blocco del salvataggio profilo

### TC-035

- `Tipo`: integrazione
- `Titolo`: riepilogo consensi in profilo
- `Precondizioni`: utente con consensi gia' salvati
- `Passi`:
  - aprire il profilo
- `Atteso`:
  - termini, privacy, marketing, versione e data visibili

### TC-035B

- `Tipo`: smoke, UX
- `Titolo`: link esterni nel profilo
- `Precondizioni`: sessione autenticata
- `Passi`:
  - aprire `Profilo`
  - aggiungere un link Instagram o YouTube con URL senza `https://`
  - salvare
  - cliccare il chip del link
- `Atteso`:
  - il link viene normalizzato e salvato localmente
  - il chip compare nella sezione `Link e canali`
  - il click prova ad aprire il link esterno
  - il link puo' essere rimosso se il profilo e' editabile

## Garage

### TC-036

- `Tipo`: smoke
- `Titolo`: aggiunta build con immagine
- `Precondizioni`: sessione autenticata
- `Passi`:
  - aggiungere una build
  - caricare una foto locale
- `Atteso`:
  - build visibile in lista
  - immagine visibile nella card build

### TC-037

- `Tipo`: UX
- `Titolo`: visibilita' build
- `Precondizioni`: build presente
- `Passi`:
  - cambiare stato pubblico/privato
- `Atteso`:
  - badge coerente sulla card

### TC-038

- `Tipo`: regressione
- `Titolo`: leggibilita' hero garage
- `Precondizioni`: pagina garage aperta
- `Passi`:
  - verificare la hero scura
- `Atteso`:
  - pulsanti e toggle leggibili

## Legale

### TC-039

- `Tipo`: smoke, legale
- `Titolo`: apertura informativa privacy
- `Precondizioni`: nessuna
- `Passi`:
  - aprire `/#/legal/privacy`
- `Atteso`:
  - pagina pubblica leggibile

### TC-040

- `Tipo`: smoke, legale
- `Titolo`: apertura termini di servizio
- `Precondizioni`: nessuna
- `Passi`:
  - aprire `/#/legal/terms`
- `Atteso`:
  - pagina pubblica leggibile

### TC-041

- `Tipo`: smoke, legale
- `Titolo`: apertura cookie policy
- `Precondizioni`: nessuna
- `Passi`:
  - aprire `/#/legal/cookies`
- `Atteso`:
  - pagina pubblica leggibile

## Permessi e ruoli

### TC-042

- `Tipo`: permessi
- `Titolo`: matrice guest minima
- `Precondizioni`: sessione non autenticata
- `Passi`:
  - navigare tra home, piste, negozi, eventi, vicino a te
- `Atteso`:
  - sola lettura pubblica disponibile
  - nessuna area privata accessibile

### TC-043

- `Tipo`: permessi
- `Titolo`: matrice utente registrato minima
- `Precondizioni`: sessione autenticata
- `Passi`:
  - verificare accesso a profilo, garage, creazione evento, arrivi
- `Atteso`:
  - funzioni base utente disponibili

### TC-044

- `Tipo`: tecnico, documentale
- `Titolo`: registro API allineato
- `Precondizioni`: nessuna
- `Passi`:
  - aprire `docs/api-registry.md`
- `Atteso`:
  - Supabase e Open-Meteo presenti
  - note attribuzione e privacy presenti

### TC-045

- `Tipo`: smoke, permessi
- `Titolo`: dashboard admin senza placeholder tecnici
- `Precondizioni`: sessione admin autenticata
- `Passi`:
  - aprire `/#/admin`
  - osservare overview, categorie, impersonifica e monitoraggio
- `Atteso`:
  - metriche reali dove disponibili
  - voci non ancora collegate indicate come `Da collegare`
  - nessun testo `TODO` visibile

### TC-046

- `Tipo`: UX, navigazione
- `Titolo`: `Vicino a te` con dati correnti
- `Precondizioni`: almeno una pista pubblica disponibile
- `Passi`:
  - aprire `/#/nearby`
  - filtrare per piste
  - filtrare per negozi
  - cliccare un risultato
- `Atteso`:
  - lista senza box descrittivi demo
  - piste aperte dal dettaglio pista
  - negozi aperti dal dettaglio negozio

## Gestione pista V2 e affidabilita' Supabase

### TC-047

- `Tipo`: integrazione, UX
- `Titolo`: preset rapido `Pronta gara`
- `Precondizioni`: utente gestore autenticato, pista assegnata
- `Passi`:
  - aprire `/#/manager`
  - selezionare preset `Pronta gara`
  - salvare
- `Atteso`:
  - stato pista `open`
  - messaggio precompilato persistito
  - servizi essenziali coerenti con preset

### TC-048

- `Tipo`: integrazione, UX
- `Titolo`: preset rapido `Bagnata ma aperta`
- `Precondizioni`: utente gestore autenticato, pista assegnata
- `Passi`:
  - aprire `/#/manager`
  - selezionare preset `Bagnata ma aperta`
  - salvare
- `Atteso`:
  - stato pista `wet`
  - messaggio preset persistito
  - aggiornamento visibile anche su dettaglio pista pubblico

### TC-049

- `Tipo`: integrazione, UX
- `Titolo`: preset rapido `Chiusa manutenzione`
- `Precondizioni`: utente gestore autenticato, pista assegnata
- `Passi`:
  - applicare preset `Chiusa manutenzione`
  - salvare
- `Atteso`:
  - stato pista `closed`
  - messaggio manutenzione salvato
  - badge stato coerente nelle card pista

### TC-050

- `Tipo`: regressione, UX
- `Titolo`: badge `Modifiche non salvate`
- `Precondizioni`: manager screen aperta
- `Passi`:
  - modificare almeno un campo senza salvare
- `Atteso`:
  - badge modifiche non salvate visibile
  - pulsante save abilitato

### TC-051

- `Tipo`: integrazione
- `Titolo`: save con stato `saving` e timestamp ultimo invio
- `Precondizioni`: manager screen aperta, modifica pendente
- `Passi`:
  - premere `Salva`
- `Atteso`:
  - pulsante disabilitato durante invio
  - indicazione `Salvataggio...`
  - dopo successo compare `Ultimo invio HH:MM`

### TC-052

- `Tipo`: integrazione, affidabilita'
- `Titolo`: timeline `Ultimi aggiornamenti` valorizzata
- `Precondizioni`: almeno un salvataggio effettuato sulla pista
- `Passi`:
  - aprire `/#/manager`
  - consultare blocco timeline
- `Atteso`:
  - presenza righe storico con stato e timestamp
  - ordine dal piu' recente al meno recente

### TC-053

- `Tipo`: integrazione, affidabilita'
- `Titolo`: refresh manuale timeline
- `Precondizioni`: manager screen aperta
- `Passi`:
  - premere `Ricarica dati` o `Riprova` in timeline
- `Atteso`:
  - ricarica provider senza crash
  - dati aggiornati dopo nuovo save

### TC-054

- `Tipo`: affidabilita', rete
- `Titolo`: fetch storico con rete instabile
- `Precondizioni`: throttle rete o momentaneo degrado con Supabase raggiungibile
- `Passi`:
  - aprire manager screen piu' volte
- `Atteso`:
  - eventuali errori mostrati in UI
  - nessun blocco irreversibile
  - `Riprova` consente nuova richiesta

### TC-055

- `Tipo`: affidabilita', write
- `Titolo`: save snapshot su Supabase e coerenza cross-page
- `Precondizioni`: utente gestore autenticato
- `Passi`:
  - aggiornare stato e servizi in `Gestione`
  - aprire home e dettaglio pista
- `Atteso`:
  - valori coerenti su tutte le pagine
  - nessuna divergenza tra `track_status_current` e UI

### TC-056

- `Tipo`: permessi, sicurezza
- `Titolo`: storico e update consentiti solo a owner/admin
- `Precondizioni`: utente autenticato non owner
- `Passi`:
  - tentare update pista non assegnata
  - verificare accesso timeline da route gestore non autorizzata
- `Atteso`:
  - update rifiutato da policy/flow
  - nessuna modifica scritta su `track_status_history`

### TC-057

- `Tipo`: integrazione, admin
- `Titolo`: apertura pista `pending` da coda approvazioni
- `Precondizioni`: esiste una bozza pista in stato `pending`, utente admin autenticato
- `Passi`:
  - aprire `/#/admin`
  - usare `Apri` nella card approvazione pista
- `Atteso`:
  - dettaglio pista visibile anche se non ancora pubblica
  - contenuti submission coerenti con bozza inviata

### TC-058

- `Tipo`: regressione, UX
- `Titolo`: label stato card bozza gestore allineata ad approvazione
- `Precondizioni`: bozza pista portata in stato `approved` o `rejected`
- `Passi`:
  - aprire `/#/manager` con account organizzatore pista
- `Atteso`:
  - label primaria non resta fissa su `Bozza gestore`
  - badge coerente con stato reale (`In approvazione`/`Approvata`/`Da rivedere`)

### TC-059

- `Tipo`: UX, validazione
- `Titolo`: gating invio approvazione in `/manager/tracks/new`
- `Precondizioni`: utente organizzatore pista autenticato
- `Passi`:
  - aprire `/#/manager/tracks/new`
  - lasciare incompleti uno o piu' requisiti minimi
  - tentare invio approvazione
- `Atteso`:
  - pulsante invio disabilitato finche' la checklist non e' completa
  - progress/checklist aggiornati in tempo reale

### TC-060

- `Tipo`: integrazione, ownership
- `Titolo`: owner modifica uno spot custom
- `Precondizioni`: utente autenticato con spot custom gia' creato
- `Passi`:
  - aprire il dettaglio spot
  - usare `Modifica spot`
  - aggiornare descrizione e immagini
- `Atteso`:
  - il form viene precompilato
  - il salvataggio aggiorna subito lista e dettaglio spot

### TC-061

- `Tipo`: admin, permessi
- `Titolo`: admin modifica uno spot custom creato da terzi
- `Precondizioni`: account admin autenticato, spot custom esistente
- `Passi`:
  - aprire il dettaglio spot
  - usare `Modifica spot`
- `Atteso`:
  - il pulsante edit e' disponibile per admin
  - il salvataggio va a buon fine

### TC-062

- `Tipo`: regressione, media
- `Titolo`: prima foto spot usata come cover
- `Precondizioni`: creare o modificare uno spot con almeno 2 immagini
- `Passi`:
  - tornare alla lista `/spots`
  - aprire il dettaglio spot
- `Atteso`:
  - la prima immagine e' la cover della card
  - la stessa immagine compare nella hero del dettaglio

### TC-063

- `Tipo`: integrazione, negozi
- `Titolo`: creazione negozio con servizi completi
- `Precondizioni`: utente con ruolo shop owner
- `Passi`:
  - aprire `/shops/new`
  - compilare dati principali, servizi, contatti, orari e note
  - salvare bozza
- `Atteso`:
  - tutti i campi restano persistiti
  - il negozio compare in `I tuoi negozi`

### TC-064

- `Tipo`: regressione, gestione
- `Titolo`: draft negozio visibile in `/shops` e `Gestione`
- `Precondizioni`: almeno un draft negozio salvato
- `Passi`:
  - aprire `/shops`
  - aprire `/manager` con account abilitato
- `Atteso`:
  - la card draft e' visibile in entrambe le aree
  - il bottone `Modifica negozio` riapre l'editor corretto

## Hardening pubblico e pre-online

### TC-065

- `Tipo`: regressione, pubblico
- `Titolo`: `Vicino a te` non mostra dati hardcoded
- `Precondizioni`: almeno una pista pubblica o un negozio pubblico nel database
- `Passi`:
  - aprire `/#/nearby`
  - confrontare le card visibili con i record pubblici reali
- `Atteso`:
  - nessun negozio demo o placeholder fisso
  - nessuna distanza fake mostrata come dato reale

### TC-066

- `Tipo`: pubblico, navigazione
- `Titolo`: dettaglio spot accessibile da guest
- `Precondizioni`: sessione non autenticata, almeno uno spot pubblico esistente
- `Passi`:
  - aprire `/#/spot/<slug>`
- `Atteso`:
  - dettaglio visibile senza redirect al login
  - CTA coerenti con ruolo guest

### TC-067

- `Tipo`: pubblico, navigazione
- `Titolo`: dettaglio evento accessibile da guest
- `Precondizioni`: sessione non autenticata, almeno un evento pubblico esistente
- `Passi`:
  - aprire `/#/event/<eventId>`
- `Atteso`:
  - dettaglio visibile senza redirect al login
  - se l'evento non esiste, compare stato `evento non trovato`
  - nessun fallback demo inventato

### TC-068

- `Tipo`: regressione, pubblico
- `Titolo`: catalogo negozi pubblici non contaminato da draft locali
- `Precondizioni`: utente con almeno un draft locale e almeno un negozio pubblico esistente
- `Passi`:
  - aprire `/#/shops`
  - confrontare il catalogo con i dati pubblici reali
- `Atteso`:
  - la lista pubblica mostra solo dati pubblici
  - immagini, citta' e specialita' non vengono sovrascritti da draft locali

## Scritture reali DB

### TC-069

- `Tipo`: integrazione, persistenza
- `Titolo`: onboarding persiste preferenze profilo
- `Precondizioni`: utente autenticato, Supabase configurato
- `Passi`:
  - completare onboarding con zona e preferenze
  - ricaricare la sessione
- `Atteso`:
  - i dati restano persistiti dopo refresh
  - il profilo riflette i valori appena salvati

### TC-070

- `Tipo`: integrazione, persistenza
- `Titolo`: creazione negozio come bozza persistente
- `Precondizioni`: utente autenticato, Supabase configurato
- `Passi`:
  - creare un nuovo negozio
  - usare `Salva bozza`
  - ricaricare pagina o riaprire la sessione
- `Atteso`:
  - il negozio esiste davvero nel database
  - ricompare dopo reload con i dati inseriti

### TC-071

- `Tipo`: integrazione, persistenza
- `Titolo`: modifica negozio esistente aggiorna e non reinserisce
- `Precondizioni`: negozio esistente modificabile dall'utente
- `Passi`:
  - modificare titolo o descrizione
  - salvare
  - ricaricare la pagina
- `Atteso`:
  - il salvataggio fa `update` e non `insert`
  - nessun errore su `shops_slug_key`
  - i dati modificati restano dopo reload

### TC-072

- `Tipo`: integrazione, persistenza
- `Titolo`: inserimento spot custom persistente
- `Precondizioni`: utente autenticato, Supabase configurato
- `Passi`:
  - creare uno spot da `Segnala spot`
  - completare il salvataggio
  - riaprire lista e dettaglio
- `Atteso`:
  - spot presente nel database
  - spot visibile dopo refresh
  - nessun successo mostrato se il backend fallisce

### TC-073

- `Tipo`: integrazione, persistenza
- `Titolo`: creazione community event persistente
- `Precondizioni`: utente autenticato, Supabase configurato
- `Passi`:
  - creare un evento
  - aprire admin o dettaglio evento
  - ricaricare la sessione
- `Atteso`:
  - evento presente in `community_events`
  - evento ancora visibile dopo refresh

## Env, build e media

### TC-074

- `Tipo`: smoke, configurazione
- `Titolo`: run web con file config locale
- `Precondizioni`: `app/config/dev.local.json` presente
- `Passi`:
  - avviare `flutter run -d chrome --dart-define-from-file=./config/dev.local.json`
- `Atteso`:
  - nessun banner `Supabase non configurato`
  - app collegata al backend reale

### TC-075

- `Tipo`: smoke, configurazione
- `Titolo`: run Android con file config locale
- `Precondizioni`: device collegato, `app/config/dev.local.json` presente
- `Passi`:
  - avviare build Android con `--dart-define-from-file`
- `Atteso`:
  - nessun banner `Supabase non configurato`
  - letture e scritture reali disponibili

### TC-076

- `Tipo`: regressione, UX
- `Titolo`: immagini da URL esterno persistenti
- `Precondizioni`: editor negozio o pista con URL immagine valido
- `Passi`:
  - inserire URL immagine
  - salvare
  - ricaricare pagina
- `Atteso`:
  - immagine ancora visibile dopo reload
  - nessun binario salvato nel database

### TC-077

- `Tipo`: regressione, UX
- `Titolo`: picker locale non finge persistenza definitiva
- `Precondizioni`: flow con picker file locale disponibile
- `Passi`:
  - selezionare un'immagine da file locale
  - osservare preview e poi ricaricare senza storage reale
- `Atteso`:
  - la UI chiarisce che la preview locale non e' media persistente definitiva
  - nessun falso successo lato backend

## Walkthrough admin 2026-05-07

Sessione QA manuale come admin loggato (g.santoro90@live.it) su Chrome a 1400x900 e 420x900 (mobile), Supabase configurato via `dev.json`, run via `run_dev.bat` su porta 8080. Le entry di questa sezione sono tutte test che attualmente FALLISCONO con repro/expected/actual e priorita' indicata.

### TC-WT-01

- `Tipo`: regressione, auth, robustezza
- `Titolo`: magic link scaduto o gia' usato non crasha l'app
- `Priorita`: P0
- `Precondizioni`: URL magic link con `error_code=otp_expired` o `code` gia' consumato
- `Passi`:
  - aprire la URL completa nel browser, es. `http://localhost:8080/?code=...&error=access_denied&error_code=otp_expired&...`
- `Atteso`:
  - reindirizzamento a `/login` con messaggio chiaro `Link scaduto, richiedine uno nuovo`
  - nessuna eccezione widget tree
- `Stato attuale`: FAIL - schermata rossa `Assertion failed: urlPathToCompare.startsWith(newMatchedLocationToCompare) is not true` da `go_router-17.1.0/lib/src/match.dart:256:12`. Console riporta `[AuthFlow] Handle callback ... error=otp_expired` seguito da exception widget tree.
- `Note`: probabile fix con upgrade a `go_router 17.2.3` (changelog ha fix simili) oppure intercettare i query param di error nell'auth callback prima del redirect, evitando il match con la rotta corrente.

### TC-WT-02

- `Tipo`: privacy, gdpr, dati
- `Titolo`: nessun documento personale visibile come immagine pubblica spot
- `Priorita`: P0
- `Precondizioni`: lista spot pubblici
- `Passi`:
  - aprire `/#/spots`
  - osservare la prima card visibile (slug spot creato da utenti)
- `Atteso`:
  - immagine pertinente al luogo o placeholder neutro
  - nessun documento di identita' o dichiarazione legale visibile
- `Stato attuale`: FAIL - lo spot `Claudia Ferri Luogo` (visibile in cima a `/spots`) ha come cover una scansione di documento legale con dati personali (campi `Sig.r/Sig.ra`, `carta d'identita' nr.`, indirizzo). Anche il nome dello spot e il subtitle includono il nome utente concatenato (`Claudia Ferri Luogo`, `Claudia Ferri Citta' · Rho`), suggerendo errore di seed/import.
- `Note`: rimozione/oscuramento immagine immediato dal Storage Supabase, pulizia campi nome/citta' tramite query Supabase admin, audit di altri spot pubblici per pattern simili.

### TC-WT-03

- `Tipo`: design system, regressione
- `Titolo`: track detail page coerente con theme light dell'app
- `Priorita`: P1
- `Precondizioni`: una pista pubblica esistente
- `Passi`:
  - aprire `/#/track/<slug>`, es. `/#/track/arena-rc-bologna`
  - confrontare visivamente con `/#/`, `/#/tracks`, `/#/spots`, `/#/shops`, `/#/events`
- `Atteso`:
  - background `paper`/`warmWhite` coerente con il resto dell'app
  - card chiare con bordi sottili, secondo `docs/design-system.md`
- `Stato attuale`: FAIL - track detail e' renderizzato con fondo scuro (graphite) e card scure, in netto contrasto con tutte le altre pagine (light). Isola di dark in app altrimenti light.
- `Note`: decisione di prodotto richiesta. Opzione A: e' pattern intenzionale (cockpit pista) → dichiararlo come `ContextualDarkSurface` in `docs/design-system.md`. Opzione B: bug di regressione → riportare a light. File implicato: `lib/features/tracks/presentation/track_detail_screen.dart`. Vedi anche TC-038 (hero garage scura, ma e' pattern dichiarato).

### TC-WT-04

- `Tipo`: responsive, UX
- `Titolo`: stat cards home leggibili in mobile
- `Priorita`: P2
- `Precondizioni`: viewport <= 480px (smartphone)
- `Passi`:
  - aprire `/#/` con viewport 420px
  - osservare le 3 stat cards (`Piste aperte`, `Eventi questa settimana`, `Nuovi spot questo mese`)
- `Atteso`:
  - layout collassa a 1 colonna o 2x2 grid sotto `AppBreakpoints.cardStack` (720)
  - label leggibile, numero leggibile
- `Stato attuale`: FAIL - le 3 stat cards restano in 3 colonne fisse anche a 420px. Numero leggibile ma label `Eventi questa settimana` e `Nuovi spot questo mese` troncati o microscopici.
- `Note`: file `lib/features/community/presentation/community_home_screen.dart`. Aggiungere `LayoutBuilder` o `Wrap` con `runAlignment` per consentire collasso.

### TC-WT-05

- `Tipo`: responsive, UX, navigazione
- `Titolo`: bottom nav mobile ergonomica con voci limitate
- `Priorita`: P2
- `Precondizioni`: utente admin autenticato, viewport <= 480px
- `Passi`:
  - aprire qualsiasi pagina con viewport 420px
  - osservare la NavigationBar in basso
- `Atteso`:
  - massimo 4-5 voci primarie visibili (Material Design guideline)
  - voci secondarie in overflow `More` o drawer
  - nessun testo wrappato su 2 righe
- `Stato attuale`: FAIL - NavigationBar mostra tutte le 10 voci (Home, Piste, Vicino a te, Spot, Eventi, Negozi, Gestione, Garage, Profilo, Admin). `Vicino a te` wrappa su 2 righe, le icone diventano minuscole, tap area inadeguato.
- `Note`: file `lib/core/widgets/app_scaffold.dart`. Limitare `_destinations` mostrate in mobile a 5 (Home, Piste, Vicino a te, Garage, Profilo) e mettere il resto in un drawer/menu accessibile da icona overflow.

### TC-WT-06

- `Tipo`: design system, UX
- `Titolo`: badge `Build pubblica` con tone semantico corretto
- `Priorita`: P3
- `Precondizioni`: una build pubblica nel garage utente
- `Passi`:
  - aprire `/#/garage`
  - osservare la BuildCard
- `Atteso`:
  - badge `Build pubblica` con tone success (verde) o neutral, non info (blu)
- `Stato attuale`: FAIL - badge `Build pubblica` usa tone info (blu), che nel design system identifica info neutra. Visibilita' positiva e' meglio espressa da success (verde).
- `Note`: file `lib/features/garage/presentation/garage_screen.dart`, `_BuildCard`. Cambio di una sola riga.

### TC-WT-07

- `Tipo`: design system, UX
- `Titolo`: data evento non duplicata su card
- `Priorita`: P3
- `Precondizioni`: lista eventi con almeno un evento futuro
- `Passi`:
  - aprire `/#/events`
  - osservare una event card (es. `Gara Offroad Parma`)
- `Atteso`:
  - data visibile in una sola posizione (preferibilmente come pill su media a sinistra per scannability)
- `Stato attuale`: FAIL - la data appare due volte: come pill sul media slot a sinistra (es. `Dom 14 Giu`) e come prima Pill nei signals row (stessa data). Ridondanza visiva.
- `Note`: file `lib/features/events/presentation/events_screen.dart`. Rimuovere la pill data dai signals oppure dal media, scegliere uno.

### TC-WT-08

- `Tipo`: design system, UX
- `Titolo`: location negozio in subtitle, non concatenata al body
- `Priorita`: P3
- `Precondizioni`: lista negozi con almeno un negozio
- `Passi`:
  - aprire `/#/shops`
  - osservare card es. `Track Store Bologna`, `Scalerun Milano`
- `Atteso`:
  - body card contiene solo descrizione/tagline
  - location compare nel subtitle del PlaceCard
- `Stato attuale`: FAIL - location concatenata al body con middledot, es. `Tutto per il modellismo RC: piste, elettronica, bodyshell e messa a punto. · Bologna`. Non valorizza lo slot `subtitle` di `PlaceCard`.
- `Note`: file `lib/features/shops/presentation/shops_screen.dart`. Passare `subtitle: shop.city` al `PlaceCard` e rimuovere la concatenazione nel body.

### TC-WT-09

- `Tipo`: feature, UX
- `Titolo`: distanza in km visibile su `Vicino a te`
- `Priorita`: P3
- `Precondizioni`: utente con localizzazione attiva, almeno una pista pubblica
- `Passi`:
  - aprire `/#/nearby`
  - osservare le card pista e negozio
- `Atteso`:
  - distanza dal'utente prominente nel signals row come Pill primaria, es. `1,4 km` con tone signal
- `Stato attuale`: FAIL - le card mostrano StatusBadge + `X servizi` come signals, ma non la distanza, che e' l'identita' stessa della pagina. Probabile dato gia' calcolato nel provider ma non passato al PlaceCard.
- `Note`: file `lib/features/discovery/presentation/nearby_screen.dart`, `_NearbyPreviewCard`. Aggiungere Pill distanza come primo elemento dei signals.

### Cose verificate funzionanti (smoke OK)

- foundation tokens `AppColors`/`AppSpacing`/`AppRadius`/`AppBreakpoints` applicati ovunque, banner impersonificazione e tagline pill coerenti
- `ContentScaffoldHeader` unificato in tutte le pagine principali con login/profile, ambient banner, language switcher
- navigation rail desktop a 1400px: voci `Gestione` e `Admin` filtrate per ruolo, indicatore selezione coerente
- responsive transition NavigationRail to NavigationBar a `AppBreakpoints.navRail` (1100) funziona correttamente
- statistiche home reali da Supabase (6 piste, 7 eventi, 1 spot)
- activity feed community popolato (4+ item) con type badge corretti e CTA `Vado oggi` + `Dettagli`
- /tracks: PlaceCard 2-col grid, StatusBadge `APERTA` verde, category pill, service pill su media, CTA `Iscrivimi` + heart preferito
- /spots: PlaceCard layout Row, gradient placeholder per spot senza foto, typeBadge specialty
- /shops: PlaceCard con typeBadge `Negozio` info blu, specialty pills max 3+N, CTA `Apri scheda`
- /events: PlaceCard con date pill prominente, creator pill, CTA `Apri evento` + share
- /nearby: variante compact PlaceCard, typeBadge per tipo (`Piste`/`Negozi`), filter chips
- /spots/map: mappa unificata MapTiler con marker piste+spot interattivi, side panel detail
- /garage: hero scuro con stat pills `1 modelli in vetrina`, BuildCard tokenizzata, action buttons coerenti
- /profile: hero scuro con avatar, status pills (`Accesso attivo`, `Italiano`, `Admin reale`), 4 stat cells, sezione Identita'
- /manager: hero scuro, sezione `Piste assegnate` con relazione `track_managers` reale (`Lainatina`)
- /admin: pannello con tab Dashboard/Approvazioni/Utenti/Piste/Negozi/Eventi, overview operativa con counter reali (9 utenti, 10 piste, 8 negozi, 16 eventi, 0 da approvare)
- /onboarding: 4 step progress (`Chi sei` / `Interessi` / `Zona` / `Riepilogo`), 3 opzioni profilo iniziali
- sessione admin persistita correttamente da run a run nonostante magic link scaduto

### Aree non ancora coperte da questo walkthrough

- /spot/<slug> detail
- /shop/<slug> detail
- /event/<eventId> detail
- /u/<publicSlug> public profile
- form di creazione: /shops/new, /manager/tracks/new, /submit-place
- editor: /shop/<slug>/edit, /manager/tracks/<slug>/edit, /manager/tracks/draft/edit
- pagine legali: /legal/privacy, /legal/terms, /legal/cookies
- 404
- click chain reali (es. `Iscrivimi` → conferma → riflesso in `Oggi in pista`)
- ricerca + filter combinati su `/tracks`
- mobile responsive sotto i 720 per pagine non Home

### Suggerimento di priorita' fix

1. TC-WT-02 (privacy): rimozione immediata del documento personale dal record spot pubblico. **Nota 2026-05-07**: il dato e' di test e verra' cancellato al passaggio in produzione, quindi non urgente.
2. TC-WT-01 (auth crash): fix go_router upgrade o handler difensivo per evitare schermata rossa su link scaduto.
3. TC-WT-03 (track detail dark): decisione di prodotto e allineamento.
4. TC-WT-05 / TC-WT-04 (responsive mobile): doppio fix su navigation e stat cards.
5. TC-WT-09 / TC-WT-08 / TC-WT-07 / TC-WT-06: rifiniture, costo basso, alto impatto percepito.

## Walkthrough regression completa 2026-05-07 (sessione 2)

Seconda pass come admin loggato a 1400px, regression su tutte le pagine: detail, form di creazione, editor, admin tabs, action chains, legal/404. Le entry sotto sono tutte test che FALLISCONO con repro/expected/actual.

### TC-WT-10

- `Tipo`: regressione, navigazione, integrazione mappa
- `Titolo`: pulsante `Apri mappa` su /nearby apre la mappa interna PitLap
- `Priorita`: P1
- `Precondizioni`: utente autenticato, pagina `/nearby` aperta
- `Passi`:
  - aprire `/#/nearby`
  - cliccare il pulsante `Apri mappa` (in alto a destra sopra la lista card)
- `Atteso`:
  - apertura della mappa interna (`/spots/map`) con i marker pista+spot+negozio reali del DB centrati sull'utente
- `Stato attuale`: FAIL - apre **Google Maps esterno** in nuova tab con ricerca generica `https://www.google.com/maps/search/modellismo+rc+Bologna/...`. L'utente esce dall'app e riceve risultati Google generici, non i dati PitLap.
- `Note`: il behaviour `Apri mappa` deve invece navigare in-app a `/spots/map` (la mappa unificata Flutter/MapTiler che ho gia' verificato funzionante, mostra marker pista+spot interattivi). Probabile che il CTA chiami `launchUrl` con una stringa Google Maps invece di `context.go('/spots/map')`. File: `lib/features/discovery/presentation/nearby_screen.dart`.

### TC-WT-11

- `Tipo`: regressione, navigazione, integrazione mappa
- `Titolo`: pulsante `Vicino a me` su /nearby fornisce esperienza in-app
- `Priorita`: P1
- `Precondizioni`: utente autenticato, pagina `/nearby` aperta
- `Passi`:
  - aprire `/#/nearby`
  - cliccare il pulsante `Vicino a me` (in alto a destra sopra la lista card)
- `Atteso`:
  - geolocalizzazione utente (con permesso) e refresh della lista o apertura mappa interna centrata
- `Stato attuale`: FAIL - apre Google Maps esterno con query letterale `https://www.google.com/maps/search/?api=1&query=Vicino%20a%20me`. La pagina chiamata letteralmente "Vicino a te" diventa Google con la stringa "Vicino a me" come search query - comicamente rotto.
- `Note`: anche questo deve essere reimpostato per usare la mappa interna o aggiornare la lista nearby con sort by distance dalla geolocation utente. Combinato con TC-WT-09 (manca distanza km) suggerisce che il dato distanza non viene calcolato/mostrato e i CTA della pagina non hanno un comportamento in-app coerente. File: `lib/features/discovery/presentation/nearby_screen.dart`.

### TC-WT-12

- `Tipo`: regressione, dati, ownership
- `Titolo`: editor negozio mostra i dati del negozio specificato dallo slug
- `Priorita`: P2
- `Precondizioni`: utente admin autenticato, negozio pubblico esistente con slug `track-store-bologna`
- `Passi`:
  - aprire `/#/shop/track-store-bologna/edit`
  - osservare i campi del form
- `Atteso`:
  - form precompilato con `Track Store Bologna` come nome, citta' Bologna, indirizzo Via Stalingrado 34, telefono +39 051 777 654
- `Stato attuale`: FAIL - il form mostra `RC Parts Parma` come nome, sottotitolo `Ricambi, elettronica, supporto box`, tutti gli altri campi (Citta', Indirizzo, Sito web, Societa') vuoti. Sembra che l'editor stia mostrando un draft locale residuale invece dei dati reali dello slug richiesto.
- `Note`: probabile bug nel `EditableShopDraftsController` che riusa il draft cached invece di fare fetch del negozio dello slug attivo. File: `lib/features/shops/presentation/shop_editor_screen.dart` + `lib/features/shops/application/shop_editor_providers.dart`.

### TC-WT-13

- `Tipo`: design system, regressione
- `Titolo`: hero pattern coerente tra detail page
- `Priorita`: P3
- `Precondizioni`: dati reali per pista, spot, negozio, evento
- `Passi`:
  - aprire in sequenza `/#/track/<slug>`, `/#/spot/<slug>`, `/#/shop/<slug>`, `/#/event/<id>`
- `Atteso`:
  - tutte le hero seguono lo stesso pattern (tutte dark, tutte light, oppure il pattern e' dichiarato e differenziato per categoria)
- `Stato attuale`: FAIL - track detail e spot detail hanno hero **scura** (graphite); shop detail e event detail hanno hero **light**. Inconsistenza non motivata in `docs/design-system.md`.
- `Note`: vedi anche TC-WT-03. Decisione di prodotto: estendere il pattern dark a tutti i detail page (evoca cockpit pista, ma su negozio o evento e' meno naturale), oppure portare track/spot a hero light come shop/event. Documentare la scelta in `design-system.md`.

### TC-WT-14

- `Tipo`: UX copy, design system
- `Titolo`: form negozio non contiene testi da sviluppo
- `Priorita`: P3
- `Precondizioni`: utente autenticato
- `Passi`:
  - aprire `/#/shops/new` o `/#/shop/<slug>/edit`
  - leggere il titolo della prima section
- `Atteso`:
  - copy production-ready, es. `Dati negozio` o `Scheda negozio`
- `Stato attuale`: FAIL - section title `Modalita' profilo negozio` con descrizione `Qui puoi simulare l'editing di un profilo negozio: copertina, contatti, orari e note utili per l'utente finale`. Il termine "simulare" e' da copy di sviluppo, non da prodotto live. Anche `/shop/<slug>/edit` ha title `Dettaglio negozio` con sottotitolo `Scheda iniziale per <slug>` che sembra debug-info.
- `Note`: file `lib/features/shops/presentation/shop_editor_screen.dart`. Riprendere la copy con il `ux-copy` skill.

### TC-WT-15

- `Tipo`: design system, UI
- `Titolo`: campi form (Indirizzo, Sito web) coerenti con altri input
- `Priorita`: P3
- `Precondizioni`: nessuna
- `Passi`:
  - aprire `/#/shops/new` o `/#/manager/tracks/<slug>/edit`
  - osservare i bordi e il fill dei campi del form
- `Atteso`:
  - tutti i campi hanno lo stesso stile (bordo `borderSubtle/Strong`, fill `panel`/`white`)
- `Stato attuale`: FAIL - i campi `Indirizzo` e `Sito web` hanno fondo grigio chiaro e bordo sottile, mentre `Nome`, `Sottotitolo`, `Citta'` hanno fondo bianco con bordo leggermente diverso. Visibile come "buco" visivo.
- `Note`: probabile che `Indirizzo` sia un `PlaceField` (autocomplete tramite `place_picker_field.dart`) che ha un proprio styling. Allineare con `inputDecorationTheme` del theme principale.

### TC-WT-16

- `Tipo`: regressione, dati
- `Titolo`: profilo pubblico accessibile via slug corrispondente all'utente
- `Priorita`: P3
- `Precondizioni`: utente con `public_slug = 'santorello'` esistente
- `Passi`:
  - aprire `/#/u/santorello`
- `Atteso`:
  - profilo pubblico dell'utente santorello visibile
- `Stato attuale`: FAIL - empty state `Profilo non trovato. Il profilo "santorello" non esiste o non e' pubblico.` Eppure l'utente santorello esiste come admin nel pannello admin. Probabilmente il `public_slug` reale e' diverso dal nome utente, oppure il profilo non ha `is_public=true`.
- `Note`: verificare in DB il valore reale di `public_slug` per santorello. Eventualmente il flow di onboarding non lo crea per default, va settato dal profilo. Il copy dell'empty state e' chiaro, quindi non e' un bug di rendering.

### TC-WT-17

- `Tipo`: feature, UX
- `Titolo`: event detail con CTA principale RSVP o calendar
- `Priorita`: P3
- `Precondizioni`: evento futuro pubblico esistente
- `Passi`:
  - aprire `/#/event/<id>` di un evento futuro
  - osservare i CTA
- `Atteso`:
  - oltre a `Condividi`, almeno un CTA tra `Mi interessa`/`RSVP` o `Aggiungi al calendario`
- `Stato attuale`: FAIL - solo `Condividi` come CTA. Mancano azioni di engagement diretto. Anche manca la posizione orario completa (solo `Dom 14 Giu` senza ora) e nessuna foto evento (anche se il media slot c'e' nelle card lista).
- `Note`: file `lib/features/events/presentation/event_detail_screen.dart`. Aggiungere RSVP leggero (anonimo o login-gated) e/o `Aggiungi a Google Calendar/iCal` con file ICS download.

### TC-WT-18 (verifica)

- `Tipo`: design system, documentale
- `Titolo`: pattern hero scura su detail dichiarato esplicitamente
- `Priorita`: P3
- `Precondizioni`: nessuna
- `Passi`:
  - aprire `/#/track/<slug>`, scorrere giu' fino a `Meteo pista` e `Oggi in pista`
  - confrontare hero scura vs body light
- `Atteso`:
  - il pattern "hero dark + body light" e' dichiarato in `docs/design-system.md` come pattern di "context dashboard" o "cockpit"
- `Stato attuale`: FAIL parziale - vedi TC-WT-03. La hero dark sotto-utilizza i token dark gia' presenti in AppColors (darkSurface, darkScaffold, darkBorder) ma non e' nominato come pattern. Confermo che e' verosimile sia intenzionale (sezione status/condizioni della pista evoca dashboard tecnico), ma serve sancirlo.
- `Note`: nessuna azione tecnica necessaria, solo documentale. Aggiungere sezione `Pattern: ContextualDarkHero` a `design-system.md` con i casi d'uso (track detail, spot detail, garage hero, profile hero, manager hero).

### Cose verificate funzionanti (regression OK)

- /track/<slug>: hero scura con stat cards (Presenze, Meteo, Servizi, Preferiti), category pills, service pills, descrizione, CTA Iscrivimi+heart funzionanti, sezione Meteo light con forecast 3 giorni Open-Meteo + attribuzione, sezione "Oggi in pista" con conteggi aggregati e stato personale
- /spot/<slug>: hero scura con typeBadge + 3 info pills (Ideale per, Terreno, foto count), CTA Modifica spot + Apri mappa, section Preview visuale con 3 placeholder "Archivio in arrivo", section Panoramica spot
- /shop/<slug>: hero light con typeBadge + location pill, CTA Modifica negozio + heart, section Contatti con telefono cliccabile + indirizzo + CTA Chiama / Indicazioni
- /event/<id>: layout light, typeBadge + title + location + data + creator + CTA Condividi, section Panoramica con descrizione + 3 chip
- /shops/new: form completo con Nome/Sottotitolo/Citta'/Indirizzo/Sito web/Societa', sezione Immagine copertina + galleria
- /manager/tracks/new: hero scura con 4 status pills (Card pubblica, Servizi, Invio, Prontezza %), checklist invio 0/5, layout 2-col Identita' + Preview card live
- /submit-place?type=spot: dropdown tipologia, form Nome luogo + Citta' + Indirizzo, CTA Usa posizione attuale, descrizione
- /manager/tracks/<slug>/edit: form precompilato con dati reali della pista (nome, slug, citta', paese, indirizzo, URL mappa, descrizioni)
- /admin: 4 sezioni accessibili (Approvazioni, Utenti con search+filter ruoli, Piste con CTA Apri/Editor/Rifiuta/Elimina + 10 categorie pista come chip eliminabili, Negozi con CTA Apri/Editor/Rifiuta/Nascondi/Elimina), 9 utenti reali con ruoli pill colorati
- Iscrivimi flow: bottom sheet `Sto arrivando` con 3 opzioni `Confermo` / `Forse` / `Annulla` con descrizioni e chevron. UX flow OK.
- /legal/privacy: pagina light con 4 section card (Dati raccolti, Finalita', Basi giuridiche, Diritti dell'interessato). NB: pagina naked senza nav rail/bottom (intenzionale).
- 404: pagina dedicata light con "PitLap" logo + "404" + "Pagina non trovata" + descrizione + CTA "Torna alla home" funzionante. NB: anche qui naked senza nav.

### Aree non coperte (rimandate a sessione futura)

- /onboarding step 2-3-4 (visto solo step 1 nella sessione precedente)
- ricerca pista con risultati: digitare testo nel search e verificare filter (TC-010 esistente)
- combinazione search + chip filter su /tracks (TC-011 esistente)
- toggle preferiti pista da guest (redirect login - TC-008)
- cambio lingua IT/EN dal profilo + persistenza dopo reload (TC-032)
- editor /manager/tracks/draft/edit con `initialDraft`
- approvazioni /admin con elemento pending (oggi 0)
- click flow event create end-to-end (form → save → dettaglio)
- click flow build create end-to-end
- click flow shop create end-to-end con immagini reali

### Suggerimento priorita' fix sessione 2

1. **TC-WT-10 + TC-WT-11** (P1, breve): /nearby attualmente apre Google Maps esterno per entrambi i CTA principali. Sostituire con navigazione interna a /spots/map e geolocalizzazione utente. Questo e' anche il prerequisito per "rendere figa" /nearby (richiesta esplicita 2026-05-07).
2. **TC-WT-12** (P2, breve): editor negozio mostra dati di un altro shop - bug di stato/cache. Verifica nel `EditableShopDraftsController`.
3. **TC-WT-13** + **TC-WT-18** (P3, decisione): unificare hero pattern e dichiararlo. Scelta consigliata: estendere dark hero anche a shop/event detail (gia' fatto su track/spot/garage/profile/manager).
4. **TC-WT-14** (P3, breve): rinominare copy form negozio (rimuovere "Modalita' profilo / simulare" e "Scheda iniziale per <slug>").
5. **TC-WT-17** (P3, medio): aggiungere CTA RSVP/Aggiungi al calendario su event detail per chiudere il loop di engagement.

## Walkthrough regression - sessione 3 followup (2026-05-07)

Findings emersi durante la verifica runtime dei fix sessione 2.

### TC-WT-19

- `Tipo`: regressione, admin, dati
- `Titolo`: card riepilogo Approvazioni admin aggrega tutti gli elementi pending
- `Priorita`: P2
- `Precondizioni`: utente admin loggato, almeno una pista o negozio in stato `pending` nel DB
- `Passi`:
  - aprire `/#/admin`
  - osservare la card di riepilogo `Approvazioni` in cima alla pagina
  - confrontare con la lista completa Piste e Negozi sotto, che mostra elementi con badge `pending` e CTA `Approva`/`Rifiuta`
- `Atteso`:
  - la card `Approvazioni` lista (o conta correttamente) tutti gli elementi pending: piste + negozi + spot
- `Stato attuale`: FIXED (sessione 3) - `adminOverviewProvider` chiamava solo `countPendingTracks()`, hardcodando il conteggio pending senza includere i negozi. Aggiunto `countPendingShops()` nel repository e aggregato `pendingApprovalsCount: pendingTracks + pendingShops`.
- `Note`: file modificato `lib/features/admin/application/admin_providers.dart`. La firma pubblica di `adminOverviewProvider` è invariata. Gli spot non hanno ancora un flow di approval status nel DB, quindi non conteggiati (da aggiungere se il modello spot evolve).

### TC-WT-20

- `Tipo`: regressione, ownership, permessi
- `Titolo`: editor shop carica anche i dati di shop in stato pending
- `Priorita`: P2
- `Precondizioni`: utente admin o owner di un negozio in stato `pending` (non ancora approvato)
- `Passi`:
  - aprire `/#/shop/<slug>/edit` di un negozio pending
- `Atteso`:
  - il form precompilato con i dati attuali (anche se non ancora pubblici)
- `Stato attuale`: FIXED (sessione 3) - `fetchShopBySlug` filtrava con `.eq('is_public', true)`, escludendo i pending (is_public = false). `editableShopOrPublishedProvider` chiamava quel metodo e riceveva null. Fix: aggiunto `fetchBySlugIncludingDrafts` in `EditableShopsRepository` (query senza filtro is_public, RLS Supabase gestisce l'accesso). Il provider ora usa questo metodo. `publicShopDetailProvider` e home continuano a usare `fetchShopBySlug` con filtro is_public invariato.
- `Note`: file modificati `lib/features/shops/application/shop_editor_providers.dart`. L'import di `public_shops_provider.dart` rimosso dall'editor (non più necessario). `editableShopOrPublishedProvider` ora restituisce anche `approvalStatus` reale dal DB (non più hardcodato a 'approved').

### Sintesi fix verificati runtime sessione 2

| TC | Fix | Status runtime |
|---|---|---|
| TC-WT-09/10/11 | /nearby Apri mappa naviga in-app | OK |
| TC-WT-12 (v2) | editor shop popolato da fetch async | OK su shop approved, fail su pending (vedi TC-WT-20) |
| TC-WT-01 | auth crash su otp_expired | non testato runtime (serve link scaduto reale) |
| TC-WT-13/18 | pattern ContextualDarkHero documentato | OK doc, hero track ancora dark coerente |
| TC-WT-14 | copy form negozio production-ready | OK ("Modifica negozio" / "Dati negozio") |
| TC-WT-15 | PlaceField allineato | OK (gia' allineato) |
| TC-WT-06 | Build pubblica tone success verde | OK |
| TC-WT-07 | data evento solo sul media | OK |
| TC-WT-08 | location shop in subtitle | OK

## Walkthrough sessione 3 (2026-05-09): flusso operativo track_organizer + shop_owner

Test end-to-end del flow di creazione pista (impersona Lorenzo Bianchi - track_organizer) e creazione negozio (impersona Davide Moretti - shop_owner) come admin loggato.

### TC-WT-21

- `Tipo`: regressione, navigazione, UI
- `Titolo`: navigazione tra rotte non lascia widgets sovrapposti
- `Priorita`: P2
- `Precondizioni`: utente loggato, qualsiasi rotta caricata
- `Passi`:
  - aprire `/#/manager/tracks/new` (lasciare caricare)
  - navigare a `/#/manager` cliccando voce sidebar
- `Atteso`:
  - la rotta destinazione si renderizza pulita, senza widget della rotta precedente sovrapposti
- `Stato attuale`: FAIL - lo Scaffold della rotta precedente (titolo, descrizione, hero, card) rimane visibile sotto la rotta nuova. L'overlay dura per piu' frame ed e' chiaramente visibile in screenshot. Visibile su tutti i navigate go_router fra rotte top-level, dopo aver creato una bozza pista. Il refresh hard (F5) pulisce.
- `Note`: probabile leak di state nello Scaffold/CustomScrollView quando la pagina precedente non viene smontata correttamente. Verificare se ContentScaffold dispone correttamente i child al cambio rotta. Possibile interazione fra `ListView`/`CustomScrollView` e l'animazione di transizione di go_router.

### TC-WT-22

- `Tipo`: regressione, sessione, admin
- `Titolo`: impersonazione admin persistente al reload (F5)
- `Priorita`: P3
- `Precondizioni`: admin loggato, impersonazione attiva (banner "Vista come ...")
- `Passi`:
  - attivare impersonazione di un utente da `/admin > Utenti > 👁`
  - premere F5 sul browser per ricaricare
- `Atteso`:
  - impersonazione mantenuta dopo reload, banner ancora visibile
- `Stato attuale`: FAIL - reload F5 perde lo stato `impersonationProvider`, la sidebar torna a mostrare le voci di admin santorello, banner sparito. Bisogna ri-impersonare manualmente.
- `Note`: probabile che `impersonationProvider` sia un `StateNotifierProvider` non persistito su `SharedPreferences`. Persistere su localStorage con scadenza temporale (es. 1 ora) per evitare riavvii fastidiosi durante sviluppo/QA. Bassa priorita' perche' shippable senza fix, alto fastidio per QA.

### TC-WT-23

- `Tipo`: regressione, dati, ownership
- `Titolo`: bozza pista creata da track_organizer visibile in /manager dopo save
- `Priorita`: P2
- `Precondizioni`: track_organizer loggato (Lorenzo Bianchi via impersonazione admin), almeno un campo nome/citta'/descrizione/servizio popolato in `/manager/tracks/new`
- `Passi`:
  - aprire `/#/manager/tracks/new` come Lorenzo Bianchi
  - compilare Nome="Pista RC Test Lorenzo", Citta'="Bologna", Descrizione, selezionare 2 servizi
  - cliccare `Salva bozza`
  - osservare snackbar di conferma
  - navigare a `/#/manager`
- `Atteso`:
  - la bozza compare nelle "Piste assegnate" o in una sezione "Bozze in lavorazione" dedicata
- `Stato attuale`: FAIL - snackbar "Bozza pista salvata in Gestione" visibile, counter pubblico admin "Piste totali" passato da 10 a 11 (quindi salvata su DB), MA in `/manager` la lista "Piste assegnate" mostra solo le 4 piste assegnate via `track_managers`, NON la bozza appena creata.
- `Note`: probabile che la query di `/manager` mostri SOLO piste con record in `track_managers` per quell'utente, escludendo le bozze appena create che non sono ancora linked. Soluzione: il flow di save bozza dovrebbe auto-creare un record `track_managers` per il creatore, oppure aggiungere una sezione separata "Bozze in lavorazione" che cerca per `created_by = effectiveUserId`.

### TC-WT-24

- `Tipo`: regressione, permessi, blocking
- `Titolo`: shop_owner accede al form di creazione negozio
- `Priorita`: P1
- `Precondizioni`: utente con role `shop_owner` autenticato, NON ancora manager di alcun negozio
- `Passi`:
  - impersonare Davide Moretti (shop_owner) da admin
  - aprire `/#/shops/new`
- `Atteso`:
  - form completo visibile: Nome negozio, Sottotitolo, Citta', Indirizzo, Sito web, Societa' o negozio, Immagine copertina, Galleria foto
- `Stato attuale`: FAIL - shop_owner vede SOLO la sezione "Link e canali" con messaggio "Nessun link pubblico aggiunto." Il form di creazione (titolo "Dati negozio" e tutti i campi) e' completamente invisibile. Confermato che lo stesso URL come admin santorello mostra il form completo correttamente.
- `Note`: probabile gating del form dietro `canManageShopsProvider` o equivalente che ritorna false per shop_owner non ancora linkati a uno specifico shop via `shop_managers`. Paradosso: per creare il primo negozio devi essere gia' manager di un negozio. Soluzione: il form di creazione deve essere accessibile a chiunque abbia role `shop_owner` (o anche `user`), e il save deve auto-creare il record `shop_managers` linkando l'utente come owner del nuovo shop. File implicato: `lib/features/shops/presentation/shop_editor_screen.dart` + `lib/features/shops/application/shop_permissions_providers.dart`.

### Cose verificate funzionanti (sessione 3)

- impersonazione admin via 👁 in `/admin > Utenti > shop_owner|track_organizer` filter chip: banner "Vista come ... · ruolo" + snackbar di feedback OK
- filter chip ruoli admin (Tutti / user / track_org / shop_owner / admin): conteggio coerente (es. "2 profili (shop_owner)")
- `/manager` come track_organizer Lorenzo Bianchi: hero scura "Pochi strumenti, molto chiari" con pill di 4 piste assegnate via `track_managers` reali, sezione "Piste assegnate" con CTA Apri/Modifica scheda per ognuna
- `/manager/tracks/new` come track_organizer: tutto il form caricato, hero "Scheda pista completa" con 4 status pills (Card pubblica, Servizi e label, Invio approvazione, Prontezza X%), checklist progress reattiva (0/5 → 1/5 → 3/5 → 4/5), preview card aggiornata su blur, servizi pill multi-select con tone signal, bottom Azioni con Salva bozza attivo + Invia in approvazione gated finche' checklist non completa
- save bozza pista: snackbar "Bozza pista salvata in Gestione" + counter admin "Piste" incrementato (10 → 11), conferma persistenza Supabase
- `/shops/new` come admin: form production-ready con copy aggiornata "Dati negozio" + "Compila i dati che appariranno sulla scheda pubblica del tuo negozio." (TC-WT-14 v2 confermato runtime)
- click "Esci" sul banner impersonazione: termina impersonazione, rotta corrente preservata

### Suggerimento priorita' fix sessione 3

1. **TC-WT-24** (P1): blocca creazione negozio per shop_owner. E' il flow principale del ruolo, va sbloccato.
2. **TC-WT-21** (P2): overlay rotte e' un bug visivo grave che si nota subito durante QA. Probabile root cause unico per tutto il navigate.
3. **TC-WT-23** (P2): bozza pista invisibile dopo save danneggia UX del track_organizer (vede salvataggio OK ma non puo' continuare a editare).
4. **TC-WT-22** (P3): impersonazione persa al reload, fastidioso ma non bloccante.

### Stato fix sessione 3

| TC | Stato | File toccati | Note |
|---|---|---|---|
| TC-WT-24 | FIXED | `shop_editor_screen.dart` | `canEditShop` ora bypassa l'AsyncValue di `canEditShopSlugProvider` quando `widget.isCreating == true`. Risolve il caso shop_owner non ancora manager di alcun negozio: il form e' sempre visibile in modalita' creazione. |
| TC-WT-23 | FIXED | `track_editor_screen.dart` | Save bozza ora usa `effectiveUserIdProvider` (con fallback a `currentUser.id`) come `submitted_by`, invece di `currentUser.id`. Cosi' la bozza creata da admin in impersonazione viene attributata all'utente osservato e appare correttamente in `submittedTracksProvider` di Lorenzo Bianchi quando si esce da impersonazione. |
| TC-WT-21 | INVESTIGATO, RIMANDATO | - | Diagnosi: probabile interazione tra `ContentScaffold` (`CustomScrollView` + `SliverFillRemaining`) e l'animazione di transizione di `MaterialPage` di go_router. Possibile fix: sostituire `builder` con `pageBuilder` + `NoTransitionPage` su tutte le rotte top-level, oppure forzare key-based remount del child di ContentScaffold. Entrambe le opzioni sono invasive e meritano iterazione dedicata con regression test. F5 pulisce, quindi non e' bloccante per QA. |
| TC-WT-22 | RIMANDATO | - | Persistenza impersonazione su localStorage richiede modifica a `impersonationProvider`. P3, basso valore vs costo. | |
| TC-WT-19 | admin pendingApprovalsCount aggrega tracks + shops | fix applicato, test runtime richiede DB con pending |
| TC-WT-20 | editor shop carica pending via fetchBySlugIncludingDrafts | fix applicato, test runtime richiede shop in stato pending |

## Fix QA E2E 2026-06-10 (D07 / D08 / D09)

| Difetto | Stato | File toccati | Note |
|---|---|---|---|
| D07 | FIXED 2026-06-10 | `app/lib/features/manager/presentation/manager_screen.dart` | Sezione "Bozze e in approvazione" aggiunta nel branch operativo (quando `managedTracks` non è vuota). `submittedTracksProvider` già esistente; la sezione filtra per `approvalStatus != 'approved'` ed è sempre mostrata quando non vuota. |
| D08 | FIXED 2026-06-10 | `app/lib/features/tracks/presentation/track_editor_screen.dart`, `app/lib/app/l10n/arb/app_it.arb`, `app/lib/app/l10n/arb/app_en.arb` | Blocco hard-coded "Servizi e label" sostituito con due sezioni distinte "Categoria pista" e "Servizi disponibili" alimentate da `trackCategoryOptionsProvider` e `trackServiceOptionsProvider` — stesse sorgenti DB usate da "Modifica pista". |
| D09 | FIXED 2026-06-10 | `app/lib/features/tracks/presentation/track_editor_screen.dart`, `supabase/deltas/2026-06-10-draft-taxonomy-policies.sql` | Servizi e categorie persistiti su `track_services`/`track_category_links` in `_saveDraft` e `_submitForApproval` via nuovo metodo `_persistTaxonomy`. Richiede applicazione manuale del delta SQL che aggiunge le policy RLS per il submitter su bozze/pending. |

## Nuovi TC da audit statico 2026-07-29 (cfr. docs/qa-audit-2026-07-29.md)

| TC | Area | Scenario | Atteso | Rif. finding |
|---|---|---|---|---|
| TC-078 | Commenti | Aprire dettaglio di un evento creato localmente (id `created-*`) | Sezione commenti nascosta o funzionante, mai in stato errore | QA-2026-07-29-01 |
| TC-079 | Profilo | Tap su un negozio preferito dal bottom sheet di `/profile` | Apre `/shop/<slug>` con dettaglio corretto (non "non trovato") | QA-2026-07-29-02 |
| TC-080 | Profilo | Aprire i preferiti pista da `/profile` | Nome pista leggibile e tap che apre `/track/<slug>` (niente UUID) | QA-2026-07-29-03 |
| TC-081 | Condividi | Copiare il link di un evento creato localmente e aprirlo in finestra anonima | Link risolvibile oppure azione Condividi nascosta per eventi non pubblicati | QA-2026-07-29-04 |
| TC-082 | Notifiche | Guest apre `/notifications` da URL diretto | Redirect a login o CTA login, non empty state "nessuna notifica" | QA-2026-07-29-05 |
| TC-083 | Notifiche | Tap su notifica "build pubblicata da profilo seguito" | Naviga alla build/profilo dell'autore, non al garage del destinatario | QA-2026-07-29-06 |
| TC-084 | Notifiche | Tap su notifica "nuovo follower" | Naviga a `/u/<slug follower>`, non alla directory `/profiles` | QA-2026-07-29-07 |
| TC-085 | l10n | App in EN: card feed home (azioni Commenta/Condividi/conteggi) | Testi in inglese da ARB, nessuna stringa italiana hardcoded | QA-2026-07-29-08 |
| TC-086 | Liste | `/shops`, `/spots`, `/nearby` con rete assente | Stato errore con retry, non empty state "nessun risultato" | QA-2026-07-29-11 |
