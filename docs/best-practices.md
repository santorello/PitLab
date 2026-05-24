# Best Practices

Regole guida permanenti per costruire PitLap in modo coerente, scalabile e professionale.

Obiettivo:

- mantenere una direzione costante nel tempo
- ridurre decisioni impulsive o incoerenti
- proteggere il progetto da complessita' premature

## Principi non negoziabili

1. utilita' prima dell'effetto wow
2. semplicita' operativa prima della feature density
3. leggibilita' prima della decorazione
4. una sola fonte di verita' per ogni dato
5. scalabilita' vera, non overengineering
6. documentazione aggiornata insieme alle decisioni

## Regola prodotto

Ogni feature deve rispondere almeno a una di queste domande:

- aiuta a capire dove andare?
- aiuta a capire com'e' la pista?
- aiuta a capire cosa c'e' in pista?
- aiuta a capire chi c'e' o chi arriva?
- aiuta il gestore a mantenere i dati affidabili?

Se la risposta e' no, la feature va probabilmente rimandata.

## Regola MVP

Per l'MVP:

- preferire workflow corti
- evitare setup lunghi
- evitare configurazioni profonde
- evitare feature social generiche
- evitare integrazioni esterne finche' non servono davvero

## Best practice architetturali

- mantenere il dominio separato da UI e infrastruttura
- evitare logica business nei widget
- evitare accesso diretto a Supabase dalla presentazione
- trattare il backend come sistema estendibile, non come dump di tabelle
- usare naming consistente e stabile fin dall'inizio

## Best practice dati

- usare UUID come chiavi principali dove possibile
- usare enum testuali in inglese per stati e ruoli applicativi
- tenere `created_at` e `updated_at` coerenti ovunque
- progettare i campi pubblici per lettura anonima semplice
- progettare le scritture con ownership chiara
- lasciare spazio allo storico senza forzarlo ovunque nell'MVP

## Best practice Supabase

- separare subito `dev` e `prod`
- scrivere policy minime ma corrette prima di aprire scritture sensibili
- usare realtime solo dove aggiunge valore percepibile
- non abusare di Edge Functions nel bootstrap
- mantenere bucket storage semplici e con naming chiaro

## Best practice Flutter

- struttura a feature
- theme centrale e riusabile
- i18n fin dal primo giorno
- routing chiaro e predicibile
- componenti UI riusabili per pattern ripetuti
- stato server-first con caching leggero dove serve

## Best practice UX

- mostrare prima le informazioni operative
- ogni schermata deve avere una CTA primaria chiara
- badge e stati devono essere leggibili in meno di un secondo
- niente testi lunghi sopra le informazioni pratiche
- evitare layout da social feed
- evitare design troppo corporate o troppo gaming

## Best practice visuali

- massimo un accento cromatico forte per la brand identity
- colori di stato solo con significato semantico
- contrasto alto e gerarchia netta
- motion minima, utile e veloce
- dark mode curata ma non dominante

## Best practice di sviluppo

- ogni nuova decisione importante va documentata
- ogni nuovo documento va indicizzato
- evitare refactor estesi senza motivazione forte
- evitare dipendenze aggiunte senza reale vantaggio
- preferire iterazioni piccole e verificabili

## Best practice di naming

- inglese per codice, schema dati e chiavi tecniche
- italiano e inglese in UI tramite localizzazione
- nomi brevi, espliciti e coerenti
- evitare abbreviazioni oscure

## Best practice per componenti

Ogni componente deve essere:

- chiaro nello scopo
- facilmente riusabile
- facile da leggere
- semplice da testare

Segnali di componente sbagliato:

- conosce troppo del backend
- fa troppe cose insieme
- richiede molte prop poco chiare
- incorpora copy o colori hardcoded

## Best practice per decisioni future

Quando emerge un dubbio:

1. scegliere la soluzione che riduce attrito per l'utente
2. scegliere la soluzione che non blocca estensioni future
3. scegliere la soluzione piu' semplice che resta professionale
4. documentare il motivo della scelta

## Regola: nessun dato condiviso nello stato locale

Qualsiasi dato che deve essere visibile su un altro dispositivo, da un altro utente, o dall'admin deve vivere su Supabase, non in SharedPreferences o in memoria.

Corollari operativi:

- non usare SharedPreferences per entità che attraversano sessioni o utenti diversi
- lo stato locale è ammesso solo per preferenze di navigazione, cache UI effimera, o dati puramente privati e non strutturati
- i `NotifierProvider` Riverpod sono il punto di accesso unico allo stato server; mai creare provider paralleli che duplicano la stessa entità

Segnali che qualcosa sta andando storto:

- un admin su un dispositivo non vede i dati inviati da un organizzatore su un altro
- rimuovere e reinstallare l'app cancella dati che l'utente si aspetta di ritrovare
- un UUID viene usato come slug in una query Supabase

## Anti-pattern da evitare

- inseguire feature per entusiasmo
- usare il realtime ovunque
- creare ruoli troppo complicati troppo presto
- riempire l'interfaccia di card decorative
- aggiungere mappe, telemetria o automazioni senza dati reali che le giustifichino
- far sembrare PitLap un clone di Facebook o Discord

## Regola cross-platform (Android + Web)

PitLap e' distribuito come **web app Flutter** e come **app Android nativa**. Questa non e' un'opzione futura: e' un requisito strutturale fin dall'inizio.

Conseguenze operative non negoziabili:

- ogni schermata deve funzionare bene su schermo mobile (< 400 dp larghezza) e su desktop/tablet
- non usare `dart:html`, `dart:js` o API browser-only senza un equivalente nativo o un guard di platform
- non usare `dart:io` direttamente senza un guard per il web (preferire abstractions di `flutter_platform_aware` o condizionali `kIsWeb`)
- il touch target minimo e' 48x48 dp ovunque: sul web si usa il mouse, su Android il dito
- evitare hover-only UI: tutto cio' che comunica informazione in hover deve avere un equivalente su tap/long-press
- i layout responsive devono testare almeno tre breakpoint: mobile (< 600), tablet (600-1024), desktop (> 1024)
- evitare dipendenze da plugin che non supportano entrambe le piattaforme; verificare il supporto prima di aggiungere
- le notifiche, i permessi e l'accesso filesystem devono usare packaging condizionale con fallback web coerente
- le CTA principali devono essere raggiungibili con il pollice (zona bassa dello schermo su mobile) senza violare la gerarchia visiva su desktop

Quando si progetta una nuova schermata: **disegnarla prima per mobile, poi verificare su desktop** — non il contrario.

## Regola finale

Se una scelta rende PitLap piu' bello ma meno chiaro, meno veloce o meno affidabile, non e' la scelta giusta.
