import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/media/media_upload_controller.dart';
import '../../../shared/media/media_upload_labels.dart';
import '../../../shared/media/media_upload_service.dart';
import '../../../shared/media/media_upload_state.dart';
import '../../../shared/models/submitted_track.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/image_transfer_progress_card.dart';
import '../../auth/application/auth_providers.dart';
import '../application/track_taxonomy_option.dart';
import '../application/tracks_providers.dart';

class TrackEditorScreen extends ConsumerStatefulWidget {
  const TrackEditorScreen({super.key, this.initialDraft});

  /// Se non null, lo schermo è in modalità edit per una bozza/rifiutata esistente.
  final SubmittedTrack? initialDraft;

  @override
  ConsumerState<TrackEditorScreen> createState() => _TrackEditorScreenState();
}

class _TrackEditorScreenState extends ConsumerState<TrackEditorScreen> {

  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _organizationController;
  late final TextEditingController _coverImageUrlController;
  bool _uploadingCover = false;
  MediaUploadBatchState? _coverTransferState;
  /// Preview locale (data-URL da picker). Non viene inviato a Supabase.
  String _coverImagePreview = '';
  bool _isSaving = false;
  /// Bozza già persistita su Supabase in questa sessione di editing.
  /// Inizializzata da [widget.initialDraft] e aggiornata dopo il primo
  /// "Salva bozza" così che i salvataggi/invii successivi facciano UPDATE
  /// invece di un nuovo INSERT (evita duplicate slug — D06).
  SubmittedTrack? _persistedDraft;
  /// Chiavi DB delle categorie selezionate (da track_categories.key).
  final Set<String> _selectedCategoryKeys = <String>{};
  /// Chiavi DB dei servizi selezionati (da service_types.key).
  final Set<String> _selectedServiceKeys = <String>{};

  String get _resolvedCoverImage =>
      _coverImageUrlController.text.trim().isNotEmpty
          ? _coverImageUrlController.text.trim()
          : _coverImagePreview;

  int get _requiredChecklistCompleted {
    var done = 0;
    if (_nameController.text.trim().isNotEmpty) done++;
    if (_cityController.text.trim().isNotEmpty) done++;
    if (_shortDescriptionController.text.trim().isNotEmpty) done++;
    if (_resolvedCoverImage.isNotEmpty) done++;
    if (_selectedServiceKeys.isNotEmpty) done++;
    return done;
  }

  bool get _canSubmitForApproval => _requiredChecklistCompleted >= 5;

