import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../application/admin_providers.dart';

/// Control room: fascia di stato, numeri, "Da fare ora", salute, andamento.
/// Tutti i dati arrivano da una sola chiamata (`admin_dashboard`).
class AdminControlRoom extends ConsumerWidget {
  const AdminControlRoom({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDashboardProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _Banner(
        color: AppColors.closedRed,
        background: const Color(0xFFFDECEC),
        title: 'Dati non disponibili',
        subtitle: 'Riprova ad aggiornare la pagina. ($error)',
      ),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBand(data: data),
            const SizedBox(height: 12),
            _CountsRow(data: data),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final todo = _TodoList(data: data);
                final health = _HealthCard(data: data);
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [todo, const SizedBox(height: 16), health],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: todo),
                    const SizedBox(width: 16),
                    SizedBox(width: 320, child: health),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _SignupsChart(data: data),
          ],
        );
      },
    );
  }
}

// ── Fascia di stato ───────────────────────────────────────────────────────────

class _StatusBand extends StatelessWidget {
  const _StatusBand({required this.data});

  final AdminDashboard data;

  @override
  Widget build(BuildContext context) {
    final open = data.todoTotal;
    if (open == 0) {
      return _Banner(
        color: AppColors.openGreen,
        background: const Color(0xFFE9F7EF),
        title: 'Tutto tranquillo',
        subtitle:
            'Niente da approvare, niente da moderare, nessun feedback da leggere.',
      );
    }
    final oldest = data.todo('oldest_pending_days');
    return _Banner(
      color: AppColors.signalOrange,
      background: const Color(0xFFFEF6EC),
      title: 'C\'è da lavorare · $open ${open == 1 ? 'azione' : 'azioni'}',
      subtitle: oldest > 0
          ? 'La più vecchia aspetta da $oldest ${oldest == 1 ? 'giorno' : 'giorni'}.'
          : 'Tutte arrivate oggi.',
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final Color background;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.steel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Numeri ────────────────────────────────────────────────────────────────────

class _CountsRow extends StatelessWidget {
  const _CountsRow({required this.data});

  final AdminDashboard data;

  @override
  Widget build(BuildContext context) {
    final users7d = data.count('users_7d');
    final prev7d = data.count('users_prev_7d');
    final delta = users7d - prev7d;
    final silence = data.silenceHours;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _Tile(
          label: 'Iscritti',
          value: '${data.count('users')}',
          hint: delta == 0
              ? '$users7d negli ultimi 7 giorni'
              : '${delta > 0 ? '+' : ''}$delta rispetto ai 7 giorni prima',
          hintColor: delta > 0 ? AppColors.openGreen : AppColors.steel,
        ),
        _Tile(
          label: 'Onboarding completato',
          value: '${data.count('onboarding_done')} / ${data.count('users')}',
        ),
        _Tile(
          label: 'Piste',
          value: '${data.count('tracks')}',
          hint: '${data.count('tracks_open')} aperte ora',
        ),
        _Tile(label: 'Spot', value: '${data.count('spots')}'),
        _Tile(label: 'Eventi futuri', value: '${data.count('events_future')}'),
        _Tile(
          label: 'Silenzio',
          value: silence == null ? '—' : '$silence h',
          hint: 'dall\'ultimo contenuto pubblicato',
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    this.hint,
    this.hintColor,
  });

  final String label;
  final String value;
  final String? hint;
  final Color? hintColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.steel),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: hintColor ?? AppColors.steel,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Da fare ora ───────────────────────────────────────────────────────────────

class _TodoList extends StatelessWidget {
  const _TodoList({required this.data});

  final AdminDashboard data;

  @override
  Widget build(BuildContext context) {
    final pending = data.todo('pending_tracks') + data.todo('pending_shops');
    final rows = <Widget>[
      _TodoRow(
        count: pending,
        title: 'Piste e negozi da approvare',
        detail: pending == 0
            ? 'Nessuna richiesta in coda'
            : '${data.todo('pending_tracks')} piste · ${data.todo('pending_shops')} negozi',
        urgent: data.todo('oldest_pending_days') >= 2,
      ),
      _TodoRow(
        count: data.todo('reported_comments'),
        title: 'Commenti segnalati',
        detail: 'Da moderare nella sezione Moderazione',
      ),
      _TodoRow(
        count: data.todo('feedback'),
        title: 'Feedback dagli utenti',
        detail: 'Sezione "Feedback utenti"',
      ),
      _TodoRow(
        count: data.todo('deletion_requests'),
        title: 'Richieste di cancellazione account',
        detail: data.todo('deletion_requests') == 0
            ? 'Nessuna richiesta aperta'
            : 'La più vecchia da ${data.todo('deletion_oldest_days')} giorni sui 30',
        urgent: data.todo('deletion_oldest_days') >= 20,
      ),
      _TodoRow(
        count: data.todo('content_to_fix'),
        title: 'Contenuti da sistemare',
        detail: 'Senza coordinate o senza foto, ed eventi scaduti',
      ),
    ];

    return _Card(
      title: 'Da fare ora',
      child: Column(
        children: [
          for (final row in rows) ...[row, const SizedBox(height: 10)],
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.count,
    required this.title,
    required this.detail,
    this.urgent = false,
  });

  final int count;
  final String title;
  final String detail;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final done = count == 0;
    final color = done
        ? AppColors.openGreen
        : urgent
            ? AppColors.closedRed
            : AppColors.signalOrange;
    final background = done
        ? const Color(0xFFF1F7F3)
        : urgent
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFFEF6EC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: done
                ? Icon(Icons.check_rounded, color: color, size: 22)
                : Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  detail,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.steel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Salute ────────────────────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.data});

  final AdminDashboard data;

  String _since(DateTime? moment) {
    if (moment == null) return 'mai';
    final diff = DateTime.now().difference(moment);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 48) return '${diff.inHours} ore fa';
    return '${diff.inDays} giorni fa';
  }

  @override
  Widget build(BuildContext context) {
    final keepalive = data.healthDate('keepalive_at');
    final keepaliveOk =
        keepalive != null && DateTime.now().difference(keepalive).inHours < 48;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salute',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                keepaliveOk ? Icons.check_circle : Icons.error_outline,
                color: keepaliveOk ? AppColors.openGreen : AppColors.closedRed,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keepalive database: ${_since(keepalive)}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _HealthRow(
            label: 'Ultimo iscritto',
            value: _since(data.healthDate('last_signup_at')),
          ),
          _HealthRow(
            label: 'Ultimo contenuto',
            value: _since(data.healthDate('last_content_at')),
          ),
          _HealthRow(
            label: 'Consensi legali correnti',
            value: '${data.consentsCurrent} utenti',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Text(
              'Email ancora dal mittente di prova Supabase',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Andamento iscritti ────────────────────────────────────────────────────────

class _SignupsChart extends StatelessWidget {
  const _SignupsChart({required this.data});

  final AdminDashboard data;

  @override
  Widget build(BuildContext context) {
    final values = data.signups30d;
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final max = values.isEmpty
        ? 0
        : values.reduce((a, b) => a > b ? a : b);

    return _Card(
      title: 'Iscritti al giorno · ultimi 30 giorni',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sotto i 5 iscritti il grafico è una barra sola e sembra rotto.
          if (total < 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                total == 0
                    ? 'Nessuna iscrizione negli ultimi 30 giorni.'
                    : '$total ${total == 1 ? 'iscritto' : 'iscritti'} negli ultimi 30 giorni: troppo pochi per un grafico.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.steel),
              ),
            )
          else
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final value in values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Tooltip(
                        message: '$value iscritti',
                        child: Container(
                          // Barra minima visibile anche a zero.
                          height: max == 0 ? 2 : 2 + (value / max) * 80,
                          decoration: BoxDecoration(
                            color: value == 0
                                ? AppColors.borderSubtle
                                : AppColors.signalOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              Text(
                'Creati negli ultimi 7 giorni:',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.steel),
              ),
              Text('${data.created7d('spots')} spot'),
              Text('${data.created7d('events')} eventi'),
              Text('${data.created7d('builds')} build'),
              Text('${data.created7d('comments')} commenti'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Contenitore comune ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
