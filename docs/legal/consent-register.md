# Consent Register

Stato: struttura operativa di riferimento.

Scopo:

- definire quali consensi esistono
- evitare di mescolare consensi facoltativi con condizioni necessarie del servizio
- preparare la futura tracciatura tecnica su database

## Consensi e prese visione previste

### Necessari al servizio

- accettazione Termini di Servizio
- presa visione Informativa Privacy

Note:

- questi elementi vanno tracciati con versione del documento e timestamp
- la privacy notice non e' un consenso marketing

### Facoltativi

- consenso marketing via email
- eventuali preferenze avanzate di personalizzazione non necessarie

Note:

- devono essere separati
- non preselezionati
- revocabili facilmente

## Tracciamento futuro minimo

Per ogni consenso o presa visione conviene registrare:

- `user_id`
- `consent_type`
- `accepted`
- `document_version`
- `timestamp`
- `source`

## Tipi consigliati

- `terms_accepted`
- `privacy_notice_seen`
- `marketing_email_opt_in`
- `personalization_opt_in`

## Stato prodotto

Al momento:

- marketing resta opzionale
- il servizio non deve dipendere dal consenso marketing
- la UI login dovra' distinguere chiaramente elementi obbligatori e facoltativi

## Allineamento con il codice attuale

Stato implementato in app:

- `terms_accepted`
- `privacy_notice_seen`
- `marketing_email_opt_in`

Stato persistenza:

- salvataggio su `public.user_consents`
- tracciatura di `document_version`
- tracciatura di `source`
- visibilita' nel profilo utente tramite riepilogo consensi

Nota:

- il marketing deve restare revocabile anche dopo il login
- la revoca lato profilo e' ancora da completare come flusso utente
