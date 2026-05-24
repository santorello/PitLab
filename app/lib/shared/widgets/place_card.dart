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

  /// Aspect ratio media: 16:9 per mobile (Column), 4:3 per desktop (Row).
  /// Usato calcolato dopo aver risolto il layout.
  double _getMediaAspectRatio(bool isColumn) => isColumn ? 16 / 9 : 4 / 3;

  /// Larghezza media in Row layout.
  static const double _mediaWidthRow = 280;

  /// Spacing verticale tra gli slot.
  static const double _slotSpacing = 12;

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

  /// Costruisce il widget media con aspect ratio e clip.
  Widget _buildMediaSlot(bool isColumn) {
    final aspectRatio = _getMediaAspectRatio(isColumn);
    final mediaHeight = isColumn ? null : double.infinity;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: SizedBox(
          height: mediaHeight,
          child: media,
        ),
      ),
    );
  }

  /// Costruisce il contenuto (header, location, signals, body, footer).
  Widget _buildContent(BuildContext context) {
    final children = <Widget>[];

    // Header: titolo + typeBadge a destra.
    children.add(_buildHeader(context));

    // Subtitle (location).
    if (subtitle != null) {
      children.add(const SizedBox(height: _slotSpacing));
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
