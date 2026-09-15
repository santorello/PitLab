# Sessione del 2026-09-15 (sera) — prod allineato, feedback online su prod

Seguito di `sessione-2026-09-15.md`. Eseguito da Claude via MCP Supabase, con via libera di Giuseppe.

## Applicato su pitlap-prod (klfjvyytubiorqzfisdu)

| Migrazione | Origine | Esito |
|---|---|---|
| `20260914_identita_utente` | `2026-09-14-identita-utente.sql` | OK — 0 profili senza nome |
| `20260915_timbro_revisore` | `2026-09-15-timbro-revisore.sql` | OK |
| `20260915_pista_collegata_al_creatore` | `2026-09-15-pista-collegata-al-creatore.sql` | OK — 2 righe in `track_managers` |
| `20260915_conservazione_dati` | `2026-09-15-conservazione-dati.sql` (**non citato nel verbale del pomeriggio**, trovato confrontando le funzioni) | OK |
| `20260915_grant_hardening_nuove_funzioni` | nuovo, applicato **anche su dev** | OK |

`begin;`/`commit;` rimossi perché `apply_migration` è già transazionale.

### Nuovo: grant delle funzioni nate il 14-15 settembre

Su dev `trg_stamp_review_author`, `auto_link_track_manager_on_insert` e `complete_onboarding`
avevano ancora EXECUTE a PUBLIC/anon (default Postgres di `create function`). Allineati a regola:

```sql
revoke execute on function public.trg_stamp_review_author() from public, anon, authenticated;
revoke execute on function public.auto_link_track_manager_on_insert() from public, anon, authenticated;
revoke execute on function public.complete_onboarding(text, text, text[], text, text, double precision, double precision, text) from public, anon;
grant  execute on function public.complete_onboarding(text, text, text[], text, text, double precision, double precision, text) to authenticated;
```

**Regola da ricordare:** ogni `create function` nuova nasce con EXECUTE a PUBLIC. Ogni delta
che crea una funzione deve chiudere con il suo `revoke`/`grant` esplicito.

## Edge Function

- `submit-feedback` pubblicata su **prod** (v1, ACTIVE, `verify_jwt: false` come su dev).
- **Manca:** secret `RESEND_API_KEY` (+ `FEEDBACK_TO`, `FEEDBACK_FROM` dopo la verifica del
  dominio su Resend). Senza chiave il feedback viene salvato ma non arriva nessuna email.

## Verifica

- Funzioni (codice normalizzato + ACL): impronta **identica** dev/prod.
- Trigger: 54 su entrambe.
- Advisor sicurezza prod: nessun ERROR. Solo WARN attesi (helper SECURITY DEFINER delle RLS;
  `cleanup_expired_arrivals` eseguibile da anon **per scelta**, vedi commento nel delta).
- Differenze residue note, non funzionali: policy `keepalive` SELECT = `(id = true)` su prod,
  `true` su dev (prod più restrittivo).

## Stato del dominio

`pitlap.app` **non risolve** (DNS: "Name or service not known") alle 19:10 del 15/09.
Nessun sito collegato: anche le pagine `/legal/*` non sono raggiungibili.

## Nota per il futuro

`submit-feedback` si fida di `userId` passato dal client (è falsificabile). Impatto basso
(solo attribuzione di un feedback); da sistemare leggendo l'utente dal JWT quando presente.

---

## GO-LIVE WEB — completato alle 19:55 del 15/09

| Passo | Esito |
|---|---|
| Build prod (`build_web_prod.bat`) | ✅ verificata: URL prod presente, 0 riferimenti a dev, `DONATION_URL` presente, 0.3.0+30 |
| Cloudflare Pages, progetto `pitlap` (upload diretto, 42 file) | ✅ `pitlap.pages.dev` |
| Domini personalizzati `pitlap.app` e `www.pitlap.app` | ✅ Active, SSL enabled |
| Pagine legali `/legal/*.html` senza login | ✅ (Cloudflare toglie `.html` con un redirect: gli URL `/legal/privacy-policy` funzionano) |
| Rotte profonde (`/tracks`) con `_redirects` | ✅ |
| Supabase prod: Redirect URL | ✅ aggiunti `https://pitlap.app/**`, `https://www.pitlap.app/**`, `io.pitlap.app://login-callback` (Site URL era già `https://pitlap.app`) |
| Supabase prod: SMTP Resend | ✅ era già configurato (noreply@pitlap.app, smtp.resend.com:465) |
| Resend: dominio pitlap.app | ✅ già verificato, regione Irlanda (coerente con privacy §8) |
| Supabase prod: 6 template email PitLap | ✅ incollati e verificati dopo ricarica |
| `submit-feedback` su prod | ✅ test reale: riga salvata con user_agent, poi cancellata |

