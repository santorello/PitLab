# Design System Audit - PitLap

**Data:** 2026-05-06
**Versione:** 0.1.9 (pre-alpha)
**Scope:** intera applicazione (mobile + web)
**Allineamento:** `docs/ui-direction.md` ("industrial premium", information first, blocchi compatti)

## Sintesi

| Area                    | Score | Stato                                                                                |
|-------------------------|-------|--------------------------------------------------------------------------------------|
| **Token foundation**    | 4/10  | Theme presente ma sotto-utilizzato; 163 colori hardcoded sparsi                      |
| **Card system**         | 3/10  | Nessuna card condivisa; 7 implementazioni indipendenti per entita' simili            |
| **Page templates**      | 6/10  | `ContentScaffold` + `AppScaffold` esistono e sono coerenti; navigazione responsive OK |
| **Tipografia**          | 5/10  | TextTheme definito ma 39 `TextStyle(...)` inline in 15 schermate                     |
| **Spacing scale**       | 3/10  | 299 `EdgeInsets` ad-hoc, nessuna scala formalizzata                                  |
| **Border radius**       | 4/10  | 13 valori distinti in uso vs 4 nel theme                                             |

**Verdetto:** la sensazione di "schermate sconnesse" e' fondata. Il theme c'e' ma non e' la fonte di verita'; ogni feature ha reinventato card e spacing nel proprio file. La direzione e' corretta - serve consolidare prima dell'Alpha pubblica.

## Cosa funziona

- **Navigazione responsive**: `AppScaffold` gestisce gia' bene il salto tra mobile (NavigationBar) e desktop (NavigationRail collassabile). Soglia 1100px coerente.
- **ContentScaffold**: header unico (logo PitLap + tagline + CTA login/profilo + banner impersonificazione) usato dalle pagine principali. E' l'unico vero pattern di layout condiviso.
- **Theme M3 base**: `ColorScheme.fromSeed(signalOrange)` + `useMaterial3: true` + dark mode parallelo gia' impostati.
- **Token palette**: 11 colori semantici nominati (graphite, signalOrange, openGreen, wetBlue, closedRed, ecc.) - foundation di partenza buona.
- **Tipografia di carattere**: scelta `sans-serif-condensed` per i titoli e' coerente con la direzione "industrial premium" del brief.

## Cosa e' rotto

### 1. Card system - PROBLEMA PRINCIPALE

Sette card indipendenti per entita' concettualmente vicine (luoghi/oggetti consultabili in lista), tutte definite come widget privati `_XxxCard` dentro la propria schermata. Nessuna card in `shared/widgets/`.

| Card               | File                        | Border radius | Padding | Background       | Media size |
|--------------------|-----------------------------|---------------|---------|------------------|------------|
| `_TrackCardV3`     | tracks_home_screen.dart     | 24            | 16      | AppColors.panel  | ~220px     |
| `_SpotCard`        | spots_screen.dart           | 24            | 18      | -                | ~300px     |
| `_ShopCard`        | shops_screen.dart           | **28**        | 18      | gradient inline  | ~310px     |
| `_NearbyPreviewCard` | nearby_screen.dart        | **18**        | 16      | `0xFFF8F7F3`     | -          |
| `_EventCard`       | events_screen.dart          | 24            | 18      | `0xFFF8F7F3`     | ~280px     |
| `_BuildCard`       | garage_screen.dart          | **20**        | 16      | `0xFFF8F7F3`     | 56px thumb |
| `_BaseFeedCard`    | community_home_screen.dart  | **14**        | 16      | AppColors.panel  | -          |

**Inconsistenze strutturali (gravi):**

- 5 valori diversi di border radius (14, 18, 20, 24, 28) per la stessa primitiva concettuale.
- Background card frammentato fra 3 sorgenti: `AppColors.panel`, `0xFFF8F7F3` hardcoded, gradient inline.
- Layout responsive deciso card-per-card: alcune passano da Column a Row a 600px, altre a 700px, altre mai. Niente breakpoint condiviso.
- Posizione e dimensione del media non sincronizzate: pista 220, spot 300, negozio 310, evento 280 - l'occhio percepisce ritmi diversi nelle stesse griglie.
- Slot informativi presenti/assenti senza logica: bottone "follow" su pista e negozio (in due posizioni diverse), assente su evento e spot. Distanza presente solo su nearby.

