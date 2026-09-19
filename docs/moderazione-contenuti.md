# Moderazione contenuti — PitLap

Stato: **in produzione** dal 2026-09-19 (applicato prima su dev, stesso giorno).
Privacy policy aggiornata alla v1.3 (punti 3.8, 4.3-bis, 9, 13).
Delta: `supabase/deltas/2026-09-19c-moderation-filter.sql`

## Obiettivo

Impedire che testi con parolacce, bestemmie, contenuti sessuali espliciti,
insulti discriminatori o riferimenti sessuali a minori finiscano nei contenuti
pubblici di PitLap.

## Decisioni prese

| Domanda | Scelta | Perché |
|---|---|---|
| Cosa succede al testo | **Blocco all'inserimento** | Niente entra nel DB, nemmeno nascosto. Zero lavoro di moderazione a valle |
| Dove vive il controllo | **Trigger Postgres** | È l'unico punto che nessun client può aggirare. Una validazione solo in Flutter salta con una chiamata REST diretta |
| Come si riconosce | **Dizionario in tabella** | Aggiornabile senza deploy, nessuna dipendenza di rete, nessun costo |
| Cosa vede l'utente | **Messaggio che cita la policy** | Snackbar 6 secondi, testo mantenuto nel campo per correggere |

### Perché non un LLM a runtime

L'idea di "usare la conoscenza dell'LLM" è stata usata **in fase di progetto,
non di esecuzione**: il dizionario e le regex di frase sono scritti a mano una
volta e vivono nel DB. PitLap non chiama nessun modello quando un utente scrive
un commento.

Farlo a runtime richiederebbe una Edge Function verso un'API esterna, con
tre costi che oggi non valgono: latenza su ogni commento, una dipendenza che
se cade blocca la funzione commenti, e un costo per chiamata. Resta un'opzione
se il volume crescerà o se emergerà un abuso che il dizionario non copre.

## Architettura

```
Utente scrive → client Flutter → insert Supabase
                                       ↓
                            BEFORE INSERT trigger
                                       ↓
                       moderation_normalize(testo)
                                       ↓
                       match su moderation_terms
                                       ↓
                   hit? → raise PITLAP_MODERATION:<cat>:<campo>
                                       ↓
                   client: moderationMessage() → snackbar
```

### Oggetti DB

| Oggetto | Ruolo |
|---|---|
| `moderation_normalize(text)` | minuscole, accenti via, leetspeak (`4`→`a`, `@`→`a`, `$`→`s`…), lettere ripetute compresse, punteggiatura rimossa senza spezzare la parola |
| `moderation_terms` | dizionario: `pattern` (regex), `category`, `is_active`. RLS: solo admin |
| `moderation_violation(text)` | ritorna la categoria del primo match, `null` se pulito. Priorità: `minori` → `odio` → `bestemmia` → `sessuale` → `volgare` |
| `moderation_guard()` | trigger generico, riceve i campi da controllare come `TG_ARGV` |
| `moderation_guard_suggestion()` | variante per i testi dentro il `payload` jsonb delle proposte |

### Campi coperti

| Tabella | Campi | Trigger |
|---|---|---|
| `entity_comments` | `body` | insert + update |
| `spots` | `title`, `note` | insert + update |
| `profiles` | `display_name` | insert + update |
| `spot_edit_suggestions` | `payload.title/city/note` | insert |

I commenti coprono tutti e 6 i tipi di entità (`track`, `shop`, `event`,
`community_event`, `spot`, `user_build`) con un solo trigger.

### Normalizzazione — cosa neutralizza

| Scritto | Normalizzato | Esito |
|---|---|---|
| `C.A.Z.Z.O` | `cazzo` | bloccato |
| `c-a-z-z-o` | `cazzo` | bloccato |
| `caaaazzzo` | `caazzo` → match | bloccato |
| `c4zz0` | `cazzo` | bloccato |
| `cazzuola` | `cazzuola` | **passa** (confini di parola) |
| `lo scopo del test` | idem | **passa** |

## Client

`app/lib/shared/utils/moderation_message.dart` traduce
`PITLAP_MODERATION:<categoria>:<campo>` in un messaggio IT/EN. Non ripete la
parola incriminata.

Modificati:

- `comments_providers.dart` — `postComment` ora ritorna `String?` (null = ok).
  Un blocco del filtro **non** finisce in `AppErrorReporter`: non è un guasto.
- `comments_section.dart` — mostra il messaggio e lascia il testo nel campo.
- `spots_providers.dart` — `lastSaveError` esposto sul controller.
- `submit_place_screen.dart` — mostra `lastSaveError` quando presente.

## Limiti — da leggere prima di dire che il problema è risolto

