import 'package:flutter/material.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import 'rich_text_note_controller.dart';

/// Floating or keyboard-attached formatting toolbar for the note editor.
/// Supports real rich-text toggling, active style highlighting, and keeps
/// keyboard focus steady.
class EditorFormattingToolbar extends StatelessWidget {
  final RichTextNoteController textController;
  final VoidCallback onToggleChecklist;
  final bool isChecklistMode;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final FocusNode? focusNode;

  const EditorFormattingToolbar({
    super.key,
    required this.textController,
    required this.onToggleChecklist,
    required this.isChecklistMode,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.focusNode,
  });

  void _runAction(VoidCallback action) {
    action();
    // Maintain editor focus so the keyboard is not accidentally dismissed
    focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: ListenableBuilder(
        listenable: textController,
        builder: (context, _) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              // Checklist Mode Toggle
              _ToolbarButton(
                icon: Icons.checklist_rounded,
                tooltip: 'Checklist Mode',
                isActive: isChecklistMode,
                onTap: onToggleChecklist,
              ),
              const _ToolbarDivider(),
              // Heading
              _ToolbarButton(
                icon: Icons.title_rounded,
                tooltip: 'Heading',
                isActive: textController.isHeadingActive,
                onTap: () => _runAction(textController.toggleHeading),
              ),
              // Bold
              _ToolbarButton(
                icon: Icons.format_bold_rounded,
                tooltip: 'Bold',
                isActive: textController.isBoldActive,
                onTap: () => _runAction(textController.toggleBold),
              ),
              // Italic
              _ToolbarButton(
                icon: Icons.format_italic_rounded,
                tooltip: 'Italic',
                isActive: textController.isItalicActive,
                onTap: () => _runAction(textController.toggleItalic),
              ),
              // Bullet List
              _ToolbarButton(
                icon: Icons.format_list_bulleted_rounded,
                tooltip: 'Bullet List',
                isActive: textController.isBulletActive,
                onTap: () => _runAction(textController.toggleBulletList),
              ),
              // Quote
              _ToolbarButton(
                icon: Icons.format_quote_rounded,
                tooltip: 'Quote',
                isActive: textController.isQuoteActive,
                onTap: () => _runAction(textController.toggleQuote),
              ),
              // Code
              _ToolbarButton(
                icon: Icons.code_rounded,
                tooltip: 'Code',
                isActive: textController.isCodeActive,
                onTap: () => _runAction(textController.toggleCode),
              ),
              const _ToolbarDivider(),
              // Timestamp
              _ToolbarButton(
                icon: Icons.schedule_rounded,
                tooltip: 'Insert Timestamp',
                onTap: () => _runAction(textController.insertTimestamp),
              ),
              const _ToolbarDivider(),
              // Undo
              _ToolbarButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                isEnabled: canUndo,
                onTap: () => _runAction(() => onUndo?.call()),
              ),
              // Redo
              _ToolbarButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                isEnabled: canRedo,
                onTap: () => _runAction(() => onRedo?.call()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isEnabled;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isActive = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    if (!isEnabled) {
      iconColor = isDark ? Colors.white24 : Colors.black26;
    } else if (isActive) {
      iconColor = AppColors.primary;
    } else {
      iconColor = isDark
          ? AppColors.darkTextPrimary
          : AppColors.lightTextPrimary;
    }

    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.12))
                : Colors.transparent,
            borderRadius: AppRadii.borderSm,
            border: isActive
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