**Inconsistenze cosmetiche:**

- Pills categoria: `signalOrange` su pista, `warningAmber` su spot, hardcoded vari su nearby - nessun token "category badge".
- Spacing verticale tra elementi della card: 8/10/12/14 - quattro ritmi diversi.
- `999px` radius usato 63 volte per pills/chips - corretto come pattern, ma non centralizzato in un componente.

### 2. Token coverage - molto sotto-sfruttata

| Categoria                  | Definito nel theme | Hardcoded nel codice    |
|----------------------------|--------------------|--------------------------|
| Colori                     | 11 token AppColors | 163 `Color(0xFF...)` in 29 file |
| Border radius              | 4 valori (18, 24, 999) | 13 valori distinti in uso        |
| Spacing                    | nessuna scala      | 299 `EdgeInsets` ad-hoc          |
| TextStyle                  | 7 stili in textTheme | 39 `TextStyle(...)` inline       |
| BoxShadow                  | nessuno            | 5 ombre in 4 file (basso)        |

**Cluster di colori hardcoded ricorrenti** (gli stessi gruppi compaiono in 5+ file):

- Orange shades senza token: `0xFFC2410C`, `0xFF7C2D12`, `0xFFFFF0E6`, `0xFFFFD1B5`, `0xFFFFF4E6`, `0xFF8A3C12` (sono i toni "impersonificazione" + "tagline pill")
- Surface neutri: `0xFFF8F7F3`, `0xFFF5F3EE`, `0xFFEAEEF3` - tre grigi caldi diversi che vorrebbero dire la stessa cosa
- Verde "active": `0xFF16A34A` accanto al gia' definito `AppColors.openGreen` (`0xFF1F9D55`) - due verdi simili sovrapposti

### 3. Tipografia - non centralizzata

39 occorrenze di `TextStyle(...)` inline in 15 file, fuori dal `TextTheme`. I titoli non usano sempre il `sans-serif-condensed` previsto dal brief: alcune card usano `headlineSmall`, altre `titleLarge`, altre `titleMedium` per ruoli equivalenti.

### 4. Page templates - parzialmente buoni

`ContentScaffold` e' l'asset migliore del codebase a livello di consistency, ma:

- Hardcoda 7 colori orange dentro il proprio body invece di usare `AppColors.signalOrange` e derivati.
- L'header puo' diventare denso (logo + tagline pill + login/profile + banner impersonificazione + titolo + descrizione + 6 SizedBox) - dovrebbe diventare un sotto-componente esplicito.
- Pagine come `community_home_screen` e `garage_screen` non lo usano sempre uniformemente - controllare se tutte le pagine principali passano per ContentScaffold o se alcune saltano il pattern.

## Priority actions

### P0 - Foundation (1-2 sessioni, blocca tutto il resto)

1. **Estendere `AppColors`** con i token che esistono gia' di fatto nel codice ma sono hardcoded:
   - `surface` (oggi `paper`/`warmWhite` confusi con `panel`), `surfaceMuted` (per `0xFFF8F7F3`/`0xFFF5F3EE`), `surfaceCool` (per `0xFFEAEEF3`)
   - `onSurfaceMuted` per i grigi caldi sui testi secondari
   - Family `signalOrange` con scale: 50/100/300/500/700/900 (i 6 toni orange hardcoded sono questi, basta nominarli)
   - `borderSubtle`, `borderStrong` (oggi `concrete` usato per entrambi)
2. **Creare `AppSpacing`** in `app/theme/`:
   ```dart
   class AppSpacing {
     static const xs = 4.0;
     static const sm = 8.0;
     static const md = 12.0;
     static const lg = 16.0;
     static const xl = 24.0;
     static const xxl = 32.0;
   }
   ```
   E `AppRadius` con scala 8/12/16/24/pill(999). Le occorrenze 14/18/20/22/28 vanno tutte mappate sul valore piu' vicino della scala.
