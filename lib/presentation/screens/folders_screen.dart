import 'package:flutter/material.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../data/models/note_filter.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../widgets/note_list_item.dart';
import '../widgets/quick_actions_sheet.dart';
import 'note_editor_screen.dart';

/// Screen dedicated to Folder & Notebook organization.
class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  String? _selectedFolder;

  void _showAddFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                NotesRepository.instance.addFolder(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFolder(String folder) {
    if (folder == 'Normal') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete default "Normal" folder')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$folder"?'),
        content: const Text(
          'Notes inside this folder will be safely moved to the "Normal" folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              NotesRepository.instance.deleteFolder(folder);
              if (_selectedFolder == folder) {
                setState(() => _selectedFolder = null);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openEditor([NoteModel? note]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          initialNote: note,
          initialCategory: _selectedFolder ?? 'Normal',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = NotesRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final folders = repo.folders;
        final allNotes = repo.activeNotes;

        if (_selectedFolder != null) {
          // Detail view of single folder
          final notesInFolder = repo.filterNotes(
            NoteFilter(category: _selectedFolder!),
          );

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => setState(() => _selectedFolder = null),
              ),
              title: Text(_selectedFolder!),
              actions: [
                if (_selectedFolder != 'Normal')
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    tooltip: 'Delete Folder',
                    onPressed: () => _confirmDeleteFolder(_selectedFolder!),
                  ),
              ],
            ),
            body: notesInFolder.isEmpty
                ? EmptyStateView(
                    icon: Icons.folder_open_rounded,
                    title: 'Empty Folder',
                    description: 'No notes yet in "$_selectedFolder".',
                    actionLabel: 'New Note Here',
                    onAction: () => _openEditor(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: notesInFolder.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final note = notesInFolder[index];
                      return NoteListItem(
                        note: note,
                        onTap: () => _openEditor(note),
                        onLongPress: () => QuickActionsSheet.show(
                          context,
                          note: note,
                          onEdit: () => _openEditor(note),
                        ),
                      );
                    },
                  ),
          );
        }

        // Overview of folders
        return Scaffold(
          appBar: AppBar(
            title: const Text('Folders'),
            actions: [
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: 'Add Folder',
                onPressed: _showAddFolderDialog,
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: folders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final folder = folders[index];
              final count = allNotes.where((n) => n.category == folder).length;

              return PressableScale(
                onTap: () => setState(() => _selectedFolder = folder),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: AppRadii.borderLg,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      width: 1,
                    ),
                    boxShadow: isDark
                        ? AppShadows.darkCard
                        : AppShadows.lightCard,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: AppRadii.borderMd,
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              folder,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count ${count == 1 ? "note" : "notes"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ],
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
