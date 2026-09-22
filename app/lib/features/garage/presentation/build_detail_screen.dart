import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/utils/share_entity.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/fullscreen_gallery.dart';
import '../../auth/application/auth_providers.dart';
import '../../comments/presentation/comments_section.dart';
import '../application/public_builds_provider.dart';

/// Pagina di una build pubblica: galleria stile Instagram, like, commenti.
/// Rotta: /build/:buildId (pubblica, visibile anche agli ospiti).
class BuildDetailScreen extends ConsumerWidget {
  const BuildDetailScreen({required this.buildId, super.key});

  final String buildId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildAsync = ref.watch(publicBuildDetailProvider(buildId));

    return buildAsync.when(
      loading: () => const ContentScaffold(
        title: 'Build',
        description: '',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const _Unavailable(),
      data: (listing) =>
          listing == null ? const _Unavailable() : _BuildDetail(listing: listing),
    );
  }
}

class _BuildDetail extends ConsumerWidget {
  const _BuildDetail({required this.listing});

  final PublicBuildListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final author = listing.author;
    final canOpenAuthor = author?.hasPublicProfile == true;

    return ContentScaffold(
      title: listing.title,
      description: listing.authorName,
      child: ListView(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InlineImageCarousel(
                    images: listing.imageUrls,
                    fallback: const _ImageFallback(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _LikeButton(listing: listing),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Condividi',
                        onPressed: () => shareEntity(
                          context: context,
                          entityType: 'user_build',
                          entityId: listing.id,
                        ),
                        icon: const Icon(Icons.ios_share),
                      ),
                      const Spacer(),
                      if (listing.imageUrls.length > 1)
                        Text(
                          '${listing.imageUrls.length} foto',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: AppColors.steel),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: canOpenAuthor
                        ? () => context.push('/u/${author!.publicSlug}')
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          _AuthorAvatar(author: author),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              listing.authorName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (canOpenAuthor)
                            Text(
                              'Vedi garage',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.signalOrange,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (listing.meta.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(listing.meta.trim(), style: theme.textTheme.bodyLarge),
                  ],
                  if (listing.specs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Specifiche',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final spec in listing.specs)
                          if (spec.trim().isNotEmpty)
                            Chip(label: Text(spec.trim())),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  CommentsSection(
                    entityType: 'user_build',
                    entityId: listing.id,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.listing});

  final PublicBuildListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeAsync = ref.watch(buildLikeProvider(listing.id));
    final userId = ref.watch(currentUserProvider)?.id;
    final isOwner = userId != null && userId == listing.ownerId;
    final state = likeAsync.value;
    final count = state?.count ?? listing.likeCount;
    final liked = state?.likedByMe ?? false;

    Future<void> onTap() async {
      final messenger = ScaffoldMessenger.of(context);
      if (userId == null) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Accedi per mettere like alle build.'),
            action: SnackBarAction(
              label: 'Accedi',
              onPressed: () => context.push(
                '/login?redirect=${Uri.encodeComponent('/build/${listing.id}')}',
              ),
            ),
          ),
        );
        return;
      }
      final error =
          await ref.read(buildLikeProvider(listing.id).notifier).toggle();
      if (error != null && error.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
      }
    }

    // Niente "0": su una build appena pubblicata il contatore a zero
    // scoraggia invece di invitare (vedi rischio "vetrina vuota").
    final label = count > 0 ? '$count' : '';

    return Tooltip(
      message: isOwner
          ? 'Like ricevuti dalla tua build'
          : (liked ? 'Togli il like' : 'Mi piace'),
      child: TextButton.icon(
        onPressed: isOwner || state == null ? null : onTap,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(liked),
            color: liked ? AppColors.signalOrange : null,
          ),
        ),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
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
    final fallback = Text(
      initial.toUpperCase(),
      style: const TextStyle(
        color: AppColors.orangeText,
        fontWeight: FontWeight.w900,
      ),
    );
    final avatarUrl = author?.avatarUrl;
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.orange50,
      child: avatarUrl != null && avatarUrl.trim().isNotEmpty
          ? ClipOval(
              child: AdaptiveImage(
                source: avatarUrl,
                fit: BoxFit.cover,
                width: 36,
                height: 36,
                fallback: fallback,
              ),
            )
          : fallback,
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

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

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return ContentScaffold(
      title: 'Build',
      description: '',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 42, color: AppColors.steel),
            const SizedBox(height: 12),
            const Text(
              'Questa build non esiste o non e\' piu\' pubblica.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/builds'),
              child: const Text('Vedi tutte le build'),
            ),
          ],
        ),
      ),
    );
  }
}
