import 'package:flutter/material.dart';
import '../animations/spring_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import 'glass_container.dart';

class GlassDockItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const GlassDockItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Floating liquid-glass bottom navigation dock with smooth animated tab indicator.
class GlassFloatingBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddNote;
  final List<GlassDockItem> items;

  const GlassFloatingBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddNote,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            // Floating Dock Tabs
            Expanded(
              child: GlassContainer(
                blur: 24,
                borderRadius: AppRadii.borderFull,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                boxShadow: isDark
                    ? AppShadows.floatingDark
                    : AppShadows.floatingLight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(items.length, (index) {
                    final isSelected = index == currentIndex;
                    final item = items[index];

                    return PressableScale(
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                    ? AppColors.primary.withValues(alpha: 0.18)
                                    : AppColors.primary.withValues(alpha: 0.12))
                              : Colors.transparent,
                          borderRadius: AppRadii.borderFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Text(
                                item.label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Floating Create Button
            PressableScale(
              onTap: onAddNote,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.glow(AppColors.primary),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
