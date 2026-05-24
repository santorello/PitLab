# Media Strategy

Strategia operativa per immagini, gallerie e link social di PitLap.

## Obiettivo

Evitare che il prodotto collassi quando aumentano utenti, negozi, piste, eventi e contenuti visuali.

La regola guida e': le immagini non sono semplici campi testo. Sono asset con ciclo di vita, owner, limiti, trasformazioni, privacy, costi e moderazione.

## Stato

Data aggiornamento: `2026-05-10`

Stato attuale:

- caricamento locale in test tramite `file_picker`
- resize temporaneo lato client con package Dart `image`
- salvataggio temporaneo come data URL solo per validare UX
- protezione temporanea contro immagini troppo grandi e crash CanvasKit
- profilo locale prudente per web test: input massimo 5 MB, output circa 520 KB, lato lungo massimo 1200 px
- introdotta base condivisa `media upload system` con stato batch, stage per-file e progress card riusabile
- progress card aggiornata con stato e avanzamento animato
- rollout iniziale gia' applicato a profilo, editor pista, editor negozio, eventi e submit-place

Stato target:

- Supabase Storage come storage principale
- tabella `media_assets` come registro degli asset
- URL persistenti e thumbnail, non data URL nel database applicativo
- RLS e ownership su upload, lettura, update e delete
- moderazione admin per media pubblici

## Limiti prodotto proposti

Limiti iniziali lato prodotto:

- `Profilo utente`: 1 avatar + 1 cover opzionale in futuro
- `Garage`: massimo 5 immagini per ogni build
- `Negozio`: massimo 10 immagini in galleria + 1 cover
- `Pista`: massimo 10 immagini in galleria + 1 cover hero
- `Evento`: massimo 5 immagini + 1 cover evento

Questi limiti sono abbastanza generosi per l'MVP, ma evitano gallerie ingestibili e costi fuori controllo.

## Pipeline immagini consigliata

### 1. Validazione client

Prima dell'upload:

- accettare solo immagini
- limite input massimo
- resize lato client
- compressione JPEG/WebP quando compatibile
- preview locale leggera
- messaggio chiaro se l'immagine e' troppo grande o non valida
- feedback progressivo di preparazione per-file anche quando non c'e ancora upload di rete

### 2. Upload storage

Target:

- upload verso Supabase Storage
- path generato dall'app, non dal nome file originale
- nessun dato personale nel nome file
- bucket separati per dominio o path chiaramente separati
- reporting reale in byte disponibile pienamente quando i flussi passano a upload storage-backed

Bucket o path suggeriti:

- `avatars/{user_id}/avatar.jpg`
- `garage-builds/{user_id}/{build_id}/{asset_id}.jpg`
- `shop-media/{shop_id}/{asset_id}.jpg`
- `track-media/{track_id}/{asset_id}.jpg`
- `event-media/{event_id}/{asset_id}.jpg`

### 3. Varianti

Ogni asset pubblico dovrebbe avere almeno:

- `thumb`: per card e liste
- `preview`: per dettaglio
- `original_optimized`: versione ottimizzata conservabile se serve

Nota: se usiamo Supabase Image Transformations, valutare costi e piano necessario prima del rilascio.

### 4. Registro media

Tabella proposta: `media_assets`.

Campi iniziali:

- `id`
- `owner_user_id`
- `entity_type`
- `entity_id`
- `bucket`
- `storage_path`
- `public_url`
- `thumb_url`
- `mime_type`
- `size_bytes`
- `width`
- `height`
- `sort_order`
- `visibility`
- `moderation_status`
- `created_at`
- `updated_at`
- `deleted_at`

Valori suggeriti:

- `entity_type`: `profile`, `garage_build`, `shop`, `track`, `event`
- `visibility`: `private`, `public`
- `moderation_status`: `approved`, `pending`, `rejected`, `removed`

## Regole di ownership

### Utente registrato

Puo':

- caricare avatar profilo
- caricare immagini per le proprie build garage
- caricare immagini per eventi creati da lui

Non puo':

- modificare immagini di altri utenti
- cancellare media pubblici altrui

### Negozio

Puo':

- caricare cover e galleria del proprio negozio se collegato tramite ownership reale
- caricare immagini per eventi creati come negozio

### Organizzatore pista

Puo':

- caricare cover e galleria della pista assegnata
- caricare immagini per eventi collegati alla propria pista

### Admin

Puo':

