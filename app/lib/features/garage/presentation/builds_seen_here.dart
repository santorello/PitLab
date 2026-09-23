import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../application/build_links_provider.dart';

/// "Build viste qui": build pubbliche collegate a una pista, un negozio,
/// uno spot o un evento. Si nasconde se non ce ne sono.
class BuildsSeenHere extends ConsumerWidget {
  const BuildsSeenHere({
    required this.entityType,
    required this.entityId,
    super.key,
  });

  final String entityType;
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
        buildsSeenHereProvider((entityType: entityType, entityId: entityId)));
    if (async.hasError) {
      debugPrint('[BuildsSeenHere] $entityType/$entityId: ${async.error}');
    }
    final builds = async.value ?? const [];
    if (builds.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.precision_manufacturing_outlined,
                  size: 20, color: AppColors.signalOrange),
              const SizedBox(width: 8),
              Text(
                'Build viste qui',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text(
                '${builds.length}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.steel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: builds.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final b = builds[i];
                return SizedBox(
                  width: 180,
                  child: Material(
                    color: AppColors.panel,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    child: InkWell(
                      onTap: () => context.push('/build/${b.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: AdaptiveImage(
                              source: b.primaryImageUrl,
                              fit: BoxFit.cover,
                              fallback: const ColoredBox(
                                color: AppColors.graphite,
                                child: Icon(
                                  Icons.precision_manufacturing_outlined,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                            child: Text(
                              b.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (b.meta.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                              child: Text(
                                b.meta.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.steel),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