3. **Spostare i 39 `TextStyle` inline** dentro `TextTheme` - aggiungere named styles `cardTitle`, `cardSubtitle`, `pill`, `metaLabel`, `heroTitle` se servono.

### P1 - Card system (2-3 sessioni)

Creare in `app/lib/shared/widgets/place_card.dart` una **card base unica** con varianti per tipologia.

Struttura proposta (allineata a "industrial premium" + "information first"):

```
PlaceCard (Stateless)
+-- mediaSlot (foto o placeholder, 16:9 mobile / 4:3 desktop, radius AppRadius.lg)
+-- header (titolo + typeBadge a destra)
+-- locationLine (icona luogo + citta' + distanza opzionale)
+-- signalsRow (max 3 pill: stato/oggi/specialita' - tokens unificati)
+-- bodyOptional (descrizione 2 righe max)
+-- footer (CTA primario + actions secondarie come icone)
```

Varianti via enum: `PlaceCardVariant.track | spot | shop | event | build | nearby`.
Layout responsive uniforme: Column < 720px, Row >= 720px (un solo breakpoint condiviso, non 3 diversi).

Tutte le card esistenti diventano wrapper sottili che passano i dati alla `PlaceCard` base.

### P2 - Page templates (1 sessione)

- Estrarre `ContentScaffoldHeader` come widget separato e tokenizzare i suoi colori.
- Definire `AppBreakpoints` (`compact: 0-720`, `medium: 720-1100`, `expanded: 1100+`) e usarlo ovunque al posto di numeri sparsi. Allinearsi a `AppScaffold` che gia' usa 1100.
- Garantire che ogni pagina principale passi per `ContentScaffold` per il chrome (titolo + descrizione + banner impersonificazione).

### P3 - Documentazione (continuativa)

- Creare `docs/design-system.md` (non solo `ui-direction.md`) con:
  - Token snapshot (colori, spacing, radius, tipografia)
  - Componenti documentati: PlaceCard, Pill, StatusBadge, FollowButton, MetaRow
  - Do's & Don'ts per ogni componente
  - Anteprime con esempi di codice
- Aggiungere uno `widgetbook` o catalog screen interno (anche solo una `/dev/components` route in debug) per vedere tutti i componenti del sistema affiancati.

## Cosa NON fare

- **Non** ridisegnare le 7 card una per una mantenendo widget separati: fissi i sintomi senza fissare la causa.
- **Non** introdurre un design system esterno (Material You expanded, FluentUI, ecc.): hai gia' un theme M3 personalizzato che e' ottimo come punto di partenza.
- **Non** rinviare i token alla post-Alpha: dopo che ci sono utenti reali, ogni cambio di radius o spacing diventa "regression visiva" e costa il triplo.
- **Non** mescolare il refactor con nuove feature - fai le P0 e P1 in PR dedicate, altrimenti la review diventa impossibile.

## Stima e impatto

- **Effort totale P0+P1+P2**: 4-6 sessioni di Claude (1-2 settimane di lavoro a 1 sessione/giorno).
- **Beneficio**: percezione "app coerente" risolta strutturalmente; meno regressioni future; onboarding di nuove feature dimezzato perche' la card base e' gia' pronta.
- **Rischio se rimandato**: ogni nuova schermata aggiunge un altro stile e la divergenza accelera. A 15-20 schermate il debt diventa permanente.

## Allineamento con UI direction

Tutte le proposte sono coerenti con `docs/ui-direction.md`:

- "blocchi compatti e leggibili" -> PlaceCard unificata, slot fissi
- "information first" -> signalsRow esplicita in posizione costante
- "pochi accenti" -> orange family centralizzata, 1 sola signalRow per card
- "industrial premium" -> spacing scale tecnica, radius limitati a 5 valori, niente ombre soft inutili