- vedere e rimuovere media pubblici
- sostituire immagini di negozi, piste, eventi e profili se necessario
- gestire media segnalati
- pulire immagini orfane o non conformi

## Moderazione

Aggiornato 2026-05-09 con le decisioni prese in sessione.

### Principio

L'AI di moderazione e' un **suggerimento**, non un giudice. Per una community di nicchia con admin presenti, il flag automatico passa sempre in revisione admin che decide approve/reject. L'unica eccezione e' CSAM (Child Sexual Abuse Material) che richiede auto-block immediato per obbligo di legge.

### Stati e comportamento UI

Lo `moderation_status` evolve a 5 stati:

- `approved`: visibile al pubblico (default per upload sicuri)
- `pending`: in attesa di primo verdetto AI (transitorio, brevi secondi)
- `flagged`: hide-pending - **visibile solo a autore + admin**, pubblico vede placeholder "Foto in revisione". L'autore vede sempre la sua foto senza penalita'.
- `rejected`: rimosso dopo review admin (soft-delete con motivo)
- `csam_blocked`: rimosso automaticamente, hash conservato + alert tecnico, mai visibile a nessuno tranne log audit

Nel widget di display (`AdaptiveImage` ed equivalenti), comportamento:

```
if (moderation_status == 'flagged') {
  if (currentUser == owner || isAdmin) showImage();
  else showPlaceholder('Foto in revisione');
}
if (moderation_status == 'rejected' || 'csam_blocked') showPlaceholder();
```

### Pipeline async (non bloccante per l'utente)

1. Utente carica → `MediaUploadService` salva in bucket Storage con `moderation_status='pending'`
2. URL gia' disponibile, autore vede subito la propria foto
3. Edge Function Supabase (trigger su INSERT in `media_assets`) chiama Sightengine async
4. Sightengine ritorna verdict in 200-500ms con scores per categoria
5. Edge Function aggiorna `moderation_status`:
   - se sotto soglia di tutte le categorie → `approved`
   - se sopra soglia su una categoria sensibile → `flagged` (entra in coda admin)
   - se CSAM detection positivo → `csam_blocked` + alert + hash log
6. Coda admin in `/admin > Approvazioni` mostra anche le foto flagged con il motivo del flag (es. "Sightengine: nudity 0.85, faces minor 0.6")

### Provider AI consigliato: Sightengine

Motivi: REST endpoint semplice, ~$0.001/immagine, free tier 500/mese, categorie native pertinenti (nudity, gore, weapons, faces con tag minor/adult, document detection, OCR, offensive symbols, CSAM con hash matching contro NCMEC).

Costo stimato per primo anno: ~10.000 immagini totali → **~$10-30/anno** di moderation.

### Soglie suggerite per fase 2

| Categoria | Auto-block (csam_blocked) | Flag (visible solo a autore+admin) | Note |
|---|---|---|---|
| CSAM hash match | sempre | n/a | obbligo di legge, alert tecnico |
| Nudity (raw) | n/a | prob > 0.5 | review admin |
| Gore / weapons | n/a | prob > 0.5 | review admin |
| Faces probable minor | n/a | prob > 0.6 | privacy GDPR |
| Document detection | n/a | prob > 0.7 | caso "Claudia Ferri Luogo" |
| Offensive text in image | n/a | prob > 0.5 | OCR + classifier |

### Fasi di rollout della moderazione

- **Fase 1 (MVP, oggi)**: nessuna AI moderation. Solo pulsante "Segnala" su ogni foto pubblica + coda admin manuale + approval workflow esistente per shop/track/spot. CSAM gestito dalla detection nativa di Supabase Storage se disponibile, altrimenti solo report manuale.
- **Fase 2 (volumi crescenti, > 100 upload/giorno)**: integrazione Sightengine via Edge Function. Soft-flag per tutte le categorie tranne CSAM. Nessun auto-block (solo CSAM).
- **Fase 3 (community matura, > 1000 upload/giorno)**: nessun cambio rispetto a fase 2 finche' la coda admin regge. Se l'admin non riesce a stare dietro, valutare auto-approve per signal score < 0.2 e auto-reject solo per CSAM (decisione futura).

### Validation client-side (gratis, fa parte di MediaUploadService)

Anche prima di attivare AI moderation, vale la pena fare validation rigorosa lato client come prima difesa:

- whitelist MIME (`image/jpeg`, `image/png`, `image/webp`)
- limite dimensione file (5 MB input)
- limite dimensione pixel (mai 1x1, mai oltre 8000x8000)
- resize/compress lato client al lato lungo 1600px, qualita' 80%
- EXIF orientation fix per foto da telefono
- messaggio chiaro per file rifiutato

Questo elimina l'80% dei contenuti problematici (file enormi, formati strani, immagini corrotte) prima che arrivino al server.

## Pulizia e costi

Servono regole per:

- immagini orfane dopo cancellazione evento/build/negozio
- immagini sostituite ma non piu' usate
- limiti per utente/entita'
- compressione e thumbnail per ridurre traffico
- monitoraggio storage e banda

## Social link e canali esterni

Ogni profilo o entita' pubblica potra' avere link esterni verificati.

Entita' coinvolte:

- profilo utente/modellista
- negozio
- pista
- organizzatore pista

Canali iniziali ammessi:

- sito web
- Instagram
- Facebook
- YouTube
- TikTok
- WhatsApp / Telegram solo se ha senso per negozi o piste

Tabella proposta: `external_links`.

Campi iniziali:

- `id`
- `owner_user_id`
- `entity_type`
- `entity_id`
- `provider`
- `label`
- `url`
- `is_public`
- `sort_order`
- `created_at`
- `updated_at`

Regole:

- validare URL e provider
- non mostrare automaticamente link non pubblici
- evitare link liberi non controllati nel primo MVP
- admin puo' rimuovere link non conformi

## Step di implementazione

### Step 1 - Stabilizzazione locale

- mantenere resize client-side temporaneo
- impedire data URL troppo grandi
- testare immagini su eventi, garage e negozi
- usare `MediaUploadController` / `ImageTransferProgressCard` condivisi per evitare logiche duplicate
- evitare base64 visibile nei campi testo

### Step 2 - Storage reale

- creare bucket Supabase Storage
- creare tabella `media_assets`
- creare policy RLS per upload/lettura/cancellazione
- collegare avatar, garage, negozi, piste ed eventi

### Step 3 - Thumbnail e performance

- introdurre thumbnail nelle card
- usare preview nel dettaglio
- lazy load dove possibile
- evitare originali nelle liste

### Step 4 - Moderazione

- aggiungere stato moderazione
- aggiungere dashboard admin media
- aggiungere cancellazione media
- tracciare immagini rimosse e orfane

### Step 5 - Social link

- creare tabella `external_links`
- aggiungere editor link in profilo, negozio e pista
- mostrare link pubblici nelle schede
- aggiungere rimozione/moderazione admin

Stato UI locale:

- profilo utente: prima sezione `Link e canali` aggiunta
- negozio: prima sezione `Link e canali` aggiunta
- provider ammessi: sito web, Instagram, Facebook, YouTube, TikTok, WhatsApp, Telegram
- persistenza temporanea: `SharedPreferences`
- prossimo step: portare la persistenza su tabella `external_links` con ownership reale

## Decisioni chiuse 2026-05-09

