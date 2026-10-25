import 'package:flutter/material.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../data/repositories/notes_repository.dart';

/// Screen for managing Archived and Trashed notes with full restoration.
class TrashArchiveScreen extends StatefulWidget {
  final int initialTab; // 0: Trash, 1: Archive
  const TrashArchiveScreen({super.key, this.initialTab = 0});

  @override
  State<TrashArchiveScreen> createState() => _TrashArchiveScreenState();
}

class _TrashArchiveScreenState extends State<TrashArchiveScreen> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  void _confirmEmptyTrash() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All items in trash will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              NotesRepository.instance.emptyTrash();
              Navigator.pop(ctx);
            },
            child: const Text('Empty All'),
          ),
        ],
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
        final trash = repo.trashNotes;
        final archived = repo.archivedNotes;
        final currentNotes = _activeTab == 0 ? trash : archived;

        return Scaffold(
          appBar: AppBar(
            title: Text(_activeTab == 0 ? 'Trash' : 'Archive'),
            actions: [
              if (_activeTab == 0 && trash.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(
                    Icons.delete_forever_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Empty',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onPressed: _confirmEmptyTrash,
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Container(
                  height: 36,
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
                            child: Text(
                              'Trash (${trash.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _activeTab == 0
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                              ),
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
                            child: Text(
                              'Archive (${archived.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _activeTab == 1
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                              ),
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
          body: currentNotes.isEmpty
              ? EmptyStateView(
                  icon: _activeTab == 0
                      ? Icons.delete_outline_rounded
                      : Icons.archive_outlined,
                  title: _activeTab == 0
                      ? 'Trash is empty'
                      : 'No archived notes',
                  description: _activeTab == 0
                      ? 'Deleted notes appear here. You can restore or permanently remove them.'
                      : 'Archived notes stay hidden from the main view until you unarchive them.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  itemCount: currentNotes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = currentNotes[index];

                    return Container(
                      padding: const EdgeInsets.all(14),
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
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  note.displayTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                note.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note.previewSnippet,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_activeTab == 0) ...[
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.restore_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Restore'),
                                  onPressed: () {
                                    repo.restoreFromTrash(note.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Note restored to active notes',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.delete_forever_rounded,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                  onPressed: () =>
                                      repo.permanentlyDelete(note.id),
                                ),
                              ] else ...[
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.unarchive_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Unarchive'),
                                  onPressed: () => repo.toggleArchive(note.id),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
