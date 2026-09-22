import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../application/public_builds_provider.dart';

class PublicBuildsScreen extends ConsumerStatefulWidget {
  const PublicBuildsScreen({super.key});

  @override
  ConsumerState<PublicBuildsScreen> createState() => _PublicBuildsScreenState();
}

class _PublicBuildsScreenState extends ConsumerState<PublicBuildsScreen> {
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
    final buildsAsync = ref.watch(publicBuildsProvider);

    return ContentScaffold(
      title: 'Build PitLap',
      description: 'Marketplace pubblico delle build condivise dalla community.',
      child: buildsAsync.when(
        loading: () => const _LoadingState(),
        error: (error, _) => const _ErrorState(),
        data: (builds) {
          final filtered = _filterBuilds(builds, _query);
          return ListView(
            children: [
              _SearchField(
                controller: _searchController,
                hint: 'Cerca build, autore o specifiche...',
              ),
              const SizedBox(height: 18),
              _BuildsSummary(total: builds.length, visible: filtered.length),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                const _EmptyState(
                  icon: Icons.precision_manufacturing_outlined,
                  title: 'Nessuna build pubblica',
                  body:
                      'Quando gli utenti renderanno pubbliche le build del garage, appariranno qui.',
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000
                        ? 3
                        : constraints.maxWidth >= 680
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
                        mainAxisExtent: columns == 1 ? 360 : 380,
                      ),
                      itemBuilder: (context, index) {
                        return _BuildMarketplaceCard(listing: filtered[index]);
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

  List<PublicBuildListing> _filterBuilds(
    List<PublicBuildListing> builds,
    String query,
  ) {
    if (query.isEmpty) return builds;
    return builds.where((build) {
      final haystack = [
        build.title,
        build.meta,
        build.authorName,
        build.specsLabel,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }
}

class _BuildsSummary extends StatelessWidget {
  const _BuildsSummary({required this.total, required this.visible});

  final int total;
  final int visible;

  @override
  Widget build(BuildContext context) {
    final label = total == visible
        ? '$total ${total == 1 ? 'build pubblica' : 'build pubbliche'}'
        : '$visible di $total ${total == 1 ? 'build pubblica' : 'build pubbliche'}';
    return Row(
      children: [
        const Icon(Icons.view_module_outlined, color: AppColors.signalOrange),
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

class _BuildMarketplaceCard extends StatelessWidget {
  const _BuildMarketplaceCard({required this.listing});

  final PublicBuildListing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      // La card apre la pagina della build (autore, like, commenti).
      onTap: () => context.push('/build/${listing.id}'),
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
                      source: listing.primaryImageUrl,
                      fit: BoxFit.cover,
                      fallback: const _BuildImageFallback(),
                    ),
                    if (listing.imageUrls.length > 1)
                      Positioned(
                        right: 14,
                        top: 14,
                        child: _PhotoCountBadge(count: listing.imageUrls.length),
                      ),
                    if (listing.likeCount > 0)
                      Positioned(
                        left: 14,
                        bottom: 14,
                        child: _LikeCountBadge(count: listing.likeCount),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _AuthorAvatar(author: listing.author),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.steel,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (listing.meta.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      listing.meta.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.graphite,
                      ),
                    ),
                  ],
                  if (listing.specsLabel.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      listing.specsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.steel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.author});

  final PublicBuildAuthor? author;

  @override
  Widget build(BuildContext context) {
    final name = author?.displayName ?? 'Pilota PitLap';
    final initial = name.trim().isEmpty ? 'P' : name.trim().characters.first;
    final avatarUrl = author?.avatarUrl;

    return CircleAvatar(
      radius: 15,
      backgroundColor: AppColors.orange50,
      child: avatarUrl != null && avatarUrl.trim().isNotEmpty
          ? ClipOval(
              child: AdaptiveImage(
                source: avatarUrl,
                fit: BoxFit.cover,
                width: 30,
                height: 30,
                fallback: Text(
                  initial.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.orangeText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          : Text(
              initial.toUpperCase(),
              style: const TextStyle(
                color: AppColors.orangeText,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _PhotoCountBadge extends StatelessWidget {
  const _PhotoCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _OverlayPill(
      icon: Icons.collections_outlined,
      label: '$count',
    );
  }
}

class _LikeCountBadge extends StatelessWidget {
  const _LikeCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return _OverlayPill(icon: Icons.favorite, label: '$count');
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildImageFallback extends StatelessWidget {
  const _BuildImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF334155)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.precision_manufacturing_outlined,
          size: 58,
          color: Colors.white.withAlpha(210),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.error_outline,
      title: 'Build non disponibili',
      body: 'Non riesco a caricare le build pubbliche in questo momento.',
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
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
    );
  }
}
