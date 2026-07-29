import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/empty_state_panel.dart';
import '../../../shared/models/submitted_track.dart';
import '../../../shared/models/track_list_item.dart';
import '../../auth/application/auth_providers.dart';
import '../../shops/application/shop_editor_providers.dart';
import '../../tracks/application/tracks_providers.dart';

class ManagerScreen extends ConsumerStatefulWidget {
  const ManagerScreen({super.key});

  @override
  ConsumerState<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends ConsumerState<ManagerScreen> {
  late final TextEditingController _statusMessageController;
  late String _trackStatus;
  late bool _compressorAvailable;
  late bool _bathroomsAvailable;
  late bool _eventReady;
  bool _saving = false;
  bool _hasUnsavedChanges = false;
  bool _ignoreMessageChanges = false;
  DateTime? _lastSavedAt;
  String? _serviceSeedTrackId;
  String? _selectedTrackId;

  @override
  void initState() {
    super.initState();
    _statusMessageController = TextEditingController();
    _statusMessageController.addListener(_onMessageChanged);
    _trackStatus = 'open';
    _compressorAvailable = true;
    _bathroomsAvailable = true;
    _eventReady = false;
  }

  @override
  void dispose() {
    _statusMessageController.removeListener(_onMessageChanged);
    _statusMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final managedTracksAsync = ref.watch(managedTracksProvider);
    final trackDrafts = ref.watch(submittedTracksProvider).asData?.value ?? const <SubmittedTrack>[];
    final myShopDrafts = ref.watch(myEditableShopDraftsProvider);
    final publicTracksAsync = ref.watch(publicTracksProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final canManageShops = ref.watch(canManageShopsProvider);

    return ContentScaffold(
      title: l10n.managerScreenTitle,
      description: l10n.managerDescription,
      child: managedTracksAsync.when(
        data: (managedTracks) {
          if (managedTracks.isEmpty) {
            return ListView(
              children: [
                Card(
                  color: AppColors.graphite,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.managerHeroTitle,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.managerHeroBody,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.concrete),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _HeroPointChip(
                              icon: Icons.flag_outlined,
                              label: l10n.managerActionStatusTitle,
                            ),
                            _HeroPointChip(
                              icon: Icons.handyman_outlined,
                              label: l10n.managerActionServicesTitle,
                            ),
                            _HeroPointChip(
                              icon: Icons.event_outlined,
                              label: l10n.managerActionEventsTitle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 980;
                    final introCard = Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏁 ${l10n.managerNoTracksTitle}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.managerNoTracksBody,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.steel),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: () =>
                                      context.go('/manager/tracks/new'),
                                  icon: const Icon(Icons.add_road_outlined),
                                  label: const Text('Crea la tua pista'),
                                ),
                                if (canManageShops)
                                  OutlinedButton.icon(
                                    onPressed: () => context.go('/shops/new'),
                                    icon: const Icon(Icons.storefront_outlined),
                                    label: const Text('Crea negozio'),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () => context.go('/'),
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Apri le piste'),
                                ),
                                if (isAdmin)
                                  OutlinedButton.icon(
                                    onPressed: () => context.go('/admin'),
                                    icon: const Icon(Icons.settings_outlined),
                                    label: const Text(
                                      'Apri configuratore admin',
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 18),
                            Text(
                              'Quando una pista verrà collegata al tuo account, qui potrai aggiornare stato del fondo, servizi disponibili e giornate speciali senza passare da SQL o dashboard tecniche.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.steel),
                            ),
                          ],
                        ),
                      ),
                    );

                    final capabilityCard = Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏁 Cosa troverai qui',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Abbiamo già preparato il pannello per una gestione rapida, pensata per club e organizzatori che devono aggiornare il contesto in pochi tocchi.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.steel),
                            ),
                            const SizedBox(height: 16),
                            _ManagerActionCard(
                              icon: Icons.flag_outlined,
                              title: l10n.managerActionStatusTitle,
                              body: l10n.managerActionStatusBody,
                            ),
                            const SizedBox(height: 10),
                            _ManagerActionCard(
                              icon: Icons.handyman_outlined,
                              title: l10n.managerActionServicesTitle,
                              body: l10n.managerActionServicesBody,
                            ),
                            const SizedBox(height: 10),
                            _ManagerActionCard(
                              icon: Icons.event_outlined,
                              title: l10n.managerActionEventsTitle,
                              body: l10n.managerActionEventsBody,
                            ),
                          ],
                        ),
                      ),
                    );

