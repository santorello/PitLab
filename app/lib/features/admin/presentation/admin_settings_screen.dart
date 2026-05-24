import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../application/admin_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../shops/application/shop_editor_providers.dart';

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
    final overviewAsync = ref.watch(adminOverviewProvider);
    final trackCategoriesAsync = ref.watch(adminTrackCategoriesProvider);
    final approvalsAsync = ref.watch(adminApprovalQueueProvider);
    final approvals = approvalsAsync.asData?.value ?? const [];
    final allTracksAsync = ref.watch(adminAllTracksProvider);
    final allShopsAsync = ref.watch(adminAllShopsProvider);
    final allEventsAsync = ref.watch(adminAllEventsProvider);

    return ContentScaffold(
      title: l10n.adminTitle,
      description: l10n.adminDescription,
      child: ListView(
        children: [
          // ── Hero header ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6EFE3), Colors.white, Color(0xFFF2F4F7)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Color(0xFFE5DDD0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.signalOrange.withAlpha(22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.signalOrange.withAlpha(80)),
                  ),
                  child: const Text(
                    '⚙️ Pannello admin',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Admin operativo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.graphite,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isAdmin
                      ? 'Controllo completo su utenti, piste, negozi ed eventi.'
                      : l10n.adminAccessDeniedBody,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.steel,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _AdminChip(label: '📊 Dashboard'),
                    _AdminChip(label: '✅ Approvazioni'),
                    _AdminChip(label: '👥 Utenti'),
                    _AdminChip(label: '🏁 Piste'),
                    _AdminChip(label: '🏪 Negozi'),
                    _AdminChip(label: '📅 Eventi'),
                    if (approvals.isNotEmpty)
                      _AdminChip(label: '🔔 ${approvals.length} in coda'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (!isAdmin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.adminAccessDeniedCard,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.steel,
                  ),
                ),
              ),
            )
          else ...[

            // ── Dashboard ────────────────────────────────────────────────
            _AdminSectionCard(
              title: 'Dashboard',
              body: 'Snapshot operativo e accesso rapido alle aree chiave.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminOverviewCard(
                    title: l10n.adminOverviewTitle,
                    body: l10n.adminOverviewBody,
                    itemsAsync: overviewAsync,
                  ),
                  const SizedBox(height: 18),
                  if (approvals.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.signalOrange.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        'Inbox admin: ${approvals.length} richiesta${approvals.length == 1 ? '' : 'e'} da controllare.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.graphite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Approvazioni ──────────────────────────────────────────────
            _AdminSectionCard(
              title: 'Approvazioni',
              body: 'Coda di lavoro per spot, piste e negozi da validare.',
              child: _ApprovalQueueCard(
                items: approvals,
                onApprove: (item) => _resolveApproval(item, 'approved'),
                onReject: (item) => _resolveApproval(item, 'rejected'),
              ),
            ),
            const SizedBox(height: 18),

            // ── Utenti ────────────────────────────────────────────────────
            _AdminSectionCard(
              title: 'Utenti',
              body: 'Cerca, filtra per ruolo, modifica o osserva l\'app come un utente specifico.',
              child: _AdminUsersPanel(
                onChangeRole: _changeUserRole,
                onRename: _renameUser,
              ),
            ),
            const SizedBox(height: 18),

            // ── Piste ─────────────────────────────────────────────────────
            _AdminSectionCard(
              title: 'Piste',
              body: 'Lista completa: modifica stato approvazione, naviga all\'editor, elimina.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminTracksSection(
                    tracksAsync: allTracksAsync,
                    onApprove: (t) => _updateTrackApproval(t, 'approved'),
                    onReject: (t) => _updateTrackApproval(t, 'rejected'),
                    onDelete: (t) => _deleteTrack(t),
                  ),
                  const SizedBox(height: 24),
                  _TrackCategoriesSection(
                    title: 'Label categorie pista',
                    body: 'Le categorie alimentano card e filtri senza hardcode.',
                    controller: _trackLabelController,
                    addLabel: 'Nuova categoria',
                    actionLabel: 'Aggiungi',
                    categoriesAsync: trackCategoriesAsync,
                    onAdd: _addTrackCategory,
                    onDelete: _deleteTrackCategory,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Negozi ────────────────────────────────────────────────────
            _AdminSectionCard(
              title: 'Negozi',
              body: 'Lista completa: modifica stato approvazione, visibilità pubblica, elimina.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminShopsSection(
                    shopsAsync: allShopsAsync,
                    onApprove: (s) => _updateShopApproval(s, 'approved'),
                    onReject: (s) => _updateShopApproval(s, 'rejected'),
                    onTogglePublic: (s) => _toggleShopPublic(s),
                    onDelete: (s) => _deleteShop(s),
                  ),
                  const SizedBox(height: 24),
                  _EditableTagSection(
                    title: 'Label servizi negozio',
                    body: 'Tag usati in card e dettaglio negozio.',
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
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Eventi ────────────────────────────────────────────────────
            _AdminSectionCard(
              title: 'Eventi',
              body: 'Lista degli eventi pubblici. Modifica visibilità o elimina.',
              child: _AdminEventsSection(
                eventsAsync: allEventsAsync,
                onToggleVisibility: _toggleEventVisibility,
                onDelete: (e) => _deleteEvent(e),
              ),
            ),
            const SizedBox(height: 18),

            // ── Spot & Garage ─────────────────────────────────────────────
            _AdminSectionCard(
              title: 'Spot & Garage',
              body: 'Stato attuale del backend per spot e garage.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoBanner(
                    icon: Icons.place_outlined,
                    title: 'Spot — su Supabase',
                    body:
                        'Gli spot sono salvati nella tabella `spots` su Supabase con RLS. I 3 spot di default sono seedati. Gli utenti autenticati possono aggiungere spot custom (is_custom=true, owner_id). La discovery guest legge la view `public_spots`, che mantiene il contenuto pubblico ma non espone `owner_id` al client.',
                  ),
                  const SizedBox(height: 14),
                  _InfoBanner(
                    icon: Icons.directions_car_outlined,
                    title: 'Garage / Build — su Supabase',
                    body:
                        'Le build del garage sono salvate su Supabase nella tabella `user_builds`. La migrazione dal locale al remoto è completata.',
                  ),
                  const SizedBox(height: 14),
                  _InfoBanner(
                    icon: Icons.event_outlined,
                    title: 'Community Events — su Supabase',
                    body:
                        'Gli eventi creati dagli utenti sono salvati nella tabella `community_events`. Ottimismo UI attivo: l\'evento appare subito e l\'UUID server sostituisce l\'ID temporaneo in background.',
                  ),
                  const SizedBox(height: 14),
                  _InfoBanner(
                    icon: Icons.link_outlined,
                    title: 'Link esterni — su Supabase',
                    body:
                        'I link esterni (Instagram, sito, YouTube, ecc.) di piste, negozi e profili sono salvati nella tabella `external_links`. Sincronizzazione ottimistica attiva con fallback a SharedPreferences.',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
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
        ref.invalidate(adminOverviewProvider);
        ref.invalidate(adminAllTracksProvider);
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
        ref.invalidate(adminOverviewProvider);
        ref.invalidate(adminAllShopsProvider);
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
                    title: Text(r),
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
      _showSnackBar('Ruolo aggiornato: $selected');
    } catch (e) {
      _showSnackBar('Errore: $e');
    }
  }

  Future<void> _renameUser(AdminFullUserRecord user) async {
    final controller = TextEditingController(text: user.displayName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    );
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
  static const _roleLabels = <String>['Tutti', 'user', 'track_org', 'shop_owner', 'admin'];

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
              '${state.countLabel} profili${state.roleFilter != null ? ' (${state.roleFilter})' : ''}',
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
                  'ID $shortId… · ${user.preferredLanguage.toUpperCase()}',
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
                user.role,
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
              '${tracks.length} piste nel database',
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
              '${shops.length} negozi nel database',
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
              '${events.length} eventi nel database',
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
                                ? 'Community event'
                                : 'Evento ufficiale',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.steel),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: e.visibility,
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
                label: approvalStatus,
                color: _approvalColor(),
              ),
              if (showPublicStatus) ...[
                const SizedBox(width: 6),
                _StatusPill(
                  label: isPublic ? 'pub' : 'hid',
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.concrete),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.steel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.steel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Existing reused widgets ──────────────────────────────────────────────────

class _AdminOverviewCard extends StatelessWidget {
  const _AdminOverviewCard({
    required this.title,
    required this.body,
    this.itemsAsync,
  });

  final String title;
  final String body;
  final AsyncValue<AdminOverviewRecord?>? itemsAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            if (itemsAsync != null)
              itemsAsync!.when(
                data: (overview) {
                  if (overview == null) return const SizedBox.shrink();
                  return _OverviewWrap(
                    items: [
                      _OverviewItem(
                        label: AppLocalizations.of(context)!.adminUsersMetric,
                        value: overview.usersCount.toString(),
                      ),
                      _OverviewItem(
                        label: AppLocalizations.of(context)!.adminTracksMetric,
                        value: overview.tracksCount.toString(),
                      ),
                      _OverviewItem(
                        label: 'Negozi',
                        value: overview.shopsCount.toString(),
                      ),
                      _OverviewItem(
                        label: AppLocalizations.of(context)!.adminEventsMetric,
                        value: overview.eventsCount.toString(),
                      ),
                      _OverviewItem(
                        label: AppLocalizations.of(context)!
                            .adminCategoriesMetric,
                        value: overview.trackCategoriesCount.toString(),
                      ),
                      _OverviewItem(
                        label: 'Da approvare',
                        value: overview.pendingApprovalsCount.toString(),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
                error: (_, _) => Text(
                  AppLocalizations.of(context)!.adminOverviewFallback,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.steel,
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(24),
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
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 12),
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
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 12),
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

class _AdminChip extends StatelessWidget {
  const _AdminChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.signalOrange.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.signalOrange.withAlpha(60)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.graphite,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


class _OverviewWrap extends StatelessWidget {
  const _OverviewWrap({required this.items});

  final List<_OverviewItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items
          .map(
            (item) => Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7F3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.concrete),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OverviewItem {
  const _OverviewItem({required this.label, required this.value});

  final String label;
  final String value;
}
