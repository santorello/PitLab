import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../auth/application/auth_providers.dart';
import '../data/models/pitcoin_action_definition.dart';
import '../data/models/pitcoin_transaction.dart';
import '../providers/pitcoin_providers.dart';

/// Schermata `/profile/activity`: storico paginato delle transazioni PitCoin
/// dell'utente effettivo (loggato o impersonato).
///
/// Visibile solo a owner+admin via RLS — il provider restituisce lista vuota
/// se la policy nega l'accesso.
class PitcoinHistoryScreen extends ConsumerStatefulWidget {
  const PitcoinHistoryScreen({super.key});

  @override
  ConsumerState<PitcoinHistoryScreen> createState() =>
      _PitcoinHistoryScreenState();
}

class _PitcoinHistoryScreenState extends ConsumerState<PitcoinHistoryScreen> {
  static const int _pageSize = 30;

  final List<PitcoinTransaction> _accumulated = [];
  DateTime? _cursor;
  bool _isLoadingMore = false;
  bool _exhausted = false;
  String? _userIdSnapshot;

  Future<void> _loadInitial(String userId) async {
    if (_userIdSnapshot == userId && _accumulated.isNotEmpty) return;
    _userIdSnapshot = userId;
    _accumulated.clear();
    _cursor = null;
    _exhausted = false;
    final repo = ref.read(pitcoinRepositoryProvider);
    if (repo == null) return;
    final first = await repo.fetchTransactions(userId, limit: _pageSize);
    setState(() {
      _accumulated.addAll(first);
      if (first.isNotEmpty) {
        _cursor = first.last.awardedAt;
      }
      if (first.length < _pageSize) {
        _exhausted = true;
      }
    });
  }

  Future<void> _loadMore(String userId) async {
    if (_isLoadingMore || _exhausted || _cursor == null) return;
    setState(() => _isLoadingMore = true);
    final repo = ref.read(pitcoinRepositoryProvider);
    if (repo == null) {
      setState(() => _isLoadingMore = false);
      return;
    }
    final next = await repo.fetchTransactions(
      userId,
      limit: _pageSize,
      before: _cursor,
    );
    setState(() {
      _accumulated.addAll(next);
      if (next.isNotEmpty) {
        _cursor = next.last.awardedAt;
      }
      if (next.length < _pageSize) {
        _exhausted = true;
      }
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.watch(effectiveUserIdProvider);
    final definitionsAsync = ref.watch(pitcoinActionDefinitionsProvider);

    if (userId == null) {
      return ContentScaffold(
        title: l10n.pitcoinHistoryTitle,
        description: l10n.pitcoinHistoryEmpty,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(l10n.pitcoinHistoryEmpty),
          ),
        ),
      );
    }

    // Carica la prima pagina al primo build dopo che userId e' disponibile.
    if (_userIdSnapshot != userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitial(userId);
      });
    }

    return ContentScaffold(
      title: l10n.pitcoinHistoryTitle,
      description: l10n.pitcoinHistorySubtitle,
      child: definitionsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(l10n.pitcoinHistoryEmpty),
          ),
        ),
        data: (definitions) {
          if (_accumulated.isEmpty && !_exhausted) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (_accumulated.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(l10n.pitcoinHistoryEmpty),
              ),
            );
          }
          final languageCode = Localizations.localeOf(context).languageCode;
          return ListView.separated(
            itemCount: _accumulated.length + (_exhausted ? 0 : 1),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == _accumulated.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: _isLoadingMore
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: () => _loadMore(userId),
                            child: Text(l10n.pitcoinHistoryLoadMore),
                          ),
                  ),
                );
              }
              final tx = _accumulated[index];
              final def = definitions[tx.actionKey];
              return _TransactionTile(
                transaction: tx,
                definition: def,
                languageCode: languageCode,
                onTap: () => _openSource(context, tx),
              );
            },
          );
        },
      ),
    );
  }

  void _openSource(BuildContext context, PitcoinTransaction tx) {
    final sourceTable = tx.sourceTable;
    final sourceId = tx.sourceId;
    if (sourceTable == null || sourceId == null) return;
    // Deep-link best-effort: la maggior parte delle entita' usa slug, non id,
    // ma offriamo comunque scorciatoie verso le sezioni principali.
    switch (sourceTable) {
      case 'arrivals':
      case 'track_status_history':
      case 'tracks':
      case 'track_follows':
      case 'track_services':
      case 'track_media':
        context.go('/tracks');
        break;
      case 'shops':
      case 'shop_follows':
        context.go('/shops');
        break;
      case 'events':
      case 'community_events':
      case 'event_rsvps':
        context.go('/events');
        break;
      case 'spots':
        context.go('/spots');
        break;
      case 'user_builds':
        context.go('/garage');
        break;
      case 'profiles':
      case 'external_links':
        context.go('/profile');
        break;
    }
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.definition,
    required this.languageCode,
    required this.onTap,
  });

  final PitcoinTransaction transaction;
  final PitcoinActionDefinition? definition;
  final String languageCode;
  final VoidCallback onTap;

  IconData _iconForCategory(String? category) {
    switch (category) {
      case 'identity':
        return Icons.badge_outlined;
      case 'garage':
        return Icons.directions_car_outlined;
      case 'catalog':
        return Icons.public_outlined;
      case 'operations':
        return Icons.tune_outlined;
      case 'events':
        return Icons.event_outlined;
      case 'engagement':
        return Icons.directions_run_outlined;
      case 'moderation':
        return Icons.shield_outlined;
      default:
        return Icons.savings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = definition?.localizedName(languageCode) ?? transaction.actionKey;
    final points = transaction.points;
    final isPositive = points > 0;
    final isZero = points == 0;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.signalOrange.withAlpha(40),
          child: Icon(
            _iconForCategory(definition?.category),
            color: AppColors.signalOrange,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_formatDate(transaction.awardedAt, languageCode)),
        trailing: Text(
          isZero
              ? l10n.pitcoinPointsZero
              : (isPositive
                  ? l10n.pitcoinPointsShort(points)
                  : l10n.pitcoinPointsLabel(points)),
          style: TextStyle(
            color: isZero
                ? AppColors.concrete
                : (isPositive ? Colors.green : Colors.redAccent),
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: transaction.sourceId != null ? onTap : null,
      ),
    );
  }

  String _formatDate(DateTime date, String languageCode) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    if (languageCode == 'en') {
      return '$year-$month-$day  $hour:$minute';
    }
    return '$day/$month/$year  $hour:$minute';
  }
}
