# Design System - PitLap

## Filosofia

PitLap adotta la direzione `industrial premium`: una base visiva pulita e tecnica, senza distrazioni, dove ogni elemento di UI comunica precisione e affidabilità. Il design system è pensato per utenti esigenti – appassionati di modellismo RC, meccanici, organizzatori – che amano ordine, informazioni pratiche e strumenti seri.

La semantica è `information first`: lo spazio è usato per far risaltare i dati operativi (stato pista, presenze, servizi) piuttosto che decorazioni. I componenti sono compatti e scansionabili, come moduli tecnici ordinati, non post social. Un'unica nota energica – l'arancio segnaletico – fornisce accenti intenzionali senza urlare.

Questo sistema materializza i principi di `ui-direction.md` in token concreti, componenti riutilizzabili e pattern layout. La coerenza visiva è ottenuta attraverso una scala limitata ma deliberata di valori: 5 radius, 7 step di spacing, una famiglia arancio con 6 toni, superfici neutre distinte semanticamente.

## Token

### Colori (AppColors)

#### Brand e Core

| Token | Hex | Uso semantico | Contesto |
|-------|-----|---------------|----------|
| `graphite` | `0xFF1F2329` | Testo primario, icone forti | Titoli, icone principali |
| `steel` | `0xFF4B5563` | Testo secondario, icone soft | Subtitle, hint, disabled |
| `concrete` | `0xFFD6D9DE` | Bordo standard | Card border, divider |
| `warmWhite` | `0xFFF6F4EF` | Sfondo pagina | Scaffold background |
| `paper` | `0xFFFAF8F3` | Superficie primaria (card) | Card background standard |
| `signalOrange` | `0xFFF97316` | Accento principale, primaria | Button, switch, link attivo |

#### Superfici (Surface Scale)

| Token | Hex | Uso semantico | Contesto |
|-------|-----|---------------|----------|
| `surfaceMuted` | `0xFFF8F7F3` | Background card secondaria | Compact card, feed preview |
| `surfaceCool` | `0xFFEAEEF3` | Neutral chip/pill background | Neutral pill, chip categoria |
| `surfaceWarm` | `0xFFF5F3EE` | Info pill background caldo | Info pill, spot categoria |
| `surfaceTaglinePill` | `0xFFFFF0E6` | Tagline hero pill | Header tagline, arancio leggero |
| `surfaceImpersonation` | `0xFFFFF4E6` | Banner impersonification | Admin view indicator |

#### Confini (Border Scale)

| Token | Hex | Uso semantico | Contesto |
|-------|-----|---------------|----------|
| `borderSubtle` | `0xFFE8EAEE` | Bordo leggero | Input focus, soft divider |
| `borderStrong` | `0xFFD6D9DE` | Bordo standard (alias concrete) | Card border, form border |

#### Famiglia Arancio (6 toni)

| Token | Hex | Uso semantico |
|-------|-----|---------------|
| `orange50` | `0xFFFFF4E6` | Background softest (UI) |
| `orange100` | `0xFFFFF0E6` | Background soft (UI) |
| `orange200` | `0xFFFFD1B5` | Border arancio |
| `orange500` | `0xFFF97316` | Primaria strong (alias signalOrange) |
| `orange700` | `0xFFC2410C` | Testo su orange50/100, icona |
| `orange900` | `0xFF7C2D12` | Testo forte su background arancio |
| `orangeText` | `0xFF8A3C12` | Testo semantico per pill signal |

#### Status Semantici

| Token | Hex | Significato |
|-------|-----|-------------|
| `statusOpen` | `0xFF1F9D55` | Pista aperta, stato positivo |
| `statusClosed` | `0xFFD14343` | Pista chiusa, stato negativo |
| `statusWarning` | `0xFFD97706` | Attenzione, stato di cautela |
| `statusInfo` | `0xFF2563EB` | Informativo, stato neutro |

#### onSurface Variant

| Token | Hex | Uso semantico |
|-------|-----|---------------|
| `onSurfaceMuted` | `0xFF4B5563` | Testo/icona secondaria su surface (alias steel) |

#### Dark Mode

