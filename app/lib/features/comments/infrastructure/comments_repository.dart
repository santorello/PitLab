import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/bootstrap/error_reporting.dart';
import '../domain/entity_comment.dart';

/// Numero massimo di commenti per pagina.
const kCommentsPageSize = 20;

/// Argomento per la query paginata.
class CommentsQuery {
  const CommentsQuery({
    required this.entityType,
    required this.entityId,
    this.offset = 0,
    this.limit = kCommentsPageSize,
  });

  final String entityType;
  final String entityId;
  final int offset;
  final int limit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentsQuery &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.offset == offset &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(entityType, entityId, offset, limit);
}

class CommentsRepository {
  const CommentsRepository(this._client);

  final SupabaseClient _client;
  static const _defaultRetryAttempts = 3;

  // ── Lettura commenti (paginata) ───────────────────────────────────────────

  Future<List<EntityComment>> fetchComments(CommentsQuery query) async {
    final response = await _withRetry(
      operation: 'fetchComments',
      action: () => _client
          .from('entity_comments')
          .select('id, entity_type, entity_id, author_id, body, is_hidden, '
              'reported_count, created_at, updated_at, '
              'author:profiles!entity_comments_author_id_fkey(display_name, avatar_url)')
          .eq('entity_type', query.entityType)
          .eq('entity_id', query.entityId)
          .order('created_at', ascending: true)
          .range(query.offset, query.offset + query.limit - 1),
    );

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(EntityComment.fromMap)
        .toList();
  }

  // ── Conteggi batch (una sola query per lista) ─────────────────────────────

  /// Restituisce una mappa entityId -> count per il tipo dato.
  /// Usa un'unica query `.in.(...)` per evitare N+1.
  Future<Map<String, int>> fetchCommentCountsBatch({
    required String entityType,
    required List<String> entityIds,
  }) async {
    if (entityIds.isEmpty) return const {};

    try {
      final response = await _withRetry(
        operation: 'fetchCommentCountsBatch',
        action: () => _client
            .from('entity_comment_counts')
            .select('entity_id, comment_count')
            .eq('entity_type', entityType)
            .inFilter('entity_id', entityIds),
      );

      final result = <String, int>{};
      for (final row in (response as List<dynamic>).whereType<Map<String, dynamic>>()) {
        final id = row['entity_id'] as String?;
        final count = (row['comment_count'] as num?)?.toInt() ?? 0;
        if (id != null) result[id] = count;
      }
      return result;
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'fetchCommentCountsBatch');
      return const {};
    }
  }

  // ── Inserimento ───────────────────────────────────────────────────────────

  Future<EntityComment> postComment({
    required String entityType,
    required String entityId,
    required String authorId,
    required String body,
  }) async {
    final data = await _withRetry(
      operation: 'postComment',
      action: () => _client
          .from('entity_comments')
          .insert({
            'entity_type': entityType,
            'entity_id': entityId,
            'author_id': authorId,
            'body': body.trim(),
          })
          .select('id, entity_type, entity_id, author_id, body, is_hidden, '
              'reported_count, created_at, updated_at, '
              'author:profiles!entity_comments_author_id_fkey(display_name, avatar_url)')
          .single(),
    );
    return EntityComment.fromMap(data);
  }

  // ── Eliminazione ─────────────────────────────────────────────────────────

  Future<void> deleteComment(String commentId) async {
    await _withRetry(
      operation: 'deleteComment',
      action: () => _client
          .from('entity_comments')
          .delete()
          .eq('id', commentId),
    );
  }

  // ── Segnalazione ─────────────────────────────────────────────────────────

  Future<void> reportComment(String commentId, {String? reason}) async {
    await _withRetry(
      operation: 'reportComment',
      action: () => _client.rpc(
        'report_comment',
        params: {
          'p_comment_id': commentId,
          if (reason != null && reason.trim().isNotEmpty) 'p_reason': reason.trim(),
        },
      ),
    );
  }

  // ── Retry/backoff (stesso pattern di SupabaseTracksRepository) ────────────

  Future<T> _withRetry<T>({
    required String operation,
    required Future<T> Function() action,
    int maxAttempts = _defaultRetryAttempts,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (error) {
        lastError = error;
        final shouldRetry = attempt < maxAttempts && _isRetryableError(error);
        if (!shouldRetry) rethrow;
        debugPrint(
          '[CommentsRepo] operation=$operation attempt=$attempt failed, retrying: $error',
        );
        await Future<void>.delayed(Duration(milliseconds: attempt * 250));
      }
    }
    throw StateError('Unexpected retry exit for $operation: $lastError');
  }

  bool _isRetryableError(Object error) {
    if (error is PostgrestException) {
      final code = (error.code ?? '').toLowerCase();
      if (code.startsWith('08') || code == '53300' || code == '57014') return true;
      final message = error.message.toLowerCase();
      return message.contains('timeout') ||
          message.contains('timed out') ||
          message.contains('connection') ||
          message.contains('temporarily unavailable');
    }
    final raw = error.toString().toLowerCase();
    return raw.contains('timeout') ||
        raw.contains('timed out') ||
        raw.contains('socket') ||
        raw.contains('connection reset') ||
        raw.contains('network');
  }
}
