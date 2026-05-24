# Project Structure

Documento centrale di orientamento per PitLap.

Serve a capire rapidamente:

- quali documenti esistono
- a cosa servono
- dove trovare il contesto giusto
- quali file vanno mantenuti aggiornati nel tempo

## Documenti principali

### Root

- `README.md`
  Scopo: visione sintetica del progetto, obiettivo, stack proposto e link ai documenti principali.

- `README.txt`
  Scopo: brief iniziale storico del progetto. Va mantenuto come riferimento originale, anche se la documentazione attiva vive nei file Markdown.

- `PROJECT_STRUCTURE.md`
  Scopo: indice centrale dei documenti e della struttura del repository.

- `VERSION.md`
  Scopo: file di versionamento da aggiornare a ogni nuova release.

## Cartella `docs/`

- `docs/mvp.md`
  Scopo: perimetro della fase 1 e criteri di successo dell'MVP.

- `docs/roadmap.md`
  Scopo: suddivisione del lavoro per fasi.

- `docs/architecture.md`
  Scopo: decisioni tecniche iniziali, componenti e principi architetturali.

- `docs/data-model.md`
  Scopo: entita' principali e prime relazioni dati.

- `docs/content-launch.md`
  Scopo: contenuti minimi necessari per evitare un prodotto vuoto al lancio.

- `docs/decision-log.md`
  Scopo: decisioni operative chiuse, con motivazioni e impatti.

- `docs/development-checklist.md`
  Scopo: checklist viva di sviluppo con stato reale, punti sospesi e prossimi passi operativi.

- `docs/ui-direction.md`
  Scopo: direzione visiva e UX di riferimento per branding e interfaccia.

- `docs/backend-baseline.md`
  Scopo: baseline tecnica iniziale per backend Supabase, dati, permessi e realtime.

- `docs/app-blueprint.md`
  Scopo: struttura applicativa Flutter, navigazione e principi di implementazione MVP.

- `docs/design-brief.md`
  Scopo: brief operativo per brand, palette, typography e componenti chiave.

- `docs/best-practices.md`
  Scopo: regole guida permanenti per scelte di prodotto, design e implementazione.

- `docs/onboarding-first-access.md`
  Scopo: bozza operativa dell'onboarding post-registrazione e dei dati da raccogliere al primo accesso.

- `docs/api-registry.md`
  Scopo: registro operativo delle API e dei servizi esterni usati, con note di attribuzione, licensing e privacy.

- `docs/permissions-matrix.md`
  Scopo: matrice dei ruoli e dei permessi applicativi, con ownership e regole guest/logged-in/admin.

- `docs/pitcoin-system.md`
  Scopo: specifica del sistema PitCoin + badge — reputation score, catalogo azioni con valori, criteri badge, architettura ledger Postgres-first, RLS, backfill, UI da aggiungere. Aggiornato 2026-05-23.

- `docs/test-checklist.md`
  Scopo: checklist operativa dei test manuali e regressivi sulle funzionalita' principali.

- `docs/mockup-pitlap.svg`
  Scopo: mockup concettuale iniziale della UI MVP.

- `docs/supabase-dev-setup.md`
  Scopo: checklist operativa per creare e configurare l'ambiente Supabase di sviluppo.

### Cartella `docs/legal/`

- `docs/legal/privacy-policy.md`
  Scopo: bozza operativa della privacy policy da consolidare prima della pubblicazione.

- `docs/legal/terms-of-service.md`
  Scopo: bozza operativa dei termini di servizio.

- `docs/legal/cookie-policy.md`
  Scopo: struttura base della cookie policy, da completare quando saranno attivati cookie e strumenti equivalenti.

- `docs/legal/consent-register.md`
  Scopo: tracciare consensi, prese visione e struttura minima di versionamento documentale.

## Cartella `supabase/`

- `supabase/README.md`
  Scopo: orientamento rapido sul materiale backend presente nella cartella.

- `supabase/schema.sql`
  Scopo: schema iniziale Supabase con tabelle, enum, trigger, indici e policy.

- `supabase/seed_demo.sql`
  Scopo: seed minimo di dati demo per validare il primo flusso reale in app.

- `supabase/deltas/`
  Scopo: delta SQL incrementali da applicare senza rilanciare l'intero schema.

## Cartella `app/`

- `app/`
  Scopo: codebase Flutter per Android e Web.

- `app/lib/`
  Scopo: sorgente applicativa principale organizzata per feature, app shell e componenti condivisi.

- `app/docs/RUN_DEV.md`
  Scopo: istruzioni pratiche per eseguire l'app contro l'ambiente Supabase di sviluppo.

## Cartella `backup/`

Scopo: raccogliere snapshot e copie di sicurezza in momenti focali del progetto.

Uso previsto:

- prima di milestone importanti
- prima di refactor strutturali
- prima di release candidate
- quando conviene congelare uno stato del progetto in modo leggibile

## Regole di manutenzione

- ogni nuovo documento di contesto va aggiunto qui
- ogni release deve aggiornare `VERSION.md`
- i documenti principali devono restare leggibili sia da umano sia da agente
- i file root devono raccontare il contesto senza costringere a scavare troppo nel repository

## Struttura attuale del repository

- `README.md`
- `README.txt`
- `PROJECT_STRUCTURE.md`
- `VERSION.md`
- `docs/`
- `backup/`

## File prioritari da leggere per primi

Ordine consigliato:

1. `README.md`
2. `PROJECT_STRUCTURE.md`
3. `VERSION.md`
4. `docs/decision-log.md`
5. `docs/best-practices.md`
6. `docs/mvp.md`
7. `docs/backend-baseline.md`
8. `docs/app-blueprint.md`
9. `docs/ui-direction.md`
10. `docs/design-brief.md`
11. `docs/architecture.md`
12. `docs/data-model.md`
