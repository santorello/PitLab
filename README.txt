Project: PitLane Hub (Working Title)
L'ecosistema digitale per il modellismo dinamico e statico
Confidence Score: 98%
(Basato sulla validazione dei requisiti utente/gestore e fattibilità tecnica 2026)

1. Vision & Obiettivi
Creare un'app di aggregazione per la community del modellismo che risolva il disordine informativo (WhatsApp/Facebook) e fornisca strumenti logistici reali ai gestori di piste e organizzatori di eventi.

Target: Piloti (Buggy, Mini-Z, Mini4WD, Scaler, Bashing) e Gestori di circuiti/club.

Principio Guida: Utilità immediata ("Cosa trovo in pista?") e Socialità ("Chi c'è oggi?").

2. Specifiche Funzionali (MVP - Fase 1)
A. Per i Piloti
Track Snapshot: Visualizzazione del layout attuale e dello stato della pista (Asciutta/Bagnata/Inagibile).

Checklist Servizi: Verifica rapida di: Luce 220V, Aria compressa, Tavoli/Sedie, Bagni, Ristoro.

Sistema "Sto Arrivando": Pulsante per segnalare la propria presenza in tempo reale e vedere chi altro sarà in pista.

Iscrizione Eventi: Calendario gare con registrazione rapida e visualizzazione della Entry List.

Digital Setup: Archivio personale per salvare i settaggi del modello per ogni specifica pista.

B. Per i Gestori
Dashboard di Controllo: Modifica rapida dello stato pista e invio notifiche push ai follower.

Gestione Iscrizioni: Automazione delle liste partecipanti per gare e giornate di prova.

Kit QR Code: Generazione automatica di un QR da esporre ai box per far scaricare l'app o fare il check-in.

3. Categorie Supportate
Buggy/On-Road: Focus su stato terreno e layout.

Mini-Z/Mini4WD: Focus su affluenza sessioni e classi tecniche.

Scaler/Bashing: Mappa dei punti di interesse (POI) e spot di ritrovo.

Coming Soon: Sezione mockata per Ferroviario, Mezzi Agricoli, Militare (per validazione interesse).

4. Stack Tecnico (Architettura)
Frontend: Flutter (Android + WebApp) per un unico codice cross-platform.

Backend: Supabase/Firebase (Serverless) per gestione utenti, database real-time e notifiche.

Mappe: Google Maps API / Mapbox.

Meteo: OpenWeather API integration.

Hosting: Hosting statico per la WebApp (Vercel/Firebase Hosting).

5. Modello di Business Iniziale
Sponsorizzazioni Tecniche: Spazi pubblicitari per negozi di modellismo e brand di settore.

Donazioni: Sistema di supporto "Coffee for the Dev" per la manutenzione.

Fase 2 (PRO): Feature avanzate (Cronometraggio live, Telemetria condivisa, Gestione Campionati complessi).

6. Domande Aperte & Roadmap
[ ] Contenuto Iniziale: Quali sono le prime 5-10 piste "pilota" da mappare per il lancio?

[ ] Validazione: Quale gestore di fiducia può testare il modulo "Iscrizioni"?

[ ] Grafica: Definire il logo e lo stile "Dark Mode" (molto amato nei box).

[ ] Fase 2: Analisi dei protocolli MyRCM/LiveTime per l'integrazione tempi.