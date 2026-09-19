import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/widgets/dialog_controller_scope.dart';
import '../../events/application/public_events_provider.dart';
import '../../garage/application/public_builds_provider.dart';
import '../../profile/application/public_profiles_provider.dart';
import '../../shops/application/public_shops_provider.dart';
import '../../spots/application/spots_providers.dart';
import '../../tracks/application/tracks_providers.dart';
import '../application/admin_providers.dart';
import 'admin_control_room.dart';
import '../../auth/application/auth_providers.dart';
import '../../shops/application/shop_editor_providers.dart';

// FR-18: etichette leggibili per ruoli/stati (allineate a /profiles) invece
// dei valori DB grezzi.
String adminRoleLabel(String role) => switch (role) {
  'track_organizer' => 'Organizzatore pista',
  'shop_owner' || 'shop_manager' => 'Gestore negozio',
  'admin' => 'Admin',
  'user' => 'Pilota',
  _ => role,
};

String adminApprovalLabel(String status) => switch (status) {
  'approved' => 'Approvato',
  'rejected' => 'Rifiutato',
  'pending' => 'In attesa',
  _ => status,
};

String adminVisibilityLabel(String v) => switch (v) {
  'public' => 'Pubblico',
  'hidden' => 'Nascosto',
  _ => v,
};

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final TextEditingController _trackLabelController = TextEditingController();
  final TextEditingController _shopLabelController = TextEditingController();
  final List<String> _shopServiceLabels = [
    'Pickup',
    'Bench tuning',
    'Ricambi',
    'Riparazioni',
  ];

  /// Scheda aperta: 0 Panoramica · 1 Contenuti · 2 Persone · 3 Impostazioni.
  int _tab = 0;

  @override
  void dispose() {
    _trackLabelController.dispose();
    _shopLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentRole = ref.watch(effectiveUserRoleProvider);
    final isAdmin = currentRole == 'admin';
    final trackCategoriesAsync = ref.watch(adminTrackCategoriesProvider);
    final pendingDeletionsAsync = ref.watch(adminPendingDeletionsProvider);
    final approvalsAsync = ref.watch(adminApprovalQueueProvider);
    final approvals = approvalsAsync.asData?.value ?? const [];
    final allTracksAsync = ref.watch(adminAllTracksProvider);
    final allShopsAsync = ref.watch(adminAllShopsProvider);
    final allEventsAsync = ref.watch(adminAllEventsProvider);
    final feedbackAsync = ref.watch(adminFeedbackProvider);
    final feedback = feedbackAsync.asData?.value ?? const <AdminFeedbackRecord>[];

    if (!isAdmin) {
      return ContentScaffold(
        title: l10n.adminTitle,
        description: l10n.adminDescription,
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.card(context),
                child: Text(
                  l10n.adminAccessDeniedCard,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.steel),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final pendingDeletions = pendingDeletionsAsync.asData?.value ?? const [];
    final reported = ref.watch(adminReportedCommentsProvider).asData?.value ??
        const <AdminReportedComment>[];
    final claims = ref.watch(adminTrackClaimsProvider).asData?.value ??
        const <AdminTrackClaim>[];

    // Sezioni per scheda. La panoramica sta in una schermata; le altre
    // scorrono dentro il loro riquadro, non trascinando tutta la pagina.
    final sections = <List<Widget>>[
      // 0 · Panoramica
      const [AdminControlRoom()],
      // 1 · Contenuti
      [
        _AdminSectionCard(
          title: 'Approvazioni',
          body: 'Coda di lavoro per spot, piste e negozi da validare.',
          child: _ApprovalQueueCard(
            items: approvals,
            onApprove: (item) => _resolveApproval(item, 'approved'),
            onReject: (item) => _resolveApproval(item, 'rejected'),
          ),
        ),
        _AdminSectionCard(
          title: 'Rivendicazioni piste',
          body:
              'Utenti che dichiarano di gestire una pista segnalata dalla community. '
              'Verifica tu prima di approvare: chi approvi diventa gestore della scheda.',
          child: _AdminTrackClaimsSection(
            claims: claims,
            onApprove: (claim) => _resolveClaim(claim, approve: true),
            onReject: (claim) => _resolveClaim(claim, approve: false),
          ),
        ),
        _AdminSectionCard(
          title: 'Piste',
          body:
              'Lista completa: modifica stato approvazione, naviga all\'editor, elimina.',
          child: _AdminTracksSection(
            tracksAsync: allTracksAsync,
            onApprove: (t) => _updateTrackApproval(t, 'approved'),
            onReject: (t) => _updateTrackApproval(t, 'rejected'),
            onDelete: (t) => _deleteTrack(t),
          ),
        ),
        _AdminSectionCard(
          title: 'Aggiungi pista segnalata dalla community',
          body:
              'Dati pubblici raccolti da te. La scheda nasce senza gestore, '
              'senza stato pista e senza PitCoin per nessuno.',
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _openCommunityTrackDialog,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Nuova scheda community'),
            ),
          ),
        ),
        _AdminSectionCard(
          title: 'Negozi',
          body:
              'Lista completa: modifica stato approvazione, visibilità pubblica, elimina.',
          child: _AdminShopsSection(
            shopsAsync: allShopsAsync,
            onApprove: (s) => _updateShopApproval(s, 'approved'),
            onReject: (s) => _updateShopApproval(s, 'rejected'),
            onTogglePublic: (s) => _toggleShopPublic(s),
            onDelete: (s) => _deleteShop(s),
          ),
        ),
        _AdminSectionCard(
          title: 'Moderazione',
          body: 'Commenti segnalati dagli utenti e ancora da gestire.',
          child: _AdminReportedCommentsSection(
            itemsAsync: ref.watch(adminReportedCommentsProvider),
            onHide: (item) => _resolveReport(item, hide: true),
            onDismiss: (item) => _resolveReport(item, hide: false),
          ),
        ),
        _AdminSectionCard(
          title: 'Proposte sugli spot',
          body:
              'Modifiche proposte dagli utenti su spot che non possono editare. '
              'Approvando, i campi proposti sovrascrivono quelli dello spot.',
          child: _AdminSpotSuggestionsSection(
            itemsAsync: ref.watch(adminSpotSuggestionsProvider),
            onApprove: (item) => _reviewSpotSuggestion(item, true),
            onReject: (item) => _reviewSpotSuggestion(item, false),
          ),
        ),
        _AdminSectionCard(
          title: 'Eventi',
          // Il controllo di visibilità esiste solo per gli eventi ufficiali
          // (tabella `events`): quelli della community si possono solo eliminare.
          body:
              'Eventi ufficiali e della community. La visibilità si può '
              'cambiare solo sugli eventi ufficiali; quelli creati dagli '
              'utenti si possono solo eliminare.',
          child: _AdminEventsSection(
            eventsAsync: allEventsAsync,
            onToggleVisibility: _toggleEventVisibility,
            onDelete: (e) => _deleteEvent(e),
          ),
        ),
      ],
      // 2 · Persone
      [
        _AdminSectionCard(
          title: 'Utenti',
          body:
              'Cerca, filtra per ruolo, modifica o osserva l\'app come un utente specifico.',
          child: _AdminUsersPanel(
            onChangeRole: _changeUserRole,
            onRename: _renameUser,
          ),
        ),
        _AdminSectionCard(
          title: 'Cancellazioni account richieste',
          body:
              'Richieste ex art. 17 GDPR. L\'informativa promette la '
              'cancellazione entro 30 giorni: la rimozione va eseguita a '
              'mano dalla dashboard Supabase.',
          child: _AdminDeletionRequestsSection(
            requestsAsync: pendingDeletionsAsync,
            onHandled: _markDeletionHandled,
          ),
        ),
        _AdminSectionCard(
          title: 'Feedback utenti',
          body:
              'Messaggi inviati dagli utenti (anche guest). Visibili solo a te.',
          child: _AdminFeedbackSection(
            feedbackAsync: feedbackAsync,
            onHandled: _markFeedbackHandled,
            onReply: _replyToFeedback,
          ),
        ),
      ],
      // 3 · Impostazioni
      [
        _AdminSectionCard(
          title: 'Categorie pista',
          body: 'Le categorie alimentano card e filtri senza hardcode.',
          child: _TrackCategoriesSection(
            title: '',
            body: '',
            controller: _trackLabelController,
            addLabel: 'Nuova categoria',
            actionLabel: 'Aggiungi',
            categoriesAsync: trackCategoriesAsync,
            onAdd: _addTrackCategory,
            onDelete: _deleteTrackCategory,
          ),
        ),
        _AdminSectionCard(
          title: 'Servizi negozio',
          body: 'Tag usati in card e dettaglio negozio.',
          child: _EditableTagSection(
            title: '',
            body: '',
            controller: _shopLabelController,
            items: _shopServiceLabels,
            addLabel: 'Nuova label negozio',
            actionLabel: 'Aggiungi',
            onAdd: () async {
              final value = _shopLabelController.text.trim();
              if (value.isEmpty) return;
              setState(() {
                _shopServiceLabels.insert(0, value);
                _shopLabelController.clear();
              });
            },
          ),
        ),
      ],
    ];

    final current = sections[_tab];

    return ContentScaffold(
      title: l10n.adminTitle,
      description: l10n.adminDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminTabBar(
            current: _tab,
            badges: [
              0,
              approvals.length + reported.length + claims.length,
              feedback.length + pendingDeletions.length,
              0,
            ],
            onChanged: (index) => setState(() => _tab = index),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              key: ValueKey(_tab),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: current.length,
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemBuilder: (_, index) => current[index],
            ),
          ),
        ],
      ),
    );
  }

  // ── Snackbar helper ───────────────────────────────────────────────────────

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────

  Future<bool> _confirmDelete(String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text('Eliminare "$label"? L\'operazione non è reversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Le liste pubbliche sono in cache per tutta la sessione: senza questo
  /// svuotamento un'approvazione o un'eliminazione dall'admin non si vedeva
  /// nelle pagine Piste/Spot/Eventi/Negozi/Home fino a un ricaricamento.
  void _invalidatePublicCaches() {
    ref.invalidate(publicTracksProvider);
    ref.invalidate(publicTrackPinsProvider);
    ref.invalidate(publicShopsProvider);
    ref.invalidate(publicUpcomingEventsProvider);
    ref.invalidate(publicPastEventsProvider);
    ref.invalidate(spotEntriesProvider);
    ref.invalidate(publicBuildsProvider);
    ref.invalidate(publicProfilesProvider);
  }

  // ── Fase 2: segnare come gestito ──────────────────────────────────────────

  Future<void> _runAdminAction(Future<void> Function() action, String done) async {
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    try {
      await action();
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(adminFeedbackProvider);
      ref.invalidate(adminReportedCommentsProvider);
      ref.invalidate(adminPendingDeletionsProvider);
      ref.invalidate(adminSpotSuggestionsProvider);
      ref.invalidate(adminTrackClaimsProvider);
      _showSnackBar(done);
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  Future<void> _markFeedbackHandled(AdminFeedbackRecord item) => _runAdminAction(
        () => ref.read(adminRepositoryProvider)!.markFeedbackHandled(item.id),
        'Feedback segnato come letto',
      );

  Future<void> _resolveReport(AdminReportedComment item, {required bool hide}) =>
      _runAdminAction(
        () => ref
            .read(adminRepositoryProvider)!
            .resolveCommentReport(item.id, hide: hide),
        hide ? 'Commento nascosto' : 'Segnalazione respinta',
      );

  Future<void> _reviewSpotSuggestion(AdminSpotSuggestion item, bool approve) =>
      _runAdminAction(
        () => ref
            .read(adminRepositoryProvider)!
            .reviewSpotSuggestion(item.id, approve),
        approve ? 'Proposta applicata allo spot' : 'Proposta rifiutata',
      );

  /// Apre il client di posta con destinatario, oggetto e citazione già pronti.
  /// L'invio dall'app richiederebbe SMTP configurato (Resend), non ancora attivo.
  Future<void> _replyToFeedback(AdminFeedbackRecord item) async {
    final to = (item.contactEmail ?? '').trim();
    if (to.isEmpty) return;
    final quoted = item.message
        .split('\n')
        .map((line) => '> $line')
        .join('\n');
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        'subject': 'Re: il tuo feedback su PitLap',
        'body': 'Ciao,\ngrazie per la segnalazione.\n\n'
            '\n\n--- Il tuo messaggio ---\n$quoted\n\n'
            'PitLap · https://pitlap.app',
      },
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Nessun client di posta disponibile: scrivi a $to');
    }
  }

  Future<void> _markDeletionHandled(AdminDeletionRequest request) =>
      _runAdminAction(
        () => ref
            .read(adminRepositoryProvider)!
            .markDeletionHandled(request.userId),
        'Richiesta segnata come gestita',
      );

  Future<void> _resolveClaim(AdminTrackClaim claim, {required bool approve}) =>
      _runAdminAction(
        () => ref
            .read(adminRepositoryProvider)!
            .resolveTrackClaim(claim.id, approve: approve),
        approve
            ? '${claim.userName} è ora gestore di ${claim.trackName}'
            : 'Richiesta rifiutata',
      );

  Future<void> _openCommunityTrackDialog() async {
    final name = TextEditingController();
    final city = TextEditingController();
    final address = TextEditingController();
    final coords = TextEditingController();
    final website = TextEditingController();
    final hours = TextEditingController();
    final description = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DialogControllerScope(
        controllers: [name, city, address, coords, website, hours, description],
        child: AlertDialog(
          title: const Text('Nuova scheda community'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                  ),
                  TextField(
                    controller: city,
                    decoration: const InputDecoration(labelText: 'Città *'),
                  ),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Indirizzo'),
                  ),
                  TextField(
                    controller: coords,
                    decoration: const InputDecoration(
                      labelText: 'Coordinate (lat, lon)',
                      hintText: '45.622246, 8.9596614',
                    ),
                  ),
                  TextField(
                    controller: website,
                    decoration: const InputDecoration(labelText: 'Sito'),
                  ),
                  TextField(
                    controller: hours,
                    decoration: const InputDecoration(
                      labelText: 'Orari',
                      hintText: 'Domenica 10:30-18:00',
                    ),
                  ),
                  TextField(
                    controller: description,
                    minLines: 2,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Descrizione breve'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Crea'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    if (name.text.trim().isEmpty || city.text.trim().isEmpty) {
      _showSnackBar('Nome e città sono obbligatori');
      return;
    }
    final parts = coords.text.split(',');
    final lat = parts.length == 2 ? double.tryParse(parts[0].trim()) : null;
    final lon = parts.length == 2 ? double.tryParse(parts[1].trim()) : null;

    await _runAdminAction(
      () => ref.read(adminRepositoryProvider)!.createCommunityTrack(
            name: name.text.trim(),
            city: city.text.trim(),
            address: address.text.trim(),
            latitude: lat,
            longitude: lon,
            website: website.text.trim(),
            hours: hours.text.trim(),
            shortDescription: description.text.trim(),
          ),
      'Scheda creata: ora è visibile come "segnalata dalla community"',
    );
    ref.invalidate(adminAllTracksProvider);
    _invalidatePublicCaches();
  }

  // ── Approvals ─────────────────────────────────────────────────────────────

  Future<void> _resolveApproval(AdminApprovalRecord item, String nextStatus) async {
    if (item.id.startsWith('track-')) {
      final trackId = item.id.replaceFirst('track-', '');
      final repository = ref.read(adminRepositoryProvider);
      if (repository == null) {
        _showSnackBar('Connessione al server non disponibile.');
        return;
      }
      try {
        await repository.updateTrackApproval(trackId, nextStatus);
        ref.invalidate(adminApprovalQueueProvider);
        ref.invalidate(adminDashboardProvider);
        ref.invalidate(adminAllTracksProvider);
        _invalidatePublicCaches();
      } catch (e) {
        if (mounted) _showSnackBar('Errore nell\'aggiornamento: $e');
        return;
      }
    } else if (item.id.startsWith('shop-')) {
      final identifier = item.id.replaceFirst('shop-', '');
      try {
        await ref
            .read(editableShopDraftsProvider.notifier)
            .updateApprovalStatus(
              identifier: identifier,
              approvalStatus: nextStatus,
            );
        ref.invalidate(adminApprovalQueueProvider);
        ref.invalidate(adminDashboardProvider);
        ref.invalidate(adminAllShopsProvider);
        _invalidatePublicCaches();
      } catch (e) {
        if (mounted) _showSnackBar('Errore nell\'aggiornamento: $e');
        return;
      }
    }
    if (mounted) {
      _showSnackBar(
        '${item.entityType} "${item.title}" ${nextStatus == 'approved' ? 'approvato' : 'rifiutato'}',
      );
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<void> _changeUserRole(AdminFullUserRecord user) async {
    final roles = ['user', 'shop_owner', 'track_organizer', 'admin'];
    String selected = user.role;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Ruolo: ${user.displayName.isEmpty ? user.id.substring(0, 8) : user.displayName}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: roles
                .map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected == r
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(adminRoleLabel(r)),
                    onTap: () => setDialogState(() => selected = r),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selected == user.role) return;
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.updateUserRole(user.id, selected);
      // Aggiorna in-place senza ricaricare tutto
      ref.read(adminUsersProvider.notifier).patchUser(
        AdminFullUserRecord(
          id: user.id,
          displayName: user.displayName,
          role: selected,
          preferredLanguage: user.preferredLanguage,
          createdAt: user.createdAt,
        ),
      );
      _invalidatePublicCaches();
      _showSnackBar('Ruolo aggiornato: $selected');
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  Future<void> _renameUser(AdminFullUserRecord user) async {
    final controller = TextEditingController(text: user.displayName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => DialogControllerScope(
        controllers: [controller],
        child: AlertDialog(
          title: const Text('Modifica display name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Display name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
    // Il controller resta valido fino allo smontaggio della route: la lettura
    // di controller.text qui sotto avviene prima.
    if (confirmed != true) return;
    final newName = controller.text.trim();
    if (newName == user.displayName) return;
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.updateUserDisplayName(user.id, newName);
      ref.read(adminUsersProvider.notifier).patchUser(
        AdminFullUserRecord(
          id: user.id,
          displayName: newName,
          role: user.role,
          preferredLanguage: user.preferredLanguage,
          createdAt: user.createdAt,
        ),
      );
      _invalidatePublicCaches();
      _showSnackBar('Display name aggiornato');
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  // ── Tracks ────────────────────────────────────────────────────────────────

  Future<void> _updateTrackApproval(AdminTrackRecord track, String status) async {
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.updateTrackApproval(track.id, status);
      ref.invalidate(adminAllTracksProvider);
      ref.invalidate(adminApprovalQueueProvider);
      ref.invalidate(adminDashboardProvider);
      _invalidatePublicCaches();
      _showSnackBar(
        '"${track.name}" ${status == 'approved' ? 'approvata' : 'rifiutata'}',
      );
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  Future<void> _deleteTrack(AdminTrackRecord track) async {
    if (!await _confirmDelete(track.name)) return;
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.deleteTrack(track.id);
      ref.invalidate(adminAllTracksProvider);
      ref.invalidate(adminApprovalQueueProvider);
      ref.invalidate(adminDashboardProvider);
      _invalidatePublicCaches();
      _showSnackBar('"${track.name}" eliminata');
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  // ── Shops ─────────────────────────────────────────────────────────────────

  Future<void> _updateShopApproval(AdminShopRecord shop, String status) async {
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.updateShopApproval(shop.id, status);
      ref.invalidate(adminAllShopsProvider);
      ref.invalidate(adminDashboardProvider);
      _invalidatePublicCaches();
      _showSnackBar(
        '"${shop.name}" ${status == 'approved' ? 'approvato' : 'rifiutato'}',
      );
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  Future<void> _toggleShopPublic(AdminShopRecord shop) async {
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.updateShopVisibility(shop.id, isPublic: !shop.isPublic);
      ref.invalidate(adminAllShopsProvider);
      _invalidatePublicCaches();
      _showSnackBar(
        '"${shop.name}" ora ${!shop.isPublic ? 'pubblico' : 'nascosto'}',
      );
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  Future<void> _deleteShop(AdminShopRecord shop) async {
    if (!await _confirmDelete(shop.name)) return;
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.deleteShop(shop.id);
      ref.invalidate(adminAllShopsProvider);
      ref.invalidate(adminApprovalQueueProvider);
      ref.invalidate(adminDashboardProvider);
      _invalidatePublicCaches();
      _showSnackBar('"${shop.name}" eliminato');
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  // ── Events ────────────────────────────────────────────────────────────────

  Future<void> _toggleEventVisibility(AdminEventRecord event) async {
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    if (!event.supportsVisibilityToggle) return;
    final newVisibility = event.visibility == 'public' ? 'hidden' : 'public';
    try {
      await repository.updateEventVisibility(event.id, newVisibility);
      ref.invalidate(adminAllEventsProvider);
      _invalidatePublicCaches();
      _showSnackBar('"${event.title}" ora $newVisibility');
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  Future<void> _deleteEvent(AdminEventRecord event) async {
    if (!await _confirmDelete(event.title)) return;
    final repository = ref.read(adminRepositoryProvider);
    if (repository == null) return;
    try {
      await repository.deleteEvent(event);
      ref.invalidate(adminAllEventsProvider);
      ref.invalidate(adminDashboardProvider);
      _invalidatePublicCaches();
      _showSnackBar('"${event.title}" eliminato');
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  // ── Track categories ──────────────────────────────────────────────────────

  Future<void> _addTrackCategory() async {
    final repository = ref.read(adminRepositoryProvider);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final value = _trackLabelController.text.trim();
    if (repository == null || value.isEmpty) return;
    try {
      await repository.createTrackCategory(value);
      _trackLabelController.clear();
      ref.invalidate(adminTrackCategoriesProvider);
      ref.invalidate(trackCategoryOptionsProvider);
      // La dashboard legge i conteggi dalla RPC: senza invalidarla il numero
      // delle categorie resterebbe fermo (difetto A-18).
      ref.invalidate(adminDashboardProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminCategorySaved)));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminCategorySaveError(error.toString()))),
      );
    }
  }

  Future<void> _deleteTrackCategory(String categoryId) async {
    final repository = ref.read(adminRepositoryProvider);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (repository == null || categoryId.isEmpty) return;
    try {
      await repository.deleteTrackCategory(categoryId);
      ref.invalidate(adminTrackCategoriesProvider);
      ref.invalidate(trackCategoryOptionsProvider);
      ref.invalidate(adminDashboardProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminCategoryDeleted)));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.adminCategoryDeleteError(error.toString())),
        ),
      );
    }
  }
}

// ─── Panel: Users (paginato + search + impersonazione) ───────────────────────

class _AdminUsersPanel extends ConsumerStatefulWidget {
  const _AdminUsersPanel({
    required this.onChangeRole,
    required this.onRename,
  });

  final Future<void> Function(AdminFullUserRecord) onChangeRole;
  final Future<void> Function(AdminFullUserRecord) onRename;

  @override
  ConsumerState<_AdminUsersPanel> createState() => _AdminUsersPanelState();
}

class _AdminUsersPanelState extends ConsumerState<_AdminUsersPanel> {
  final TextEditingController _searchController = TextEditingController();

  static const _roles = <String?>[null, 'user', 'track_organizer', 'shop_owner', 'admin'];
  static const _roleLabels = <String>['Tutti', 'Pilota', 'Organizzatore', 'Gestore negozio', 'Admin'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final controller = ref.read(adminUsersProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search ────────────────────────────────────────────────────────
        TextField(
          controller: _searchController,
          onChanged: controller.setQuery,
          decoration: InputDecoration(
            hintText: 'Cerca per nome...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Cancella',
                    onPressed: () {
                      _searchController.clear();
                      controller.setQuery('');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // ── Role filter chips ─────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_roles.length, (i) {
              final role = _roles[i];
              final isSelected = state.roleFilter == role;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_roleLabels[i]),
                  selected: isSelected,
                  onSelected: (_) => controller.setRoleFilter(role),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // ── Count ─────────────────────────────────────────────────────────
        if (!state.isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              // ponytail: accordo singolare/plurale inline. La schermata admin non
              // e' localizzata (stringhe italiane hardcoded), quindi niente ICU.
              '${state.countLabel} ${state.countLabel == '1' ? 'profilo' : 'profili'}'
              '${state.roleFilter != null ? ' (${state.roleFilter})' : ''}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.steel,
              ),
            ),
          ),

        // ── List ──────────────────────────────────────────────────────────
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null)
          Text(
            'Errore: ${state.error}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade700,
            ),
          )
        else if (state.users.isEmpty)
          Text(
            'Nessun utente trovato.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.users.length,
            itemBuilder: (context, index) {
              final user = state.users[index];
              return _UserRow(
                user: user,
                onChangeRole: () => widget.onChangeRole(user),
                onRename: () => widget.onRename(user),
                onImpersonate: () {
                  ref.read(impersonationProvider.notifier).impersonateUser(
                    userId: user.id,
                    displayName: user.displayName,
                    role: user.role,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vista come ${user.displayName.isNotEmpty ? user.displayName : user.id.substring(0, 8)} (${user.role}) · Solo UI, JWT e RLS invariati',
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              );
            },
          ),

        // ── Load more ─────────────────────────────────────────────────────
        if (state.hasMore) ...[
          const SizedBox(height: 12),
          Center(
            child: state.isLoadingMore
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : OutlinedButton.icon(
                    onPressed: () => ref.read(adminUsersProvider.notifier).loadMore(),
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: const Text('Carica altri 30'),
                  ),
          ),
        ],
      ],
    );
  }
}


class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onChangeRole,
    required this.onRename,
    this.onImpersonate,
  });

  final AdminFullUserRecord user;
  final VoidCallback onChangeRole;
  final VoidCallback onRename;
  final VoidCallback? onImpersonate;

  Color _roleColor(String role) {
    return switch (role) {
      'admin' => Colors.red.shade600,
      'track_organizer' => AppColors.signalOrange,
      'shop_owner' => Colors.teal,
      _ => AppColors.steel,
    };
  }

  /// createdAt arriva come stringa ISO da Supabase.
  static String _signupLabel(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return ' · iscritto il ${two(date.day)}/${two(date.month)}/${date.year}';
  }

  String _initials(String name, String id) {
    if (name.isNotEmpty) return name.substring(0, 1).toUpperCase();
    return id.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final label = user.displayName.isEmpty ? '(senza nome)' : user.displayName;
    final shortId = user.id.length >= 8 ? user.id.substring(0, 8) : user.id;
    final roleColor = _roleColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.concrete),
      ),
      child: Row(
        children: [
          // Avatar con colore ruolo
          CircleAvatar(
            radius: 16,
            backgroundColor: roleColor.withAlpha(28),
            child: Text(
              _initials(user.displayName, user.id),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: roleColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nome + ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'ID $shortId… · ${user.preferredLanguage.toUpperCase()}'
                  '${_signupLabel(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Badge ruolo (tap → cambia ruolo)
          GestureDetector(
            onTap: onChangeRole,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withAlpha(18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: roleColor.withAlpha(80)),
              ),
              child: Text(
                adminRoleLabel(user.role),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: roleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Osserva (impersona utente)
          if (onImpersonate != null)
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 17),
              tooltip:
                  'Osserva come questo utente\n⚠️ Solo UI — non modifica JWT né policy RLS',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: onImpersonate,
            ),
          // Rinomina
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 17),
            tooltip: 'Rinomina',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: onRename,
          ),
        ],
      ),
    );
  }
}

// ─── Section: All Tracks ──────────────────────────────────────────────────────

class _AdminTracksSection extends StatelessWidget {
  const _AdminTracksSection({
    required this.tracksAsync,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final AsyncValue<List<AdminTrackRecord>> tracksAsync;
  final void Function(AdminTrackRecord) onApprove;
  final void Function(AdminTrackRecord) onReject;
  final void Function(AdminTrackRecord) onDelete;

  @override
  Widget build(BuildContext context) {
    return tracksAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return Text(
            'Nessuna pista trovata.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tracks.length} ${tracks.length == 1 ? 'pista' : 'piste'} nel database',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...tracks.map(
              (t) => _EntityRow(
                name: t.name,
                subtitle: t.city,
                approvalStatus: t.approvalStatus,
                isPublic: t.isPublic,
                detailRoute: '/track/${t.slug}',
                editRoute: '/manager/tracks/${t.slug}/edit',
                onApprove: t.approvalStatus != 'approved'
                    ? () => onApprove(t)
                    : null,
                onReject: t.approvalStatus != 'rejected'
                    ? () => onReject(t)
                    : null,
                onDelete: () => onDelete(t),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      ),
      error: (_, _) => Text(
        'Impossibile caricare le piste.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.steel,
        ),
      ),
    );
  }
}

// ─── Section: All Shops ───────────────────────────────────────────────────────

class _AdminShopsSection extends StatelessWidget {
  const _AdminShopsSection({
    required this.shopsAsync,
    required this.onApprove,
    required this.onReject,
    required this.onTogglePublic,
    required this.onDelete,
  });

  final AsyncValue<List<AdminShopRecord>> shopsAsync;
  final void Function(AdminShopRecord) onApprove;
  final void Function(AdminShopRecord) onReject;
  final void Function(AdminShopRecord) onTogglePublic;
  final void Function(AdminShopRecord) onDelete;

  @override
  Widget build(BuildContext context) {
    return shopsAsync.when(
      data: (shops) {
        if (shops.isEmpty) {
          return Text(
            'Nessun negozio trovato.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${shops.length} ${shops.length == 1 ? 'negozio' : 'negozi'} nel database',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...shops.map(
              (s) => _EntityRow(
                name: s.name,
                subtitle: s.city,
                approvalStatus: s.approvalStatus,
                isPublic: s.isPublic,
                showPublicStatus: true,
                detailRoute: '/shop/${s.slug}',
                editRoute: '/shop/${s.slug}/edit',
                onApprove: s.approvalStatus != 'approved'
                    ? () => onApprove(s)
                    : null,
                onReject: s.approvalStatus != 'rejected'
                    ? () => onReject(s)
                    : null,
                onTogglePublic: s.approvalStatus == 'approved'
                    ? () => onTogglePublic(s)
                    : null,
                onDelete: () => onDelete(s),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      ),
      error: (_, _) => Text(
        'Impossibile caricare i negozi.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.steel,
        ),
      ),
    );
  }
}

// ─── Section: All Events ──────────────────────────────────────────────────────

class _AdminEventsSection extends StatelessWidget {
  const _AdminEventsSection({
    required this.eventsAsync,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  final AsyncValue<List<AdminEventRecord>> eventsAsync;
  final void Function(AdminEventRecord) onToggleVisibility;
  final void Function(AdminEventRecord) onDelete;

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Text(
            'Nessun evento nel database.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${events.length} ${events.length == 1 ? 'evento' : 'eventi'} nel database',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...events.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7F3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.concrete),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(e.startAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.steel),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.source == 'community_events'
                                ? 'Evento community'
                                : 'Evento ufficiale',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.steel),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: adminVisibilityLabel(e.visibility),
                      color: e.visibility == 'public'
                          ? Colors.green.shade600
                          : AppColors.steel,
                    ),
                    if (e.supportsVisibilityToggle) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          e.visibility == 'public'
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        tooltip: e.visibility == 'public'
                            ? 'Rendi privato'
                            : 'Rendi pubblico',
                        onPressed: () => onToggleVisibility(e),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      tooltip: 'Elimina',
                      onPressed: () => onDelete(e),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      ),
      error: (_, _) => Text(
        'Impossibile caricare gli eventi.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.steel,
        ),
      ),
    );
  }
}

// ─── Shared entity row (tracks + shops) ──────────────────────────────────────

class _AdminFeedbackSection extends StatelessWidget {
  const _AdminFeedbackSection({
    required this.feedbackAsync,
    required this.onHandled,
    required this.onReply,
  });

  final AsyncValue<List<AdminFeedbackRecord>> feedbackAsync;
  final ValueChanged<AdminFeedbackRecord> onHandled;
  final ValueChanged<AdminFeedbackRecord> onReply;

  static String _fmt(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return feedbackAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Errore nel caricamento feedback: $e'),
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'Nessun feedback da leggere.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.steel),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.message,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: AppColors.graphite),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_fmt(f.createdAt)} · ${f.contactEmail ?? (f.userId != null ? 'utente' : 'guest')}'
                        '${(f.page != null && f.page!.isNotEmpty) ? ' · ${f.page}' : ''}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.steel),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          if ((f.contactEmail ?? '').trim().isNotEmpty)
                            TextButton.icon(
                              onPressed: () => onReply(f),
                              icon: const Icon(Icons.reply_outlined, size: 18),
                              label: const Text('Rispondi'),
                            ),
                          TextButton.icon(
                            onPressed: () => onHandled(f),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Segna come letto'),
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
    );
  }
}

/// Commenti segnalati: nasconderli o respingere la segnalazione.
class _AdminTrackClaimsSection extends StatelessWidget {
  const _AdminTrackClaimsSection({
    required this.claims,
    required this.onApprove,
    required this.onReject,
  });

  final List<AdminTrackClaim> claims;
  final ValueChanged<AdminTrackClaim> onApprove;
  final ValueChanged<AdminTrackClaim> onReject;

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty) {
      return Text(
        'Nessuna rivendicazione in attesa.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.steel),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final claim in claims)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${claim.userName} → ${claim.trackName}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (claim.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(claim.message),
                ],
                if (claim.contact.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Contatto: ${claim.contact}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.steel),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => onReject(claim),
                      child: const Text('Rifiuta'),
                    ),
                    FilledButton.icon(
                      onPressed: () => onApprove(claim),
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Approva: diventa gestore'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AdminReportedCommentsSection extends StatelessWidget {
  const _AdminReportedCommentsSection({
    required this.itemsAsync,
    required this.onHide,
    required this.onDismiss,
  });

  final AsyncValue<List<AdminReportedComment>> itemsAsync;
  final ValueChanged<AdminReportedComment> onHide;
  final ValueChanged<AdminReportedComment> onDismiss;

  @override
  Widget build(BuildContext context) {
    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Errore nel caricamento segnalazioni: $e'),
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'Nessuna segnalazione da gestire.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.steel),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF6EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3D5AE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.body,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.graphite),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.author} · ${item.reportedCount} '
                      '${item.reportedCount == 1 ? 'segnalazione' : 'segnalazioni'}'
                      '${item.reasons.isEmpty ? '' : ' · ${item.reasons.join(', ')}'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.steel),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => onDismiss(item),
                          child: const Text('Respingi segnalazione'),
                        ),
                        FilledButton.icon(
                          onPressed: () => onHide(item),
                          icon: const Icon(Icons.visibility_off_outlined, size: 18),
                          label: const Text('Nascondi commento'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EntityRow extends StatelessWidget {
  const _EntityRow({
    required this.name,
    required this.subtitle,
    required this.approvalStatus,
    required this.isPublic,
    required this.detailRoute,
    required this.editRoute,
    this.showPublicStatus = false,
    this.onApprove,
    this.onReject,
    this.onTogglePublic,
    required this.onDelete,
  });

  final String name;
  final String subtitle;
  final String approvalStatus;
  final bool isPublic;
  final String detailRoute;
  final String editRoute;
  final bool showPublicStatus;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTogglePublic;
  final VoidCallback onDelete;

  Color _approvalColor() {
    return switch (approvalStatus) {
      'approved' => Colors.green.shade600,
      'rejected' => Colors.red.shade600,
      'pending' => AppColors.signalOrange,
      _ => AppColors.steel,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.steel,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusPill(
                label: adminApprovalLabel(approvalStatus),
                color: _approvalColor(),
              ),
              if (showPublicStatus) ...[
                const SizedBox(width: 6),
                _StatusPill(
                  label: isPublic ? 'Pubblico' : 'Nascosto',
                  color: isPublic ? Colors.blue.shade600 : AppColors.steel,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                icon: Icons.open_in_new_outlined,
                label: 'Apri',
                onPressed: () => context.go(detailRoute),
              ),
              _ActionButton(
                icon: Icons.edit_outlined,
                label: 'Editor',
                onPressed: () => context.go(editRoute),
              ),
              if (onApprove != null)
                _ActionButton(
                  icon: Icons.check,
                  label: 'Approva',
                  color: Colors.green.shade600,
                  onPressed: onApprove!,
                ),
              if (onReject != null)
                _ActionButton(
                  icon: Icons.close,
                  label: 'Rifiuta',
                  color: Colors.red.shade600,
                  onPressed: onReject!,
                ),
              if (onTogglePublic != null)
                _ActionButton(
                  icon: isPublic
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  label: isPublic ? 'Nascondi' : 'Pubblica',
                  onPressed: onTogglePublic!,
                ),
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Elimina',
                color: Colors.red.shade700,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.graphite;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: effectiveColor),
      label: Text(label, style: TextStyle(color: effectiveColor, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        side: BorderSide(color: effectiveColor.withAlpha(80)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ─── Existing reused widgets ──────────────────────────────────────────────────

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.title,
    required this.body,
    required this.child,
  });

  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.steel,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ApprovalQueueCard extends StatelessWidget {
  const _ApprovalQueueCard({
    required this.items,
    required this.onApprove,
    required this.onReject,
  });

  final List<AdminApprovalRecord> items;
  final void Function(AdminApprovalRecord item) onApprove;
  final void Function(AdminApprovalRecord item) onReject;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.concrete),
        ),
        child: Text(
          'Nessun elemento in approvazione al momento.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.steel,
          ),
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7F3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.concrete),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.steel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusPill(
                          label: item.entityType,
                          color: AppColors.graphite,
                        ),
                        _StatusPill(
                          label: item.ownerLabel,
                          color: AppColors.steel,
                        ),
                        _StatusPill(
                          label: item.locationLabel,
                          color: AppColors.steel,
                        ),
                        _StatusPill(
                          label: item.submittedAtLabel,
                          color: AppColors.steel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.go(item.route),
                          icon: const Icon(Icons.open_in_new_outlined),
                          label: const Text('Apri'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed:
                              item.needsReview ? () => onApprove(item) : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Approva'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => onReject(item),
                          icon: const Icon(Icons.close),
                          label: const Text('Rifiuta'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TrackCategoriesSection extends StatelessWidget {
  const _TrackCategoriesSection({
    required this.title,
    required this.body,
    required this.controller,
    required this.addLabel,
    required this.actionLabel,
    required this.categoriesAsync,
    required this.onAdd,
    required this.onDelete,
  });

  final String title;
  final String body;
  final TextEditingController controller;
  final String addLabel;
  final String actionLabel;
  final AsyncValue<List<AdminTrackCategoryRecord>> categoriesAsync;
  final Future<void> Function() onAdd;
  final Future<void> Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo e descrizione li mette la card della sezione: qui si
        // ripetevano identici (scheda Impostazioni).
        if (title.isNotEmpty) ...[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: addLabel),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
        const SizedBox(height: 14),
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Text(
                l10n.adminTrackCategoriesEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.steel,
                ),
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories
                  .map((category) {
                    final label = languageCode == 'en'
                        ? category.labelEn
                        : category.labelIt;
                    return InputChip(
                      label: Text(label),
                      onDeleted: () => onDelete(category.id),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  })
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: CircularProgressIndicator(),
          ),
          error: (_, _) => Text(
            l10n.adminTrackCategoriesUnavailable,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableTagSection extends StatelessWidget {
  const _EditableTagSection({
    required this.title,
    required this.body,
    required this.controller,
    required this.items,
    required this.addLabel,
    required this.actionLabel,
    required this.onAdd,
  });

  final String title;
  final String body;
  final TextEditingController controller;
  final List<String> items;
  final String addLabel;
  final String actionLabel;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo e descrizione li mette la card della sezione: qui si
        // ripetevano identici (scheda Impostazioni).
        if (title.isNotEmpty) ...[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: addLabel),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.concrete),
                  ),
                  child: Text(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AdminDeletionRequestsSection extends StatelessWidget {
  const _AdminDeletionRequestsSection({
    required this.requestsAsync,
    required this.onHandled,
  });

  final ValueChanged<AdminDeletionRequest> onHandled;

  final AsyncValue<List<AdminDeletionRequest>> requestsAsync;

  @override
  Widget build(BuildContext context) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Text(
            'Nessuna richiesta in attesa.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.steel,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requests.length == 1
                  ? '1 richiesta in attesa'
                  : '${requests.length} richieste in attesa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...requests.map((request) {
              final overdue = request.isOverdue;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: overdue
                      ? Colors.red.shade50
                      : const Color(0xFFF8F7F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: overdue ? Colors.red.shade200 : AppColors.concrete,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      overdue
                          ? Icons.warning_amber_rounded
                          : Icons.schedule_outlined,
                      size: 18,
                      color: overdue ? Colors.red.shade700 : AppColors.steel,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            request.displayName,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            'ID ${request.userId.substring(0, 8)}… · '
                            'richiesta ${request.daysElapsed} '
                            '${request.daysElapsed == 1 ? "giorno" : "giorni"} fa',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.steel),
                          ),
                        ],
                      ),
                    ),
                    if (overdue)
                      Text(
                        'Scaduta',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => onHandled(request),
                      child: const Text('Segna gestita'),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Text(
        'Impossibile leggere le richieste: $error',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.red.shade700,
        ),
      ),
    );
  }
}

/// Schede della pagina admin. Il pallino arancione segnala che dentro c'è
/// qualcosa da guardare.
class _AdminTabBar extends StatelessWidget {
  const _AdminTabBar({
    required this.current,
    required this.badges,
    required this.onChanged,
  });

  static const labels = ['Panoramica', 'Contenuti', 'Persone', 'Impostazioni'];

  final int current;
  final List<int> badges;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < labels.length; index++)
          ChoiceChip(
            selected: current == index,
            onSelected: (_) => onChanged(index),
            selectedColor: AppColors.signalOrange.withAlpha(35),
            side: BorderSide(
              color: current == index
                  ? AppColors.signalOrange
                  : AppColors.borderSubtle,
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  labels[index],
                  style: TextStyle(
                    fontWeight:
                        current == index ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (badges[index] > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.signalOrange,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${badges[index]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Proposte di modifica agli spot: applicarle o rifiutarle.
class _AdminSpotSuggestionsSection extends StatelessWidget {
  const _AdminSpotSuggestionsSection({
    required this.itemsAsync,
    required this.onApprove,
    required this.onReject,
  });

  final AsyncValue<List<AdminSpotSuggestion>> itemsAsync;
  final ValueChanged<AdminSpotSuggestion> onApprove;
  final ValueChanged<AdminSpotSuggestion> onReject;

  @override
  Widget build(BuildContext context) {
    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Errore nel caricamento proposte: $e'),
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'Nessuna proposta in attesa.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.steel),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF6EC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3D5AE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.spotTitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.graphite),
                    ),
                    const SizedBox(height: 6),
                    // ponytail: riepilogo grezzo dei campi proposti. Un diff
                    // campo per campo si fa quando le proposte saranno tante.
                    Text(
                      item.summary,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.graphite),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Proposta da ${item.author}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.steel),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => onReject(item),
                          child: const Text('Rifiuta'),
                        ),
                        FilledButton.icon(
                          onPressed: () => onApprove(item),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Applica allo spot'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
