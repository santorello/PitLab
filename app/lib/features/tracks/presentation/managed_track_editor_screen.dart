import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/models/track_detail.dart';
import '../../../shared/widgets/external_links_section.dart';
import '../../auth/application/auth_providers.dart';
import '../application/track_taxonomy_option.dart';
import '../application/tracks_providers.dart';

class ManagedTrackEditorScreen extends ConsumerStatefulWidget {
  const ManagedTrackEditorScreen({
    required this.slug,
    super.key,
  });

  final String slug;

  @override
  ConsumerState<ManagedTrackEditorScreen> createState() =>
      _ManagedTrackEditorScreenState();
}

class _ManagedTrackEditorScreenState
    extends ConsumerState<ManagedTrackEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _addressController;
  late final TextEditingController _mapUrlController;
  late final TextEditingController _coverImageUrlController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _descriptionController;
  final Set<String> _selectedServiceKeys = <String>{};
  final Set<String> _selectedCategoryKeys = <String>{};
  bool _seeded = false;
  bool _saving = false;
  String? _trackId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _slugController = TextEditingController();
    _cityController = TextEditingController();
    _countryController = TextEditingController();
    _addressController = TextEditingController();
    _mapUrlController = TextEditingController();
    _coverImageUrlController = TextEditingController();
    _shortDescriptionController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    _mapUrlController.dispose();
    _coverImageUrlController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trackAsync = ref.watch(managedTrackDetailProvider(widget.slug));
    final categoryOptions = ref.watch(trackCategoryOptionsProvider).maybeWhen(
      data: (options) => options,
      orElse: () => const <TrackTaxonomyOption>[],
    );
    final serviceOptions = ref.watch(trackServiceOptionsProvider).maybeWhen(
      data: (options) => options,
      orElse: () => const <TrackTaxonomyOption>[],
    );

    return ContentScaffold(
      title: 'Modifica pista',
      description:
          'Editor operativo per aggiornare la scheda pubblica della pista assegnata.',
      child: trackAsync.when(
        data: (track) {
          if (track == null) {
            return const Center(
              child: Text('Questa pista non risulta assegnata al tuo account.'),
            );
          }

          _seed(track);

          return ListView(
            children: [
              // ── Scheda pubblica ──────────────────────────────────
              _SectionCard(
                title: 'Scheda pubblica',
                body: 'Nome, posizione e testi visibili nel dettaglio pista.',
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Nome pista'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _slugController,
                      decoration:
                          const InputDecoration(labelText: 'Slug pubblico'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'Città'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Paese'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Indirizzo'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mapUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL mappa esterna',
                        hintText: 'https://maps.google.com/...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _coverImageUrlController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'URL immagine di copertina',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _shortDescriptionController,
                      onChanged: (_) => setState(() {}),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrizione breve',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Descrizione completa',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Categorie ────────────────────────────────────────
              _SectionCard(
                title: 'Categoria pista',
                body: 'Seleziona il tipo di pista — usato nei filtri di ricerca.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categoryOptions
                      .map(
                        (option) => FilterChip(
                          avatar: option.icon == null
                              ? null
                              : Icon(option.icon, size: 16),
                          label: Text(option.label),
                          selected: _selectedCategoryKeys.contains(option.key),
                          onSelected: (_) => _toggleCategory(option.key),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 18),

              // ── Servizi ──────────────────────────────────────────
              _SectionCard(
                title: 'Servizi disponibili',
                body: 'Seleziona i servizi confermati presenti in pista.',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: serviceOptions
                      .map(
                        (option) => FilterChip(
                          label: Text(option.label),
                          selected: _selectedServiceKeys.contains(option.key),
                          onSelected: (_) => _toggleService(option.key),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 18),

              // ── Anteprima ────────────────────────────────────────
              _PreviewCard(
                name: _nameController.text.trim(),
                city: _cityController.text.trim(),
                shortDescription: _shortDescriptionController.text.trim(),
                categories: categoryOptions
                    .where(
                      (o) => _selectedCategoryKeys.contains(o.key),
                    )
                    .map((o) => o.label)
                    .toList(),
                services: serviceOptions
                    .where(
                      (o) => _selectedServiceKeys.contains(o.key),
                    )
                    .map((o) => o.label)
                    .toList(),
              ),

              const SizedBox(height: 18),

              // ── Link esterni ─────────────────────────────────────
              ExternalLinksSection(
                entityType: 'track',
                entityId: widget.slug,
                title: l10n.externalLinksTitle,
                body: l10n.externalLinksTrackBody,
                editable: true,
              ),

              const SizedBox(height: 18),

              // ── Azioni ───────────────────────────────────────────
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Salvataggio...' : 'Salva su PitLap'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/track/${widget.slug}'),
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: const Text('Apri dettaglio pubblico'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/manager'),
                    icon: const Icon(Icons.arrow_back_outlined),
                    label: const Text('Torna a Gestione'),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Non siamo riusciti a caricare la pista: $error'),
        ),
      ),
    );
  }

  void _seed(TrackDetail track) {
    if (_seeded) return;
    _seeded = true;
    _trackId = track.id;
    _nameController.text = track.name;
    _slugController.text = track.slug;
    _cityController.text = track.city;
    _countryController.text = track.country;
    _addressController.text = track.address;
    _mapUrlController.text = track.externalMapUrl;
    _shortDescriptionController.text = track.shortDescription;
    _descriptionController.text = track.description;
    _selectedServiceKeys
      ..clear()
      ..addAll(track.availableServiceKeys);
    _selectedCategoryKeys
      ..clear()
      ..addAll(track.categoryKeys);
  }

  void _toggleService(String key) {
    setState(() {
      if (!_selectedServiceKeys.add(key)) {
        _selectedServiceKeys.remove(key);
      }
    });
  }

  void _toggleCategory(String key) {
    setState(() {
      if (!_selectedCategoryKeys.add(key)) {
        _selectedCategoryKeys.remove(key);
      }
    });
  }

  Future<void> _save() async {
    final repository = ref.read(tracksRepositoryProvider);
    final currentUser = ref.read(currentUserProvider);
    final trackId = _trackId;
    if (repository == null || currentUser == null || trackId == null) return;

    final normalizedName = _nameController.text.trim();
    final normalizedCity = _cityController.text.trim();
    final normalizedSlug = _slugify(
      _slugController.text.trim().isEmpty
          ? normalizedName
          : _slugController.text.trim(),
    );

    if (normalizedName.isEmpty || normalizedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome pista e città sono obbligatori.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await repository.updateManagedTrackDetails(
        trackId: trackId,
        userId: currentUser.id,
        slug: normalizedSlug,
        name: normalizedName,
        shortDescription: _shortDescriptionController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: normalizedCity,
        country: _countryController.text.trim().isEmpty
            ? 'Italy'
            : _countryController.text.trim(),
        externalMapUrl: _mapUrlController.text.trim(),
        availableServiceKeys: _selectedServiceKeys.toList(),
        categoryKeys: _selectedCategoryKeys.toList(),
      );

      ref.invalidate(publicTracksProvider);
      ref.invalidate(managedTracksProvider);
      ref.invalidate(managedTrackDetailProvider(widget.slug));
      ref.invalidate(publicTrackDetailProvider(widget.slug));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheda pista aggiornata correttamente.')),
      );

      if (normalizedSlug != widget.slug) {
        context.go('/manager/tracks/$normalizedSlug/edit');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Salvataggio non riuscito: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _slugify(String input) {
    final source = input.trim().isEmpty ? 'nuova-pista' : input.trim();
    return source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

// ── Widget ausiliari ──────────────────────────────────────────────────────────

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
            const SizedBox(height: 6),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.name,
    required this.city,
    required this.shortDescription,
    required this.categories,
    required this.services,
  });

  final String name;
  final String city;
  final String shortDescription;
  final List<String> categories;
  final List<String> services;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.graphite,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anteprima card',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppColors.concrete),
            ),
            const SizedBox(height: 10),
            Text(
              name.isEmpty ? 'Nome pista' : name,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              city.isEmpty ? 'Città' : city,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.concrete),
            ),
            if (shortDescription.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                shortDescription,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (categories.isNotEmpty || services.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...categories.map(
                    (cat) => _PreviewChip(label: cat, isCategory: true),
                  ),
                  ...services.map(
                    (srv) => _PreviewChip(label: srv, isCategory: false),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label, required this.isCategory});

  final String label;
  final bool isCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCategory ? Colors.white12 : Colors.transparent,
        border: isCategory ? null : Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}
