import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';

/// Contextual modal sheet for note management.
class QuickActionsSheet extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onEdit;

  const QuickActionsSheet({
    super.key,
    required this.note,
    required this.onEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required NoteModel note,
    required VoidCallback onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuickActionsSheet(note: note, onEdit: onEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = NotesRepository.instance;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: AppRadii.borderFull,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header with note title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.displayTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Folder: ${note.category} • ${note.wordCount} words',
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
            const SizedBox(height: 12),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined, size: 22),
              title: const Text('Open & Edit'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(
                note.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                size: 22,
              ),
              title: Text(note.pinned ? 'Unpin from Top' : 'Pin to Top'),
              onTap: () {
                Navigator.pop(context);
                repo.togglePin(note.id);
              },
            ),
            ListTile(
              leading: Icon(
                note.favorite ? Icons.star_outline_rounded : Icons.star_rounded,
                size: 22,
              ),
              title: Text(
                note.favorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              onTap: () {
                Navigator.pop(context);
                repo.toggleFavorite(note.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, size: 22),
              title: const Text('Duplicate Note'),
              onTap: () async {
                Navigator.pop(context);
                await repo.duplicateNote(note.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note duplicated')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, size: 22),
              title: const Text('Share Note'),
              onTap: () {
                Navigator.pop(context);
                final shareText = '${note.displayTitle}\n\n${note.content}';
                SharePlus.instance.share(
                  ShareParams(text: shareText, subject: note.displayTitle),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, size: 22),
              title: Text(note.archived ? 'Unarchive' : 'Archive Note'),
              onTap: () {
                Navigator.pop(context);
                repo.toggleArchive(note.id);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                size: 22,
                color: AppColors.error,
              ),
              title: const Text(
                'Delete Note',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                repo.moveToTrash(note.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Note deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppColors.primaryLight,
                      onPressed: () => repo.restoreFromTrash(note.id),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
