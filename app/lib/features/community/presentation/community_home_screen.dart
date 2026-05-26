import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_breakpoints.dart';
import '../../../app/theme/app_colors.dart';
import '../../../features/auth/application/auth_providers.dart';
import '../../../features/location/application/user_location_context_provider.dart';
import '../../../features/pitcoin/providers/pitcoin_providers.dart';
import '../../../features/shops/application/public_shops_provider.dart';
import '../../../features/spots/application/spots_providers.dart';
import '../../../features/tracks/application/tracks_providers.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../application/activity_feed_provider.dart';
import '../application/home_dashboard_provider.dart';
import '../domain/activity_feed_item.dart';

class CommunityHomeScreen extends ConsumerWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(homeOverviewStatsProvider);
    final featuredAsync = ref.watch(homeFeaturedTrackProvider);
    final trendingAsync = ref.watch(homeTrendingTracksProvider);
    final leaderboardAsync = ref.watch(pitcoinPublicLeaderboardProvider);
    final feedAsync = ref.watch(activityFeedProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final weatherAsync = ref.watch(homeTrackWeatherProvider);
    final buildOfWeekAsync = ref.watch(homeBuildOfWeekProvider);
    final locationAsync = ref.watch(userLocationContextProvider);
    final trackPinsAsync = ref.watch(publicTrackPinsProvider);
    final spots = ref.watch(spotEntriesProvider);
    final shopsAsync = ref.watch(publicShopsProvider);
    final balanceAsync = ref.watch(effectiveUserPitcoinBalanceProvider);
    final deltaAsync = ref.watch(effectiveUserPitcoinRecentDeltaProvider);
    final streakAsync = ref.watch(myPitcoinStreakProvider);
    final profile = profileAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final displayName = _homeDisplayName(
      profileName: profile?.displayName,
      email: user?.email,
    );
    final location = locationAsync.maybeWhen(
      data: (value) => value,
      orElse: () => UserLocationContext.none,
    );
    final trackPins = trackPinsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const [],
    );
    final shops = shopsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const [],
    );
    final hasGeoContext = location.hasCoordinates;
    final mappableSpots = spots
        .where((spot) => spot.latitude != null && spot.longitude != null)
        .toList();
    final mappableShops = shops
        .where((shop) => shop.latitude != null && shop.longitude != null)
        .toList();
    final nearbyTracks = hasGeoContext
        ? trackPins
            .where((track) => isWithinUserRadius(
                  location: location,
                  latitude: track.latitude,
                  longitude: track.longitude,
                ))
            .toList()
        : trackPins;
    final nearbySpots = hasGeoContext
        ? mappableSpots
            .where((spot) => isWithinUserRadius(
                  location: location,
                  latitude: spot.latitude!,
                  longitude: spot.longitude!,
                ))
            .toList()
        : mappableSpots;
    final nearbyShops = hasGeoContext
        ? mappableShops
            .where((shop) => isWithinUserRadius(
                  location: location,
                  latitude: shop.latitude!,
                  longitude: shop.longitude!,
                ))
            .toList()
        : mappableShops;

    return ColoredBox(
      color: AppColors.warmWhite,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidth,
            ),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.sizeOf(context).width < AppBreakpoints.cardStack
                        ? 18
                        : 24,
                    18,
                    MediaQuery.sizeOf(context).width < AppBreakpoints.cardStack
                        ? 18
                        : 24,
                    120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TopBar(userLabel: user?.email),
                      const SizedBox(height: 14),
                      _GreetingCard(
                        greeting: _timeGreeting(DateTime.now()),
                        userName: displayName,
                        openTracks: statsAsync.maybeWhen(
                          data: (stats) => stats.openTracks,
                          orElse: () => 0,
                        ),
                        weatherAsync: weatherAsync,
                      ),
                      const SizedBox(height: 12),
                      if (user != null)
                        _PitcoinStrip(
                          totalPoints: balanceAsync.maybeWhen(
                            data: (balance) => balance?.totalPoints ?? 0,
                            orElse: () => 0,
                          ),
                          recentDelta: deltaAsync.maybeWhen(
                            data: (delta) => delta,
                            orElse: () => 0,
                          ),
                          streakDays: streakAsync.maybeWhen(
                            data: (streak) => streak,
                            orElse: () => 0,
                          ),
                        )
                      else
                        const _GuestPitcoinNotice(),
                      const SizedBox(height: 14),
                      const _QuickActions(),
                      const SizedBox(height: 18),
                      _WeatherStrip(weatherAsync: weatherAsync),
                      const SizedBox(height: 18),
                      _NearbyMapPreview(
                        trackCount: nearbyTracks.length,
                        openTrackCount: nearbyTracks
                            .where((track) => track.status == 'open')
                            .length,
                        spotCount: nearbySpots.length,
                        shopCount: nearbyShops.length,
                        isLocalized: hasGeoContext,
                        radiusKm: location.radiusKm,
                      ),
                      const SizedBox(height: 18),
                      _BuildOfWeekSection(buildAsync: buildOfWeekAsync),
                      featuredAsync.maybeWhen(
                        data: (track) => track == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: _FeaturedTrackCard(track: track),
                              ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 18),
                      _OverviewStatsGrid(statsAsync: statsAsync),
                      const SizedBox(height: 18),
                      _TrendingTracksSection(trendingAsync: trendingAsync),
                      const SizedBox(height: 18),
                      _LeaderboardSection(leaderboardAsync: leaderboardAsync),
                      const SizedBox(height: 18),
                      _FeedSection(feedAsync: feedAsync),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.userLabel});

  final String? userLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.signalOrange, AppColors.orange200],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.signalOrange.withAlpha(80),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.bolt, color: Colors.white),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
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
        const Spacer(),
        IconButton.filledTonal(
          onPressed: () => context.push(userLabel == null ? '/login' : '/profile'),
          icon: Icon(userLabel == null ? Icons.login : Icons.person_outline),
          tooltip: userLabel == null ? 'Accedi' : 'Profilo',
        ),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.greeting,
    required this.userName,
    required this.openTracks,
    required this.weatherAsync,
  });

  final String greeting;
  final String userName;
  final int openTracks;
  final AsyncValue<List<HomeTrackWeather>> weatherAsync;

  @override
  Widget build(BuildContext context) {
    final firstWeather = weatherAsync.maybeWhen(
      data: (items) => items.isEmpty ? null : items.first,
      orElse: () => null,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2937), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(36),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  greeting,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (firstWeather != null)
                _WeatherPill(weather: firstWeather, dark: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            openTracks > 0
                ? 'Oggi risultano $openTracks piste aperte su PitLap.'
                : 'Dove il modellismo si incontra.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeatherStrip extends StatelessWidget {
  const _WeatherStrip({required this.weatherAsync});

  final AsyncValue<List<HomeTrackWeather>> weatherAsync;

  @override
  Widget build(BuildContext context) {
    final items = weatherAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <HomeTrackWeather>[],
    );

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Meteo alle tue piste',
          actionLabel: 'Open-Meteo',
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 156,
                child: _WeatherCard(weather: item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});

  final HomeTrackWeather weather;

  @override
  Widget build(BuildContext context) {
    final color = _weatherColor(weather);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weather.city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.steel,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                weather.temperatureC == null ? '--' : '${weather.temperatureC}°',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.graphite,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Icon(_weatherIcon(weather), color: color, size: 28),
            ],
          ),
          Text(
            weather.trackName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _PitcoinStrip extends StatelessWidget {
  const _PitcoinStrip({
    required this.totalPoints,
    required this.recentDelta,
    required this.streakDays,
  });

  final int totalPoints;
  final int recentDelta;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _MetricCard(
              label: 'PitCoin',
              value: '$totalPoints PC',
              hint: recentDelta > 0
                  ? '+$recentDelta ultimi 7 giorni'
                  : 'Saldo reale',
              icon: Icons.paid_outlined,
              tint: AppColors.warningAmber,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: _MetricCard(
              label: 'Streak',
              value: '$streakDays gg',
              hint: 'Da transazioni',
              icon: Icons.local_fire_department_outlined,
              tint: AppColors.signalOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyMapPreview extends StatelessWidget {
  const _NearbyMapPreview({
    required this.trackCount,
    required this.openTrackCount,
    required this.spotCount,
    required this.shopCount,
    required this.isLocalized,
    required this.radiusKm,
  });

  final int trackCount;
  final int openTrackCount;
  final int spotCount;
  final int shopCount;
  final bool isLocalized;
  final double radiusKm;

  @override
  Widget build(BuildContext context) {
    final mappedTotal = trackCount + spotCount + shopCount;
    final subtitleParts = [
      if (openTrackCount > 0) '$openTrackCount aperte',
      if (trackCount > 0) '$trackCount piste',
      if (spotCount > 0) '$spotCount spot',
      if (shopCount > 0) '$shopCount negozi',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Vicino a te',
          actionLabel: 'mappa intera',
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => context.push('/spots/map'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 170,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7FB),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wetBlue.withAlpha(18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _MiniMapBackground()),
                Positioned(
                  left: 36,
                  top: 36,
                  child: _MapBubble(
                    label: '${(spotCount + 1).clamp(1, 9)}',
                    color: AppColors.openGreen,
                  ),
                ),
                Positioned(
                  right: 48,
                  top: 48,
                  child: _MapBubble(
                    label: '${(shopCount + 1).clamp(1, 9)}',
                    color: AppColors.signalOrange,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 22),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(238),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.wetBlue.withAlpha(26),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.add_location_alt_outlined,
                              color: AppColors.wetBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mappedTotal > 0
                                      ? isLocalized
                                          ? '$mappedTotal luoghi entro ${radiusKm.round()} km'
                                          : '$mappedTotal luoghi in mappa'
                                      : 'Apri la mappa PitLap',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.graphite,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                Text(
                                  subtitleParts.isEmpty
                                      ? 'Piste, spot e negozi RC'
                                      : subtitleParts.join(' - '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.steel),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.signalOrange,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapBubble extends StatelessWidget {
  const _MapBubble({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _MiniMapBackground extends StatelessWidget {
  const _MiniMapBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MiniMapPainter());
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE6F7FB);
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = const Color(0xFFB9D5E0).withAlpha(70)
      ..strokeWidth = 1;
    for (double x = 36; x < size.width; x += 54) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 28; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final green = Paint()..color = const Color(0xFF86EFAC).withAlpha(150);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.34),
        width: size.width * 0.28,
        height: 58,
      ),
      green,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.56),
        width: size.width * 0.34,
        height: 66,
      ),
      green,
    );

    final roadPaint = Paint()
      ..color = const Color(0xFFF6D86B).withAlpha(190)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.06, size.height * 0.52),
      Offset(size.width * 0.94, size.height * 0.52),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.08),
      Offset(size.width * 0.5, size.height * 0.92),
      roadPaint,
    );

    final blueRoad = Paint()
      ..color = AppColors.wetBlue.withAlpha(90)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * -0.05, size.height * 0.76),
      Offset(size.width * 1.05, size.height * 0.36),
      blueRoad,
    );

    final userPaint = Paint()..color = AppColors.wetBlue.withAlpha(90);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.52), 28, userPaint);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.52),
      8,
      Paint()..color = AppColors.wetBlue,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) => false;
}

