import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Un luogo gia' presente che somiglia a quello che l'utente sta inserendo.
/// Arriva dalla RPC `find_similar_places` (delta 2026-09-23-controllo-duplicati-luoghi).
class SimilarPlace {
  const SimilarPlace({
    required this.kind,
    required this.slug,
    required this.name,
    required this.city,
    required this.isPending,
    this.distanceMeters,
  });

  factory SimilarPlace.fromMap(Map<String, dynamic> map) => SimilarPlace(
        kind: map['kind'] as String? ?? '',
        slug: map['slug'] as String? ?? '',
        name: map['name'] as String? ?? '',
        city: map['city'] as String? ?? '',
        isPending: map['is_pending'] as bool? ?? false,
        distanceMeters: (map['distance_m'] as num?)?.toInt(),
      );

  final String kind;
  final String slug;
  final String name;
  final String city;
  final bool isPending;
  final int? distanceMeters;

  /// Rotta pubblica della scheda; null se il luogo e' ancora in approvazione.
  String? get route {
    if (isPending || slug.isEmpty) return null;
    return switch (kind) {
      'track' => '/track/$slug',
      'shop' => '/shop/$slug',
      'spot' => '/spot/$slug',
      _ => null,
    };
  }
}

/// Cerca luoghi simili. In caso di errore (rete, RPC assente su un ambiente
/// non aggiornato) restituisce lista vuota: il controllo non deve mai
/// impedire l'inserimento.
Future<List<SimilarPlace>> findSimilarPlaces(
  SupabaseClient? client, {
  required String kind,
  required String name,
  String? city,
  double? latitude,
  double? longitude,
  String? excludeId,
}) async {
  if (client == null || name.trim().length < 3) return const [];
  try {
    final rows = await client.rpc(
      'find_similar_places',
      params: <String, dynamic>{
        'p_kind': kind,
        'p_name': name.trim(),
        'p_city': (city == null || city.trim().isEmpty) ? null : city.trim(),
        'p_lat': latitude,
        'p_lng': longitude,
        'p_exclude_id': excludeId,
      },
    );
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => SimilarPlace.fromMap(row.cast<String, dynamic>()))
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}

/// Esito del dialogo "Esiste gia'?".
sealed class DuplicateDecision {
  const DuplicateDecision();
}

/// L'utente conferma che e' un luogo diverso: si prosegue col salvataggio.
class DuplicateProceed extends DuplicateDecision {
  const DuplicateProceed();
}

/// L'utente ha riconosciuto il luogo: non si salva; se c'e' una rotta, si apre.
class DuplicateOpenExisting extends DuplicateDecision {
  const DuplicateOpenExisting(this.place);
  final SimilarPlace place;
}

/// Dialogo chiuso senza scelta: si resta nel form.
class DuplicateCancel extends DuplicateDecision {
  const DuplicateCancel();
}

Future<DuplicateDecision> showDuplicatePlaceDialog(
  BuildContext context,
  List<SimilarPlace> matches,
) async {
  final isIt = Localizations.localeOf(context).languageCode == 'it';
  String t(String it, String en) => isIt ? it : en;

  String subtitle(SimilarPlace p) {
    final parts = <String>[
      if (p.city.isNotEmpty) p.city,
      if (p.distanceMeters != null)
        p.distanceMeters! < 1000
            ? t('a ${p.distanceMeters} m', '${p.distanceMeters} m away')
            : t('a ${(p.distanceMeters! / 1000).toStringAsFixed(1)} km',
                '${(p.distanceMeters! / 1000).toStringAsFixed(1)} km away'),
      if (p.isPending) t('in approvazione', 'pending review'),
    ];
    return parts.join(' · ');
  }

  final result = await showDialog<DuplicateDecision>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.content_copy_outlined),
      title: Text(t('Esiste gia\'?', 'Already on PitLap?')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t(
              'Abbiamo trovato luoghi simili. Se e\' uno di questi, aprilo: puoi proporre modifiche o aggiungere foto li\'.',
              'We found similar places. If it is one of these, open it: you can suggest edits or add photos there.',
            )),
            const SizedBox(height: 12),
            for (final place in matches)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(switch (place.kind) {
                  'shop' => Icons.storefront_outlined,
                  'spot' => Icons.location_pin,
                  _ => Icons.flag_outlined,
                }),
                title: Text(place.name),
                subtitle: Text(subtitle(place)),
                trailing: place.route == null
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(ctx).pop(DuplicateOpenExisting(place)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(const DuplicateCancel()),
          child: Text(t('Torna al modulo', 'Back to form')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(const DuplicateProceed()),
          child: Text(t('No, e\' un luogo nuovo', 'No, it is a new place')),
        ),
      ],
    ),
  );
  return result ?? const DuplicateCancel();
}
