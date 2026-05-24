import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_providers.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class PublicShop {
  const PublicShop({
    required this.id,
    required this.slug,
    required this.name,
    required this.city,
    this.shortDescription = '',
    this.subtitle = '',
    this.organizationName = '',
    this.imageUrl = '',
    this.galleryImages = const [],
    this.website = '',
    this.phone = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.externalMapUrl = '',
    this.serviceLabels = const [],
    this.hours = '',
    this.contacts = '',
    this.notes = '',
  });

  final String id;
  final String slug;
  final String name;
  final String city;
  final String shortDescription;
  final String subtitle;
  final String organizationName;
  final String imageUrl;
  final List<String> galleryImages;
  final String website;
  final String phone;
  final String address;
  final double? latitude;
  final double? longitude;
  final String externalMapUrl;
  final List<String> serviceLabels;
  final String hours;
  final String contacts;
  final String notes;

  factory PublicShop.fromMap(Map<String, dynamic> map) {
    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.whereType<String>().where((s) => s.isNotEmpty).toList();
      }
      return const [];
    }

    return PublicShop(
      id:               map['id']               as String? ?? '',
      slug:             map['slug']             as String? ?? '',
      name:             map['name']             as String? ?? '',
      city:             map['city']             as String? ?? '',
      shortDescription: map['short_description'] as String? ?? '',
      subtitle:         map['subtitle']          as String? ?? '',
      organizationName: map['organization_name'] as String? ?? '',
      imageUrl:         map['image_url']         as String? ?? '',
      galleryImages:    parseStringList(map['gallery_images']),
      website:          map['website_url']       as String? ?? '',
      phone:            map['phone']             as String? ?? '',
      address:          map['address']           as String? ?? '',
      latitude:         (map['latitude']          as num?)?.toDouble(),
      longitude:        (map['longitude']         as num?)?.toDouble(),
      externalMapUrl:   map['external_map_url']  as String? ?? '',
      serviceLabels:    parseStringList(map['service_labels']),
      hours:            map['hours']             as String? ?? '',
      contacts:         map['contacts']          as String? ?? '',
      notes:            map['notes']             as String? ?? '',
    );
  }
}

// ─── Repository ──────────────────────────────────────────────────────────────

const _shopSelectFields =
    'id, slug, name, city, short_description, subtitle, organization_name, '
    'image_url, gallery_images, website_url, phone, address, latitude, longitude, external_map_url, '
    'service_labels, hours, contacts, notes';

class PublicShopsRepository {
  const PublicShopsRepository(this._client);

  final SupabaseClient _client;

  Future<List<PublicShop>> fetchPublicShops() async {
    final response = await _client
        .from('shops')
        .select(_shopSelectFields)
        .eq('is_public', true)
        .eq('approval_status', 'approved')
        .order('name');

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PublicShop.fromMap)
        .toList();
  }

  Future<PublicShop?> fetchShopBySlug(String slug) async {
    final response = await _client
        .from('shops')
        .select(_shopSelectFields)
        .eq('slug', slug)
        .eq('is_public', true)
        .eq('approval_status', 'approved')
        .maybeSingle();

    if (response == null) return null;
    return PublicShop.fromMap(response);
  }

  /// Come [fetchShopBySlug] ma senza filtrare per is_public/approval_status.
  /// Usato dall'editor per caricare anche i negozi in stato pending o draft
  /// di cui l'utente corrente è owner o admin (la RLS Supabase gestisce
  /// l'accesso: admin policy + owner policy garantiscono che solo i titolari
  /// vedano il proprio negozio non ancora approvato).
  Future<PublicShop?> fetchShopBySlugIncludingDrafts(String slug) async {
    final response = await _client
        .from('shops')
        .select(_shopSelectFields)
        .eq('slug', slug)
        .maybeSingle();

    if (response == null) return null;
    return PublicShop.fromMap(response);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final publicShopsRepositoryProvider = Provider<PublicShopsRepository?>((ref) {
  final client = ref.watch(authClientProvider);
  if (client == null) return null;
  return PublicShopsRepository(client);
});

final publicShopsProvider = FutureProvider<List<PublicShop>>((ref) async {
  final repo = ref.watch(publicShopsRepositoryProvider);
  if (repo == null) return const [];
  return repo.fetchPublicShops();
});

final publicShopDetailProvider =
    FutureProvider.family<PublicShop?, String>((ref, slug) async {
      final repo = ref.watch(publicShopsRepositoryProvider);
      if (repo == null) return null;
      return repo.fetchShopBySlug(slug);
    });
