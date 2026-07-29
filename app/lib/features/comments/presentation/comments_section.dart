import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../auth/application/auth_providers.dart';
import '../application/comments_providers.dart';
import '../domain/entity_comment.dart';

// ── Entry point pubblico ──────────────────────────────────────────────────

class CommentsSection extends ConsumerWidget {
  const CommentsSection({
    required this.entityType,
    required this.entityId,
    super.key,
  });

  final String entityType;
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = CommentsKey(entityType: entityType, entityId: entityId);
    final commentsAsync = ref.watch(commentsProvider(key));
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.signalOrange),
                const SizedBox(width: 8),
                Text(
                  l10n.commentsSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Lista commenti ─────────────────────────────────────────────
            commentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorState(l10n: l10n),
              data: (comments) => _CommentsList(
                comments: comments,
                currentUserId: currentUser?.id,
                isAdmin: isAdmin,
                entityType: entityType,
                entityId: entityId,
                l10n: l10n,
              ),
            ),

            // ── Input nuovo commento ───────────────────────────────────────
            const SizedBox(height: 16),
            if (currentUser != null)
              _CommentInput(
                entityType: entityType,
                entityId: entityId,
                userId: currentUser.id,
                l10n: l10n,
              )
            else
              _GuestCta(l10n: l10n, entityType: entityType, entityId: entityId),
          ],
        ),
      ),
    );
  }
}

// ── Lista ─────────────────────────────────────────────────────────────────

class _CommentsList extends ConsumerWidget {
  const _CommentsList({
    required this.comments,
    required this.currentUserId,
    required this.isAdmin,
    required this.entityType,
    required this.entityId,
    required this.l10n,
  });

  final List<EntityComment> comments;
  final String? currentUserId;
  final bool isAdmin;
  final String entityType;
  final String entityId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = CommentsKey(entityType: entityType, entityId: entityId);
    final notifier = ref.read(commentsProvider(key).notifier);
    final hasMore = notifier.hasMore;

    if (comments.isEmpty) {
      return _EmptyState(l10n: l10n);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...comments.map(
          (comment) => _CommentTile(
            comment: comment,
            currentUserId: currentUserId,
            isAdmin: isAdmin,
            l10n: l10n,
            onDelete: () => notifier.deleteComment(comment.id),
            onReport: (reason) => _confirmReport(context, notifier, comment.id, reason, l10n),
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: () => notifier.loadMore(),
              child: Text(l10n.commentsLoadMore),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmReport(
    BuildContext context,
    CommentsNotifier notifier,
    String commentId,
    String? reason,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.commentsReportTitle),
        content: Text(l10n.commentsReportBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.commentsReportCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.commentsReportConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await notifier.reportComment(commentId, reason: reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? l10n.commentsReportSuccess : l10n.commentsReportError,
            ),
          ),
        );
      }
    }
  }
}

// ── Singolo commento ──────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    required this.isAdmin,
    required this.l10n,
    required this.onDelete,
    required this.onReport,
  });

  final EntityComment comment;
  final String? currentUserId;
  final bool isAdmin;
  final AppLocalizations l10n;
  final Future<void> Function() onDelete;
  final void Function(String? reason) onReport;

  bool get _isOwn => currentUserId != null && comment.authorId == currentUserId;
  bool get _canDelete => _isOwn || isAdmin;

  @override
  Widget build(BuildContext context) {
    final author = comment.author;
    final displayName = author?.displayName ?? 'Pilota PitLap';
    final avatarUrl = author?.avatarUrl;
    final initial = displayName.trim().isEmpty ? 'P' : displayName.trim().characters.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.orange50,
            child: avatarUrl != null && avatarUrl.trim().isNotEmpty
                ? ClipOval(
                    child: AdaptiveImage(
                      source: avatarUrl,
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                      fallback: Text(
                        initial.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.orangeText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                : Text(
                    initial.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.orangeText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 10),

          // Body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _relativeTime(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.steel,
                          ),
                    ),
                    // Azioni
                    if (_canDelete || !_isOwn) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<_CommentAction>(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: const Icon(Icons.more_horiz, color: AppColors.steel),
                        onSelected: (action) {
                          if (action == _CommentAction.delete) {
                            _confirmDelete(context);
                          } else if (action == _CommentAction.report) {
                            onReport(null);
                          }
                        },
                        itemBuilder: (_) => [
                          if (_canDelete)
                            PopupMenuItem(
                              value: _CommentAction.delete,
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(l10n.commentsDeleteAction),
                                ],
                              ),
                            ),
                          if (!_isOwn && currentUserId != null)
                            PopupMenuItem(
                              value: _CommentAction.report,
                              child: Row(
                                children: [
                                  const Icon(Icons.flag_outlined, size: 18, color: AppColors.steel),
                                  const SizedBox(width: 8),
                                  Text(l10n.commentsReportAction),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.graphite,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.commentsDeleteTitle),
        content: Text(l10n.commentsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.commentsDeleteCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.commentsDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDelete();
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'ora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min fa';
    if (diff.inHours < 24) return '${diff.inHours}h fa';
    if (diff.inDays < 7) return '${diff.inDays}g fa';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}sett fa';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mesi fa';
    return '${(diff.inDays / 365).floor()}a fa';
  }
}

enum _CommentAction { delete, report }

// ── Input nuovo commento ──────────────────────────────────────────────────

class _CommentInput extends ConsumerStatefulWidget {
  const _CommentInput({
    required this.entityType,
    required this.entityId,
    required this.userId,
    required this.l10n,
  });

  final String entityType;
  final String entityId;
  final String userId;
  final AppLocalizations l10n;

  @override
  ConsumerState<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<_CommentInput> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || body.length > 2000) return;
    setState(() => _submitting = true);
    final key = CommentsKey(entityType: widget.entityType, entityId: widget.entityId);
    final ok = await ref.read(commentsProvider(key).notifier).postComment(
          authorId: widget.userId,
          body: body,
        );
    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        _controller.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.commentsPostError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLength: 2000,
            maxLines: 3,
            minLines: 1,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: widget.l10n.commentsInputHint,
              filled: true,
              fillColor: AppColors.panel,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded),
          tooltip: widget.l10n.commentsSubmitAction,
        ),
      ],
    );
  }
}

// ── CTA guest ─────────────────────────────────────────────────────────────

class _GuestCta extends StatelessWidget {
  const _GuestCta({
    required this.l10n,
    required this.entityType,
    required this.entityId,
  });

  final AppLocalizations l10n;
  final String entityType;
  final String entityId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.signalOrange.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.signalOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.commentsGuestCta,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.graphite,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => context.go(
              '/login?redirect=${Uri.encodeComponent('/comment-anchor')}',
            ),
            child: Text(l10n.commentsGuestLogin),
          ),
        ],
      ),
    );
  }
}

// ── Empty & Error states ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline, size: 36, color: AppColors.concrete),
          const SizedBox(height: 10),
          Text(
            l10n.commentsEmptyTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.steel,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.commentsEmptyBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.steel),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        l10n.commentsLoadError,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
      ),
    );
  }
}
