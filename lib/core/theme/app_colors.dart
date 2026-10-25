import 'package:flutter/material.dart';

/// Centralized color palette and tokens for iNote.
///
/// Designed with Apple Notes & Notion influences:
/// deep obsidian dark mode, warm paper light mode, and a signature crimson coral accent.
class AppColors {
  AppColors._();

  // Signature Accent
  static const Color primary = Color(
    0xFFFF453A,
  ); // Crimson Coral (Apple/Modern iOS tone)
  static const Color primaryDark = Color(0xFFD6342A);
  static const Color primaryLight = Color(0xFFFF6961);
  static const Color primaryGlow = Color(0x33FF453A);

  // Dark Theme Palette (Obsidian & Deep Slate)
  static const Color darkBackground = Color(0xFF0D0F12);
  static const Color darkSurface = Color(0xFF16191F);
  static const Color darkSurfaceElevated = Color(0xFF1E232B);
  static const Color darkSurfaceHighlight = Color(0xFF282E38);
  static const Color darkBorder = Color(0x1FFFFFFF);
  static const Color darkBorderSubtle = Color(0x0FFFFFFF);

  static const Color darkTextPrimary = Color(0xFFF0F3F6);
  static const Color darkTextSecondary = Color(0xFF9EA7B3);
  static const Color darkTextTertiary = Color(0xFF656D76);

  // Light Theme Palette (Warm Paper & Clean Studio)
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFEDF0F5);
  static const Color lightSurfaceHighlight = Color(0xFFE2E7EE);
  static const Color lightBorder = Color(0x14000000);
  static const Color lightBorderSubtle = Color(0x0A000000);

  static const Color lightTextPrimary = Color(0xFF1F2328);
  static const Color lightTextSecondary = Color(0xFF656D76);
  static const Color lightTextTertiary = Color(0xFF8C959F);

  // Semantic Status Colors
  static const Color success = Color(0xFF2EA043);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // Glass Elements
  static const Color darkGlassBackground = Color(0x9916191F);
  static const Color lightGlassBackground = Color(0xD9FFFFFF);
  static const Color glassBorderLight = Color(0x2EFFFFFF);
  static const Color glassBorderDark = Color(0x1A000000);
}
