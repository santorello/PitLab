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
    );
  }
}

class SpotCatalog {
  static final defaultSpots = <SpotEntry>[
    SpotEntry(
      slug: 'argine-del-taro',
      title: 'Argine del Taro',
      city: 'Parma',
      category: 'Bashing',
      bestFor: 'Buggy 1/8, monster, short course',
      surface: 'Terra battuta e sterrato aperto',
      note:
          'Spazio largo, fondo variabile e buon margine per sessioni libere in compagnia. Da usare con rispetto e buon senso.',
      imageAccent: Color(0xFFD97706),
      photoCount: 3,
      latitude: 44.8015,
      longitude: 10.2402,
    ),
    SpotEntry(
      slug: 'cava-roveri-trail',
      title: 'Cava Roveri Trail',
      city: 'Modena',
      category: 'Scaler',
      bestFor: 'Scaler, crawler, trail truck',
      surface: 'Roccia leggera, ghiaia e salite tecniche',
      note:
          'Spot adatto a uscite lente e tecniche, con punti fotogenici e passaggi da affrontare in gruppo.',
      imageAccent: Color(0xFF2563EB),
      photoCount: 3,
      latitude: 44.6459,
      longitude: 10.9252,
    ),
    SpotEntry(
      slug: 'campo-volo-nord',
      title: 'Campo Volo Nord',
      city: 'Reggio Emilia',
      category: 'Droni',
      bestFor: 'Freestyle, cinewhoop, micro FPV',
      surface: 'Area aperta con prato e visuale ampia',
      note:
          'Buona visibilita\' e spazio per voli tranquilli. Da verificare sempre contesto, sicurezza e regole locali prima di usarlo.',
      imageAccent: Color(0xFF059669),
      photoCount: 3,
      latitude: 44.7212,
      longitude: 10.6314,
    ),
  ];

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