**Attenzione per i prossimi deploy:** `run_dev.bat build` usa `dev.json`. Per la produzione usare SEMPRE `build_web_prod.bat`.

## Pulizia dati di prova su prod (decisa da Giuseppe)

Cancellati: pista `[QA] Pista di test PitLap` (con dipendenze in cascata) + 1 notifica, spot QA, 2 eventi community QA,
build QA, commento QA, categorie `francobolli` / `treni` / `qa_test_categoria`. Slug profilo `qa-test-pitlap` azzerato.
La presenza QA era già stata rimossa dalla pulizia giornaliera. **Pistona** resa non pubblica (non cancellata).
Negozio "di Beppe" era già `draft` e non pubblico: non toccato.

**Lezione:** `guard_track_moderation_columns` ripristina in silenzio `is_public` se la sessione non è admin, anche
per le query SQL da MCP/SQL Editor (`auth.uid()` nullo). Per cambiare visibilità da SQL: in transazione
`select set_config('request.jwt.claims','{"sub":"<id admin>","role":"authenticated"}', true);` e poi l'update.

## Ancora aperto

- [ ] **Secret `RESEND_API_KEY` su prod** (Edge Functions → Secrets). Senza, il feedback viene salvato ma l'email non parte. Facoltativi `FEEDBACK_FROM=PitLap Feedback <noreply@pitlap.app>`, `FEEDBACK_TO`.
- [ ] **Gate E2E** negozio + organizzatore su prod: serve il login con magic link, quindi la tua casella email. Profili di prova già presenti su prod: `Pilota 7ffa` (shop_owner), `Pilota c56a` (track_organizer).
- [ ] Testi legali: la privacy dichiara **v1.2** in testa ma il piè di pagina dice ancora "Versione 1.0 — 2026-06-03"; `legalDocumentVersion` nell'app è `'1.1'`. §3.5 dice "log 90 giorni", §9 dice "nessun log proprio". Allineare, rigenerare e rideployare.
- [ ] Verificare che la GitHub Action giornaliera (keepalive + `cleanup_expired_arrivals`) punti anche a **prod**.
- [ ] Android: keystore, build, Play Console (URL privacy da usare: `https://pitlap.app/legal/privacy-policy`).
- [ ] Commit: `git add docs/sessione-2026-09-15-sera.md && git commit -m "docs: go-live web 15/09" && git push`

---

## Dopo il go-live — header uniforme + login Google (15/09, sera)

**Header (codice, NON ancora compilato):** nuovo `core/widgets/language_toggle.dart`; `HeaderAccountActions` (ex `_HeaderActions`) ora
pubblico, include sempre il selettore IT/EN ed è allineato a destra; la Home usa lo stesso componente al posto dell'icona sola;
rimosso il selettore duplicato da `tracks_home_screen.dart`. Da fare: `run_dev.bat analyze` → `build_web_prod.bat` → nuovo deploy su Cloudflare (Pages → pitlap → Create deployment).

**Login Google su prod: provider DISABILITATO.** Su dev è attivo con Client ID `269462898998-j6poup49ujla8etuk7pa934ml1dtu65c.apps.googleusercontent.com`.
Passi (Giuseppe): Supabase prod → Sign In / Providers → Google → Enable, stesso Client ID + Client Secret → Save.
Google Cloud Console → Credenziali → client OAuth → aggiungere redirect `https://klfjvyytubiorqzfisdu.supabase.co/auth/v1/callback`
e origine JS `https://pitlap.app` (+ `https://www.pitlap.app`). Schermata consenso: se in "Testing" pubblicarla ("In production").