class _BuildOfWeekSection extends StatelessWidget {
  const _BuildOfWeekSection({required this.buildAsync});

  final AsyncValue<HomeBuildOfWeek?> buildAsync;

  @override
  Widget build(BuildContext context) {
    final build = buildAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );

    if (build == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Build della settimana',
          actionLabel: 'tutte le build',
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => context.push('/garage'),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(34),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AdaptiveImage(
                        source: build.primaryImageUrl,
                        fit: BoxFit.cover,
                        fallback: const _BuildHeroFallback(),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(12),
                              Colors.black.withAlpha(98),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        top: 18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFBBF24).withAlpha(80),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            'TROFEO BUILD',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.orange900,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        build.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          'by ${_authorLabel(build)}',
                          if (build.meta.trim().isNotEmpty) build.meta.trim(),
                          if (build.awardedPoints > 0) '+${build.awardedPoints} PC',
                        ].join(' - '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _DarkStatIcon(
                            icon: Icons.favorite,
                            label: '${build.weeklyVotes}',
                            color: const Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 16),
                          _DarkStatIcon(
                            icon: Icons.chat_bubble,
                            label: '${build.commentCount}',
                            color: Colors.white70,
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 6),
                          Text(
                            'Featured',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: const Color(0xFFFBBF24),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkStatIcon extends StatelessWidget {
  const _DarkStatIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _BuildHeroFallback extends StatelessWidget {
  const _BuildHeroFallback();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BuildHeroPainter());
  }
}

class _BuildHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF374151), Color(0xFF111827)],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final shadowPaint = Paint()..color = Colors.black.withAlpha(120);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.78),
        width: size.width * 0.72,
        height: 32,
      ),
      shadowPaint,
    );

    final bodyPaint = Paint()..color = AppColors.signalOrange;
    final body = Path()
      ..moveTo(size.width * 0.18, size.height * 0.58)
      ..lineTo(size.width * 0.27, size.height * 0.43)
      ..lineTo(size.width * 0.62, size.height * 0.43)
      ..lineTo(size.width * 0.76, size.height * 0.58)
      ..lineTo(size.width * 0.80, size.height * 0.68)
      ..lineTo(size.width * 0.16, size.height * 0.68)
      ..close();
    canvas.drawPath(body, bodyPaint);

    final roofPaint = Paint()..color = AppColors.orange200;
    final roof = Path()
      ..moveTo(size.width * 0.33, size.height * 0.39)
      ..lineTo(size.width * 0.42, size.height * 0.28)
      ..lineTo(size.width * 0.64, size.height * 0.28)
      ..lineTo(size.width * 0.72, size.height * 0.43)
      ..close();
    canvas.drawPath(roof, roofPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF7C2D12)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.20, size.height * 0.60),
      Offset(size.width * 0.78, size.height * 0.60),
      linePaint,
    );

    void wheel(double x) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * 0.69),
        24,
        Paint()..color = const Color(0xFF0F172A),
      );
      canvas.drawCircle(
        Offset(size.width * x, size.height * 0.69),
        12,
        Paint()..color = const Color(0xFF334155),
      );
      canvas.drawCircle(
        Offset(size.width * x, size.height * 0.69),
        6,
        Paint()..color = const Color(0xFFFBBF24),
      );
    }

    wheel(0.29);
    wheel(0.70);

    final antenna = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.32),
      Offset(size.width * 0.82, size.height * 0.16),
      antenna,
    );
    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.14),
      7,
      Paint()..color = const Color(0xFFEF4444),
    );
  }

  @override
  bool shouldRepaint(covariant _BuildHeroPainter oldDelegate) => false;
}