  double get _readinessProgress => _requiredChecklistCompleted / 5;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDraft;
    _persistedDraft = widget.initialDraft;
    _nameController = TextEditingController(text: d?.name ?? '');
    _slugController = TextEditingController(text: d?.slug ?? '');
    _cityController = TextEditingController(text: d?.city ?? '');
    _addressController = TextEditingController(text: d?.address ?? '');
    _shortDescriptionController = TextEditingController(text: d?.shortDescription ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _contactEmailController = TextEditingController(text: d?.contactEmail ?? '');
    _phoneController = TextEditingController(text: d?.phone ?? '');
    _websiteController = TextEditingController(text: d?.website ?? '');
    _organizationController = TextEditingController(text: d?.organizationName ?? '');
    _coverImageUrlController = TextEditingController(text: d?.imageUrl ?? '');
    for (final controller in [
      _nameController,
      _slugController,
      _cityController,
      _addressController,
      _shortDescriptionController,
      _descriptionController,
      _contactEmailController,
      _phoneController,
      _websiteController,
      _organizationController,
      _coverImageUrlController,
    ]) {
      controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
    // Se si sta editando una bozza esistente, carica le chiavi tassonomia dal DB.
    final draftId = d?.id;
    if (draftId != null && draftId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDraftTaxonomy(draftId);
      });
    }
  }

  /// Carica i servizi e le categorie già associati alla bozza/pista in editing.
  /// Necessario per pre-selezionare i chip quando si apre il form in modalità edit.
  Future<void> _loadDraftTaxonomy(String trackId) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      return;
    }
    try {
      // Legge i servizi attivi per questa pista
      final servicesResp = await client
          .from('track_services')
          .select('is_available, service_types(key)')
          .eq('track_id', trackId);

      final serviceKeys = (servicesResp as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .where((row) => row['is_available'] == true)
          .map((row) {
            final st = row['service_types'];
            if (st is Map<String, dynamic>) return st['key'] as String?;
            return null;
          })
          .whereType<String>()
          .toSet();

      // Legge le categorie per questa pista
      final categoriesResp = await client
          .from('track_category_links')
          .select('track_categories(key)')
          .eq('track_id', trackId);

      final categoryKeys = (categoriesResp as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final tc = row['track_categories'];
            if (tc is Map<String, dynamic>) return tc['key'] as String?;
            return null;
          })
          .whereType<String>()
          .toSet();

      if (mounted) {
        setState(() {
          _selectedServiceKeys
            ..clear()
            ..addAll(serviceKeys);
          _selectedCategoryKeys
            ..clear()
            ..addAll(categoryKeys);
        });
      }
    } catch (_) {
      // Fallback silenzioso: l'utente può ri-selezionare manualmente.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _organizationController.dispose();
    _coverImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    // effectiveUserIdProvider: in impersonazione l'attribution della bozza pista
    // (campo `submitted_by`) deve seguire l'utente osservato, non l'admin reale.
    // Senza questo, una bozza creata via impersonazione resta invisibile in /manager
    // dell'utente impersonato perche' submittedTracksProvider filtra per submitted_by.
    final attributionUserId = ref.watch(effectiveUserIdProvider) ?? currentUser?.id;

    return ContentScaffold(
      title: _isEditMode ? 'Modifica bozza pista' : 'Crea pista',
      description:
          'Editor completo per scheda pista, servizi, card pubblica e invio in approvazione.',
      child: ListView(
        children: [
          Card(
            color: AppColors.graphite,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheda pista completa',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Qui costruiamo davvero la tua pista: identità, posizione, servizi, contatti e preview della card.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.concrete,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      const _DarkHeroChip(label: 'Card pubblica'),
                      const _DarkHeroChip(label: 'Categorie e servizi'),
                      const _DarkHeroChip(label: 'Invio approvazione'),
                      _DarkHeroChip(
                        label:
                            'Prontezza ${(_readinessProgress * 100).round()}%',
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checklist invio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _readinessProgress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: const Color(0xFFE9EDF2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Completati $_requiredChecklistCompleted/5 requisiti minimi per inviare in approvazione.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 960;
              final categoryOptions = ref.watch(trackCategoryOptionsProvider).maybeWhen(
                data: (options) => options,
                orElse: () => const <TrackTaxonomyOption>[],
              );
              final serviceOptions = ref.watch(trackServiceOptionsProvider).maybeWhen(
                data: (options) => options,
                orElse: () => const <TrackTaxonomyOption>[],
              );

              final editor = _EditorSections(
                nameController: _nameController,
                slugController: _slugController,
                cityController: _cityController,
                addressController: _addressController,
                shortDescriptionController: _shortDescriptionController,
                descriptionController: _descriptionController,
                contactEmailController: _contactEmailController,
                phoneController: _phoneController,
                websiteController: _websiteController,
                organizationController: _organizationController,
                coverImageUrlController: _coverImageUrlController,
                coverImagePreview: _coverImagePreview,
                uploadingCover: _uploadingCover,
                coverStageLabel: _coverTransferState?.stageLabel,
                selectedServiceKeys: _selectedServiceKeys,
                selectedCategoryKeys: _selectedCategoryKeys,
                serviceOptions: serviceOptions,
                categoryOptions: categoryOptions,
                onPickCover: _pickCoverImage,
                coverProgress: _coverTransferState?.progress ?? 0,
                coverCompletedCount: _coverTransferState?.completedCount ?? 0,
                coverTotalCount: _coverTransferState?.totalCount ?? 0,
                onToggleService: (key) => _toggleItem(_selectedServiceKeys, key),
                onToggleCategory: (key) => _toggleItem(_selectedCategoryKeys, key),
              );

              // Etichette leggibili per la preview card
              final selectedServiceLabels = serviceOptions
                  .where((o) => _selectedServiceKeys.contains(o.key))
                  .map((o) => o.label)
                  .toList();
              final selectedCategoryLabels = categoryOptions
                  .where((o) => _selectedCategoryKeys.contains(o.key))
                  .map((o) => o.label)
                  .toList();

              final preview = Column(
                children: [
                  _TrackPreviewCard(
                    name: _nameController.text.trim(),
                    city: _cityController.text.trim(),
                    shortDescription: _shortDescriptionController.text.trim(),
                    coverImage: _resolvedCoverImage,
                    services: selectedServiceLabels,
                    categories: selectedCategoryLabels,
                  ),
                  const SizedBox(height: 18),
                  _ReadinessCard(
                    nameReady: _nameController.text.trim().isNotEmpty,
                    cityReady: _cityController.text.trim().isNotEmpty,
                    descriptionReady:
                        _shortDescriptionController.text.trim().isNotEmpty,
                    coverReady: _resolvedCoverImage.isNotEmpty,
                    servicesReady: _selectedServiceKeys.isNotEmpty,
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  children: [
                    editor,
                    const SizedBox(height: 18),
                    preview,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: editor),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: preview),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Azioni',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Salva in bozza quando stai lavorando. Invia in approvazione quando la scheda è pronta per la revisione admin.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: attributionUserId == null || _isSaving
                            ? null
                            : () => _saveDraft(attributionUserId),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Salva bozza'),
                      ),
                      OutlinedButton.icon(
                        onPressed: attributionUserId == null || !_canSubmitForApproval || _isSaving
                            ? null
                            : () => _submitForApproval(attributionUserId),
                        icon: const Icon(Icons.rule_outlined),
                        label: const Text('Invia in approvazione'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final uploadService = ref.read(mediaUploadServiceProvider);
    final userId = ref.read(effectiveUserIdProvider) ??
        ref.read(currentUserProvider)?.id;

    if (uploadService == null || userId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Devi essere autenticato per caricare immagini.'),
        ),
      );
      return;
    }

    final uploadController = MediaUploadController(
      totalItems: 1,
      initialStageLabel: 'Sto preparando la cover pista',
    );
    setState(() {
      _uploadingCover = true;
      _coverTransferState = uploadController.snapshot;
    });

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (!mounted) return;
    if (bytes == null) {
      setState(() {
        _uploadingCover = false;
        _coverTransferState = null;
      });
      return;
    }

    try {
      final result = await uploadService.uploadImage(
        bytes: bytes,
        userId: userId,
        entityType: 'tracks',
        filePrefix: 'cover',
        onProgress: (stage, progress) {
          if (!mounted) return;
          uploadController.setStageLabel(mediaUploadStageLabel(context, stage));
          uploadController.updateItem(index: 0, stage: stage, progress: progress);
          setState(() {
            _coverTransferState = uploadController.snapshot;
          });
        },
      );
      if (!mounted) return;
      uploadController.markDone(0);
      setState(() {
        _uploadingCover = false;
        _coverImagePreview = '';
        _coverImageUrlController.text = result.publicUrl;
        _coverTransferState = null;
      });
    } on MediaUploadException catch (e) {
      if (!mounted) return;
      uploadController.markError(0);
      setState(() {
        _uploadingCover = false;
        _coverTransferState = uploadController.snapshot;
      });
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      uploadController.markError(0);
      setState(() {
        _uploadingCover = false;
        _coverTransferState = uploadController.snapshot;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Errore caricamento cover pista: $e')),
      );
    }
  }

  void _toggleItem(Set<String> target, String value) {
    setState(() {
      if (!target.add(value)) {
        target.remove(value);
      }
    });
  }

  bool get _isEditMode =>
      (_persistedDraft?.id.isNotEmpty ?? false) || widget.initialDraft != null;

  Future<void> _saveDraft(String userId) async {
    final repository = ref.read(tracksRepositoryProvider);
    if (repository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connessione al server non disponibile.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final track = _buildSubmittedTrack(approvalStatus: 'draft');
      if (_isEditMode) {
        final saved = await repository.updateSubmittedTrack(track: track);
        _persistedDraft = saved;
      } else {
        final inserted =
            await repository.insertSubmittedTrack(submittedBy: userId, track: track);
        // Memorizza l'id assegnato così i salvataggi successivi fanno UPDATE.
        _persistedDraft = inserted;
      }
      // Persisti servizi e categorie ora che il track_id è disponibile.
      await _persistTaxonomy(_persistedDraft!.id);
      ref.invalidate(submittedTracksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bozza pista salvata in Gestione.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitForApproval(String userId) async {
    if (!_canSubmitForApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa nome, città, descrizione breve, cover e almeno un servizio prima di inviare.',
          ),
        ),
      );
      return;
    }
    final repository = ref.read(tracksRepositoryProvider);
    if (repository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connessione al server non disponibile.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final track = _buildSubmittedTrack(approvalStatus: 'pending');
      if (_isEditMode) {
        final saved = await repository.updateSubmittedTrack(track: track);
        _persistedDraft = saved;
      } else {
        final inserted =
            await repository.insertSubmittedTrack(submittedBy: userId, track: track);
        _persistedDraft = inserted;
      }
      // Persisti servizi e categorie prima di invalidare il provider.
      await _persistTaxonomy(_persistedDraft!.id);
      ref.invalidate(submittedTracksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pista inviata alla coda approvazioni admin.')),
        );
        context.go('/manager');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nell\'invio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Persiste servizi e categorie su Supabase per la pista con il dato [trackId].
  /// Richiede che la policy RLS `submitter can manage own draft track services` /
  /// `submitter can manage own draft track category links` (delta
  /// 2026-06-10-draft-taxonomy-policies.sql) sia applicata sul DB.
  /// In assenza di client Supabase, non fa nulla silenziosamente.
  Future<void> _persistTaxonomy(String trackId) async {
    if (trackId.isEmpty) return;
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;

    // ── Servizi ──────────────────────────────────────────────────────────────
    // Legge tutti i service_type id/key dal DB (già in cache se il provider
    // è stato caricato, altrimenti fa una query leggera).
    try {
      final serviceTypes = await client.from('service_types').select('id, key');
      final selectedKeys = _selectedServiceKeys;
      final serviceUpserts = <Map<String, dynamic>>[];

      for (final row in (serviceTypes as List<dynamic>).whereType<Map<String, dynamic>>()) {
        final serviceId = row['id'] as String?;
        final serviceKey = row['key'] as String?;
        if (serviceId == null || serviceKey == null) continue;
        serviceUpserts.add({
          'track_id': trackId,
          'service_type_id': serviceId,
          'is_available': selectedKeys.contains(serviceKey),
        });
      }

      if (serviceUpserts.isNotEmpty) {
        await client.from('track_services').upsert(
          serviceUpserts,
          onConflict: 'track_id,service_type_id',
        );
      }
    } catch (_) {
      // Fallback silenzioso: la policy RLS potrebbe non essere ancora applicata.
      // L'utente potrà riselezionare i servizi da "Modifica pista" dopo l'approvazione.
    }

    // ── Categorie ─────────────────────────────────────────────────────────────
    try {
      if (_selectedCategoryKeys.isNotEmpty) {
        final categoryRows = await client
            .from('track_categories')
            .select('id, key')
            .inFilter('key', _selectedCategoryKeys.toList());

        final selectedCategoryIds = (categoryRows as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((row) => row['id'] as String?)
            .whereType<String>()
            .toList();

        await client.from('track_category_links').delete().eq('track_id', trackId);

        if (selectedCategoryIds.isNotEmpty) {
          await client.from('track_category_links').insert(
            selectedCategoryIds
                .map((catId) => {'track_id': trackId, 'category_id': catId})
                .toList(),
          );
        }
      } else {
        // Nessuna categoria selezionata: rimuove i link esistenti.
        await client.from('track_category_links').delete().eq('track_id', trackId);
      }
    } catch (_) {
      // Fallback silenzioso: come per i servizi, la policy RLS potrebbe
      // non essere ancora applicata.
    }
  }

  SubmittedTrack _buildSubmittedTrack({required String approvalStatus}) {
    final slug = _slugController.text.trim().isEmpty
        ? _slugify(_nameController.text)
        : _slugify(_slugController.text);
    // data-URL da picker non viene inviato a Supabase: solo URL http/https
    final coverUrl = _coverImageUrlController.text.trim().isNotEmpty
        ? _coverImageUrlController.text.trim()
        : null;
    return SubmittedTrack(
      id: _persistedDraft?.id ?? widget.initialDraft?.id ?? '',
      slug: slug,
      name: _nameController.text.trim().isEmpty
          ? 'Nuova pista'
          : _nameController.text.trim(),
      city: _cityController.text.trim(),
      shortDescription: _shortDescriptionController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      contactEmail: _contactEmailController.text.trim(),
      phone: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
      organizationName: _organizationController.text.trim(),
      approvalStatus: approvalStatus,
      imageUrl: coverUrl,
    );
  }

  String _slugify(String input) {
    final source = input.trim().isEmpty ? 'nuova-pista' : input.trim();
    return source
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

class _EditorSections extends StatelessWidget {
  const _EditorSections({
    required this.nameController,
    required this.slugController,
    required this.cityController,
    required this.addressController,
    required this.shortDescriptionController,
    required this.descriptionController,
    required this.contactEmailController,
    required this.phoneController,
    required this.websiteController,
    required this.organizationController,
    required this.coverImageUrlController,
    required this.coverImagePreview,
    required this.uploadingCover,
    required this.coverStageLabel,
    required this.coverProgress,
    required this.coverCompletedCount,
    required this.coverTotalCount,
    required this.selectedServiceKeys,
    required this.selectedCategoryKeys,
    required this.serviceOptions,
    required this.categoryOptions,
    required this.onPickCover,
    required this.onToggleService,
    required this.onToggleCategory,
  });

  final TextEditingController nameController;
  final TextEditingController slugController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final TextEditingController shortDescriptionController;
  final TextEditingController descriptionController;
  final TextEditingController contactEmailController;
  final TextEditingController phoneController;
  final TextEditingController websiteController;
  final TextEditingController organizationController;
  final TextEditingController coverImageUrlController;
  /// Anteprima locale (data-URL). Non viene salvato su Supabase.
  final String coverImagePreview;
  final bool uploadingCover;
  final String? coverStageLabel;
  final double coverProgress;
  final int coverCompletedCount;
  final int coverTotalCount;
  /// Chiavi DB dei servizi selezionati.
  final Set<String> selectedServiceKeys;
  /// Chiavi DB delle categorie selezionate.
  final Set<String> selectedCategoryKeys;
  /// Opzioni tassonomia servizi caricate da DB (service_types).
  final List<TrackTaxonomyOption> serviceOptions;
  /// Opzioni tassonomia categorie caricate da DB (track_categories).
  final List<TrackTaxonomyOption> categoryOptions;
  final Future<void> Function() onPickCover;
  final void Function(String) onToggleService;
  final void Function(String) onToggleCategory;

  String get _resolvedCoverImage =>
      coverImageUrlController.text.trim().isNotEmpty
          ? coverImageUrlController.text.trim()
          : coverImagePreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Identità pista',
          body: 'Nome, slug, città e copy breve per la card pubblica.',
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome pista')),
              const SizedBox(height: 12),
              TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug pubblico')),
              const SizedBox(height: 12),
              TextField(controller: cityController, decoration: const InputDecoration(labelText: 'Città')),
              const SizedBox(height: 12),
              TextField(
                controller: shortDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descrizione breve card'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Posizione e media',
          body: 'Indirizzo completo e cover per la card pista.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Indirizzo')),
              const SizedBox(height: 12),
              TextField(
                controller: coverImageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL cover (https://…)',
                  helperText: 'Incolla un link diretto all\'immagine. Consigliato rispetto al caricamento locale.',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onPickCover,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Oppure carica da file (anteprima locale)'),
              ),
              if (uploadingCover) ...[
                const SizedBox(height: 10),
                ImageTransferProgressCard(
                  label: 'Preparazione cover pista',
                  stageLabel: coverStageLabel,
                  progress: coverProgress,
                  completedCount: coverCompletedCount,
                  totalCount: coverTotalCount == 0 ? 1 : coverTotalCount,
                  icon: Icons.image_outlined,
                ),
              ],
              if (_resolvedCoverImage.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: AdaptiveImage(
                      source: _resolvedCoverImage,
                      fit: BoxFit.cover,
                      fallback: const ColoredBox(color: Color(0xFFEDEFF3)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Categoria pista',
          body: 'Seleziona il tipo di pista — usato nei filtri di ricerca.',
          child: categoryOptions.isEmpty
              ? const _TaxonomyLoadingHint()
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categoryOptions
                      .map(
                        (option) => FilterChip(
                          avatar: option.icon == null
                              ? null
                              : Icon(option.icon, size: 16),
                          label: Text(option.label),
                          selected: selectedCategoryKeys.contains(option.key),
                          onSelected: (_) => onToggleCategory(option.key),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Servizi disponibili',
          body: 'Seleziona i servizi confermati presenti in pista.',
          child: serviceOptions.isEmpty
              ? const _TaxonomyLoadingHint()
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: serviceOptions
                      .map(
                        (option) => FilterChip(
                          label: Text(option.label),
                          selected: selectedServiceKeys.contains(option.key),
                          onSelected: (_) => onToggleService(option.key),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Contatti e dettaglio',
          body: 'Descrizione lunga, contatti e riferimenti dell\'organizzazione.',
          child: Column(
            children: [
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descrizione completa'),
              ),
              const SizedBox(height: 12),
              TextField(controller: organizationController, decoration: const InputDecoration(labelText: 'Società o club')),
              const SizedBox(height: 12),
              TextField(controller: contactEmailController, decoration: const InputDecoration(labelText: 'Email contatto')),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefono')),
              const SizedBox(height: 12),
              TextField(controller: websiteController, decoration: const InputDecoration(labelText: 'Sito web')),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackPreviewCard extends StatelessWidget {
  const _TrackPreviewCard({
    required this.name,
    required this.city,
    required this.shortDescription,
    required this.coverImage,
    required this.services,
    required this.categories,
  });

  final String name;
  final String city;
  final String shortDescription;
  final String coverImage;
  final List<String> services;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preview card', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7F3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.concrete),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: coverImage.isEmpty
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.signalOrange.withValues(alpha: 0.35),
                                    const Color(0xFFF2F4F7),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.flag_outlined, size: 40),
                              ),
                            )
                          : AdaptiveImage(
                              source: coverImage,
                              fit: BoxFit.cover,
                              fallback: const ColoredBox(color: Color(0xFFEDEFF3)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name.isEmpty ? 'Nome pista' : name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    city.isEmpty ? 'Città' : city,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    shortDescription.isEmpty
                        ? 'La descrizione breve comparirà qui.'
                        : shortDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (categories.isNotEmpty || services.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...categories.map((item) => _PreviewChip(label: item, isCategory: true)),
                        ...services.map((item) => _PreviewChip(label: item, isCategory: false)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.nameReady,
    required this.cityReady,
    required this.descriptionReady,
    required this.coverReady,
    required this.servicesReady,
  });

  final bool nameReady;
  final bool cityReady;
  final bool descriptionReady;
  final bool coverReady;
  final bool servicesReady;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pronta per approvazione',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Checklist minima prima dell\'invio admin.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 12),
            _ReadinessRow(label: 'Nome pista', done: nameReady),
            _ReadinessRow(label: 'Città', done: cityReady),
            _ReadinessRow(
              label: 'Descrizione breve',
              done: descriptionReady,
            ),
            _ReadinessRow(label: 'Cover', done: coverReady),
            _ReadinessRow(label: 'Almeno un servizio', done: servicesReady),
          ],
        ),
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.label,
    required this.done,
  });

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? const Color(0xFF0E9F4B) : AppColors.steel,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label, this.isCategory = false});

  final String label;
  final bool isCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCategory
            ? AppColors.signalOrange.withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isCategory
              ? AppColors.signalOrange.withValues(alpha: 0.30)
              : AppColors.concrete,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Placeholder mostrato finché le opzioni tassonomia vengono caricate dal DB.
class _TaxonomyLoadingHint extends StatelessWidget {
  const _TaxonomyLoadingHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Text(
          'Caricamento opzioni…',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.steel,
          ),
        ),
      ],
    );
  }
}

class _DarkHeroChip extends StatelessWidget {
  const _DarkHeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}
