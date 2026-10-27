import 'package:flutter/material.dart';

/// Soft, realistic depth shadows for both light and dark themes.
class AppShadows {
  AppShadows._();

  // Subtle card shadow in light mode
  static const List<BoxShadow> lightCard = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 6),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];

  // Soft depth shadow in dark mode
  static const List<BoxShadow> darkCard = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Floating dock / modal shadow
  static const List<BoxShadow> floatingLight = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 10),
      blurRadius: 30,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> floatingDark = [
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, 12),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];

  // Accent glow
  static List<BoxShadow> glow(Color accent) => [
    BoxShadow(
      color: accent.withValues(alpha: 0.28),
      offset: const Offset(0, 6),
      blurRadius: 18,
      spreadRadius: -2,
    ),
  ];
}
