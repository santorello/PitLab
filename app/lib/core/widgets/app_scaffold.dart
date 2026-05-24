import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/app_breakpoints.dart';
import '../../app/theme/app_colors.dart';
import '../../features/auth/application/auth_providers.dart';

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
              .where((item) => item.location != '/manager' || canManageTracks)
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
                selectedIndex: selectedIndex,
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
                trailing: null,
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
                child: widget.child,
                impersonation: impersonation,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: _ScaffoldBodyWithImpersonationBanner(
        child: widget.child,
        impersonation: impersonation,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            context.go(visibleDestinations[index].location),
        destinations: visibleDestinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: widget._label(context, item),
              ),
            )
            .toList(),
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
    }
    final index = destinations.indexWhere((item) {
      if (item.location == '/') {
        return normalizedLocation == '/';
      }
      return normalizedLocation.startsWith(item.location);
    });
    return index < 0 ? 0 : index;
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