| Decisione | Scelta | Note |
|---|---|---|
| bucket separati o unico con path | **separati per dominio** | gia' definiti sopra: `avatars`, `garage-builds`, `shop-media`, `track-media`, `event-media`. Permette policy RLS dedicate e cleanup mirato per dominio. |
| Supabase Image Transformations | **rimandate a fase 3** | costo extra del piano Pro, per MVP/Alpha generiamo thumbnail lato client + fallback al `public_url` originale. Da rivalutare quando volumi visualizzazioni crescono. |
| moderazione media pubblici | **hide-pending + AI Sightengine in fase 2** | vedi sezione "Moderazione" sopra. Fase 1 solo report manuale + approval workflow esistente. |
| video in MVP | **no** | solo immagini. Per video usare link YouTube/social (gia' supportati da `external_links`). PDF rimandato a futuro se mai utile. |
| limiti storage per utente e per ruolo | **bastano i limiti per entita' gia' definiti** sopra (5 immagini build, 10 negozio, 10 pista, ecc.). Per ora nessun limite globale per utente. Da rivalutare dopo Gate Alpha se compaiono utenti che gonfiano lo storage. |
| Modulo client riusabile | **si, da costruire** | `MediaUploadService` (logica) + `MediaUploadField` widget single image, `MediaUploadGallery` widget multi image solo quando serve. Vedi sezione "Architettura modulo client" sotto. |

## Architettura modulo client

Aggiunto 2026-05-09. Sostituisce l'attuale uso disperso di `FilePicker` + `LocalImageDataUrl` + `MediaUploadController` nelle singole feature, mantenendo questi ultimi come building block interni.

### Componenti

#### `MediaUploadService` (logica pura, niente UI)

Servizio centrale che gestisce l'intero ciclo di vita dell'upload. API esposta:

```dart
class MediaUploadService {
  Future<MediaUploadResult> uploadImage({
    required Uint8List bytes,
    required String bucket,
    required String path,
    MediaConstraints? constraints,
    void Function(double progress)? onProgress,
  });

  Future<void> deleteImage({required String bucket, required String path});
}

class MediaConstraints {
  final int maxBytes; // default 5 MB
  final int maxDimension; // default 1600 px lato lungo
  final Set<String> allowedMimes; // default {jpeg, png, webp}
  final double targetQuality; // default 0.8 per JPEG/WebP
}

class MediaUploadResult {
  final String publicUrl;
  final String storagePath;
  final int bytesUploaded;
  final int width;
  final int height;
  final String mimeType;
}
```

Responsabilita':

1. validazione MIME e size lato client
2. resize/compress lato client (usa pacchetto `image` gia' presente)
3. EXIF orientation fix
4. upload Supabase Storage con retry esponenziale
5. ritorna URL persistente
6. NON gestisce moderazione (vedi sotto: orchestrazione lato Edge Function)

#### `MediaUploadField` (widget UI per single image)

Wrapper visuale completo. Sostituisce le decine di `FilePicker.platform.pickFiles()` sparsi con preview/progress/error.

```dart
MediaUploadField(
  bucket: 'shop-media',
  pathBuilder: (file) => '${shopId}/cover-${ulid()}.jpg',
  constraints: MediaConstraints(),
  initialUrl: shop.imageUrl,
  aspectRatio: 16 / 9,
  onUploaded: (result) => _imageUrlController.text = result.publicUrl,
  onError: (e) => showSnackBar('Errore upload: $e'),
)
```

Slot interni: tap → FilePicker → preview locale immediata → progress bar via `MediaUploadController` → onUploaded callback con URL persistente. Stati visivi: empty (placeholder), uploading (progress), uploaded (preview), error (con CTA retry).

#### `MediaUploadGallery` (widget UI multi image, fase 2)

Da costruire SOLO quando si fa galleria shop o build. Orchestra N `MediaUploadField` con add/remove/reorder + `maxItems`.

#### `AvatarUploadField` (eventuale, fase 3)

Wrapper specializzato di `MediaUploadField` con crop quadrato forzato 512x512 e bucket `avatars`. Costruirlo solo se la specializzazione torna utile in piu' posti.

### Cosa NON fare

- non astraere il provider dietro un'interfaccia `IUploadProvider` finche' non c'e' un secondo provider in vista (premature abstraction)
- non gestire video, audio o PDF in `MediaUploadService` finche' non servono davvero
- non mettere logica di prodotto (es. quale ruolo puo' uploadare quante foto) dentro al modulo - quella sta nei provider Riverpod del feature; il modulo e' dumb e accetta quello che gli passi
- non costruire `MediaUploadGallery` finche' non si arriva alla galleria shop o build (YAGNI)

### Ordine di implementazione consigliato

1. **Settimana 1** - `MediaUploadService` + `MediaUploadField` + integrazione su shop cover (primo caso)
2. **Settimana 2** - integrazione su build cover ed event cover (3 bucket diversi, valida la parametrizzazione)
3. **Settimana 3** - `MediaUploadGallery` per shop + spot
4. **Settimana 4** - avatar profilo + cover pista, refactor finale dei widget legacy
5. **Settimana 5+** - integrazione AI moderation hook nella Edge Function (fase 2 della sezione Moderazione)

### Migrazione dati esistenti

Quando passiamo da data URL inline (stato attuale) a Supabase Storage:

- script di migrazione one-shot lato Edge Function: scansiona record con `image_url` che inizia con `data:image/...`, decodifica, uploada su bucket appropriato, sostituisce con URL persistente
- mantenere fallback in `AdaptiveImage` per ancora N giorni in caso di rollback
- pulizia tabelle dopo verifica completata

### Cleanup orphan files

Job notturno (Supabase cron) che:

- scansiona ogni bucket
- per ogni file, verifica se esiste un record `media_assets` con quel `storage_path`
- se non esiste e il file ha piu' di 24h, soft-delete con quarantena 7 giorni prima del delete fisico
- log delle pulizie in tabella audit
