import 'package:flutter/material.dart';
import '../../core/widgets/glass_floating_bar.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';

/// Root Application Shell featuring the floating liquid-glass navigation bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  static const List<GlassDockItem> _dockItems = [
    GlassDockItem(
      icon: Icons.notes_outlined,
      selectedIcon: Icons.notes_rounded,
      label: 'Notes',
    ),
    GlassDockItem(
      icon: Icons.push_pin_outlined,
      selectedIcon: Icons.push_pin_rounded,
      label: 'Pinned',
    ),
    GlassDockItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  void _openNewNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: GlassFloatingBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onAddNote: _openNewNote,
        items: _dockItems,
      ),
    );
  }
}
