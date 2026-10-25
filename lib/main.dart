import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/notes_repository.dart';
import 'data/repositories/preferences_repository.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/favorites_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/note_editor_screen.dart';
import 'presentation/screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotesRepository.instance.init();
  await PreferencesRepository.instance.init();
  runApp(const NotepadApp());
}

/// The root application widget supporting dynamic system/light/dark themes,
/// smooth animated theme transitions, and modern liquid-glass aesthetics.
class NotepadApp extends StatelessWidget {
  const NotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesRepository.instance;

    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'iNote',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: prefs.themeMode,
          home: const AppShell(),
        );
      },
    );
  }
}

// ============================================================================
// Backward Compatibility Layer
// Preserves original class names, constructors, and signatures so existing
// references, tests, or callers continue working seamlessly without breakage.
// ============================================================================

/// Legacy HomeShell redirect
class HomeShell extends StatelessWidget {
  final bool darkMode;
  final Function(bool)? onThemeChange;
  const HomeShell({super.key, this.darkMode = true, this.onThemeChange});

  @override
  Widget build(BuildContext context) => const AppShell();
}

/// Legacy NotesPage redirect
class NotesPage extends StatelessWidget {
  final bool darkMode;
  const NotesPage({super.key, this.darkMode = true});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

/// Legacy EditNotePage redirect
class EditNotePage extends StatelessWidget {
  final Map<String, dynamic>? existing;
  const EditNotePage({super.key, this.existing});

  @override
  Widget build(BuildContext context) {
    return NoteEditorScreen(
      initialNote: existing != null
          ? NotesRepository.instance.allNotes.firstWhere(
              (n) => n.id == existing!['id'],
              orElse: () =>
                  NotesRepository.instance.createNote(
                        title: (existing!['title'] ?? '').toString(),
                        content:
                            (existing!['content'] ?? existing!['text'] ?? '')
                                .toString(),
                        category: (existing!['category'] ?? 'Normal')
                            .toString(),
                      )
                      as dynamic, // handled gracefully
            )
          : null,
    );
  }
}

/// Legacy PinnedPage redirect
class PinnedPage extends StatelessWidget {
  final bool darkMode;
  const PinnedPage({super.key, this.darkMode = true});

  @override
  Widget build(BuildContext context) => const FavoritesScreen();
}

/// Legacy SettingsPage redirect
class SettingsPage extends StatelessWidget {
  final bool darkMode;
  final Function(bool)? onThemeChange;
  const SettingsPage({super.key, required this.darkMode, this.onThemeChange});

  @override
  Widget build(BuildContext context) => const SettingsScreen();
}
