# PitLap — Checklist go-live beta 0.3.0

> Stato al **2026-09-12**. Legenda responsabile: **G** = Giuseppe (manuale/locale), **C** = delegabile a Claude via MCP.
> L'ordine conta: le sezioni A→G sono in sequenza di dipendenza.

---

## 0. Blocker assoluti (niente rollout finché non sono chiusi)

| # | Blocco | Perché blocca | Chi |
|---|---|---|---|
| 0.1 | `pitlap-prod` è **INACTIVE** (auto-pausa tier free) | Nessun deploy o migrazione è possibile a progetto pausato | G |
| 0.2 | **83 modifiche non committate** nel working tree | Il lavoro di fine luglio + queste di oggi non sono su git: un incidente locale li perde | G |
| 0.3 | Delta DB di giugno/luglio **non applicati su prod** | Lo schema prod non regge le feature 0.3.0 (media, commenti, follow, notifiche) | C |
| 0.4 | I documenti legali **non sono raggiungibili dall'app** | Play Console richiede una privacy policy pubblica; il GDPR richiede informativa accessibile | G+C |
| 0.5 | **Gate E2E** negozio + organizzatore mai rifatto dopo le modifiche | Tuo vincolo esplicito prima di ogni messa online | G |

---

## A. Codice Flutter (in locale, prima di tutto)

- [x] `flutter pub get` — dopo le modifiche di oggi (nessuna nuova dipendenza: `url_launcher` era già presente)
- [x] `flutter analyze` — pulito (2026-09-12, `No issues found`)
- [x] `flutter test` — 13 test verdi (2026-09-12)
- [ ] Verificare che i chiamanti di `upsertUserConsent` passino la costante `legalDocumentVersion` e **non** una stringa letterale `'2026-04-03-draft'` (grep sul progetto). Se passano un letterale, sostituirlo con la costante.
- [ ] Compilare i fix "round 3" mai compile-checked: geocoding Open-Meteo fallback, mappe OSM fallback, saldo PitCoin reattivo (D13), restyle card meteo
- [ ] Allineare `pubspec.yaml` se si rilascia come 0.3.1 (oggi `0.3.0+30`)

## B. Donazione e feedback (fatto oggi, resta la configurazione)

- [x] Handle inserito in `dev.json` e `prod.json`: `https://paypal.me/santorello`
- [ ] **Passare `DONATION_URL` anche alla build Cloudflare**: i due `config/*.json` sono gitignored, quindi in CI la chiave non esiste e il pulsante si auto-nasconde
- [ ] ~~Inserire il tuo handle in `app/config/prod.json`~~ → `"DONATION_URL": "https://paypal.me/<handle>"` (e in `dev.json` se lo vuoi testare)
- [ ] Verificare di usare un account PayPal **personale**: i business non ricevono più pagamenti "amici e parenti" e il link-out cambia natura
- [ ] **Non** collegare mai PitCoin, badge o funzioni alla donazione: è la condizione che la mantiene esente da Google Play Billing
- [ ] Smoke test: pulsante caffè visibile solo quando `DONATION_URL` è valorizzato, apertura in browser esterno su Android e Web
- [ ] Smoke test feedback da **guest** e da utente loggato, verificando riga in tabella `feedback` e arrivo email

## C. Database produzione

- [ ] Ripristinare `pitlap-prod` (`klfjvyytubiorqzfisdu`) dalla dashboard
- [ ] Applicare in ordine i 6 delta del 10 giugno: `2026-06-10-prod-alignment.sql`, `-rls-consolidation.sql`, `-draft-taxonomy-policies.sql`, `-media-storage.sql`, `-entity-comments.sql`, `-profile-follows-notifications.sql` (parte A fuori transazione)
- [ ] Applicare `2026-07-29-pitcoin-privacy.sql`
- [ ] Applicare `2026-07-30-feedback.sql`
- [ ] Verificare parità dev↔prod (tabelle, view, funzioni, policy, trigger) e advisor security/performance
- [ ] Sanare i ~38 lint `multiple_permissive_policies` introdotti dai delta 0.3.0 (regressione rispetto al consolidamento di giugno) e le 2 FK non indicizzate su `entity_comments` / `entity_comment_reports`

## D. Email e Edge Function

