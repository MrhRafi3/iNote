import 'package:flutter/material.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/note_color.dart';

/// Horizontal color accent palette picker.
class NoteColorPicker extends StatelessWidget {
  final int selectedColorId;
  final ValueChanged<int> onColorSelected;

  const NoteColorPicker({
    super.key,
    required this.selectedColorId,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: NoteAccent.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final accent = NoteAccent.values[index];
          final isSelected = accent.id == selectedColorId;

          return PressableScale(
            onTap: () => onColorSelected(accent.id),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.cardColor(isDark),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2.5 : 1.2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accent.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
