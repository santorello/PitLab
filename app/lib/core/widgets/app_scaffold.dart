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

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  static const _destinations = <_Destination>[
    _Destination(
      labelKey: 'home',
      labelFallback: 'Home',
      icon: Icons.home_outlined,
      location: '/',
    ),
    _Destination(
      labelKey: 'tracks',
      labelFallback: 'Piste',
      icon: Icons.flag_outlined,
      location: '/tracks',
    ),
    _Destination(
      labelKey: 'nearby',
      labelFallback: 'Nearby',
      icon: Icons.explore_outlined,
      location: '/nearby',
    ),
    _Destination(
      labelKey: 'spots',
      labelFallback: 'Spots',
      icon: Icons.location_pin,
      location: '/spots',
    ),
    _Destination(
      labelKey: 'events',
      labelFallback: 'Events',
      icon: Icons.event_outlined,
      location: '/events',
    ),
    _Destination(
      labelKey: 'shops',
      labelFallback: 'Shops',
      icon: Icons.storefront_outlined,
      location: '/shops',
    ),
    _Destination(
      labelKey: 'manager',
      labelFallback: 'Manager',
      icon: Icons.tune_outlined,
      location: '/manager',
    ),
    _Destination(
      labelKey: 'garage',
      labelFallback: 'Garage',
      icon: Icons.precision_manufacturing_outlined,
      location: '/garage',
    ),
    _Destination(
      labelKey: 'profile',
      labelFallback: 'Profile',
      icon: Icons.person_outline,
      location: '/profile',
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
                child: widget.child,
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
        child: widget.child,
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
        NavigationDestination(
          icon: Icon(
            isOverflowSelected
                ? destinations[selectedIndex].icon
                : Icons.more_horiz,
          ),
          label: isOverflowSelected
              ? label(destinations[selectedIndex])
              : 'Altro',
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
      title: RichText(
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
      actions: [
        IconButton(
          onPressed: () => showFeedbackDialog(context),
          icon: const Icon(Icons.feedback_outlined, color: Colors.white),
          tooltip: 'Invia feedback',
        ),
        const CoffeeButton(),
        const NotificationBell(),
        const SizedBox(width: 4),
      ],
    );
  }
}

extension on AppScaffold {
  int _selectedIndex(String location, List<_Destination> destinations) {
    final uri = Uri.tryParse(location);
    final path = uri?.path ?? location;
    var normalizedLocation = path;
    if (path.startsWith('/track/')) {
      normalizedLocation = '/tracks';
    } else if (path.startsWith('/spot/')) {
      normalizedLocation = '/spots';
    } else if (path == '/submit-place') {
      switch (uri?.queryParameters['type']) {
        case 'spot':
          normalizedLocation = '/spots';
          break;
        case 'shop':
          normalizedLocation = '/shops';
          break;
        default:
          normalizedLocation = '/tracks';
          break;
      }
    } else if (path.startsWith('/shop/')) {
      normalizedLocation = '/shops';
    } else if (path.startsWith('/event/')) {
      normalizedLocation = '/events';
    } else if (path.startsWith('/builds')) {
      // FR-28: le build pubbliche appartengono al mondo Garage.
      normalizedLocation = '/garage';
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
