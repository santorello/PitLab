import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/error_reporting.dart';
import '../../auth/application/auth_providers.dart';
import '../../pitcoin/providers/pitcoin_providers.dart';
import '../domain/entity_comment.dart';
import '../infrastructure/comments_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────

final commentsRepositoryProvider = Provider<CommentsRepository?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) return null;
  return CommentsRepository(client);
});

// ── Argomento family ─────────────────────────────────────────────────────

@immutable
class CommentsKey {
  const CommentsKey({required this.entityType, required this.entityId});

  final String entityType;
  final String entityId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentsKey &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(entityType, entityId);
}

// ── Notifier che gestisce paginazione + ottimistic UI ─────────────────────

class CommentsNotifier extends AsyncNotifier<List<EntityComment>> {
  CommentsNotifier(this._key);

  final CommentsKey _key;
  int _offset = 0;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<EntityComment>> build() async {
    _offset = 0;
    _hasMore = true;
    final initial = await _load(offset: 0);
    _hasMore = initial.length == kCommentsPageSize;
    return initial;
  }

  Future<List<EntityComment>> _load({required int offset}) async {
    final repo = ref.read(commentsRepositoryProvider);
    if (repo == null) return const [];
    return repo.fetchComments(
      CommentsQuery(
        entityType: _key.entityType,
        entityId: _key.entityId,
        offset: offset,
      ),
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.value ?? [];
    final nextOffset = _offset + kCommentsPageSize;
    try {
      final more = await _load(offset: nextOffset);
      if (more.length < kCommentsPageSize) _hasMore = false;
      _offset = nextOffset;
      state = AsyncData([...current, ...more]);
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'commentsLoadMore');
      // non sovrascrivere lo stato corrente in caso di errore di paginazione
    }
  }

  Future<bool> postComment({
    required String authorId,
    required String body,
  }) async {
    final repo = ref.read(commentsRepositoryProvider);
    if (repo == null) return false;
    try {
      final newComment = await repo.postComment(
        entityType: _key.entityType,
        entityId: _key.entityId,
        authorId: authorId,
        body: body,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, newComment]);
      _offset++;
      // Invalida i conteggi batch e il balance PitCoin (il trigger DB ha già
      // accreditato i punti; qui aggiorniamo la UI lato client).
      ref.invalidate(commentCountsBatchProvider(_key.entityType));
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        ref.invalidate(effectiveUserPitcoinBalanceProvider);
        ref.invalidate(effectiveUserPitcoinRecentDeltaProvider);
      });
      return true;
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'commentsPost');
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    final repo = ref.read(commentsRepositoryProvider);
    if (repo == null) return false;
    try {
      await repo.deleteComment(commentId);
      final current = state.value ?? [];
      state = AsyncData(current.where((c) => c.id != commentId).toList());
      if (_offset > 0) _offset--;
      ref.invalidate(commentCountsBatchProvider(_key.entityType));
      return true;
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'commentsDelete');
      return false;
    }
  }

  Future<bool> reportComment(String commentId, {String? reason}) async {
    final repo = ref.read(commentsRepositoryProvider);
    if (repo == null) return false;
    try {
      await repo.reportComment(commentId, reason: reason);
      return true;
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'commentsReport');
      return false;
    }
  }
}

final commentsProvider = AsyncNotifierProvider.autoDispose
    .family<CommentsNotifier, List<EntityComment>, CommentsKey>(
  CommentsNotifier.new,
);

// ── Conteggi batch ───────────────────────────────────────────────────────

/// Provider che tiene in cache la mappa id->count per un dato entityType.
/// Viene invalidato dopo ogni post/delete di commento.
/// Le liste chiamano [commentCountsBatchProvider] passando il tipo, poi
/// leggono il singolo conteggio tramite [commentCountForProvider].
final commentCountsBatchProvider =
    NotifierProvider.family<CommentCountsBatchNotifier, Map<String, int>, String>(
  CommentCountsBatchNotifier.new,
);

class CommentCountsBatchNotifier extends Notifier<Map<String, int>> {
  CommentCountsBatchNotifier(this._entityType);

  final String _entityType;

  @override
  Map<String, int> build() => const {};

  /// Ricarica i conteggi per una lista di id. Chiamato dalle screen di lista.
  Future<void> loadBatch(List<String> entityIds) async {
    if (entityIds.isEmpty) return;
    final repo = ref.read(commentsRepositoryProvider);
    if (repo == null) return;
    try {
      final counts = await repo.fetchCommentCountsBatch(
        entityType: _entityType,
        entityIds: entityIds,
      );
      // Merge: mantieni conteggi già in cache, aggiorna/aggiungi i nuovi.
      state = {...state, ...counts};
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'commentCountsBatch/$_entityType');
    }
  }
}

/// Conteggio per una singola entità — legge dalla cache batch.
final commentCountForProvider =
    Provider.autoDispose.family<int, CommentsKey>((ref, key) {
  final batch = ref.watch(commentCountsBatchProvider(key.entityType));
  return batch[key.entityId] ?? 0;
});