| Token | Hex | Uso |
|-------|-----|-----|
| `darkSurface` | `0xFF1B2027` | Card background dark |
| `darkScaffold` | `0xFF12161B` | Scaffold background dark |
| `darkBorder` | `0xFF29303A` | Border dark |

### Spacing (AppSpacing)

Scala verticale e orizzontale unificata:

| Token | Valore | Uso principale |
|-------|--------|-----------------|
| `xs` | 4px | Spazio interno chip, gap icona-label |
| `sm` | 8px | Gap tra label e icona, spacing pills |
| `md` | 12px | Gap tra elementi in card (subtitle, body, signals) |
| `lg` | 16px | Padding card, gap sezioni |
| `xl` | 24px | Padding pagina, gap blocchi grandi |
| `xxl` | 32px | Gap tra sezioni separate |
| `xxxl` | 48px | Gap hero section |

**Regola**: non usare valori assoluti (8, 12, 16). Sempre usare `AppSpacing.sm`, `AppSpacing.lg`, ecc.

### Radius (AppRadius)

Scala ristretta di 5 valori semantici:

| Token | Valore | Uso principale |
|-------|--------|-----------------|
| `sm` | 8px | Chip rettangolari piccoli, input corners soft |
| `md` | 12px | — (riservato) |
| `lg` | 16px | Media in card, input border, button soft |
| `xl` | 24px | Card border, modal border, container grande |
| `pill` | 999px | Chip arrotondati, pill badge, button pill |

**Regola**: mai usare valori in mezzo (14, 18, 20). Mappa tutto a uno dei 5 valori sopra.

### Breakpoints (AppBreakpoints)

Tre soglie di layout responsive:

| Token | Valore | Significato |
|-------|--------|-------------|
| `cardStack` | 720px | Sotto: card layout Column verticale; sopra: Row orizzontale |
| `navRail` | 1100px | Sotto: NavigationBar mobile; sopra: NavigationRail desktop |
| `contentMaxWidth` | 1200px | Max-width contenuto centrato pagina |

**Helper**:
- `AppBreakpoints.isCompact(width)`: width < 720
- `AppBreakpoints.isMedium(width)`: 720 <= width < 1100
- `AppBreakpoints.isExpanded(width)`: width >= 1100

### Tipografia (TextTheme)

Estratta da `app_theme.dart`:

| Style | Famiglia | Peso | Uso |
|-------|----------|------|-----|
| `displaySmall` | sans-serif-condensed | w700 | Page hero title |
| `headlineMedium` | sans-serif-condensed | w700 | Section title |
| `titleLarge` | sans-serif-condensed | w700 | Card title, headline |
| `bodyLarge` | sans-serif | normal | Corpo testo lungo |
| `bodyMedium` | sans-serif | normal | Descrizione, subtitle |
| `labelLarge` | sans-serif | w700 | Button label, action label |
| `labelMedium` | sans-serif | w600 | Pill label, badge label |

**Regola**: Usare sempre `Theme.of(context).textTheme.STYLE` instead di `TextStyle(...)` inline.

## Pattern

### Pattern: ContextualDarkHero

Una hero dark sopra un body light usata in pagine di **stato/contesto operativo** dove l'utente vuole leggere
"a colpo d'occhio" lo stato corrente di un'entita'.

Pagine che usano questo pattern oggi:
- /track/<slug>: hero con stato pista, presenze, meteo, servizi (cockpit pilota)
- /spot/<slug>: hero con tipologia, terreno, idoneita' veicoli (briefing rapido)
- /garage: hero "Le tue build in evidenza" con stat pills (vetrina personale)
- /profile: hero con avatar, ruolo, lingua (status account)
- /manager: hero "Pochi strumenti, molto chiari" con piste assegnate (cockpit gestore)

Pagine che NON usano il pattern (intenzionalmente light):
- /event/<id>: l'evento e' contenuto editoriale, non stato operativo
- /shop/<slug>: il negozio e' una scheda commerciale, hero gradient soft

#### Token usati

