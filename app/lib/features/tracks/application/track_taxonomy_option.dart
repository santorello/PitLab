import 'package:flutter/material.dart';

class TrackTaxonomyOption {
  const TrackTaxonomyOption({
    required this.key,
    required this.label,
    this.icon,
  });

  final String key;
  final String label;
  final IconData? icon;
}
