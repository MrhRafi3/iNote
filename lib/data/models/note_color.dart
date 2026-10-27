import 'package:flutter/material.dart';

/// Available subtle color accents for personalizing notes.
enum NoteAccent {
  defaultSlate(
    id: 0,
    name: 'Default',
    lightColor: Color(0xFFF7F8FA),
    darkColor: Color(0xFF16191F),
    accentColor: Color(0xFF656D76),
  ),
  coral(
    id: 1,
    name: 'Coral',
    lightColor: Color(0xFFFFF1F0),
    darkColor: Color(0xFF2B1716),
    accentColor: Color(0xFFFF453A),
  ),
  amber(
    id: 2,
    name: 'Amber',
    lightColor: Color(0xFFFFF8E6),
    darkColor: Color(0xFF2A2010),
    accentColor: Color(0xFFD29922),
  ),
  emerald(
    id: 3,
    name: 'Emerald',
    lightColor: Color(0xFFEDF8F1),
    darkColor: Color(0xFF11261B),
    accentColor: Color(0xFF2EA043),
  ),
  azure(
    id: 4,
    name: 'Azure',
    lightColor: Color(0xFFEDF5FD),
    darkColor: Color(0xFF132338),
    accentColor: Color(0xFF58A6FF),
  ),
  violet(
    id: 5,
    name: 'Violet',
    lightColor: Color(0xFFF7F0FC),
    darkColor: Color(0xFF251633),
    accentColor: Color(0xFFBC8CFF),
  ),
  rose(
    id: 6,
    name: 'Rose',
    lightColor: Color(0xFFFFF0F5),
    darkColor: Color(0xFF2F1420),
    accentColor: Color(0xFFFF69B4),
  ),
  mint(
    id: 7,
    name: 'Mint',
    lightColor: Color(0xFFE8F7F4),
    darkColor: Color(0xFF0F2624),
    accentColor: Color(0xFF3FB950),
  );

  final int id;
  final String name;
  final Color lightColor;
  final Color darkColor;
  final Color accentColor;

  const NoteAccent({
    required this.id,
    required this.name,
    required this.lightColor,
    required this.darkColor,
    required this.accentColor,
  });

  static NoteAccent fromId(int id) {
    return NoteAccent.values.firstWhere(
      (accent) => accent.id == id,
      orElse: () => NoteAccent.defaultSlate,
    );
  }

  Color cardColor(bool isDark) => isDark ? darkColor : lightColor;
}
