import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../data/models/note_filter.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/preferences_repository.dart';

/// Minimal, elegant Settings & About screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=iNote%20Feedback');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              decoration: const InputDecoration(
                hintText: '{\n  "app": "iNote",\n  "notes": [...]\n}',
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
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to import: Invalid JSON format'),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notes?'),
        content: const Text(
          'This will permanently delete all notes. Make sure to export a backup first if you want to keep your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final repo = NotesRepository.instance;
              for (var n in List.of(repo.allNotes)) {
                await repo.permanentlyDelete(n.id);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notes have been cleared')),
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

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              // Appearance Section
              _SectionHeader(title: 'APPEARANCE'),
              Material(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.borderLg,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.brightness_6_rounded,
                            size: 22,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Theme Mode',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(
                                  Icons.settings_brightness_rounded,
                                  size: 18,
                                ),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_rounded, size: 18),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_rounded, size: 18),
                              ),
                            ],
                            selected: {prefs.themeMode},
                            onSelectionChanged: (set) =>
                                prefs.setThemeMode(set.first),
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: AppRadii.borderMd,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Default Note Layout
                    ListTile(
                      leading: const Icon(
                        Icons.view_compact_alt_rounded,
                        size: 22,
                      ),
                      title: const Text('Default Notes Layout'),
                      trailing: DropdownButton<NotesViewMode>(
                        value: repo.viewMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: NotesViewMode.grid,
                            child: Text('Grid View'),
                          ),
                          DropdownMenuItem(
                            value: NotesViewMode.list,
                            child: Text('List View'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) repo.setViewMode(v);
                        },
                      ),
                    ),
                    const Divider(),
                    // Haptic feedback toggle
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration_rounded, size: 22),
                      title: const Text('Haptic Micro-feedback'),
                      subtitle: const Text(
                        'Tactile response on taps and interactions',
                      ),
                      value: prefs.hapticsEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => prefs.toggleHaptics(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data & Storage Section
              _SectionHeader(title: 'DATA & STORAGE'),
              Material(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.borderLg,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.inventory_2_outlined, size: 22),
                      title: const Text('Notes in Storage'),
                      subtitle: Text(
                        '$activeCount active • $pinnedCount pinned',
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined, size: 22),
                      title: const Text('Export Backup (JSON)'),
                      subtitle: const Text(
                        'Save your notes safely to a backup file',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onTap: () => _exportNotes(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.file_download_outlined,
                        size: 22,
                      ),
                      title: const Text('Import Backup (JSON)'),
                      subtitle: const Text('Restore notes from a backup file'),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onTap: () => _showImportDialog(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_sweep_outlined,
                        size: 22,
                        color: AppColors.error,
                      ),
                      title: const Text(
                        'Clear All Notes',
                        style: TextStyle(color: AppColors.error),
                      ),
                      subtitle: const Text(
                        'Delete all stored notes permanently',
                      ),
                      onTap: () => _confirmClearAll(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About & Creator Section (Sole place for developer credit)
              _SectionHeader(title: 'ABOUT'),
              Material(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.borderLg,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: AppRadii.borderMd,
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'iNote',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
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
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 12),
                      // Subtle developer credit
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Contact button
                      InkWell(
                        onTap: () => _launchEmail('mrhrafi@hotmail.com'),
                        borderRadius: AppRadii.borderSm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'mrhrafi@hotmail.com',
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
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '100% On-Device • Your notes stay private and never leave your phone.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
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
