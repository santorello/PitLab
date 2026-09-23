import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_colors.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/feedback/presentation/feedback_dialog.dart';
import '../../features/notifications/presentation/notification_bell.dart';
import '../../features/support/presentation/coffee_button.dart';
import '../../shared/widgets/pitlap_logo.dart';
import 'language_toggle.dart';

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  // Navigazione "A" (23/09/2026): Piste, Spot, Negozi, Vicino a te e Mappa
  // stanno dentro Esplora (schede in cima, vedi _ExploreTabs); le build hanno
  // una voce propria. Le rotte di prima restano tutte valide.
  static const _destinations = <_Destination>[
    _Destination(
      labelKey: 'home',
      labelFallback: 'Home',
      icon: Icons.home_outlined,
      location: '/',
    ),
    _Destination(
      labelKey: 'explore',
      labelFallback: 'Esplora',
      icon: Icons.explore_outlined,
      location: '/tracks',
    ),
    _Destination(
      labelKey: 'builds',
      labelFallback: 'Build',
      icon: Icons.precision_manufacturing_outlined,
      location: '/builds',
    ),
    _Destination(
      labelKey: 'events',
      labelFallback: 'Events',
      icon: Icons.event_outlined,
      location: '/events',
    ),
    // Su telefono le prime 4 voci stanno in barra, queste finiscono in "Altro"
    // (il profilo e' raggiungibile anche dal pulsante in alto).
    _Destination(
      labelKey: 'profile',
      labelFallback: 'Profile',
      icon: Icons.person_outline,
      location: '/profile',
    ),
    _Destination(
      labelKey: 'garage',
      labelFallback: 'Garage',
      icon: Icons.garage_outlined,
      location: '/garage',
    ),
    _Destination(
      labelKey: 'manager',
      labelFallback: 'Manager',
      icon: Icons.tune_outlined,
      location: '/manager',
    ),
  ];
  static const _adminDestination = _Destination(
    labelKey: 'admin',
    labelFallback: 'Admin',
    icon: Icons.admin_panel_settings_outlined,
    location: '/admin',
  );

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  bool _isRailExpanded = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = AppBreakpoints.isExpanded(screenWidth);
    final location = GoRouterState.of(context).uri.toString();
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final canManageTracks = ref.watch(canManageTracksProvider);
    // La voce "Gestione" serve anche a chi gestisce un negozio: prima era
    // condizionata alle sole piste, quindi uno shop_owner non la vedeva pur
    // avendo accesso alla pagina raggiungendola da altre strade.
    final canManageShops = ref.watch(canManageShopsProvider);
    final impersonation = ref.watch(impersonationProvider);
    final baseDestinations = currentUser == null
        ? AppScaffold._destinations
              .where(
                (item) =>
                    item.location != '/manager' &&
                    item.location != '/garage' &&
                    item.location != '/profile',
              )
              .toList()
        : AppScaffold._destinations
              .where(
                (item) =>
                    item.location != '/manager' ||
                    canManageTracks ||
                    canManageShops,
              )
              .toList();
    final visibleDestinations = [
      ...baseDestinations,
      if (isAdmin) AppScaffold._adminDestination,
    ];
    final selectedIndex = widget._selectedIndex(location, visibleDestinations);
    final l10n = AppLocalizations.of(context)!;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _isRailExpanded ? 220 : 88,
              child: NavigationRail(
                selectedIndex: selectedIndex < 0 ? null : selectedIndex,
                onDestinationSelected: (index) =>
                    context.go(visibleDestinations[index].location),
                scrollable: true,
                backgroundColor: AppColors.graphite,
                indicatorColor: AppColors.signalOrange,
                selectedIconTheme: const IconThemeData(color: Colors.white),
                unselectedIconTheme: const IconThemeData(
                  color: AppColors.concrete,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: AppColors.concrete,
                ),
                extended: _isRailExpanded,
                trailing: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => showFeedbackDialog(context),
                        icon: const Icon(Icons.feedback_outlined,
                            color: AppColors.concrete),
                        tooltip: 'Invia feedback',
                      ),
                      const CoffeeButton(color: AppColors.concrete),
                      const NotificationBell(),
                    ],
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isRailExpanded = !_isRailExpanded;
                          });
                        },
                        icon: Icon(
                          _isRailExpanded ? Icons.menu_open : Icons.menu,
                          color: Colors.white,
                        ),
                        tooltip: _isRailExpanded
                            ? l10n.menuClose
                            : l10n.menuOpen,
                      ),
                      if (_isRailExpanded)
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _isRailExpanded ? 1 : 0,
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                children: const [
                                  TextSpan(text: 'Pit'),
                                  TextSpan(
                                    text: 'Lap',
                                    style: TextStyle(
                                      color: AppColors.signalOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                destinations: visibleDestinations
                    .map(
                      (item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(widget._label(context, item)),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: _ScaffoldBodyWithImpersonationBanner(
                impersonation: impersonation,
                child: _withExploreTabs(location, widget.child),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const _MobileTopBar(),
      body: _ScaffoldBodyWithImpersonationBanner(
        impersonation: impersonation,
        child: _withExploreTabs(location, widget.child),
      ),
      bottomNavigationBar: _MobileNavigationBar(
        destinations: visibleDestinations,
        selectedIndex: selectedIndex,
        label: (item) => widget._label(context, item),
      ),
    );
  }
}

/// Barra inferiore con un numero di voci limitato.
///
/// Le destinazioni sono fino a dieci (utente admin che gestisce anche pista e
/// negozio): messe tutte in una NavigationBar a 400 px diventano colonne da
/// 40 px con le etichette spezzate a meta' parola. Qui ne restano
/// [_kPrimaryCount] in barra e le altre finiscono dietro "Altro", che apre un
/// foglio inferiore. Nessuna destinazione viene persa.
class _MobileNavigationBar extends StatelessWidget {
  const _MobileNavigationBar({
    required this.destinations,
    required this.selectedIndex,
    required this.label,
  });

  static const int _kPrimaryCount = 4;

  final List<_Destination> destinations;

  /// Indice nella lista completa, oppure -1 se la rotta corrente non
  /// corrisponde a nessuna voce (es. /notifications, /legal/*).
  final int selectedIndex;
  final String Function(_Destination) label;

  @override
  Widget build(BuildContext context) {
    if (destinations.length <= _kPrimaryCount + 1) {
      return NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (index) =>
            context.go(destinations[index].location),
        destinations: destinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: label(item),
              ),
            )
            .toList(),
      );
    }

    final primary = destinations.take(_kPrimaryCount).toList();
    final overflow = destinations.skip(_kPrimaryCount).toList();
    final isOverflowSelected = selectedIndex >= _kPrimaryCount;

    return NavigationBar(
      selectedIndex: isOverflowSelected
          ? _kPrimaryCount
          : (selectedIndex < 0 ? 0 : selectedIndex),
      onDestinationSelected: (index) {
        if (index == _kPrimaryCount) {
          _showOverflowSheet(context, overflow);
          return;
        }
        context.go(primary[index].location);
      },
      destinations: [
        ...primary.map(
          (item) => NavigationDestination(
            icon: Icon(item.icon),
            label: label(item),
          ),
        ),
        // Voce fissa: prima prendeva icona ed etichetta della pagina aperta
        // (Eventi, Negozi, Garage...) e la barra cambiava a ogni pagina.
        // L'evidenziazione basta a dire che si e' dentro "Altro".
        const NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'Altro',
        ),
      ],
    );
  }

  void _showOverflowSheet(BuildContext context, List<_Destination> items) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map(
                (item) => ListTile(
                  leading: Icon(item.icon),
                  title: Text(label(item)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(item.location);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ScaffoldBodyWithImpersonationBanner extends ConsumerWidget {
  const _ScaffoldBodyWithImpersonationBanner({
    required this.child,
    required this.impersonation,
  });

  final Widget child;
  final ImpersonationState? impersonation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = impersonation;
    if (active == null) return child;

    final displayName = active.displayName.isNotEmpty
        ? active.displayName
        : active.userId.substring(0, 8);

    return Column(
      children: [
        Material(
          color: AppColors.surfaceImpersonation,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.orange900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vista come $displayName · ${active.role}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.orange900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(impersonationProvider.notifier).stop();
                      context.go('/admin');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.orange900,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Esci'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ── Mobile top bar ────────────────────────────────────────────────────────────

class _MobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _MobileTopBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.graphite,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PitLapLogo(size: 30, shadow: false),
          const SizedBox(width: 10),
          RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          children: const [
            TextSpan(text: 'Pit'),
            TextSpan(
              text: 'Lap',
              style: TextStyle(color: AppColors.signalOrange),
            ),
          ],
        ),
      ),
        ],
      ),
      actions: const [
        NotificationBell(),
        _MobileOverflowMenu(),
        SizedBox(width: 4),
      ],
    );
  }
}