- [ ] Verificare il dominio **pitlap.app** su Resend (record DNS)
- [ ] Supabase → Auth → SMTP Settings → Custom SMTP con dati Resend, mittente `noreply@pitlap.app` nome "PitLap" (dev **e** prod). Senza questo il mittente di default ha limiti di poche email/ora: inaccettabile con utenti reali
- [ ] Incollare i 6 template brandizzati da `docs/email-templates-pitlap.md` (oggi sono ancora "TrackHub")
- [ ] Deploy della function `submit-feedback` su **prod** (su dev è già ACTIVE)
- [ ] Impostare i secret su entrambi i progetti: `RESEND_API_KEY`, e i nuovi opzionali `FEEDBACK_FROM` (es. `PitLap Feedback <noreply@pitlap.app>`) e `FEEDBACK_TO`

## E. Documenti legali

- [x] Titolare, foro, età minima 14 anni, retention, sub-responsabili — completati il 30 luglio
- [x] Resend censito come responsabile ex art. 28 + SCC per trasferimento USA (v1.1, oggi)
- [x] Trattamento "feedback" censito: categorie, finalità, base giuridica, retention 24 mesi (v1.1, oggi)
- [x] PayPal inquadrato come titolare autonomo + clausola "Donazioni volontarie" nei Termini (v1.1, oggi)
- [x] `legalDocumentVersion` portata da `2026-04-03-draft` a `1.1` (oggi)
- [ ] **Pubblicare i testi completi come pagine su pitlap.app** (es. `/legal/privacy`, `/legal/terms`, `/legal/cookie`) e linkarli dalle schermate legali dell'app: oggi l'app mostra solo un riassunto dalle stringhe ARB e il testo integrale non è raggiungibile da nessuna parte. Serve anche per la URL pubblica richiesta da Play Console
- [ ] Decidere se forzare la ri-accettazione degli utenti esistenti (i loro consensi risultano su versione `2026-04-03-draft`)

## F. Android

- [ ] Generare il keystore release (`keytool ... pitlap-release.jks alias pitlap` in `app/android/app/`) e creare `key.properties` da template
- [ ] Aggiungere `io.pitlap.app://login-callback` nei Redirect URL di Supabase Auth (serve al login Google su mobile)
- [ ] Verificare `targetSdk` ≥ 34 (oggi è il default Flutter)
- [ ] `flutter build apk` e test su device reale: rete, GPS, deep link OAuth, splash e icona
- [ ] Nodi UX mobile aperti: bottom nav troppo carica (10 voci → menu "Altro"), padding sotto header sticky

## F-bis. Già chiuso (verificato 2026-09-12)

- [x] Error handler globale: `main.dart` gira dentro `AppErrorReporter.runGuarded`, con `app/bootstrap/error_reporting.dart`
- [x] `<meta viewport>` in `web/index.html` (+ meta SEO/OpenGraph, manifest PWA)
- [x] `usePathUrlStrategy()` + `web/_redirects` per il fallback SPA su Cloudflare
- [x] Delta `2026-07-29-pitcoin-privacy.sql`: `security_invoker=on` già attivo su dev (da replicare su prod)

---

## G. Dashboard e sicurezza

- [ ] Attivare **Leaked Password Protection** (ancora OFF su dev, da attivare anche su prod)
- [ ] Imposare lunghezza minima password ≥ 8
- [ ] Attivare MFA sull'account admin
- [ ] Creare l'admin di produzione: registrarsi su prod, poi promuovere a `role='admin'`

## H. Gate finale

- [ ] Test E2E completo con profilo **shop_owner**
- [ ] Test E2E completo con profilo **track_organizer**
- [ ] Rimuovere il commento `[QA-TEST]` sull'evento seed di dev
- [ ] Chiudere QA-04 (share evento locale con id `created-<micros>` genera link rotto)
- [ ] Aggiornare `VERSION.md` e taggare la release

---

## Note di policy da non perdere

**Google Play — donazioni.** La Payments policy esenta da Play Billing i contributi in cui *"100% of the tip or contribution from a user goes to the creator and the payment does not grant access to any digital content or services (including stickers, badges, special emojis etc.)"*. Riconoscere PitCoin o un badge al donatore farebbe decadere l'esenzione e trasformerebbe la donazione in acquisto digitale soggetto a commissione. La clausola §13 dei Termini mette per iscritto questa condizione.

**PayPal — amici e parenti.** Dal 2022 gli account business non possono più ricevere pagamenti "amici e parenti". Su account personale il canale funziona, ma non offre protezione e raccogliere da sconosciuti è un innesco tipico di limitazione dell'account: PayPal.me resta la forma più difendibile.