class _GuestPitcoinNotice extends StatelessWidget {
  const _GuestPitcoinNotice();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          const Icon(Icons.lock_open_outlined, color: AppColors.signalOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Accedi per vedere PitCoin, streak e garage collegati al tuo profilo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction('Vado oggi', Icons.directions_car_outlined, '/tracks'),
      _QuickAction('Cerca pista', Icons.flag_outlined, '/tracks'),
      _QuickAction('Eventi', Icons.event_outlined, '/events'),
      _QuickAction('Garage', Icons.precision_manufacturing_outlined, '/garage'),
      _QuickAction('Aggiungi spot', Icons.add_location_alt_outlined, '/submit-place?type=spot'),
      _QuickAction('Negozi', Icons.storefront_outlined, '/shops'),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          return ActionChip(
            avatar: Icon(action.icon, size: 17),
            label: Text(action.label),
            onPressed: () => context.push(action.route),
            backgroundColor: index == 0 ? AppColors.signalOrange : AppColors.panel,
            side: BorderSide(
              color: index == 0 ? AppColors.signalOrange : AppColors.concrete,
            ),
            labelStyle: TextStyle(
              color: index == 0 ? Colors.white : AppColors.graphite,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

class _ComingSoonStories extends StatelessWidget {
  const _ComingSoonStories();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Live ai box',
          actionLabel: 'Arriva presto',
        ),
        const SizedBox(height: 10),
        _SurfaceCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.orange50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: AppColors.signalOrange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arriva presto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.graphite,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'Mostreremo solo presenze reali e privacy-safe quando il contratto dati sara pronto.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.steel,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedTrackCard extends StatelessWidget {
  const _FeaturedTrackCard({required this.track});

  final HomeTrendingTrack track;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Pista del giorno'),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => context.push('/track/${track.slug}'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 250,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B1F2A), Color(0xFF0F172A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DarkPill(label: _statusLabel(track.status)),
                    const Spacer(),
                    _DarkPill(label: 'Trend ${track.trendScore}'),
                  ],
                ),
                const Spacer(),
                Text(
                  track.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (track.city.isNotEmpty) track.city,
                    if (track.shortDescription.isNotEmpty) track.shortDescription,
                  ].join(' - '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => context.push('/track/${track.slug}'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Apri scheda'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.signalOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewStatsGrid extends StatelessWidget {
  const _OverviewStatsGrid({required this.statsAsync});

  final AsyncValue<HomeOverviewStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    final stats = statsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => HomeOverviewStats.empty,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 360
            ? 1
            : width < 560
                ? 2
                : width < 720
                    ? 3
                    : 5;
        final cardHeight = width < 420 ? 104.0 : 112.0;
        final metrics = [
          _MetricCard(
            label: 'Piste aperte',
            value: '${stats.openTracks}',
            hint: 'Ora',
            icon: Icons.radio_button_checked,
            tint: AppColors.openGreen,
          ),
          _MetricCard(
            label: 'Eventi',
            value: '${stats.eventsNext30Days}',
            hint: '30 giorni',
            icon: Icons.event_outlined,
            tint: AppColors.signalOrange,
          ),
          _MetricCard(
            label: 'Nuovi spot',
            value: '${stats.newSpots30Days}',
            hint: '30 giorni',
            icon: Icons.add_location_alt_outlined,
            tint: AppColors.wetBlue,
          ),
          _MetricCard(
            label: 'Negozi',
            value: '${stats.publicShops}',
            hint: '${stats.geocodedShops} in mappa',
            icon: Icons.storefront_outlined,
            tint: AppColors.statusOpen,
          ),
          _MetricCard(
            label: 'Build',
            value: '${stats.publicBuilds}',
            hint: 'Pubbliche',
            icon: Icons.precision_manufacturing_outlined,
            tint: AppColors.warningAmber,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) => metrics[index],
        );
      },
    );
  }
}

