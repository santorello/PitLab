import 'dart:convert';

import 'package:flutter/material.dart';

int colorToSignedArgb32(Color color) {
  final value = color.toARGB32();
  return value > 0x7FFFFFFF ? value - 0x100000000 : value;
}

Color colorFromSignedArgb32(int? value, {int fallback = 0xFFD97706}) {
  if (value == null) {
    return Color(fallback);
  }
  return Color(value & 0xFFFFFFFF);
}

class SpotEntry {
  SpotEntry({
    required this.slug,
    required this.title,
    required this.city,
    required this.category,
    required this.bestFor,
    required this.surface,
    required this.note,
    required this.imageAccent,
    required this.photoCount,
    this.id,
    this.address,
    this.latitude,
    this.longitude,
    this.imageUrls = const [],
    this.videoUrl,
    this.isCustom = false,
    this.isOwnedByCurrentUser = false,
    this.bestForTags = const [],
    this.surfaceTags = const [],
    this.accessType,
    this.bestSeason,
  });

  /// UUID Supabase (null per spot default non ancora caricati da DB).
  final String? id;
  final String slug;
  final String title;
  final String city;
  final String category;
  final String bestFor;
  final String surface;
  final String note;
  final Color imageAccent;
  final int photoCount;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;
  final String? videoUrl;
  final bool isCustom;
  final bool isOwnedByCurrentUser;
  final List<String> bestForTags;
  final List<String> surfaceTags;
  final String? accessType;
  final String? bestSeason;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'slug': slug,
      'title': title,
      'city': city,
      'category': category,
      'best_for': bestFor,
      'surface': surface,
      'note': note,
      'image_accent': colorToSignedArgb32(imageAccent),
      'photo_count': photoCount,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'image_urls': imageUrls,
      'video_url': videoUrl,
      'is_custom': isCustom,
      'is_owned_by_current_user': isOwnedByCurrentUser,
      'best_for_tags': bestForTags,
      'surface_tags': surfaceTags,
      'access_type': accessType,
      'best_season': bestSeason,
    };
  }

  factory SpotEntry.fromMap(Map<String, dynamic> map) {
    return SpotEntry(
      id: map['id'] as String?,
      slug: map['slug'] as String? ?? '',
      title: map['title'] as String? ?? '',
      city: map['city'] as String? ?? '',
      category: map['category'] as String? ?? '',
      bestFor: map['best_for'] as String? ?? '',
      surface: map['surface'] as String? ?? '',
      note: map['note'] as String? ?? '',
      imageAccent: colorFromSignedArgb32(map['image_accent'] as int?),
      photoCount: map['photo_count'] as int? ?? 0,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imageUrls: (map['image_urls'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      videoUrl: map['video_url'] as String?,
      isCustom: map['is_custom'] as bool? ?? true,
      isOwnedByCurrentUser:
          map['is_owned_by_current_user'] as bool? ?? false,
      bestForTags: (map['best_for_tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      surfaceTags: (map['surface_tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      accessType: map['access_type'] as String?,
      bestSeason: map['best_season'] as String?,
    );
  }
}

class SpotCatalog {
  static SpotEntry? bySlug(String slug, List<SpotEntry> spots) {
    for (final spot in spots) {
      if (spot.slug == slug) {
        return spot;
      }
    }
    return null;
  }

  static String createSlug(String title, String city) {
    final base = '$title-$city'.toLowerCase();
    return base
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static List<SpotEntry> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SpotEntry.fromMap)
        .toList();
  }

  static String encodeList(List<SpotEntry> spots) {
    return jsonEncode(spots.map((spot) => spot.toMap()).toList());
  }
}
