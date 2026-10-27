import 'package:flutter/material.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../data/models/note_filter.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../widgets/folder_chip_list.dart';
import '../widgets/note_card.dart';
import '../widgets/note_list_item.dart';
import '../widgets/quick_actions_sheet.dart';
import 'note_editor_screen.dart';

/// Redesigned Home Screen with Apple Notes elegance and Notion organization.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
    }
  }

  void _openEditor([NoteModel? note]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          initialNote: note,
          initialCategory: _selectedCategory != 'All'
              ? _selectedCategory
              : null,
        ),
      ),
    );
  }

  void _showSortSheet() {
    final repo = NotesRepository.instance;
    final current = repo.sortOption;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Sort Notes By',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(),
              ...NoteSortOption.values.map(
                (opt) => ListTile(
                  title: Text(opt.label),
                  trailing: opt == current
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    repo.setSortOption(opt);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = NotesRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final filter = NoteFilter(
          category: _selectedCategory,
          searchQuery: _searchQuery,
          sortOption: repo.sortOption,
        );

        final filteredNotes = repo.filterNotes(filter);
        final activeNotes = repo.activeNotes;

        // Folder counts
        final folderCounts = <String, int>{'All': activeNotes.length};
        for (var f in repo.folders) {
          folderCounts[f] = activeNotes.where((n) => n.category == f).length;
        }

        // Pinned notes
        final pinnedNotes = filteredNotes.where((n) => n.pinned).toList();
        final unpinnedNotes = filteredNotes.where((n) => !n.pinned).toList();
        final isGrid = repo.viewMode == NotesViewMode.grid;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Navigation & Actions Bar
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'iNote',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Search toggle button
                            PressableScale(
                              onTap: () {
                                setState(() {
                                  _isSearchOpen = !_isSearchOpen;
                                  if (!_isSearchOpen) {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _isSearchOpen
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.darkSurfaceElevated
                                            : AppColors.lightSurfaceElevated),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  _isSearchOpen
                                      ? Icons.close_rounded
                                      : Icons.search_rounded,
                                  size: 22,
                                  color: _isSearchOpen
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Sort option button
                            PressableScale(
                              onTap: _showSortSheet,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.lightSurfaceElevated,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.sort_rounded,
                                  size: 22,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // View Mode Toggle (Grid vs List)
                            PressableScale(
                              onTap: () => repo.setViewMode(
                                isGrid
                                    ? NotesViewMode.list
                                    : NotesViewMode.grid,
                              ),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.lightSurfaceElevated,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  isGrid
                                      ? Icons.view_agenda_outlined
                                      : Icons.grid_view_rounded,
                                  size: 22,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Animated Search Bar
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: SearchBarWidget(
                              controller: _searchController,
                              hintText: 'Search in notes and tasks...',
                            ),
                          ),
                          crossFadeState: _isSearchOpen
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 220),
                        ),
                      ],
                    ),
                  ),
                ),
                // Horizontal Category Filter Chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FolderChipList(
                      folders: repo.folders,
                      selectedCategory: _selectedCategory,
                      folderCounts: folderCounts,
                      onSelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                ),
              ],
              body: RefreshIndicator(
                onRefresh: () async => await repo.init(),
                color: AppColors.primary,
                child: filteredNotes.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: EmptyStateView(
                            icon: _searchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.note_alt_outlined,
                            title: _searchQuery.isNotEmpty
                                ? 'No matching notes'
                                : 'No notes in $_selectedCategory',
                            description: _searchQuery.isNotEmpty
                                ? 'No notes matched "$_searchQuery". Try searching a different term or keyword.'
                                : 'Tap the button below or "+" in the dock to capture your first thought or checklist.',
                            actionLabel: _searchQuery.isNotEmpty
                                ? 'Clear Search'
                                : 'Create Note',
                            onAction: _searchQuery.isNotEmpty
                                ? () => _searchController.clear()
                                : () => _openEditor(),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        children: [
                          // Pinned Section (if any pinned notes exist and no specific search)
                          if (pinnedNotes.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
                                top: 2,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.push_pin_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PINNED',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isGrid)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.88,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: pinnedNotes.length,
                                itemBuilder: (context, index) {
                                  final note = pinnedNotes[index];
                                  return StaggeredEntrance(
                                    index: index,
                                    child: NoteCard(
                                      note: note,
                                      searchQuery: _searchQuery,
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
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pinnedNotes.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final note = pinnedNotes[index];
                                  return StaggeredEntrance(
                                    index: index,
                                    child: NoteListItem(
                                      note: note,
                                      searchQuery: _searchQuery,
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
                            const SizedBox(height: 18),
                            if (unpinnedNotes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
                                child: Text(
                                  'OTHER NOTES',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                          ],
                          // Regular Notes Section
                          if (unpinnedNotes.isNotEmpty) ...[
                            if (isGrid)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.88,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemCount: unpinnedNotes.length,
                                itemBuilder: (context, index) {
                                  final note = unpinnedNotes[index];
                                  return StaggeredEntrance(
                                    index: index,
                                    child: NoteCard(
                                      note: note,
                                      searchQuery: _searchQuery,
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
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: unpinnedNotes.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final note = unpinnedNotes[index];
                                  return StaggeredEntrance(
                                    index: index,
                                    child: NoteListItem(
                                      note: note,
                                      searchQuery: _searchQuery,
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
                          ],
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