enum _MenuAction { language, feedback, coffee, account }

/// Menu ⋮ della barra su telefono: raccoglie con etichetta le azioni che
/// prima erano icone senza testo (feedback, caffe') piu' lingua e account.
class _MobileOverflowMenu extends ConsumerWidget {
  const _MobileOverflowMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isLoggedIn = ref.watch(currentUserProvider) != null;
    final isIt = Localizations.localeOf(context).languageCode == 'it';

    return PopupMenuButton<_MenuAction>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      tooltip: 'Menu',
      onSelected: (action) {
        switch (action) {
          case _MenuAction.language:
            toggleAppLanguage(context, ref);
          case _MenuAction.feedback:
            showFeedbackDialog(context);
          case _MenuAction.coffee:
            openDonationPage(context);
          case _MenuAction.account:
            context.go(isLoggedIn ? '/profile' : '/login');
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _MenuAction.account,
          child: ListTile(
            leading: Icon(isLoggedIn ? Icons.person_outline : Icons.login),
            title: Text(isLoggedIn ? l10n.profileTitle : l10n.loginCtaButton),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.language,
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(isIt ? 'Lingua: Italiano' : 'Language: English'),
            subtitle: Text(isIt ? 'Passa a English' : 'Switch to Italiano'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: _MenuAction.feedback,
          child: ListTile(
            leading: Icon(Icons.feedback_outlined),
            title: Text('Invia feedback'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (isDonationEnabled)
          const PopupMenuItem(
            value: _MenuAction.coffee,
            child: ListTile(
              leading: Icon(Icons.local_cafe_outlined),
              title: Text('Offri un caffè'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}

extension on AppScaffold {
  int _selectedIndex(String location, List<_Destination> destinations) {
    final uri = Uri.tryParse(location);
    final path = uri?.path ?? location;
    var normalizedLocation = path;
    if (isExplorePath(path) ||
        path.startsWith('/track/') ||
        path.startsWith('/spot/') ||
        path.startsWith('/shop/') ||
        path == '/submit-place') {
      normalizedLocation = '/tracks';
    } else if (path.startsWith('/event/')) {
      normalizedLocation = '/events';
    } else if (path.startsWith('/build/')) {
      normalizedLocation = '/builds';
    } else if (path.startsWith('/profiles') || path.startsWith('/u/')) {
      // FR-28: elenco/profilo pubblico → voce Profilo.
      normalizedLocation = '/profile';
    }
    final index = destinations.indexWhere((item) {
      if (item.location == '/') {
        return normalizedLocation == '/';
      }
      return normalizedLocation.startsWith(item.location);
    });
    // FR-28: -1 = nessuna voce corrispondente (es. /notifications, /legal/*).
    // Su desktop il NavigationRail mostra "nessuna selezione" invece di Home.
    return index;
  }

  String _label(BuildContext context, _Destination item) {
    final l10n = AppLocalizations.of(context)!;
    return switch (item.labelKey) {
      'home' => 'Home',
      'explore' => _exploreLabel(context),
      'builds' => 'Build',
      'tracks' => l10n.tracksTitle,
      'nearby' => l10n.nearbyTitle,
      'spots' => l10n.spotsTitle,
      'events' => l10n.eventsTitle,
      'shops' => l10n.shopsTitle,
      'manager' => l10n.managerTitle,
      'garage' => l10n.garageTitle,
      'profile' => l10n.profileTitle,
      'admin' => l10n.adminTitle,
      _ => item.labelFallback,
    };
  }
}

class _Destination {
  const _Destination({
    required this.labelKey,
    required this.labelFallback,
    required this.icon,
    required this.location,
  });

  final String labelKey;
  final String labelFallback;
  final IconData icon;
  final String location;
}

// ── Esplora ─────────────────────────────────────────────────────────────────

const _exploreTabs = <({String path, String it, String en, IconData icon})>[
  (path: '/tracks', it: 'Piste', en: 'Tracks', icon: Icons.flag_outlined),
  (path: '/spots', it: 'Spot', en: 'Spots', icon: Icons.location_pin),
  (path: '/shops', it: 'Negozi', en: 'Shops', icon: Icons.storefront_outlined),
  (path: '/nearby', it: 'Vicino a te', en: 'Nearby', icon: Icons.near_me_outlined),
  // Mappa unica di piste, spot, negozi ed eventi: e' la strada verso la
  // proposta B (mappa al centro) senza rifare niente.
  (path: '/spots/map', it: 'Mappa', en: 'Map', icon: Icons.map_outlined),
];

/// Le liste che vivono dentro Esplora (non le schede di dettaglio).
bool isExplorePath(String path) =>
    _exploreTabs.any((tab) => tab.path == path);

String _exploreLabel(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'it' ? 'Esplora' : 'Explore';

Widget _withExploreTabs(String location, Widget child) {
  final path = Uri.tryParse(location)?.path ?? location;
  if (!isExplorePath(path)) return child;
  return Column(
    children: [
      _ExploreTabs(currentPath: path),
      Expanded(child: child),
    ],
  );
}

// ponytail: le schede cambiano rotta (context.go), quindi i filtri di una
// lista si azzerano passando all'altra, come succedeva gia' con la barra.
// Tenerli vivi richiede un contenitore con IndexedStack: solo se serve.
class _ExploreTabs extends StatelessWidget {
  const _ExploreTabs({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final isIt = Localizations.localeOf(context).languageCode == 'it';
    return Material(
      color: AppColors.warmWhite,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(
          children: [
            for (final tab in _exploreTabs)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(tab.icon, size: 18),
                  label: Text(isIt ? tab.it : tab.en),
                  selected: tab.path == currentPath,
                  showCheckmark: false,
                  onSelected: (_) {
                    if (tab.path != currentPath) context.go(tab.path);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
