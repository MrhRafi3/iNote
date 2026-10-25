import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Clean, compact status pill / tag badge.
class StatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;

  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? AppColors.primary;

    Color bg;
    Color fg;
    Border? border;

    if (isSelected) {
      bg = accent;
      fg = Colors.white;
    } else {
      bg = isDark
          ? accent.withValues(alpha: 0.14)
          : accent.withValues(alpha: 0.08);
      fg = isDark ? accent.withValues(alpha: 0.95) : accent;
      border = Border.all(
        color: isDark
            ? accent.withValues(alpha: 0.28)
            : accent.withValues(alpha: 0.20),
        width: 1,
      );
    }

    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.borderFull,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: pill);
    }

    return pill;
  }
}
