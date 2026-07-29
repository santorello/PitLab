import 'package:flutter/material.dart';

import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Variante di layout per una PlaceCard.
enum PlaceCardVariant {
  /// Card standard per liste (track, spot, shop, event, build).
  standard,

  /// Card compatta per feed/preview (nearby, community).
  compact,
}

/// Card unificata per entita' di luogo (pista, spot, negozio, evento, build, nearby).
///
/// Provvede un layout responsive con media, titolo, subtitle, segnali, descrizione e azioni.
/// Tutti gli slot sono opzionali e costruiti dal chiamante.
///
/// Layout responsivo:
/// - Sotto [AppBreakpoints.cardStack] (720px): Column verticale (media in alto)
/// - Sopra 720px: Row orizzontale (media a sinistra, contenuto a destra)
///
/// Esempio:
/// ```dart
/// PlaceCard(
///   media: AdaptiveImage(...),
///   title: 'Pista RC Parma',
///   subtitle: 'Parma, Italia',
///   typeBadge: Pill(label: 'Pista RC'),
///   signals: [
///     Pill(label: 'APERTA'),
///     Pill(label: '7 oggi'),
///   ],
///   body: 'Fondo asciutto, buona trazione',
///   footerLeading: ElevatedButton(...),
///   footerActions: [IconButton(...), IconButton(...)],
///   onTap: () => context.go('/track/...'),
/// )
/// ```
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    required this.media,
    required this.title,
    this.overline,
    this.subtitle,
    this.typeBadge,
    this.signals,
    this.body,
    this.footerLeading,
    this.footerActions,
    this.onTap,
    this.variant = PlaceCardVariant.standard,
    super.key,
  });

  /// Widget media (immagine, placeholder, etc.). Costruito dal chiamante.
  final Widget media;

  /// Overline opzionale sopra il titolo (piccolo, muted, es. "Bologna · Pista RC").
  final String? overline;

  /// Titolo principale della card.
  final String title;

  /// Sottotitolo opzionale (es. location).
  final String? subtitle;

  /// Badge di tipo opzionale (es. "Pista RC", "Spot", "Negozio").
  /// Posizionato in alto a destra dell'header.
  final Widget? typeBadge;

  /// Riga di pill segnali (max 3-4 visibili, es. stato, presenze, specialita').
  final List<Widget>? signals;

  /// Descrizione opzionale (max 2 righe).
  final String? body;

  /// CTA primario (es. ElevatedButton "Apri", "Vedi").
  /// Posizionato a sinistra nel footer, occupa spazio disponibile.
  final Widget? footerLeading;

  /// Azioni secondarie come icone (follow, share, edit).
  /// Posizionate a destra nel footer, no expanded.
  final List<Widget>? footerActions;

  /// Callback quando la card viene tappata.
  final VoidCallback? onTap;

  /// Variante di layout.
  final PlaceCardVariant variant;

  /// Colore di background basato sulla variante.
  Color _resolveBackgroundColor() {
    return switch (variant) {
      PlaceCardVariant.standard => AppColors.panel,
      PlaceCardVariant.compact => AppColors.surfaceMuted,
    };
  }

  /// Padding interno della card.
  EdgeInsets get _padding => EdgeInsets.all(AppSpacing.lg);

  /// Aspect ratio media: 21:9 in Column (banner più basso, meno aria), 4:3 in Row.
  /// Usato calcolato dopo aver risolto il layout.
  double _getMediaAspectRatio(bool isColumn) => isColumn ? 21 / 9 : 4 / 3;

  /// Larghezza media in Row layout.
  static const double _mediaWidthRow = 280;

  /// Spacing verticale tra gli slot.
  static const double _slotSpacing = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determina se usare layout colonna o riga.
        final isCompactLayout =
            constraints.maxWidth < AppBreakpoints.cardStack;

        // Costruisci il media con aspect ratio e border radius.
        final mediaWidget = _buildMediaSlot(isCompactLayout);

        // Costruisci il contenuto (header, location, signals, body, footer).
        final contentWidget = _buildContent(context);

        // Assembla il layout.
        final layoutWidget = isCompactLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [mediaWidget, contentWidget],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _mediaWidthRow,
                    child: mediaWidget,
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(child: contentWidget),
                ],
              );

        // Wrappa in Card + InkWell per tap e styling.
        return Card(
          color: _resolveBackgroundColor(),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: const BorderSide(
              color: AppColors.borderStrong,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: _padding,
                child: layoutWidget,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Altezza fissa del banner media in layout Column: evita il gradiente enorme
  /// quando manca l'immagine reale, senza dipendere dalla larghezza della card.
  static const double _mediaHeightColumn = 168;

  /// Costruisce il widget media con clip.
  Widget _buildMediaSlot(bool isColumn) {
    if (isColumn) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: _mediaHeightColumn,
          width: double.infinity,
          child: media,
        ),
      );
    }

    // Row layout: media a sinistra, riempie l'altezza del contenuto.
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: _getMediaAspectRatio(false),
        child: SizedBox(
          height: double.infinity,
          child: media,
        ),
      ),
    );
  }

  /// Costruisce il contenuto (header, location, signals, body, footer).
  Widget _buildContent(BuildContext context) {
    final children = <Widget>[];

    // Overline (es. "Bologna · Pista RC") sopra il titolo.
    if (overline != null && overline!.isNotEmpty) {
      children.add(
        Text(
          overline!.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceMuted,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
        ),
      );
      children.add(const SizedBox(height: 3));
    }

    // Header: titolo + typeBadge a destra.
    children.add(_buildHeader(context));

    // Subtitle (location) — gap ridotto per legarlo al titolo (blocco identità).
    if (subtitle != null) {
      children.add(const SizedBox(height: 4));
      children.add(
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
        ),
      );
    }

    // Signals row.
    if (signals != null && signals!.isNotEmpty) {
      children.add(const SizedBox(height: _slotSpacing));
      children.add(
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: signals!,
        ),
      );
    }

    // Body (descrizione).
    if (body != null && body!.isNotEmpty) {
      children.add(const SizedBox(height: _slotSpacing));
      children.add(
        Text(
          body!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.graphite,
              ),
        ),
      );
    }

    // Footer: CTA leading + azioni trailing.
    if (footerLeading != null || (footerActions != null && footerActions!.isNotEmpty)) {
      children.add(const SizedBox(height: _slotSpacing));
      children.add(_buildFooter());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Costruisce l'header: titolo a sinistra + typeBadge a destra.
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.graphite,
                ),
          ),
        ),
        if (typeBadge != null) ...[
          SizedBox(width: AppSpacing.sm),
          typeBadge!,
        ],
      ],
    );
  }

  /// Costruisce il footer: footerLeading (expanded) + footerActions (no expanded).
  Widget _buildFooter() {
    return Row(
      children: [
        if (footerLeading != null) Expanded(child: footerLeading!),
        if (footerActions != null && footerActions!.isNotEmpty) ...[
          if (footerLeading != null) SizedBox(width: AppSpacing.sm),
          ...footerActions!,
        ],
      ],
    );
  }
}
