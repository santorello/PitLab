import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../application/public_profiles_provider.dart';

class PublicProfilesScreen extends ConsumerStatefulWidget {
  const PublicProfilesScreen({super.key});

  @override
  ConsumerState<PublicProfilesScreen> createState() =>
      _PublicProfilesScreenState();
}

class _PublicProfilesScreenState extends ConsumerState<PublicProfilesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(publicProfilesProvider);

    return ContentScaffold(
      title: 'Profili pubblici',
      description: 'Piloti, gestori e creator che hanno scelto di mostrarsi su PitLap.',
      child: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _ProfilesEmptyState(
          icon: Icons.error_outline,
          title: 'Profili non disponibili',
          body: 'Non riesco a caricare i profili pubblici in questo momento.',
        ),
        data: (profiles) {
          final filtered = _filterProfiles(profiles, _query);
          return ListView(
            children: [
              _SearchField(
                controller: _searchController,
                hint: 'Cerca pilota, ruolo o handle...',
              ),
              const SizedBox(height: 18),
              _ProfilesSummary(total: profiles.length, visible: filtered.length),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                const _ProfilesEmptyState(
                  icon: Icons.people_outline,
                  title: 'Nessun profilo pubblico',
                  body:
                      'Quando gli utenti renderanno pubblico il profilo, appariranno qui.',
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 980
                        ? 3
                        : constraints.maxWidth >= 640
                            ? 2
                            : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 260,
                      ),
                      itemBuilder: (context, index) {
                        return _PublicProfileCard(profile: filtered[index]);
                      },
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  List<PublicProfileListing> _filterProfiles(
    List<PublicProfileListing> profiles,
    String query,
  ) {
    if (query.isEmpty) return profiles;
    return profiles.where((profile) {
      final haystack = [
        profile.displayName,
        profile.publicSlug,
        profile.roleLabel,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }
}

class _ProfilesSummary extends StatelessWidget {
  const _ProfilesSummary({required this.total, required this.visible});

  final int total;
  final int visible;

  @override
  Widget build(BuildContext context) {
    final label = total == visible
        ? '$total profili pubblici'
        : '$visible di $total profili pubblici';
    return Row(
      children: [
        const Icon(Icons.people_alt_outlined, color: AppColors.signalOrange),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _PublicProfileCard extends StatelessWidget {
  const _PublicProfileCard({required this.profile});

  final PublicProfileListing profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/u/${profile.publicSlug}'),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AdaptiveImage(
                      source: profile.previewImageUrl,
                      fit: BoxFit.cover,
                      fallback: const _ProfileCoverFallback(),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(0),
                            Colors.black.withAlpha(95),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 14,
                      child: _ProfileAvatar(profile: profile),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${profile.publicSlug}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.steel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MiniChip(label: profile.roleLabel),
                            _MiniChip(
                              label:
                                  '${profile.publicBuildCount} ${profile.publicBuildCount == 1 ? 'build' : 'build'}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.signalOrange,
                    size: 16,
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final PublicProfileListing profile;

  @override
  Widget build(BuildContext context) {
    final initial = profile.displayName.trim().isEmpty
        ? 'P'
        : profile.displayName.trim().characters.first.toUpperCase();
    final avatarUrl = profile.avatarUrl;
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppColors.orange50,
      child: avatarUrl != null && avatarUrl.trim().isNotEmpty
          ? ClipOval(
              child: AdaptiveImage(
                source: avatarUrl,
                fit: BoxFit.cover,
                width: 60,
                height: 60,
                fallback: _Initial(initial: initial),
              ),
            )
          : _Initial(initial: initial),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Text(
      initial,
      style: const TextStyle(
        color: AppColors.orangeText,
        fontWeight: FontWeight.w900,
        fontSize: 22,
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCool,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.graphite,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ProfileCoverFallback extends StatelessWidget {
  const _ProfileCoverFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAEEF3), Color(0xFFFFF0E6)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_search_outlined,
          size: 56,
          color: AppColors.steel.withAlpha(170),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
        filled: true,
        fillColor: AppColors.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
    );
  }
}

class _ProfilesEmptyState extends StatelessWidget {
  const _ProfilesEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.steel),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.steel),
            ),
          ],
        ),
      ),
    );
  }
}