- Background hero: `AppColors.graphite` (light theme) / `AppColors.darkSurface` (dark theme)
- Foreground principale: `AppColors.warmWhite`
- Foreground secondario: `AppColors.concrete` o testo `withAlpha(190)`
- Bordi interni hero: `AppColors.steel.withAlpha(60)` o `darkBorder`
- Pills su hero: usare tone `signal` per pill arancioni (`orange50`/`orange100` background non sono leggibili su dark, usare `orange500` con foreground white)

#### Quando aggiungere ContextualDarkHero a una nuova pagina

- Si applica solo se la pagina e' un "dashboard di stato" di un'entita' specifica
- NON applicarlo a pagine di lista, form, editor, content-only
- L'hero copre la prima fold, sotto la pagina torna light

## Componenti

### PlaceCard

**Quando usare**: Card unificata per liste di entità – piste, spot, negozi, eventi, build, nearby. Supporta media, titolo, subtitle, badge di categoria, segnali (stato/presenze/specialità), descrizione e azioni.

**Layout responsive**:
- Sotto 720px: Column verticale (media in alto, contenuto sotto)
- Sopra 720px: Row orizzontale (media sinistra 280px, contenuto destra)

**Slot disponibili**:

| Prop | Tipo | Obbligatorio | Descrizione |
|------|------|--------------|-------------|
| `media` | Widget | Si | Immagine, video, placeholder (aspect 16:9 mobile, 4:3 desktop) |
| `title` | String | Si | Titolo principale |
| `subtitle` | String? | No | Subtitle (es. location) |
| `typeBadge` | Widget? | No | Badge categoria (posizionato alto destra header) |
| `signals` | List<Widget>? | No | Riga pill segnali (max 3-4 visibili) |
| `body` | String? | No | Descrizione (max 2 righe) |
| `footerLeading` | Widget? | No | CTA primario (es. ElevatedButton) |
| `footerActions` | List<Widget>? | No | Azioni secondarie come icone (follow, share, edit) |
| `onTap` | VoidCallback? | No | Callback tap sulla card |
| `variant` | PlaceCardVariant | No | `standard` (panel) o `compact` (muted surface) |

**Esempio**:

```dart
PlaceCard(
  media: Image.network(trackImageUrl, fit: BoxFit.cover),
  title: 'OFFROAD PARMA',
  subtitle: 'Parma, Italia',
  typeBadge: Pill(label: 'Pista RC', tone: PillTone.neutral),
  signals: [
    StatusBadge(label: 'APERTA', kind: StatusBadgeKind.open),
    Pill(label: '7 oggi', tone: PillTone.info),
  ],
  body: 'Fondo asciutto, buona trazione.',
  footerLeading: ElevatedButton(
    onPressed: () => context.go('/track/...'),
    child: const Text('Vedi pista'),
  ),
  footerActions: [
    IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
    IconButton(icon: const Icon(Icons.share), onPressed: () {}),
  ],
  onTap: () => context.go('/track/...'),
)
```

### Pill

**Quando usare**: Badge compatto per etichette di categoria, filtri, segnali. Supporta toni semantici automatici o colori personalizzati.

**Toni semantici**:

| Tone | Background | Foreground | Uso |
|------|------------|------------|-----|
| `neutral` | surfaceCool | onSurfaceMuted | Categoria neutra, filtro generico |
| `signal` | orange50 | orangeText | Categoria segnaletica (pista, spot, negozio) |
| `success` | verde soft (alpha) | statusOpen | Stato positivo, servizio confermato |
| `warning` | ambra soft (alpha) | statusWarning | Attenzione, cautela |
| `danger` | rosso soft (alpha) | statusClosed | Errore, chiuso, negativo |
| `info` | blu soft (alpha) | statusInfo | Informativo, conteggio, neutro |

**Proprietà**:

| Prop | Tipo | Obbligatorio | Descrizione |
|------|------|--------------|-------------|
| `label` | String | Si | Testo etichetta |
| `icon` | IconData? | No | Icona opzionale a sinistra |
| `background` | Color? | No | Colore background (sovrascrive tone) |
| `foreground` | Color? | No | Colore testo/icona (sovrascrive tone) |
| `tone` | PillTone | No | Tono semantico (default: neutral) |

**Esempio**:

```dart
Pill(label: 'Buggy', icon: Icons.category, tone: PillTone.neutral)
Pill(label: 'APERTA', tone: PillTone.success)
Pill(label: 'Oggi', tone: PillTone.info)
```

### StatusBadge

**Quando usare**: Specializzazione di Pill per stati pista. Comunica semanticamente lo stato corrente con icona appropriata.

**Tipi di stato**:

| Kind | Colore | Icona suggerita | Uso |
|------|--------|-----------------|-----|
| `open` | verde (success) | Icons.check_circle | Pista aperta, operativa |
| `closed` | rosso (danger) | Icons.block | Pista chiusa |
| `scheduled` | blu (info) | Icons.event | Evento pianificato |
| `neutral` | grigio (neutral) | Icons.info | Stato sconosciuto |

**Proprietà**:

| Prop | Tipo | Obbligatorio | Descrizione |
|------|------|--------------|-------------|
| `label` | String | Si | Testo stato (es. "APERTA", "CHIUSA") |
| `kind` | StatusBadgeKind | Si | Tipo di stato semantico |
| `leadingIcon` | IconData? | No | Icona opzionale |

**Esempio**:

```dart
StatusBadge(label: 'APERTA', kind: StatusBadgeKind.open)
StatusBadge(label: 'BAGNATA', kind: StatusBadgeKind.scheduled, leadingIcon: Icons.water_drop)
```

### MetaRow

**Quando usare**: Riga di metadati strutturati (icona + testo + trailing text opzionale). Usato per location, distanza, attributi.

**Proprietà**:

| Prop | Tipo | Obbligatorio | Descrizione |
|------|------|--------------|-------------|
| `icon` | IconData | Si | Icona sinistra (size 16) |
| `text` | String | Si | Testo principale |
| `trailingText` | String? | No | Testo allineato destra (es. distanza) |

**Esempio**:

```dart
MetaRow(
  icon: Icons.location_on,
  text: 'Parma, Italia',
  trailingText: '1,4 km',
)
```

### ContentScaffoldHeader

**Quando usare**: Header unificato automaticamente estrapolato da `ContentScaffold` per tutte le pagine principali. Contiene logo PitLap + tagline pill + login/profilo + banner impersonificazione + titolo + descrizione pagina.

**Non istanziare direttamente**. Usato internamente da `ContentScaffold`:

```dart
ContentScaffold(
  title: 'Piste',
  description: 'Dove vuoi andare oggi?',
  child: ListView(...),
)
```

**Proprietà** (per uso avanzato):

| Prop | Tipo | Obbligatorio | Descrizione |
|------|------|--------------|-------------|
| `title` | String | Si | Titolo pagina |
| `description` | String | Si | Descrizione/subtitle |
| `trailingActions` | List<Widget>? | No | Widget aggiuntivi (es. language switcher) |

## Pattern

### Card Layout Responsive

Tutte le card di lista devono usare `PlaceCard`. Layout uniforme rispetto al breakpoint:

```dart
// Layout fisso sotto 720px
Column(
  children: [media, content]
)

// Layout fisso sopra 720px
Row(
  children: [SizedBox(width: 280, child: media), Expanded(child: content)]
)
```

Responsività gestita internamente da `PlaceCard` tramite `LayoutBuilder`.

### Scelta del Tone Pill – Albero Decisionale

```
Entità da visualizzare?
├─ Stato pista (aperta/chiusa/pianificato)
│  └─ Usa StatusBadge (mappar a PillTone automaticamente)
│
├─ Categoria principale (pista/spot/negozio)
│  └─ Usa Pill(tone: PillTone.signal) → orange50 + orangeText
│
├─ Info neutra (conteggio, categoria secondaria)
│  └─ Usa Pill(tone: PillTone.neutral) → surfaceCool + onSurfaceMuted
│
├─ Info positiva (confermato, aperto)
│  └─ Usa Pill(tone: PillTone.success) → verde soft + statusOpen
│
├─ Info critica (chiuso, attenzione)
│  └─ Usa Pill(tone: PillTone.danger) → rosso soft + statusClosed
│
└─ Info informativa (conteggio presenze, dettagli)
   └─ Usa Pill(tone: PillTone.info) → blu soft + statusInfo
```

