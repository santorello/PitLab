class AppBreakpoints {
  AppBreakpoints._();

  /// Sotto questa soglia i layout interni delle card vanno in stack verticale.
  static const double cardStack = 720;

  /// Sotto questa soglia AppScaffold usa NavigationBar in basso, sopra usa NavigationRail.
  /// Mantiene il valore gia' usato da AppScaffold per non rompere niente.
  static const double navRail = 1100;

  /// Larghezza massima del contenuto centrato in pagina, gia' usato da ContentScaffold.
  static const double contentMaxWidth = 1200;

  static bool isCompact(double width) => width < cardStack;
  static bool isMedium(double width) => width >= cardStack && width < navRail;
  static bool isExpanded(double width) => width >= navRail;
}
