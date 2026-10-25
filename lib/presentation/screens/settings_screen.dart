import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../data/models/note_filter.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import 'trash_archive_screen.dart';

/// Refined Settings & Preferences screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _launch(String urlString) async {
    final uri = Uri.parse(urlString);
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
        final trashCount = repo.trashNotes.length;
        final archivedCount = repo.archivedNotes.length;

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
                            size: 20,
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
                                  size: 16,
                                ),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_rounded, size: 16),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_rounded, size: 16),
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
                      leading: const Icon(Icons.view_compact_alt_rounded),
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
                      secondary: const Icon(Icons.vibration_rounded),
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
                      leading: const Icon(Icons.analytics_outlined),
                      title: const Text('Storage Overview'),
                      subtitle: Text(
                        '$activeCount active • $pinnedCount pinned • $archivedCount archived • $trashCount in trash',
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.archive_outlined),
                      title: const Text('Archived Notes'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$archivedCount'),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TrashArchiveScreen(initialTab: 1),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: const Text('Trash Bin'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$trashCount'),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TrashArchiveScreen(initialTab: 0),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: const Text('Export Backup (JSON)'),
                      subtitle: const Text('Safely export notes and notebooks'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _exportNotes(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Import Backup'),
                      subtitle: const Text('Restore notes from JSON format'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showImportDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About & Attribution Section (Preserves Mrh Rafi)
              _SectionHeader(title: 'ABOUT & AUTHOR'),
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
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.note_alt_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: const Text('iNote — Premium Edition'),
                      subtitle: const Text('Version 2.0.0 (Production Build)'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded),
                      title: const Text('Author & Creator'),
                      subtitle: const Text('Mrh Rafi • github.com/mrhrafi3'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _launch('https://github.com/mrhrafi3'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.mail_outline_rounded),
                      title: const Text('Contact Developer'),
                      subtitle: const Text('mrhrafi@hotmail.com'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _launch(
                        'mailto:mrhrafi@hotmail.com?subject=iNote%20App%20Inquiry',
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.feedback_outlined),
                      title: const Text('Feedback & Bug Reports'),
                      subtitle: const Text('mrhrafi99@gmail.com'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _launch(
                        'mailto:mrhrafi99@gmail.com?subject=iNote%20Feedback',
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.security_rounded),
                      title: const Text('Privacy & Security'),
                      subtitle: const Text(
                        '100% On-device storage. No analytics or tracking.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Crafted with ❤️ for fast, calm productivity',
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
