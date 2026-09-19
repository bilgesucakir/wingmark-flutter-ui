import 'package:flutter/material.dart';

/// Badge icon names are seeded server-side as free-form strings (originally
/// modeled after SF Symbol names in the Swift mock catalog, e.g.
/// "trophy.fill" / "bird.fill"). This maps common keywords to a Material
/// icon so the badge tiles have a sensible glyph regardless of exactly how
/// the backend seeds them.
IconData iconForBadge(String name) {
  final n = name.toLowerCase();
  if (n.contains('trophy')) return Icons.emoji_events;
  if (n.contains('bird') || n.contains('feather')) return Icons.flutter_dash;
  if (n.contains('star')) return Icons.star;
  if (n.contains('leaf') || n.contains('eco')) return Icons.eco;
  if (n.contains('map') || n.contains('pin') || n.contains('location')) {
    return Icons.location_on;
  }
  if (n.contains('camera') || n.contains('photo')) return Icons.camera_alt;
  if (n.contains('heart')) return Icons.favorite;
  if (n.contains('paw') || n.contains('pet')) return Icons.pets;
  if (n.contains('egg') || n.contains('baby')) return Icons.egg_outlined;
  if (n.contains('medal') || n.contains('rosette')) return Icons.military_tech;
  return Icons.emoji_events;
}