class _TrendingTracksSection extends StatelessWidget {
  const _TrendingTracksSection({required this.trendingAsync});

  final AsyncValue<List<HomeTrendingTrack>> trendingAsync;

  @override
  Widget build(BuildContext context) {
    final tracks = trendingAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <HomeTrendingTrack>[],
    );

    if (tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Piste in trend'),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _TrendingTrackTile(track: tracks[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _TrendingTrackTile extends StatelessWidget {
  const _TrendingTrackTile({required this.track});

  final HomeTrendingTrack track;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/track/${track.slug}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: _statusColor(track.status),
                ),
                const Spacer(),
                Text(
                  '${track.trendScore}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              track.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            Text(
              '${track.city} - ${track.arrivalsToday} oggi - ${track.events30d} eventi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.steel,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({required this.leaderboardAsync});

  final AsyncValue<List<PitcoinLeaderboardEntry>> leaderboardAsync;

  @override
  Widget build(BuildContext context) {
    final entries = leaderboardAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <PitcoinLeaderboardEntry>[],
    );
    final hasScores = entries.any((entry) => entry.totalPoints > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Classifica PitCoin'),
        const SizedBox(height: 10),
        if (!hasScores)
          const _EmptyStateCard(
            icon: Icons.emoji_events_outlined,
            title: 'Classifica in partenza',
            body: 'Il ranking apparira quando i profili pubblici avranno punti reali.',
          )
        else
          _SurfaceCard(
            child: Column(
              children: entries.take(3).indexed.map((indexedEntry) {
                final position = indexedEntry.$1 + 1;
                final entry = indexedEntry.$2;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.orange50,
                    child: Text(
                      '$position',
                      style: const TextStyle(
                        color: AppColors.orangeText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(entry.displayName),
                  subtitle: Text('@${entry.publicSlug}'),
                  trailing: Text(
                    '${entry.totalPoints} PC',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () => context.push('/u/${entry.publicSlug}'),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _FeedSection extends StatelessWidget {
  const _FeedSection({required this.feedAsync});

  final AsyncValue<List<ActivityFeedItem>> feedAsync;

  @override
  Widget build(BuildContext context) {
    final items = feedAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <ActivityFeedItem>[],
    );

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Novita dalla community',
        ),
        const SizedBox(height: 12),
        ...items.take(8).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ActivityCard(item: item),
              ),
            ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final ActivityFeedItem item;

  @override
  Widget build(BuildContext context) {
    final accent = _eventColor(item.eventType);
    final imageSource = item.primaryImageUrl;
    final meta = [
      if (item.actorCity.trim().isNotEmpty) item.actorCity.trim(),
      _relativeTimeLabel(item.createdAt),
    ].join(' - ');

    return InkWell(
      onTap: () => _openActivity(context, item),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 142,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AdaptiveImage(
                    source: imageSource,
                    fit: BoxFit.cover,
                    fallback: _ActivityHeroFallback(
                      item: item,
                      accent: accent,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(10),
                          Colors.black.withAlpha(92),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: _DarkPill(label: _eventHeroLabel(item.eventType)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ActivityAvatar(
                        label: item.actorName,
                        color: accent,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.actorName.isEmpty ? 'Community' : item.actorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.graphite,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.steel,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _SmallPill(label: _eventLabel(item.eventType), color: accent),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.steel,
                          ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () => _openActivity(context, item),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        child: Text(_primaryActivityAction(item.eventType)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _openActivity(context, item),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.graphite,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Dettagli'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _ActivityMetaIcon(
                    icon: Icons.favorite_outline,
                    label: '0',
                    color: const Color(0xFFE11D48),
                  ),
                  const SizedBox(width: 16),
                  _ActivityMetaIcon(
                    icon: Icons.chat_bubble_outline,
                    label: '0 commenti',
                    color: AppColors.steel,
                  ),
                  const Spacer(),
                  _ActivityMetaIcon(
                    icon: Icons.north_east,
                    label: 'condividi',
                    color: AppColors.steel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityHeroFallback extends StatelessWidget {
  const _ActivityHeroFallback({
    required this.item,
    required this.accent,
  });

  final ActivityFeedItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dateToken = _heroDateToken(item);
    final isTrack = item.eventType == 'track_status' || item.eventType == 'track_event';

    return CustomPaint(
      painter: isTrack
          ? _TrackHeroPainter(accent: accent)
          : _CommunityHeroPainter(accent: accent),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            dateToken,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white.withAlpha(42),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _ActivityAvatar extends StatelessWidget {
  const _ActivityAvatar({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withAlpha(42),
      child: Text(
        _initials(label),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _ActivityMetaIcon extends StatelessWidget {
  const _ActivityMetaIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.steel,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _CommunityHeroPainter extends CustomPainter {
  const _CommunityHeroPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withAlpha(230),
          const Color(0xFF1E1B4B),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final softPaint = Paint()..color = Colors.white.withAlpha(44);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.32), 56, softPaint);

    final warmPaint = Paint()..color = AppColors.signalOrange.withAlpha(120);
    canvas.drawCircle(Offset(size.width * 0.97, size.height * 0.72), 44, warmPaint);
  }

  @override
  bool shouldRepaint(covariant _CommunityHeroPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _TrackHeroPainter extends CustomPainter {
  const _TrackHeroPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withAlpha(220),
          const Color(0xFF0F172A),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..color = const Color(0xFF111827).withAlpha(215);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.54, size.height * 0.64),
        width: size.width * 0.94,
        height: size.height * 0.52,
      ),
      trackPaint,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.warningAmber;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.54, size.height * 0.64),
        width: size.width * 0.76,
        height: size.height * 0.34,
      ),
      linePaint,
    );

    final markerPaint = Paint()
      ..strokeWidth = 5
      ..color = Colors.white70
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.44),
      Offset(size.width * 0.48, size.height * 0.76),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrackHeroPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 116;
        final theme = Theme.of(context).textTheme;

        return Container(
          padding: EdgeInsets.fromLTRB(11, compact ? 9 : 11, 11, compact ? 9 : 11),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tint, size: compact ? 19 : 21),
              SizedBox(height: compact ? 7 : 12),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (compact ? theme.titleSmall : theme.titleMedium)?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              SizedBox(height: compact ? 0 : 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelMedium?.copyWith(
                  color: AppColors.graphite,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall?.copyWith(
                  color: AppColors.steel,
                  height: 1.05,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.steel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.steel,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
  });

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        if (actionLabel != null)
          Text(
            actionLabel!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.signalOrange,
                ),
          ),
      ],
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _WeatherPill extends StatelessWidget {
  const _WeatherPill({
    required this.weather,
    this.dark = false,
  });

  final HomeTrackWeather weather;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppColors.graphite;
    final background = dark ? Colors.white.withAlpha(26) : AppColors.orange50;
    final city = weather.city.trim().isEmpty ? 'Pista' : weather.city.trim();
    final temp = weather.temperatureC == null ? '--' : '${weather.temperatureC}°';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? Colors.white24 : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_weatherIcon(weather), color: _weatherColor(weather), size: 17),
          const SizedBox(width: 5),
          Text(
            '$temp $city',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'open' => 'Aperta',
    'wet' => 'Bagnata',
    'closed' => 'Chiusa',
    _ => 'Stato non noto',
  };
}

String _timeGreeting(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Buongiorno';
  if (hour < 18) return 'Buon Pomeriggio';
  return 'Buona sera';
}

String _homeDisplayName({
  required String? profileName,
  required String? email,
}) {
  final cleanName = profileName?.trim();
  if (cleanName != null && cleanName.isNotEmpty) return cleanName;

  final cleanEmail = email?.trim();
  if (cleanEmail != null && cleanEmail.isNotEmpty) {
    final localPart = cleanEmail.split('@').first.trim();
    if (localPart.isNotEmpty) return localPart;
  }

  return 'Pilota';
}

IconData _weatherIcon(HomeTrackWeather weather) {
  final code = weather.weatherCode;
  final rain = weather.precipitationProbability ?? 0;
  if (code >= 60 || rain >= 65) return Icons.water_drop_outlined;
  if (code >= 45) return Icons.foggy;
  if (code >= 3 || rain >= 35) return Icons.cloud_outlined;
  return Icons.wb_sunny_outlined;
}

Color _weatherColor(HomeTrackWeather weather) {
  final code = weather.weatherCode;
  final rain = weather.precipitationProbability ?? 0;
  if (code >= 60 || rain >= 65) return AppColors.wetBlue;
  if (code >= 3 || rain >= 35) return AppColors.steel;
  return AppColors.warningAmber;
}

Color _statusColor(String status) {
  return switch (status) {
    'open' => AppColors.openGreen,
    'wet' => AppColors.wetBlue,
    'closed' => AppColors.closedRed,
    _ => AppColors.steel,
  };
}

Color _eventColor(String eventType) {
  return switch (eventType) {
    'community_event' => const Color(0xFF7C3AED),
    'track_event' => AppColors.signalOrange,
    'new_spot' => AppColors.openGreen,
    'track_status' => AppColors.wetBlue,
    _ => AppColors.steel,
  };
}

IconData _eventIcon(String eventType) {
  return switch (eventType) {
    'community_event' => Icons.groups_2_outlined,
    'track_event' => Icons.event_outlined,
    'new_spot' => Icons.add_location_alt_outlined,
    'track_status' => Icons.flag_outlined,
    _ => Icons.notifications_none_outlined,
  };
}

String _eventLabel(String eventType) {
  return switch (eventType) {
    'community_event' => 'community',
    'track_event' => 'evento',
    'new_spot' => 'spot',
    'track_status' => 'pista',
    _ => 'update',
  };
}

String _eventHeroLabel(String eventType) {
  return switch (eventType) {
    'track_status' => 'scheda aggiornata',
    'track_event' => 'evento pista',
    'community_event' => 'evento community',
    'new_spot' => 'nuovo spot',
    _ => 'novita',
  };
}

String _primaryActivityAction(String eventType) {
  return switch (eventType) {
    'track_event' || 'community_event' => 'Partecipa',
    'track_status' => 'Apri pista',
    'new_spot' => 'Apri spot',
    _ => 'Apri',
  };
}

String _relativeTimeLabel(DateTime createdAt) {
  final now = DateTime.now();
  final local = createdAt.toLocal();
  final difference = now.difference(local);
  if (difference.inMinutes < 1) return 'ora';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min fa';
  if (difference.inHours < 24) return '${difference.inHours}h fa';
  if (difference.inDays < 7) return '${difference.inDays}g fa';
  return '${local.day}/${local.month}/${local.year}';
}

String _heroDateToken(ActivityFeedItem item) {
  final source = item.eventDate ?? item.createdAt;
  const months = [
    'GEN',
    'FEB',
    'MAR',
    'APR',
    'MAG',
    'GIU',
    'LUG',
    'AGO',
    'SET',
    'OTT',
    'NOV',
    'DIC',
  ];
  return '${months[source.month - 1]} ${source.day}';
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'PL';
  if (parts.length == 1) {
    final source = parts.first;
    return source.length == 1
        ? source.toUpperCase()
        : source.substring(0, 2).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _authorLabel(HomeBuildOfWeek build) {
  if (build.authorSlug.trim().isNotEmpty) return '@${build.authorSlug.trim()}';
  return build.authorName;
}

void _openActivity(BuildContext context, ActivityFeedItem item) {
  final payload = item.payload;
  final eventId = payload['event_id'] as String?;
  final spotSlug = payload['spot_slug'] as String?;

  if (eventId != null && eventId.isNotEmpty) {
    context.push('/event/$eventId');
    return;
  }

  if (spotSlug != null && spotSlug.isNotEmpty) {
    context.push('/spot/$spotSlug');
    return;
  }

  if (item.actorSlug != null && item.actorSlug!.isNotEmpty) {
    context.push('/track/${item.actorSlug}');
  }
}
