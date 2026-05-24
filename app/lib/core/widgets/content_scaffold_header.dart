import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../features/auth/application/auth_providers.dart';

class ContentScaffoldHeader extends ConsumerWidget {
  const ContentScaffoldHeader({
    required this.title,
    required this.description,
    this.trailingActions,
    super.key,
  });

  final String title;
  final String description;
  final List<Widget>? trailingActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider);
    final impersonation = ref.watch(impersonationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;
            final brand = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs + 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(210),
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTaglinePill,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.orange200,
                    ),
                  ),
                  child: Text(
                    l10n.appTagline,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.orangeText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            );
            final actions = _HeaderActions(
              currentUserEmail: currentUser?.email,
              trailingActions: trailingActions,
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  brand,
                  SizedBox(height: AppSpacing.sm),
                  actions,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: brand),
                SizedBox(width: AppSpacing.md),
                Flexible(child: actions),
              ],
            );
          },
        ),
        SizedBox(height: AppSpacing.xs + 2),
        if (impersonation != null) ...[
          Container(
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceImpersonation,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.orange500.withAlpha(80),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: AppColors.orange700,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.orange900,
                          ),
                      children: [
                        const TextSpan(text: 'Vista come '),
                        TextSpan(
                          text: impersonation.displayName.isNotEmpty
                              ? impersonation.displayName
                              : impersonation.userId.substring(0, 8),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${impersonation.role}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/admin'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange700,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs + 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('→ Admin'),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(impersonationProvider.notifier)
                        .stop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange900,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs + 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.adminImpersonationStop),
                ),
              ],
            ),
          ),
        ],
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        SizedBox(height: AppSpacing.xs),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.currentUserEmail,
    required this.trailingActions,
  });

  final String? currentUserEmail;
  final List<Widget>? trailingActions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserEmail = this.currentUserEmail;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (trailingActions != null)
          ...trailingActions!.map(
            (action) => Padding(
              padding: EdgeInsets.only(right: AppSpacing.xs),
              child: action,
            ),
          ),
        if (currentUserEmail == null)
          OutlinedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login),
            label: Text(l10n.loginCtaButton),
          )
        else ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSpacing.xs,
                    height: AppSpacing.xs,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.openGreen,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.accountActiveNow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      currentUserEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(170),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
            label: Text(l10n.profileTitle),
          ),
        ],
      ],
    );
  }
}
