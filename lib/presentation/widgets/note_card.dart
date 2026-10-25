import 'package:flutter/material.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/text_highlighter.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';

/// Refined Note Card for Grid View with liquid-glass accents, subtle tinting,
/// pin/favorite micro-interactions, and search term highlighting.
class NoteCard extends StatelessWidget {
  final NoteModel note;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
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
      height: 1.25,
    );

    final highlightStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.primary,
      backgroundColor: AppColors.primary.withValues(alpha: 0.16),
      height: 1.25,
    );

    final bodyStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary,
      height: 1.4,
    );

    return Dismissible(
      key: ValueKey('note_card_${note.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right: toggle pin
          await NotesRepository.instance.togglePin(note.id);
          return false;
        } else {
          // Swipe left: move to trash
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
              // Top Action Row (Pin & Favorite badges)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Category pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
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
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // Favorite button
                  GestureDetector(
                    onTap: () =>
                        NotesRepository.instance.toggleFavorite(note.id),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        note.favorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 17,
                        color: note.favorite
                            ? Colors.amber
                            : (isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Pin button
                  GestureDetector(
                    onTap: () => NotesRepository.instance.togglePin(note.id),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        note.pinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        size: 16,
                        color: note.pinned
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Note Title
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextHighlighter.buildHighlightedSpan(
                  text: note.displayTitle,
                  query: searchQuery,
                  baseStyle: titleStyle,
                  highlightStyle: highlightStyle,
                ),
              ),
              const SizedBox(height: 6),
              // Note Excerpt / Content
              Expanded(
                child: Text(
                  note.previewSnippet,
                  style: bodyStyle,
                  maxLines: 4,
                  overflow: TextOverflow.fade,
                ),
              ),
              const SizedBox(height: 8),
              // Bottom Date Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatSmart(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                  if (note.isChecklist)
                    Icon(
                      Icons.checklist_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
