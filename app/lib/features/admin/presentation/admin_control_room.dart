import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../application/admin_providers.dart';
import 'package:pitlap_app/app/l10n/tr.dart';

/// Control room: fascia di stato, numeri, "Da fare ora", salute, andamento.
/// Tutti i dati arrivano da una sola chiamata (`admin_dashboard`).
class AdminControlRoom extends ConsumerWidget {
  const AdminControlRoom({super.key, this.onOpen});

  /// Clic su una riga di "Da fare ora": porta alla sezione dove si lavora.
  /// Valori: `approvals`, `claims`, `moderation`, `feedback`, `deletions`,
  /// `to_fix`.
  final ValueChanged<String>? onOpen;

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
        title: tr('Dati non disponibili'),
        subtitle: trf('Riprova ad aggiornare la pagina. ({0})', [error]),
      ),
      data: (data) {
        // Niente dati: meglio dirlo che mostrare una pagina bianca.
        if (data == null) {
          return _Banner(
            color: AppColors.steel,
            background: AppColors.surfaceMuted,
            title: tr('Panoramica non disponibile'),
            subtitle: tr('Ricarica la pagina; se resta vuota, rifai l\'accesso.'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusBand(data: data),
            const SizedBox(height: 12),
            _CountsRow(data: data),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final todo = _TodoList(data: data, onOpen: onOpen);
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
        title: tr('Tutto tranquillo'),
        subtitle:
            tr('Niente da approvare, niente da moderare, nessun feedback da leggere.'),
      );
    }
    final oldest = data.todo('oldest_pending_days');
    return _Banner(
      color: AppColors.signalOrange,
      background: const Color(0xFFFEF6EC),
      title: trf('C\'è da lavorare · {0} {1}', [open, open == 1 ? 'azione' : 'azioni']),
      subtitle: oldest > 0
          ? trf('La più vecchia aspetta da {0} {1}.', [oldest, oldest == 1 ? 'giorno' : 'giorni'])
          : tr('Tutte arrivate oggi.'),
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
          label: tr('Iscritti'),
          value: '${data.count('users')}',
          hint: delta == 0
              ? trf('{0} negli ultimi 7 giorni', [users7d])
              : trf('{0}{1} rispetto ai 7 giorni prima', [delta > 0 ? '+' : '', delta]),
          hintColor: delta > 0 ? AppColors.openGreen : AppColors.steel,
        ),
        _Tile(
          label: tr('Onboarding completato'),
          value: '${data.count('onboarding_done')} / ${data.count('users')}',
        ),
        _Tile(
          label: tr('Piste'),
          value: '${data.count('tracks')}',
          hint: trf('{0} aperte ora', [data.count('tracks_open')]),
        ),
        _Tile(label: tr('Spot'), value: '${data.count('spots')}'),
        _Tile(label: tr('Eventi futuri'), value: '${data.count('events_future')}'),
        _Tile(
          label: tr('Silenzio'),
          value: silence == null ? '—' : '$silence h',
          hint: tr('dall\'ultimo contenuto pubblicato'),
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
  const _TodoList({required this.data, this.onOpen});

  final AdminDashboard data;
  final ValueChanged<String>? onOpen;

  VoidCallback? _open(String target) =>
      onOpen == null ? null : () => onOpen!(target);

  @override
  Widget build(BuildContext context) {
    final pending = data.todo('pending_tracks') + data.todo('pending_shops');
    final rows = <Widget>[
      _TodoRow(
        count: pending,
        title: tr('Piste e negozi da approvare'),
        detail: pending == 0
            ? tr('Nessuna richiesta in coda')
            : trf('{0} piste · {1} negozi', [data.todo('pending_tracks'), data.todo('pending_shops')]),
        urgent: data.todo('oldest_pending_days') >= 2,
        onTap: _open('approvals'),
      ),
      _TodoRow(
        count: data.todo('track_claims') + data.todo('shop_claims'),
        title: tr('Rivendicazioni da verificare'),
        detail: tr('Chi approvi diventa gestore della scheda'),
        onTap: _open('claims'),
      ),
      _TodoRow(
        count: data.todo('reported_comments'),
        title: tr('Commenti segnalati'),
        detail: tr('Da moderare nella sezione Moderazione'),
        onTap: _open('moderation'),
      ),
      _TodoRow(
        count: data.todo('feedback'),
        title: tr('Feedback dagli utenti'),
        detail: tr('Sezione "Feedback utenti"'),
        onTap: _open('feedback'),
      ),
      _TodoRow(
        count: data.todo('deletion_requests'),
        title: tr('Richieste di cancellazione account'),
        detail: data.todo('deletion_requests') == 0
            ? tr('Nessuna richiesta aperta')
            : trf('La più vecchia da {0} giorni sui 30', [data.todo('deletion_oldest_days')]),
        urgent: data.todo('deletion_oldest_days') >= 20,
        onTap: _open('deletions'),
      ),
      _TodoRow(
        count: data.todo('content_to_fix'),
        title: tr('Contenuti da sistemare'),
        detail: tr('Spot senza coordinate o senza foto'),
        onTap: _open('to_fix'),
      ),
    ];

    return _Card(
      title: tr('Da fare ora'),
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
    this.onTap,
  });

  final int count;
  final String title;
  final String detail;
  final bool urgent;

  /// Solo se c'è qualcosa da fare: una riga a zero non porta da nessuna parte.
  final VoidCallback? onTap;

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

    final tap = done ? null : onTap;

    // Ink (non Container): così l'effetto al clic si vede sopra lo sfondo.
    final row = Ink(
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
          if (tap != null) ...[
            const SizedBox(width: 8),
            Text(
              tr('Vai'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ],
      ),
    );

    // Material proprio: la card attorno è un Container colorato e Ink
    // dipingerebbe sotto di lei, cioè non si vedrebbe.
    return Material(
      type: MaterialType.transparency,
      child: tap == null
          ? row
          : InkWell(
              onTap: tap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: row,
            ),
    );
  }
}

// ── Salute ────────────────────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.data});

  final AdminDashboard data;

  String _since(DateTime? moment) {
    if (moment == null) return tr('mai');
    final diff = DateTime.now().difference(moment);
    if (diff.inMinutes < 60) return trf('{0} min fa', [diff.inMinutes]);
    if (diff.inHours < 48) return trf('{0} ore fa', [diff.inHours]);
    return trf('{0} giorni fa', [diff.inDays]);
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
            tr('Salute'),
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
            label: tr('Ultimo iscritto'),
            value: _since(data.healthDate('last_signup_at')),
          ),
          _HealthRow(
            label: tr('Ultimo contenuto'),
            value: _since(data.healthDate('last_content_at')),
          ),
          _HealthRow(
            label: tr('Consensi legali correnti'),
            value: trf('{0} utenti', [data.consentsCurrent]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              tr('Email ancora dal mittente di prova Supabase'),
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
      title: tr('Iscritti al giorno · ultimi 30 giorni'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sotto i 5 iscritti il grafico è una barra sola e sembra rotto.
          if (total < 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                total == 0
                    ? tr('Nessuna iscrizione negli ultimi 30 giorni.')
                    : trf('{0} {1} negli ultimi 30 giorni: troppo pochi per un grafico.', [total, total == 1 ? 'iscritto' : 'iscritti']),
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
                        message: trf('{0} iscritti', [value]),
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
                tr('Creati negli ultimi 7 giorni:'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.steel),
              ),
              Text(trf('{0} spot', [data.created7d('spots')])),
              Text(trf('{0} eventi', [data.created7d('events')])),
              Text(trf('{0} build', [data.created7d('builds')])),
              Text(trf('{0} commenti', [data.created7d('comments')])),
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
