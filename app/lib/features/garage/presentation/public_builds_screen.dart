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
                        return _BuildMarketplaceCard(build: filtered[index]);
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
        ? '$total build pubbliche'
        : '$visible di $total build pubbliche';
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
  const _BuildMarketplaceCard({required this.build});

  final PublicBuildListing build;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canOpenAuthor = build.author?.hasPublicProfile == true;

    return InkWell(
      onTap: canOpenAuthor
          ? () => context.push('/u/${build.author!.publicSlug}')
          : null,
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
                      source: build.primaryImageUrl,
                      fit: BoxFit.cover,
                      fallback: const _BuildImageFallback(),
                    ),
                    const Positioned(
                      left: 14,
                      top: 14,
                      child: _BuildBadge(),
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
                    build.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _AuthorAvatar(author: build.author),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          build.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.steel,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canOpenAuthor)
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.signalOrange,
                        ),
                    ],
                  ),
                  if (build.meta.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      build.meta.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.graphite,
                      ),
                    ),
                  ],
                  if (build.specsLabel.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      build.specsLabel,
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

class _BuildBadge extends StatelessWidget {
  const _BuildBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'build pubblica',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
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
