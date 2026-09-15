# QA — Audit browser completo, PitLap su produzione (2026-09-13)

Audit pagina per pagina eseguito da agente automatico sul Chrome collegato,
app `http://localhost:8080` puntata al database **pitlap-prod**, sessione
amministratore. 22 viste percorse, **44 difetti**: 1 bloccante, 9 gravi,
17 medi, 17 minori.

Il registro delle scritture è stato **verificato contro il database**; le
correzioni stanno in fondo. Elenco di pulizia in `qa-temp/cleanup-prod-2026-09-13.md`.

## Difetti bloccanti e gravi

| ID | Pagina | Gravità | Tipo | Sintomo | Evidenza |
|---|---|---|---|---|---|
| A-01 | Eventi / Garage (dialog) | Bloccante | Tecnico | Salvando dal dialog, l'app viene sostituita dalla schermata rossa Flutter. Il record viene creato ma l'utente resta bloccato e deve ricaricare. Riprodotto su 2 flussi diversi | `_dependents.isEmpty is not true` in framework.dart:6268 |
| A-02 | Feedback | Grave | Tecnico | Invio feedback fallisce con errore tecnico grezzo a schermo | `ClientException: Failed to fetch … /functions/v1/submit-feedback`. Causa nota: edge function non deployata su prod |
| A-03 | Piste, Home, Vicino a te | Grave | Funzionale | Piste approvate in Admin continuano a mostrare "DA VERIFICARE" in tutta l'area pubblica: lo stato non si propaga | Badge arancio su card e hero |
| A-04 | Admin → Utenti | Grave | Funzionale | Il campo "Cerca per nome" prende il focus ma non accetta caratteri: ricerca utenti inutilizzabile | Nessun input dopo `type` e dopo singolo tasto |
| A-05 | Spot → Segnala luogo | Grave | Funzionale | Stesso sintomo sul campo indirizzo: lo spot viene creato **senza coordinate** e non è posizionabile in mappa | Placeholder invariato dopo digitazione |
| A-06 | Admin → Utenti | Grave | Funzionale | Tutti i profili elencati come "(senza nome)" con solo ID troncato, nessuna email: impossibile capire chi è chi. Unica azione = rinomina display name, nessun cambio ruolo | Righe "(senza nome) — ID 87648568…" |
| A-07 | Spot / Admin | Grave | Funzionale | La pagina dichiara "contributo moderato" ma lo spot compare **subito** in pubblico. In Admin non esiste alcuna sezione Spot e la coda non lo riceve, pur dichiarando di gestire gli spot | Snackbar + spot in cima a /spots |
| A-08 | Home | Grave | Funzionale | Con 1 evento a 7 giorni, la tile riporta "0 Eventi / 30 giorni" | Admin conta correttamente "Eventi 1" |
| A-09 | Eventi → Crea | Grave | Funzionale | "Nota rapida" salva solo gli **ultimi 2 caratteri** del testo inserito | Testo lungo → salvato "re" |
| A-10 | Spot / Mappa | Grave | Contenuto | 3 spot **demo hardcoded** (Parma, Reggio Emilia, Modena) non presenti a DB, con "3 foto" che sono gradienti. Visibili anche ai non autenticati | /spots, /spots/map |

## Difetti medi

A-11 meteo pista datato 2-4 aprile con data odierna 13 settembre · A-12 chip Admin inerti, sembrano tab · A-13 i 3 pulsanti hero di Gestione non fanno nulla · A-14 pista creata da Gestione non viene collegata all'account ("Nessuna pista assegnata") · A-15 cover URL valida ignorata, l'immagine non viene mai richiesta in rete · A-16 contenuti attribuiti a "Pilota PitLap" mentre il profilo mostra "beppe.apps" · A-17 in impersonazione la Home mostra ancora i dati dell'admin · A-18 tile "Categorie pista" non si aggiorna dopo l'aggiunta · A-19 la mappa cattura la rotella e il dettaglio marker resta irraggiungibile · A-20 Admin Eventi promette controllo visibilità, offre solo il cestino · A-21 **testi di specifica interna mostrati all'utente** ("dovrà controllare nella dashboard reale", "Qui vivranno le operazioni sensibili", "Bozza del primo accesso guidato") · A-22 trofei tutti bloccati (**vedi correzione**) · A-23 categorie "Francobolli" e "Treni" fuori dominio · A-24 primo caricamento con `authError=otp_expired` pur con sessione valida · A-25 lo stesso stato pista etichettato in 4 modi diversi · A-26 "Vicino a te" promette eventi, non ne mostra mai · A-27 notifiche di approvazione all'admin anziché al proprietario, e notifica del proprio commento a sé stessi

## Difetti minori

A-28 accenti resi con apostrofo ("umidita'", "verra'", "portabilita'") · A-29 concordanza numerica ("1 negozi", "1 profili") · A-30 etichette inglesi in UI italiana · A-31 due campi "Luogo" ambigui, evento mai collegato alla pista reale · A-32 "Tre aree chiave" ma ne mostra una · A-33 stato vuoto parla di ricerca inesistente · A-34 pista "Pistona" con slug `/track/pistina` · A-35 "Tocca un marker" su desktop · A-36 payoff EN troncato "Where modeling meets", tag servizi non tradotti · A-37 l'icona caffè apre PayPal senza preavviso · A-38 valori tecnici a vista ("Origine: web_magic_link") · A-39 `/legal/cookie` 404, funziona solo `/legal/cookies` · A-40 titolare GDPR = Gmail personale (scelta nota) · A-41 "Apri mappa" disabilitato senza spiegazione · A-42 card servizi disallineata, barra azioni tagliata a 1132×888 · A-43 "Segnalazione pronta" invece di "inviata" · A-44 UUID senza etichetta in coda approvazioni

## Correzioni al report dell'agente (verificate sul database)

**A-22 non è un difetto.** Le transazioni PitCoin sono rimaste **5 prima e 5 dopo**. Gli amministratori sono esclusi dall'accumulo per progetto: l'agente operava come admin, quindi zero punti e trofei tutti grigi sono il **comportamento corretto**. Il sistema PitCoin va ricollaudato con un account non-admin prima di trarre conclusioni.

**A-08 ha una causa più profonda di un contatore sbagliato.** L'evento creato da `/events` è finito in `community_events`, non in `events`: la tabella `events` è rimasta a **zero righe**. Home e tile contano una tabella, il form di creazione scrive nell'altra. Non è un errore di conteggio, sono due entità diverse che l'interfaccia presenta come una sola.

**A-01, l'allarme "build di debug in produzione" è infondato.** L'app gira via `flutter run`, che produce sempre una build di debug: il percorso locale nel messaggio è conseguenza di questo, non di un rilascio sbagliato. Il crash da asserzione resta invece un difetto reale e serio.

## Aree non coperte

Eliminazioni (vincolo esplicito), logout e cambio account, geolocalizzazione (prompt nativo), upload da file picker, salvataggio dai dialog di modifica (bloccato da A-01), layout a larghezza telefono.