1. **Il filtro riconosce parole, non significati.** Una frase sessuale
   costruita con parole innocue passa. Le combinazioni "minore + termine
   sessuale" coprono i casi lessicali più diretti, non le allusioni.
2. **Non è un presidio di child safety completo.** Il vero presidio resta la
   segnalazione utente + `is_hidden` + revisione admin, già in uso. Il filtro
   riduce il rumore, non sostituisce la moderazione umana.
3. **Falsi positivi possibili.** Termini ambigui nel contesto modellismo sono
   stati lasciati fuori di proposito: `pompa`, `sega`, `mazza`, `fico`,
   `scopo`. Se un beta tester segnala un blocco ingiusto, si disattiva il
   termine con un `update ... set is_active = false`.
4. **Il log dei blocchi parte dal client.** Vedi la sezione apposita: è
   volutamente così, ma significa che il conteggio è indicativo, non esatto.
5. **Contenuto già a DB non è toccato.** Il trigger agisce solo su insert e
   update.

## Log dei blocchi

`moderation_blocks` registra ogni blocco: utente, categoria, tabella, campo e
i primi 300 caratteri del testo. Solo gli admin leggono (RLS), e nessuno
scrive direttamente: si passa dalla RPC `log_moderation_block`.

**Perché la scrittura parte dal client.** Il trigger alza un'eccezione, e
Postgres non ha transazioni autonome: un insert di log dentro lo stesso
statement verrebbe annullato insieme all'inserimento respinto. Il log serve a
tarare i termini, non a difendere — il blocco vero resta il trigger, che
nessuno aggira. Un client malevolo che non logga ha comunque fallito
l'inserimento.

```sql
-- quanto scatta e su cosa
select category, count(*) from public.moderation_blocks group by 1 order by 2 desc;

-- gli ultimi 30, per cercare falsi positivi
select created_at, category, source, sample
from public.moderation_blocks order by created_at desc limit 30;
```

### Retention: riga per sempre, testo 90 giorni

La segnalazione è **storicizzata**: la riga non si cancella mai, perché la
statistica serve a capire se il filtro è tarato bene e se un utente insiste.

Il **testo bloccato** (`sample`) viene azzerato dopo 90 giorni: è contenuto
sgradevole accanto a un `user_id`, quindi dato personale. Dopo la pulizia
restano le etichette — categoria, origine, campo, autore, data — e
`sample_purged_at` dice quando il testo è stato rimosso.

| Campo | Dopo 90 giorni |
|---|---|
| `category`, `source`, `field`, `user_id`, `created_at` | restano |
| `sample` | `null` |
| `sample_purged_at` | valorizzato |

Esecuzione: `purge_moderation_samples()` via **pg_cron**, ogni notte alle 03:17
UTC. La funzione non è eseguibile dall'app (`revoke all ... from authenticated`).

```sql
select count(*) from cron.job where jobname = 'purge_moderation_samples';  -- atteso 1
select public.purge_moderation_samples();  -- esecuzione manuale (solo admin/SQL editor)
```

### Consultazione

`admin_moderation_stats` aggrega per giorno, categoria e origine **senza mai
mostrare il testo**. È la vista da guardare di routine; `sample` si legge solo
per un caso specifico.

```sql
select * from public.admin_moderation_stats limit 20;
```

Nessuna schermata admin: finché i blocchi sono pochi, la vista basta.

## Manutenzione

Aggiungere un termine (solo admin):

```sql
insert into public.moderation_terms (pattern, category, note)
values ('\mnuovotermine\M', 'volgare', 'segnalato il 2026-xx-xx');
```

Disattivare un falso positivo:

```sql
update public.moderation_terms set is_active = false where pattern = '...';
```

Provare un testo senza inserirlo:

```sql
select public.moderation_violation('testo da provare');
```

## Test eseguiti su dev

| Input | Atteso | Esito |
|---|---|---|
| `Bel giro, che spot fantastico!` | passa | ✅ |
| `Il fondo diventa una merda` | volgare | ✅ |
| `C.A.Z.Z.O che salto` | volgare | ✅ |
| `caaaazzzo che bello` | volgare | ✅ |
| `Ho usato la cazzuola` | passa | ✅ |
| `Lo scopo del test` | passa | ✅ |
| `sotto-sterzo in curva` | passa | ✅ |
| `porco dio che fango` | bestemmia | ✅ |
| `foto di bambini nudi` | minori | ✅ |
| `update spots set note` con testo volgare | bloccato dal trigger | ✅ |

## Da fare

- [ ] `run_dev.bat analyze` + test manuale del messaggio in UI
- [x] Applicare il delta su prod — fatto 2026-09-19
- [x] Citare il filtro nei documenti legali — privacy policy v1.3
- [ ] Valutare copertura anche su nomi di piste, negozi ed eventi