### Padding e Spacing nelle Card

- Media verso bordo: 0px (clip al bordo card)
- Padding interno contenuto: `AppSpacing.lg` (16px)
- Gap verticale tra slot: `AppSpacing.md` (12px)
- Gap tra header e subtitle: `AppSpacing.sm` (8px)
- Gap icona-testo (MetaRow): `AppSpacing.sm` (8px)
- Gap tra pill: `AppSpacing.sm` (8px)

## Do's & Don'ts

| ✅ Do | ❌ Don't |
|-------|---------|
| `BorderRadius.circular(AppRadius.xl)` | `BorderRadius.circular(24)` |
| `EdgeInsets.all(AppSpacing.lg)` | `EdgeInsets.all(16)` |
| `AppColors.surfaceMuted` | `Color(0xFFF8F7F3)` |
| `Pill(tone: PillTone.success)` | `Container(backgroundColor: Color(0xFF...)` |
| `Theme.of(context).textTheme.titleLarge` | `TextStyle(fontSize: 18, fontWeight: FontWeight.w700)` |
| `AppBreakpoints.isExpanded(width)` | `width >= 1100` |
| `StatusBadge(kind: StatusBadgeKind.open)` | `Pill con colore arancio hardcoded` |
| Layout responsivo con `LayoutBuilder` | Media size hardcoded (280px, 600px, ecc.) |
| `ContentScaffold` per pagine principali | Header custom fatto a mano |
| Pill wrappate con `Wrap(spacing: AppSpacing.sm)` | Row con spacing hardcoded |

## Migration Guide

Per chi aggiorna codice esistente:

### Colori

**Prima**:
```dart
Container(
  color: Color(0xFFF8F7F3),
  child: Text('Text', style: TextStyle(color: Color(0xFF4B5563))),
)
```

**Dopo**:
```dart
Container(
  color: AppColors.surfaceMuted,
  child: Text('Text', style: TextStyle(color: AppColors.onSurfaceMuted)),
)
```

### Spacing

**Prima**:
```dart
EdgeInsets.symmetric(horizontal: 16, vertical: 12)
```

**Dopo**:
```dart
EdgeInsets.symmetric(
  horizontal: AppSpacing.lg,
  vertical: AppSpacing.md,
)
```

### Border Radius

**Prima**:
```dart
BorderRadius.circular(24)
```

**Dopo**:
```dart
BorderRadius.circular(AppRadius.xl)
```

### Card Layout

**Prima**:
```dart
Card(
  child: Row(
    children: [
      SizedBox(width: 200, child: Image(...)),
      Expanded(child: Column(...)),
    ],
  ),
)
```

**Dopo**:
```dart
PlaceCard(
  media: Image(...),
  title: 'Title',
  subtitle: 'Subtitle',
  signals: [...],
  body: 'Body',
  footerLeading: Button(...),
)
```

### Responsività

**Prima**:
```dart
if (width < 600) {
  Column(children: [...])
} else {
  Row(children: [...])
}
```

**Dopo**:
```dart
// Interno a PlaceCard gestito automaticamente
// Oppure usa AppBreakpoints per logica custom:
if (AppBreakpoints.isCompact(width)) {
  Column(children: [...])
} else {
  Row(children: [...])
}
```

## Future Work

- **AppTypography**: classe esplicita che espone stili nominati (`cardTitle`, `pillLabel`, `metaLabel`) oltre al raw `TextTheme`.
- **Catalog screen**: route `/dev/components` in debug mode per preview di tutti i componenti affiancati con varianti.
- **Token motion**: durations e easings standard per animazioni (reveal, feedback, transizione).
- **Elevation/shadow**: se aggiunto al tema M3, documentare qui con esempio di uso su card, modal, floating action.
- **Widgetbook**: integrare un catalogo interattivo esterno per visualizzare componenti con diverse props.

## Riferimenti

- **UI Direction**: `docs/ui-direction.md` — principi e direzione strategica
- **Design System Audit**: `docs/design-system-audit.md` — analisi storica e priority actions
- **Theme**: `app/lib/app/theme/app_theme.dart` — implementazione Flutter
