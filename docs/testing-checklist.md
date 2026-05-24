# Testing Checklist

Checklist di test funzionali e tecnici per PitLap.

Obiettivo:

- avere una base ripetibile di verifica dopo ogni blocco di sviluppo
- coprire sia i flussi core sia i casi limite emersi nel progetto
- tenere visibili le differenze tra persistenza locale, persistenza server-side e fallback

## Stato

Data aggiornamento: `2026-04-09`

## Autenticazione e sessione

1. Aprire la home da guest e verificare che `Garage` e `Profilo` non compaiano nel menu.
2. Aprire manualmente `/#/profile` da guest e verificare redirect al login.
3. Aprire manualmente `/#/garage` da guest e verificare redirect al login.
4. Richiedere magic link con Termini e Privacy attivi e marketing disattivato.
5. Verificare che il callback crei la sessione senza perdere il redirect.
6. Verificare che la lingua preferita venga riletta dopo il rientro.
7. Eseguire logout e verificare ritorno alla parte pubblica.
8. Rientrare con account esistente e verificare assenza di regressioni su profilo e lingua.
9. Verificare che un link scaduto o invalido rimandi al login con messaggio chiaro.

## Consensi e area legale

10. Confermare che `terms_accepted` venga salvato in `user_consents`.
11. Confermare che `privacy_notice_seen` venga salvato in `user_consents`.
12. Confermare che `marketing_email_opt_in` venga salvato separatamente.
13. Verificare riepilogo consensi nel profilo con versione documento, data e source.
14. Aprire `/#/legal/privacy`, `/#/legal/terms` e `/#/legal/cookies` da guest.
15. Verificare che la Privacy Policy mostri il riferimento ai fornitori/API usate dove previsto.

## Piste e home

16. Da guest, premere `Preferiti` su una pista e verificare CTA verso login.
17. Da loggato, salvare/rimuovere un preferito pista e verificare aggiornamento UI.
18. Verificare che il click sul corpo card pista apra il dettaglio come `Vedi pista`.
19. Verificare ricerca testuale su `Piste`.
20. Verificare chip filtro `Buggy`, `Mini-Z`, `Indoor`, `Outdoor`, `Vicino a te`.
21. Usare `Pulisci ricerca` e verificare reset corretto.
22. Cambiare `IT/EN` e verificare coerenza della UI.
23. Verificare che eventuali contenuti dati residuali monolingua siano riconosciuti come tali.

## Dettaglio pista e presenze

24. Aprire una pista e verificare corretto rendering di hero, servizi e meteo.
25. Segnare `Sto arrivando` e verificare aggiornamento di `Oggi in pista`.
26. Segnare `Forse` e verificare stato `maybe`.
27. Usare `Annulla` e verificare stato `cancelled`.
28. Verificare visualizzazione orario ultima registrazione.
29. Verificare che la presenza valga solo per il giorno corrente.
30. Verificare stato personale anche sulla card home pista.

## Meteo pista

31. Su pista con coordinate, verificare che compaia il badge `Meteo live`.
32. In assenza di coordinate o provider disponibile, verificare `Fallback locale`.
33. Verificare presenza dell'attribuzione `Dati meteo forniti da Open-Meteo`.
34. Verificare che il fallback non rompa la UI se il provider esterno fallisce.

## Vicino a te

35. Verificare ricerca e filtri della schermata `Vicino a te`.
36. Cliccare una pista in lista e verificare apertura del dettaglio pista.
37. Cliccare un negozio in lista e verificare apertura del dettaglio negozio.
38. Verificare che la pagina resti utile anche senza mappa dominante.

## Eventi

39. Da guest, premere `Crea evento` e verificare richiesta login.
40. Da loggato, creare un evento e verificare comparsa nella lista.
41. Cambiare pagina e tornare su `Eventi`: l'evento deve restare se previsto dalla persistenza corrente.
42. Aprire una card evento e verificare dettaglio evento coerente.
43. Verificare stato vuoto guidato se non ci sono eventi.

## Negozi

44. Aprire un negozio da guest e verificare sola lettura.
45. Premere `Modifica negozio` da guest e verificare redirect al login.
46. Da loggato, modificare nome, sottotitolo, orari, contatti e note del negozio.
47. Verificare persistenza del draft negozio nel perimetro previsto.
48. Verificare comportamento delle immagini negozio via URL.

## Profilo

49. Modificare nome visibile e verificarne la persistenza.
50. Cambiare lingua dal profilo e verificare effetto globale.
51. Inserire URL foto profilo valido e verificare preview.
52. Inserire URL foto profilo da host problematico e verificare fallback pulito.
53. Verificare che il salvataggio profilo non fallisca anche se la preview immagine fallisce.
54. Verificare link rapidi a `Garage`, `Eventi`, `Informativa Privacy`.
55. Verificare stato accesso visibile nel chrome globale.

## Garage

56. Aggiungere build e verificare comparsa in lista.
57. Cambiare visibilita' build e verificare badge coerente.
58. Verificare leggibilita' pulsanti nella hero scura.
59. Verificare comportamento delle immagini build via URL.

## Preferiti e hub profilo

60. Salvare una pista nei preferiti e verificare conteggio nel profilo.
61. Salvare un negozio e verificare conteggio nel profilo.
62. Verificare che il profilo distingua correttamente preferiti pista, build e negozi.

## Permessi e ruoli

63. Validare semanticamente `guest`, `registered`, `shop owner`, `track organizer`, `admin` contro la matrice documentata.
64. Verificare che le route community sensibili non siano visibili a guest.
65. Verificare che la UI non prometta editabilita' dove non esiste ownership reale.

## Regressioni tecniche

66. Eseguire `flutter analyze`.
67. Eseguire `flutter test`.
68. Verificare log `AuthFlow`, `ConsentFlow`, `ArrivalFlow`, `ProfileFlow` nei flussi principali.
69. Verificare che nuove API/servizi siano registrati in `docs/api-registry.md`.
70. Verificare che nuovi requisiti strutturali siano tracciati in `docs/development-checklist.md`.

## Note operative

- Alcuni flussi oggi hanno persistenza locale, non ancora server-side.
- Le immagini da host esterni possono fallire su web per CORS, hotlink o TLS.
- Le policy RLS e lo schema remoto Supabase vanno sempre riallineati quando si aggiungono nuove tabelle come `track_follows`.
