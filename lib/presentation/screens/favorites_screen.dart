import 'package:flutter/material.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../data/models/note_filter.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../widgets/note_card.dart';
import '../widgets/note_list_item.dart';
import '../widgets/quick_actions_sheet.dart';
import 'note_editor_screen.dart';

/// Pinned & Starred notes screen.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _activeTab = 0; // 0: Pinned, 1: Favorites

  void _openEditor([NoteModel? note]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(initialNote: note)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = NotesRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final pinned = repo.pinnedNotes;
        final favorites = repo.favoriteNotes;
        final notes = _activeTab == 0 ? pinned : favorites;
        final isGrid = repo.viewMode == NotesViewMode.grid;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Important Notes'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    borderRadius: AppRadii.borderFull,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PressableScale(
                          onTap: () => setState(() => _activeTab = 0),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _activeTab == 0
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: AppRadii.borderFull,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.push_pin_rounded,
                                  size: 14,
                                  color: _activeTab == 0
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pinned (${pinned.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _activeTab == 0
                                        ? Colors.white
                                        : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: PressableScale(
                          onTap: () => setState(() => _activeTab = 1),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _activeTab == 1
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: AppRadii.borderFull,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: _activeTab == 1
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Favorites (${favorites.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _activeTab == 1
                                        ? Colors.white
                                        : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: notes.isEmpty
              ? EmptyStateView(
                  icon: _activeTab == 0
                      ? Icons.push_pin_outlined
                      : Icons.star_outline_rounded,
                  title: _activeTab == 0
                      ? 'No pinned notes'
                      : 'No favorite notes',
                  description: _activeTab == 0
                      ? 'Pin notes to keep them permanently at the top of your workspace.'
                      : 'Star important notes to easily find them anytime.',
                )
              : isGrid
              ? GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.88,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return StaggeredEntrance(
                      index: index,
                      child: NoteCard(
                        note: note,
                        onTap: () => _openEditor(note),
                        onLongPress: () => QuickActionsSheet.show(
                          context,
                          note: note,
                          onEdit: () => _openEditor(note),
                        ),
                      ),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: notes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return StaggeredEntrance(
                      index: index,
                      child: NoteListItem(
                        note: note,
                        onTap: () => _openEditor(note),
                        onLongPress: () => QuickActionsSheet.show(
                          context,
                          note: note,
                          onEdit: () => _openEditor(note),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
