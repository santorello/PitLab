# PitLap — Roadmap (vista sintetica)

> Aggiornato: 2026-05-10
> Versione corrente: vedi [`VERSION.md`](VERSION.md)
> **Master di riferimento**: [`docs/roadmap.md`](docs/roadmap.md)

---

Questo file e' una vista sintetica del lavoro in corso. Le decisioni di scope, le fasi numerate, le metriche di successo Alpha e il backlog post-MVP vivono nel master `docs/roadmap.md`. Aggiornalo sempre li' per primo.

## Direzione attuale

PitLap e' uno **strumento operativo per la community RC**, non un social network generico. Il loop principale e':

- **scopro pista** -> vedo stato/servizi/presenze reali aggiornati
- **gestore pista** aggiorna stato + servizi dal pannello dedicato
- **il dato torna utile sul campo** per il pilota che arriva

Attorno a questo loop, ecosistema di negozi, spot, eventi, profili e community.

## Stato sintetico

- Stack: Flutter (Android + Web) + Supabase (Auth + Postgres + Storage + Realtime) + Riverpod
- Permessi: ownership reale via `track_managers`, `shop_managers` + RLS
- Design system: maturo, tokens centralizzati, PlaceCard unificata su 5 entita'
- Gate Alpha: 5 piste pilota gia' in DB con ownership reale; metrica di successo definita (3 check-in `Sto arrivando` su stessa pista in stesso weekend, prime 2 settimane)
- Pre-alpha: in stabilizzazione, fix bug walkthrough in corso

## Prossime milestone (sintesi)

Vedi `docs/roadmap.md` per il dettaglio completo. Quelle a piu' alto valore residuo:

- Chiudere bug rimanenti del walkthrough sessione 3 (vedi `docs/test-checklist.md` TC-WT-21/22)
- Implementare `MediaUploadService` + `MediaUploadField` con Supabase Storage (vedi `docs/media-strategy.md`)
- Approntare i contenuti reali e onboarding gestori per Gate Alpha

## Documenti correlati

- [`docs/roadmap.md`](docs/roadmap.md) — fasi numerate, output, Gate Alpha, backlog post-MVP
- [`docs/decision-log.md`](docs/decision-log.md) — decisioni storiche datate
- [`docs/test-checklist.md`](docs/test-checklist.md) — TC numerati + bug walkthrough (TC-WT-*)
- [`docs/design-system.md`](docs/design-system.md) — token, componenti, pattern UI
- [`docs/media-strategy.md`](docs/media-strategy.md) — pipeline upload, moderation, modulo client
- [`docs/permissions-matrix.md`](docs/permissions-matrix.md) — ruoli e capability
- [`VERSION.md`](VERSION.md) — versione corrente + changelog
