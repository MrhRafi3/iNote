import 'package:flutter/material.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';

/// Floating or keyboard-attached formatting toolbar for the note editor.
class EditorFormattingToolbar extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onToggleChecklist;
  final bool isChecklistMode;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const EditorFormattingToolbar({
    super.key,
    required this.textController,
    required this.onToggleChecklist,
    required this.isChecklistMode,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  void _wrapSelection(String prefix, [String? suffix]) {
    final text = textController.text;
    final selection = textController.selection;
    final after = suffix ?? prefix;

    if (!selection.isValid) {
      final newText = '$text$prefix$after';
      textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: newText.length - after.length,
        ),
      );
      return;
    }

    final selectedText = selection.textInside(text);
    final newText =
        selection.textBefore(text) +
        prefix +
        selectedText +
        after +
        selection.textAfter(text);

    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.end + prefix.length,
      ),
    );
  }

  void _insertAtLineStart(String prefix) {
    final text = textController.text;
    final selection = textController.selection;
    final offset = selection.isValid ? selection.start : text.length;

    final before = text.substring(0, offset);
    final lastNewline = before.lastIndexOf('\n');
    final lineStart = lastNewline == -1 ? 0 : lastNewline + 1;

    final newText =
        text.substring(0, lineStart) + prefix + text.substring(lineStart);

    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + prefix.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
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
      child: ListView(
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
            onTap: () => _insertAtLineStart('## '),
          ),
          // Bold
          _ToolbarButton(
            icon: Icons.format_bold_rounded,
            tooltip: 'Bold',
            onTap: () => _wrapSelection('**'),
          ),
          // Italic
          _ToolbarButton(
            icon: Icons.format_italic_rounded,
            tooltip: 'Italic',
            onTap: () => _wrapSelection('*'),
          ),
          // Bullet List
          _ToolbarButton(
            icon: Icons.format_list_bulleted_rounded,
            tooltip: 'Bullet List',
            onTap: () => _insertAtLineStart('- '),
          ),
          // Quote
          _ToolbarButton(
            icon: Icons.format_quote_rounded,
            tooltip: 'Quote',
            onTap: () => _insertAtLineStart('> '),
          ),
          // Code block
          _ToolbarButton(
            icon: Icons.code_rounded,
            tooltip: 'Code',
            onTap: () => _wrapSelection('`'),
          ),
          const _ToolbarDivider(),
          // Timestamp
          _ToolbarButton(
            icon: Icons.schedule_rounded,
            tooltip: 'Insert Timestamp',
            onTap: () {
              final now = DateTime.now();
              final timeStr =
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ';
              _wrapSelection(timeStr, '');
            },
          ),
          const _ToolbarDivider(),
          // Undo
          _ToolbarButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            isEnabled: canUndo,
            onTap: onUndo,
          ),
          // Redo
          _ToolbarButton(
            icon: Icons.redo_rounded,
            tooltip: 'Redo',
            isEnabled: canRedo,
            onTap: onRedo,
          ),
        ],
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
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                      ? AppColors.darkSurfaceHighlight
                      : AppColors.lightSurfaceHighlight)
                : Colors.transparent,
            borderRadius: AppRadii.borderSm,
          ),
          child: Icon(icon, size: 20, color: iconColor),
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
