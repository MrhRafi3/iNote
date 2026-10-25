import 'package:flutter/material.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/text_highlighter.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';

/// Refined Note List Item for List View with fluid horizontal layout.
class NoteListItem extends StatelessWidget {
  final NoteModel note;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NoteListItem({
    super.key,
    required this.note,
    this.searchQuery = '',
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = note.accent;
    final cardBg = accent.cardColor(isDark);
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );

    final highlightStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.primary,
      backgroundColor: AppColors.primary.withValues(alpha: 0.16),
    );

    return Dismissible(
      key: ValueKey('note_list_${note.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await NotesRepository.instance.togglePin(note.id);
          return false;
        } else {
          await NotesRepository.instance.moveToTrash(note.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Note moved to trash'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Undo',
                  textColor: AppColors.primaryLight,
                  onPressed: () {
                    NotesRepository.instance.restoreFromTrash(note.id);
                  },
                ),
              ),
            );
          }
          return true;
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadii.borderLg,
        ),
        child: Icon(
          note.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadii.borderLg,
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: PressableScale(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadii.borderLg,
            border: Border.all(
              color: note.colorId != 0
                  ? accent.accentColor.withValues(alpha: isDark ? 0.35 : 0.25)
                  : borderCol,
              width: 1,
            ),
            boxShadow: isDark ? AppShadows.darkCard : AppShadows.lightCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextHighlighter.buildHighlightedSpan(
                        text: note.displayTitle,
                        query: searchQuery,
                        baseStyle: titleStyle,
                        highlightStyle: highlightStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (note.favorite)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                  if (note.pinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  Text(
                    DateFormatter.formatSmart(note.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
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
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      borderRadius: AppRadii.borderSm,
                    ),
                    child: Text(
                      note.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  if (note.isChecklist) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated,
                        borderRadius: AppRadii.borderSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Checklist',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
