import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../data/models/note_filter.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import 'trash_archive_screen.dart';

/// Redesigned Settings Screen with premium Liquid Glass morphism,
/// clean grouped sections, animated theme selector, and developer attribution.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=iNote%20Feedback');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSortPicker(BuildContext context, NotesRepository repo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Default Sort Order',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...NoteSortOption.values.map(
                  (opt) => ListTile(
                    title: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: opt == repo.sortOption
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: opt == repo.sortOption
                            ? AppColors.primary
                            : null,
                      ),
                    ),
                    trailing: opt == repo.sortOption
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      repo.setSortOption(opt);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        title: const Text('Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the exported iNote JSON backup content below:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '{\n  "app": "iNote",\n  "notes": [...]\n}',
                filled: true,
                fillColor: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightSurfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: AppRadii.borderSm,
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
            ),
            onPressed: () async {
              final raw = controller.text.trim();
              if (raw.isNotEmpty) {
                try {
                  final count = await NotesRepository.instance.importFromJson(
                    raw,
                  );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully imported $count notes!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to import: Invalid JSON format'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _exportNotes(BuildContext context) {
    final jsonString = NotesRepository.instance.exportToJson();
    SharePlus.instance.share(
      ShareParams(
        text: jsonString,
        subject: 'iNote_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        title: const Text('Clear All Notes?'),
        content: const Text(
          'This will permanently delete all notes from storage. Make sure to export a backup first if you want to keep your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
            ),
            onPressed: () async {
              final repo = NotesRepository.instance;
              for (var n in List.of(repo.allNotes)) {
                await repo.permanentlyDelete(n.id);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notes have been cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = PreferencesRepository.instance;
    final repo = NotesRepository.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([prefs, repo]),
      builder: (context, _) {
        final activeCount = repo.activeNotes.length;
        final pinnedCount = repo.pinnedNotes.length;
        final totalCount = repo.allNotes.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                children: [
                  // ==========================================================
                  // 1. APPEARANCE SECTION
                  // ==========================================================
                  const _SectionHeader(title: 'APPEARANCE'),
                  _SettingsGlassCard(
                    children: [
                      // Theme Mode Header & Segmented Pill
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _IconBadge(
                                  icon: Icons.palette_outlined,
                                  color: const Color(0xFF8B5CF6), // Violet
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Theme Mode',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Choose system, light, or dark appearance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Liquid Glass Theme Selector Pill
                            _ThemeModeSegmentedPill(
                              selectedMode: prefs.themeMode,
                              onChanged: (mode) => prefs.setThemeMode(mode),
                            ),
                          ],
                        ),
                      ),
                      const _SettingsDivider(),
                      // Haptic Feedback Switch
                      _SettingsTile(
                        icon: Icons.vibration_rounded,
                        iconColor: const Color(0xFF14B8A6), // Teal
                        title: 'Haptic Micro-feedback',
                        subtitle: 'Tactile response on taps and interactions',
                        trailing: Switch.adaptive(
                          value: prefs.hapticsEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => prefs.toggleHaptics(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==========================================================
                  // 2. PREFERENCES SECTION
                  // ==========================================================
                  const _SectionHeader(title: 'PREFERENCES'),
                  _SettingsGlassCard(
                    children: [
                      // Default Notes Layout
                      _SettingsTile(
                        icon: Icons.view_quilt_rounded,
                        iconColor: const Color(0xFFF59E0B), // Amber
                        title: 'Default Notes Layout',
                        subtitle: 'Choose cards grid or vertical list',
                        trailing: _LayoutModeToggle(
                          currentMode: repo.viewMode,
                          onChanged: (mode) => repo.setViewMode(mode),
                        ),
                      ),
                      const _SettingsDivider(),
                      // Default Sort Order
                      _SettingsTile(
                        icon: Icons.sort_rounded,
                        iconColor: const Color(0xFF3B82F6), // Blue
                        title: 'Default Sort Order',
                        subtitle: repo.sortOption.label,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        onTap: () => _showSortPicker(context, repo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==========================================================
                  // 3. DATA & STORAGE SECTION
                  // ==========================================================
                  const _SectionHeader(title: 'DATA & STORAGE'),
                  _SettingsGlassCard(
                    children: [
                      // Notes in Storage
                      _SettingsTile(
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFF0EA5E9), // Sky Blue
                        title: 'Notes in Storage',
                        subtitle: '$activeCount active • $pinnedCount pinned',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceHighlight
                                : AppColors.lightSurfaceHighlight,
                            borderRadius: AppRadii.borderSm,
                          ),
                          child: Text(
                            '$totalCount total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ),
                      const _SettingsDivider(),
                      // Trash & Archive Shortcut
                      _SettingsTile(
                        icon: Icons.auto_delete_outlined,
                        iconColor: const Color(0xFFF43F5E), // Rose
                        title: 'Trash & Archive',
                        subtitle:
                            '${repo.trashNotes.length} in trash • ${repo.archivedNotes.length} archived',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TrashArchiveScreen(),
                          ),
                        ),
                      ),
                      const _SettingsDivider(),
                      // Export Backup
                      _SettingsTile(
                        icon: Icons.file_upload_outlined,
                        iconColor: const Color(0xFF6366F1), // Indigo
                        title: 'Export Backup (JSON)',
                        subtitle: 'Save notes safely to a JSON backup file',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        onTap: () => _exportNotes(context),
                      ),
                      const _SettingsDivider(),
                      // Import Backup
                      _SettingsTile(
                        icon: Icons.file_download_outlined,
                        iconColor: const Color(0xFF8B5CF6), // Violet
                        title: 'Import Backup (JSON)',
                        subtitle: 'Restore notes from a backup file',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        onTap: () => _showImportDialog(context),
                      ),
                      const _SettingsDivider(),
                      // Clear All Notes
                      _SettingsTile(
                        icon: Icons.delete_sweep_outlined,
                        iconColor: AppColors.error,
                        title: 'Clear All Notes',
                        subtitle: 'Permanently delete all stored notes',
                        isDestructive: true,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                        onTap: () => _confirmClearAll(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==========================================================
                  // 4. ABOUT SECTION (Sole Place For Developer Credit)
                  // ==========================================================
                  const _SectionHeader(title: 'ABOUT'),
                  _SettingsGlassCard(
                    children: [
                      // App Info Card
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: AppRadii.borderMd,
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.28,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'iNote',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  'Version 2.0.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.12),
                                borderRadius: AppRadii.borderSm,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 12,
                                    color: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'On-Device',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _SettingsDivider(),
                      // Developer Credit (Solely inside Settings -> About)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Designed & Created by ',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              'Mrh Rafi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _SettingsDivider(),
                      // Feedback & Support Tile
                      _SettingsTile(
                        icon: Icons.mail_outline_rounded,
                        iconColor: AppColors.primary,
                        title: 'Feedback & Support',
                        subtitle: 'mrhrafi@hotmail.com',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        onTap: () => _launchEmail('mrhrafi@hotmail.com'),
                      ),
                      const _SettingsDivider(),
                      // Privacy Guarantee
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '100% On-Device • Your notes stay private and never leave your phone.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Bottom Tagline
                  Center(
                    child: Text(
                      'Crafted for calm, distraction-free note taking',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// REUSABLE LIQUID GLASS SETTINGS WIDGETS
// ============================================================================

/// Section uppercase header with Apple-grade micro-typography.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
      ),
    );
  }
}

/// Translucent liquid glass card grouping related settings.
class _SettingsGlassCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGlassCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.lightSurface.withValues(alpha: 0.90),
        borderRadius: AppRadii.borderLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppShadows.darkCard : AppShadows.lightCard,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.borderLg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

/// Compact, aligned row inside a grouped settings card.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _IconBadge(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDestructive
                        ? AppColors.error
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      );
    }

    return content;
  }
}

/// Subtle rounded container for category leading icons.
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: AppRadii.borderSm,
      ),
      child: Center(child: Icon(icon, size: 20, color: color)),
    );
  }
}

/// Inset divider aligned with setting row content margins.
class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64, // Aligns after 34px icon + padding + spacing
      endIndent: 16,
      color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
    );
  }
}

/// 3-option liquid glass segmented control for System / Light / Dark theme switching.
class _ThemeModeSegmentedPill extends StatelessWidget {
  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSegmentedPill({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated.withValues(alpha: 0.65)
            : AppColors.lightSurfaceElevated.withValues(alpha: 0.85),
        borderRadius: AppRadii.borderMd,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorderSubtle
              : AppColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildItem(
            context: context,
            label: 'System',
            icon: Icons.settings_brightness_rounded,
            mode: ThemeMode.system,
          ),
          const SizedBox(width: 4),
          _buildItem(
            context: context,
            label: 'Light',
            icon: Icons.light_mode_rounded,
            mode: ThemeMode.light,
          ),
          const SizedBox(width: 4),
          _buildItem(
            context: context,
            label: 'Dark',
            icon: Icons.dark_mode_rounded,
            mode: ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required String label,
    required IconData icon,
    required ThemeMode mode,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedMode == mode;

    return Expanded(
      child: PressableScale(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceHighlight : Colors.white)
                : Colors.transparent,
            borderRadius: AppRadii.borderSm,
            border: isSelected
                ? Border.all(
                    color: isDark
                        ? const Color(0x33FFFFFF)
                        : const Color(0x18000000),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.08,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact 2-button segmented pill for Default Notes Layout (Grid / List).
class _LayoutModeToggle extends StatelessWidget {
  final NotesViewMode currentMode;
  final ValueChanged<NotesViewMode> onChanged;

  const _LayoutModeToggle({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated.withValues(alpha: 0.65)
            : AppColors.lightSurfaceElevated.withValues(alpha: 0.85),
        borderRadius: AppRadii.borderSm,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorderSubtle
              : AppColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context: context,
            icon: Icons.grid_view_rounded,
            tooltip: 'Grid View',
            mode: NotesViewMode.grid,
          ),
          const SizedBox(width: 2),
          _buildOption(
            context: context,
            icon: Icons.view_agenda_rounded,
            tooltip: 'List View',
            mode: NotesViewMode.list,
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required NotesViewMode mode,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = currentMode == mode;

    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceHighlight : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.20 : 0.08,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
