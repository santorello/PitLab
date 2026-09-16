import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_colors.dart';
import 'content_scaffold_header.dart';
import 'environment_banner.dart';

class ContentScaffold extends ConsumerWidget {
  const ContentScaffold({
    required this.title,
    required this.description,
    required this.child,
    this.trailingActions,
    super.key,
  });

  final String title;
  final String description;
  final Widget child;

  /// Widget aggiuntivi inseriti a destra del bottone login/profilo.
  /// Usato ad esempio da TracksHomeScreen per il selettore lingua.
  final List<Widget>? trailingActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPhone =
        AppBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
    final side = isPhone ? 16.0 : 24.0;
    // Sfondo opaco: evita il "bleed" della pagina precedente durante le
    // transizioni go_router (le pagine figlie non hanno uno Scaffold proprio).
    return ColoredBox(
      color: AppColors.warmWhite,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.contentMaxWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, isPhone ? 12 : 24, side, 0),
              // Intestazione fissa + area contenuto che occupa il resto.
              //
              // NON rimettere qui un CustomScrollView con
              // SliverFillRemaining(hasScrollBody: true): quasi tutte le
              // schermate passano una ListView come [child], quindi si
              // creavano DUE scrollabili sovrapposti. La rotella andava a
              // quello sotto il puntatore e lo scroll esterno aveva una
              // corsa pari all'altezza dell'intestazione: il risultato era
              // la pagina che "saltava" e sembrava non scorrere.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EnvironmentBanner(),
                  ContentScaffoldHeader(
                    title: title,
                    description: description,
                    trailingActions: trailingActions,
                  ),
                  SizedBox(height: isPhone ? 12 : 24),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isPhone ? 12 : 24),
                      child: isPhone ? _PhoneTypography(child: child) : child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Su telefono i titoli "da vetrina" delle pagine (display/headline) vengono
/// portati a una scala adatta a 360 px. Agisce sul tema, quindi vale per tutte
/// le schermate senza toccarle una per una; chi usa `copyWith(color: ...)`
/// mantiene il proprio colore.
class _PhoneTypography extends StatelessWidget {
  const _PhoneTypography({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    TextStyle? size(TextStyle? style, TextStyle? target) =>
        style?.copyWith(fontSize: target?.fontSize, height: target?.height);
    return Theme(
      data: theme.copyWith(
        textTheme: t.copyWith(
          displayLarge: size(t.displayLarge, t.headlineMedium),
          displayMedium: size(t.displayMedium, t.headlineSmall),
          displaySmall: size(t.displaySmall, t.headlineSmall),
          headlineLarge: size(t.headlineLarge, t.headlineSmall),
          headlineMedium: size(t.headlineMedium, t.titleLarge),
          headlineSmall: size(t.headlineSmall, t.titleLarge),
          bodyLarge: size(t.bodyLarge, t.bodyMedium),
        ),
      ),
      child: child,
    );
  }
}