                    if (compact) {
                      return Column(
                        children: [
                          introCard,
                          const SizedBox(height: 18),
                          capabilityCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: introCard),
                        const SizedBox(width: 18),
                        Expanded(child: capabilityCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                if (trackDrafts.any((d) => d.approvalStatus != 'approved')) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚀 Le tue piste in preparazione',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Qui trovi le bozze pista e le schede inviate in approvazione, così puoi seguirne lo stato senza uscire da Gestione.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.steel),
                          ),
                          const SizedBox(height: 16),
                          ...trackDrafts
                              .where((d) => d.approvalStatus != 'approved')
                              .map(
                                (draft) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _DraftTrackCard(draft: draft),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (trackDrafts.any((d) => d.approvalStatus == 'approved')) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✅ Le tue piste approvate',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Queste schede sono state approvate e sono visibili nel catalogo. Puoi modificarle e aggiornarne i contenuti.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.steel),
                          ),
                          const SizedBox(height: 16),
                          ...trackDrafts
                              .where((d) => d.approvalStatus == 'approved')
                              .map(
                                (draft) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _DraftTrackCard(draft: draft),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (canManageShops && myShopDrafts.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏪 I tuoi negozi in gestione',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bozze, negozi in approvazione e schede già preparate dal tuo account.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.steel),
                          ),
                          const SizedBox(height: 16),
                          ...myShopDrafts.map(
                            (draft) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ManagedShopDraftCard(draft: draft),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🌐 Piste già in PitLap',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nel frattempo puoi aprire le schede pista già online, verificare il tono dei contenuti e capire come si presenterà la tua area quando verrà collegata.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.steel),
                        ),
                        const SizedBox(height: 16),
                        publicTracksAsync.when(
                          data: (tracks) {
                            if (tracks.isEmpty) {
                              return const EmptyStatePanel(
                                icon: Icons.flag_outlined,
                                title: 'Nessuna pista pubblica',
                                subtitle: 'Non ci sono ancora piste pubbliche da mostrare.',
                                compact: true,
                              );
                            }

                            final previewTracks = tracks.take(4).toList();
                            return Column(
                              children: previewTracks
                                  .map(
                                    (track) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _AvailableTrackCard(
                                        track: track,
                                        statusLabel: _statusLabel(
                                          l10n,
                                          track.status,
                                        ),
                                        onOpen: () =>
                                            context.go('/track/${track.slug}'),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, errorStack) => Text(
                            'Non siamo riusciti a caricare l\'anteprima delle piste pubbliche.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.steel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final primaryTrack = managedTracks.firstWhere(
            (track) => track.id == _selectedTrackId,
            orElse: () => managedTracks.first,
          );
          final selectedTrackDetailAsync = ref.watch(
            managedTrackDetailProvider(primaryTrack.slug),
          );
          final recentUpdatesAsync = ref.watch(
            managedTrackRecentUpdatesProvider(primaryTrack.id),
          );

          if (_selectedTrackId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _selectedTrackId = managedTracks.first.id;
                _applyTrackDefaults(managedTracks.first);
              });
            });
          }

          selectedTrackDetailAsync.whenData((trackDetail) {
            if (trackDetail == null || _serviceSeedTrackId == primaryTrack.id) {
              return;
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _serviceSeedTrackId == primaryTrack.id) {
                return;
              }
              final availableKeys = trackDetail.availableServiceKeys.toSet();
              setState(() {
                _serviceSeedTrackId = primaryTrack.id;
                _compressorAvailable = availableKeys.contains('compressed_air');
                _bathroomsAvailable = availableKeys.contains('toilets');
                _hasUnsavedChanges = false;
              });
            });
          });

          return ListView(
            children: [
              Card(
                color: AppColors.graphite,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.managerHeroTitle,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.managerHeroBody,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.concrete,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: managedTracks
                            .map(
                              (track) => ActionChip(
                                label: Text(track.name),
                                onPressed: () {
                                  setState(() {
                                    _selectedTrackId = track.id;
                                    _applyTrackDefaults(track);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏁 ${l10n.managerAssignedTracksTitle}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.managerAssignedTracksBody,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppColors.steel),
                      ),
                      const SizedBox(height: 14),
                      ...managedTracks.map(
                        (track) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ManagedTrackCard(
                            slug: track.slug,
                            name: track.name,
                            city: track.city,
                            status: track.status,
                            statusMessage: track.statusMessage,
                            onOpen: () => context.go('/track/${track.slug}'),
                            onEdit: () =>
                                context.go('/manager/tracks/${track.slug}/edit'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // D07 — sezione bozze/in-approvazione sempre visibile anche
              // quando l'utente ha piste già assegnate via track_managers.
              Builder(
                builder: (context) {
                  final pendingDrafts = trackDrafts
                      .where((d) => d.approvalStatus != 'approved')
                      .toList();
                  if (pendingDrafts.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🚀 Bozze e in approvazione',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Piste che hai inviato in revisione o che sono ancora in bozza.',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: AppColors.steel),
                              ),
                              const SizedBox(height: 16),
                              ...pendingDrafts.map(
                                (draft) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _DraftTrackCard(draft: draft),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  );
                },
              ),
              if (canManageShops && myShopDrafts.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🏪 I tuoi negozi in gestione',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Qui trovi i negozi creati dal tuo account e puoi riaprire subito l\'editor.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.steel),
                        ),
                        const SizedBox(height: 16),
                        ...myShopDrafts.map(
                          (draft) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ManagedShopDraftCard(draft: draft),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📝 Ultimi aggiornamenti',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Timeline operativa degli ultimi salvataggi eseguiti su questa pista.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppColors.steel),
                      ),
                      const SizedBox(height: 14),
                      recentUpdatesAsync.when(
                        data: (updates) {
                          if (updates.isEmpty) {
                            return const EmptyStatePanel(
                              icon: Icons.history_outlined,
                              title: 'Nessun aggiornamento storico',
                              subtitle: 'Nessun aggiornamento storico disponibile per ora.',
                              compact: true,
                            );
                          }
                          return Column(
                            children: updates
                                .map(
                                  (update) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _StatusHistoryItem(
                                      status: update.status,
                                      statusLabel: _statusLabel(
                                        l10n,
                                        update.status,
                                      ),
                                      message: update.message,
                                      timeLabel: update.updatedAt == null
                                          ? 'Orario non disponibile'
                                          : _formatDateTime(
                                              context,
                                              update.updatedAt!,
                                            ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timeline non disponibile: $error',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.steel),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                ref.invalidate(
                                  managedTrackRecentUpdatesProvider(
                                    primaryTrack.id,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh_outlined),
                              label: const Text('Riprova'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📡 ${l10n.managerTodayTitle}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.managerEditingTrack(primaryTrack.name),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppColors.steel),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatusPill(
                            label: _statusLabel(l10n, _trackStatus),
                            status: _trackStatus,
                          ),
                          if (_hasUnsavedChanges)
                            const _StatusPill(
                              label: 'Modifiche non salvate',
                              status: 'draft',
                            ),
                          if (_lastSavedAt != null)
                            _StatusPill(
                              label:
                                  'Ultimo invio ${_formatTime(context, _lastSavedAt!)}',
                              status: 'open',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preset rapidi',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _applyPreset(
                                    status: 'open',
                                    message: 'Pronta per sessioni libere.',
                                    compressorAvailable: true,
                                    bathroomsAvailable: true,
                                  ),
                            child: const Text('Pronta gara'),
                          ),
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _applyPreset(
                                    status: 'wet',
                                    message:
                                        'Fondo bagnato, guida consigliata con prudenza.',
                                    compressorAvailable: true,
                                    bathroomsAvailable: true,
                                  ),
                            child: const Text('Bagnata ma aperta'),
                          ),
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _applyPreset(
                                    status: 'closed',
                                    message: 'Pista chiusa per manutenzione.',
                                    compressorAvailable: false,
                                    bathroomsAvailable: false,
                                  ),
                            child: const Text('Chiusa manutenzione'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.managerStatusLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ChoiceChip(
                            selected: _trackStatus == 'open',
                            label: Text(l10n.statusOpen),
                            onSelected: _saving
                                ? null
                                : (_) => _setStatus('open'),
                          ),
                          ChoiceChip(
                            selected: _trackStatus == 'wet',
                            label: Text(l10n.statusWet),
                            onSelected: _saving
                                ? null
                                : (_) => _setStatus('wet'),
                          ),
                          ChoiceChip(
                            selected: _trackStatus == 'closed',
                            label: Text(l10n.statusClosed),
                            onSelected: _saving
                                ? null
                                : (_) => _setStatus('closed'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _statusMessageController,
                        enabled: !_saving,
                        decoration: InputDecoration(
                          labelText: l10n.managerStatusMessageLabel,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        value: _compressorAvailable,
                        onChanged: _saving
                            ? null
                            : (value) => _setCompressor(value),
                        title: Text(l10n.managerToggleCompressor),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _bathroomsAvailable,
                        onChanged: _saving
                            ? null
                            : (value) => _setBathrooms(value),
                        title: Text(l10n.managerToggleBathrooms),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        value: _eventReady,
                        onChanged: _saving
                            ? null
                            : (value) => _setEventReady(value),
                        title: Text(l10n.managerToggleEventReady),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: currentUser == null ||
                                    _saving ||
                                    !_hasUnsavedChanges
                                ? null
                                : () => _saveManagedTrack(
                                    trackId: primaryTrack.id,
                                    userId: currentUser.id,
                                    trackName: primaryTrack.name,
                                  ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _saving
                                  ? 'Salvataggio...'
                                  : _hasUnsavedChanges
                                  ? l10n.managerSaveAction
                                  : 'Nessuna modifica da salvare',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () {
                                    ref.invalidate(
                                      managedTrackDetailProvider(
                                        primaryTrack.slug,
                                      ),
                                    );
                                    ref.invalidate(
                                      managedTrackRecentUpdatesProvider(
                                        primaryTrack.id,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.refresh_outlined),
                            label: const Text('Ricarica dati'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Azioni rapide',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tutte le operazioni disponibili per la tua pista.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.steel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => context.go(
                              '/manager/tracks/${primaryTrack.slug}/edit',
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Modifica scheda pista'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/events'),
                            icon: const Icon(Icons.event_outlined),
                            label: const Text('Gestisci eventi'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/track/${primaryTrack.slug}'),
                            icon: const Icon(Icons.open_in_new_outlined),
                            label: const Text('Vedi scheda pubblica'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.trackLoadError(error.toString()))),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    return switch (status) {
      'open' => l10n.statusOpen,
      'wet' => l10n.statusWet,
      'closed' => l10n.statusClosed,
      'info' => 'Aggiornamento scheda',
      _ => l10n.statusUnknown,
    };
  }

  void _onMessageChanged() {
    if (_saving || _ignoreMessageChanges) {
      return;
    }
    _markDirty();
  }

  void _markDirty() {
    if (_hasUnsavedChanges) {
      return;
    }
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  void _setStatus(String status) {
    if (_trackStatus == status) {
      return;
    }
    setState(() {
      _trackStatus = status;
      _hasUnsavedChanges = true;
    });
  }

  void _setCompressor(bool value) {
    if (_compressorAvailable == value) {
      return;
    }
    setState(() {
      _compressorAvailable = value;
      _hasUnsavedChanges = true;
    });
  }

  void _setBathrooms(bool value) {
    if (_bathroomsAvailable == value) {
      return;
    }
    setState(() {
      _bathroomsAvailable = value;
      _hasUnsavedChanges = true;
    });
  }

  void _setEventReady(bool value) {
    if (_eventReady == value) {
      return;
    }
    setState(() {
      _eventReady = value;
      _hasUnsavedChanges = true;
    });
  }

  void _applyPreset({
    required String status,
    required String message,
    required bool compressorAvailable,
    required bool bathroomsAvailable,
  }) {
    setState(() {
      _trackStatus = status;
      _ignoreMessageChanges = true;
      _statusMessageController.text = message;
      _ignoreMessageChanges = false;
      _compressorAvailable = compressorAvailable;
      _bathroomsAvailable = bathroomsAvailable;
      _hasUnsavedChanges = true;
    });
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final local = dateTime.toLocal();
    return TimeOfDay.fromDateTime(local).format(context);
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = MaterialLocalizations.of(
      context,
    ).formatMediumDate(local);
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '$day · $time';
  }

  void _applyTrackDefaults(TrackListItem track) {
    _trackStatus = track.status;
    _ignoreMessageChanges = true;
    _statusMessageController.text = track.statusMessage;
    _ignoreMessageChanges = false;
    _serviceSeedTrackId = null;
    _compressorAvailable = true;
    _bathroomsAvailable = true;
    _hasUnsavedChanges = false;
  }

  Future<void> _saveManagedTrack({
    required String trackId,
    required String userId,
    required String trackName,
  }) async {
    final repository = ref.read(tracksRepositoryProvider);
    final l10n = AppLocalizations.of(context)!;
    if (repository == null || _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await repository.saveManagedTrackSnapshot(
        trackId: trackId,
        userId: userId,
        status: _trackStatus,
        message: _statusMessageController.text,
        compressedAirAvailable: _compressorAvailable,
        bathroomsAvailable: _bathroomsAvailable,
      );

      ref.invalidate(publicTracksProvider);
      ref.invalidate(managedTracksProvider);
      ref.invalidate(managedTrackRecentUpdatesProvider(trackId));

      if (!mounted) {
        return;
      }

      setState(() {
        _hasUnsavedChanges = false;
        _lastSavedAt = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.managerSaveSuccessTrack(trackName))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Salvataggio non riuscito: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

class _HeroPointChip extends StatelessWidget {
  const _HeroPointChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ManagerActionCard extends StatelessWidget {
  const _ManagerActionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.concrete),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.concrete),
            ),
            child: Icon(icon, color: AppColors.graphite),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableTrackCard extends StatelessWidget {
  const _AvailableTrackCard({
    required this.track,
    required this.statusLabel,
    required this.onOpen,
  });

  final TrackListItem track;
  final String statusLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F3),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.concrete),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.warningAmber.withValues(alpha: 0.14),
              ),
              child: const Icon(Icons.flag_outlined, color: AppColors.graphite),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        track.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _StatusPill(label: statusLabel, status: track.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    track.city,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                  ),
                  if (track.shortDescription.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      track.shortDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (track.statusMessage.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      track.statusMessage,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_outlined),
              label: const Text('Apri pista'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor) = switch (status) {
      'open' => (const Color(0xFFE4F5EA), const Color(0xFF0E9F4B)),
      'wet' => (const Color(0xFFE8F0FF), const Color(0xFF2D6CF6)),
      'closed' => (const Color(0xFFFCE9E7), const Color(0xFFD04B3F)),
      'draft' => (
        AppColors.signalOrange.withValues(alpha: 0.14),
        AppColors.graphite,
      ),
      _ => (const Color(0xFFF1EFE9), AppColors.graphite),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusHistoryItem extends StatelessWidget {
  const _StatusHistoryItem({
    required this.status,
    required this.statusLabel,
    required this.message,
    required this.timeLabel,
  });

  final String status;
  final String statusLabel;
  final String message;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.concrete),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(
                label: statusLabel,
                status: status,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  timeLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.steel),
                ),
              ),
            ],
          ),
          if (message.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _ManagedTrackCard extends StatelessWidget {
  const _ManagedTrackCard({
    required this.slug,
    required this.name,
    required this.city,
    required this.status,
    required this.statusMessage,
    required this.onOpen,
    required this.onEdit,
  });

  final String slug;
  final String name;
  final String city;
  final String status;
  final String statusMessage;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.concrete),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              city,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 2),
            Text(
              '/track/$slug',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 10),
            Text(
              statusMessage.trim().isEmpty ? status : '$status - $statusMessage',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: const Text('Apri pista'),
                ),
                FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifica scheda'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftTrackCard extends StatelessWidget {
  const _DraftTrackCard({required this.draft});

  final SubmittedTrack draft;

  String get _statusLabel => switch (draft.approvalStatus) {
    'pending' => 'In approvazione',
    'approved' => 'Approvata',
    'rejected' => 'Da rivedere',
    _ => 'Bozza',
  };

  String get _statusKey => switch (draft.approvalStatus) {
    'pending' => 'wet',
    'approved' => 'open',
    'rejected' => 'closed',
    _ => 'draft',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.concrete),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final media = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 140,
              child: draft.imageUrl == null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.signalOrange.withValues(alpha: 0.4),
                            const Color(0xFFF2F4F7),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.flag_outlined,
                          color: AppColors.graphite,
                          size: 36,
                        ),
                      ),
                    )
                  : AdaptiveImage(
                      source: draft.imageUrl!,
                      fit: BoxFit.cover,
                      fallback: const ColoredBox(color: Color(0xFFEDEFF3)),
                    ),
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(draft.name, style: Theme.of(context).textTheme.titleLarge),
                  _StatusPill(label: _statusLabel, status: _statusKey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                draft.city,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.steel,
                ),
              ),
              if (draft.shortDescription.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  draft.shortDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (draft.reviewNotes != null && draft.reviewNotes!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE9E7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Note admin: ${draft.reviewNotes}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFD04B3F),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _DraftTrackActions(draft: draft),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [media, const SizedBox(height: 14), content],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 220, child: media),
              const SizedBox(width: 18),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

/// Bottoni azione per una bozza pista: Modifica per draft/rejected, info per pending.
class _DraftTrackActions extends StatelessWidget {
  const _DraftTrackActions({required this.draft});

  final SubmittedTrack draft;

  bool get _canEdit =>
      draft.approvalStatus == 'draft' || draft.approvalStatus == 'rejected';

  @override
  Widget build(BuildContext context) {
    if (_canEdit) {
      return Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => context.go(
              '/manager/tracks/draft/edit',
              extra: draft,
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Modifica scheda'),
          ),
        ],
      );
    }
    // pending: la pista è in revisione, non modificabile
    return Row(
      children: [
        const Icon(Icons.hourglass_top_outlined, size: 16, color: AppColors.steel),
        const SizedBox(width: 6),
        Text(
          'In attesa di revisione admin',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.steel,
          ),
        ),
      ],
    );
  }
}

class _ManagedShopDraftCard extends StatelessWidget {
  const _ManagedShopDraftCard({required this.draft});

  final EditableShopRecord draft;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (draft.approvalStatus) {
      'pending' => 'In approvazione',
      'approved' => 'Approvato',
      'rejected' => 'Da rivedere',
      _ => 'Bozza negozio',
    };
    final compact = MediaQuery.sizeOf(context).width < 980;

    return Card(
      color: const Color(0xFFF8F7F3),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final media = ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 160,
                child: draft.imageUrl.trim().isEmpty
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFE7D8), Color(0xFFF3F5F8)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.storefront_outlined,
                            color: AppColors.graphite,
                            size: 34,
                          ),
                        ),
                      )
                    : AdaptiveImage(
                        source: draft.imageUrl,
                        fit: BoxFit.cover,
                        fallback: const ColoredBox(color: Color(0xFFEDEFF3)),
                      ),
              ),
            );

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      draft.name.isEmpty ? draft.slug : draft.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    _StatusPill(label: statusLabel, status: 'draft'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (draft.city.trim().isNotEmpty) draft.city.trim(),
                    if (draft.address.trim().isNotEmpty) draft.address.trim(),
                  ].join(' · '),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.steel),
                ),
                if (draft.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    draft.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (draft.serviceLabels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: draft.serviceLabels
                        .take(4)
                        .map(
                          (label) => _StatusPill(label: label, status: 'draft'),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.go('/shop/${draft.slug}/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifica negozio'),
                    ),
                    if (draft.approvalStatus == 'approved')
                      OutlinedButton.icon(
                        onPressed: () => context.go('/shop/${draft.slug}'),
                        icon: const Icon(Icons.open_in_new_outlined),
                        label: const Text('Apri scheda'),
                      ),
                  ],
                ),
              ],
            );

            if (compact || constraints.maxWidth < 860) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [media, const SizedBox(height: 14), content],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 220, child: media),
                const SizedBox(width: 18),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}
